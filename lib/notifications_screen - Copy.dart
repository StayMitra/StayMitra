import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'transaction_service.dart';
import 'pg_manager_service.dart';
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState
    extends State<NotificationsScreen> {
  bool _loading = true;

  List<Map<String, dynamic>> _notifications = [];

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  User? get _currentUser =>
      FirebaseAuth.instance.currentUser;

  String? get _ownerId =>
      _currentUser?.uid;

  String? get _propertyId =>
      PgManagerService.activePgId;

  CollectionReference<Map<String, dynamic>>?
      get _notificationsCollection {
    final ownerId = _ownerId;
    final propertyId = _propertyId;

    if (ownerId == null ||
        ownerId.isEmpty ||
        propertyId == null ||
        propertyId.isEmpty) {
      return null;
    }

    return _firestore
        .collection('owners')
        .doc(ownerId)
        .collection('properties')
        .doc(propertyId)
        .collection('notifications');
  }

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> _initializeNotifications() async {
    try {
      final user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (!mounted) return;

        setState(() {
          _notifications = [];
          _loading = false;
        });

        _showMessage(
          'Please login to view notifications.',
          isError: true,
        );
        return;
      }

      final propertyId =
          PgManagerService.activePgId;

      if (propertyId == null ||
          propertyId.isEmpty) {
        if (!mounted) return;

        setState(() {
          _notifications = [];
          _loading = false;
        });

        _showMessage(
          'Please select a PG first.',
          isError: true,
        );
        return;
      }

      await _generateRentReminders();

      await _loadNotifications();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showMessage(
        'Unable to load notifications.',
        isError: true,
      );
    }
  }

  // ============================================================
  // GENERATE RENT REMINDERS
  // ============================================================

  Future<void> _generateRentReminders() async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    final propertyId =
        PgManagerService.activePgId;

    if (propertyId == null ||
        propertyId.isEmpty) {
      return;
    }

    final propertyRef = _firestore
        .collection('owners')
        .doc(user.uid)
        .collection('properties')
        .doc(propertyId);

    final tenantsSnapshot = await propertyRef
        .collection('tenants')
        .where(
          'status',
          isEqualTo: 'active',
        )
        .get();

    if (tenantsSnapshot.docs.isEmpty) {
      return;
    }

    // Make sure the transaction service has the
    // latest Firebase transactions before calculating
    // pending rent.
    await TransactionService.initialize();

    final transactions =
        TransactionService.getTransactions();

    final now = DateTime.now();

    for (final tenantDoc
        in tenantsSnapshot.docs) {
      try {
        final tenant =
            tenantDoc.data();

        final tenantId =
            tenantDoc.id;

        final tenantName =
            tenant['full_name']
                    ?.toString()
                    .trim() ??
                '';

        final joiningDate =
            _readFirebaseDate(
          tenant['joining_date'],
        );

        final monthlyRent =
            _readDouble(
          tenant['monthly_rent'],
        );

        if (tenantId.isEmpty ||
            tenantName.isEmpty ||
            joiningDate == null ||
            monthlyRent <= 0) {
          continue;
        }

        // ------------------------------------------------------
        // Current month's rent due date
        // ------------------------------------------------------

        final dueDate =
            _getMonthlyDueDate(
          now.year,
          now.month,
          joiningDate.day,
        );

        // ------------------------------------------------------
        // If this month's due date has already passed,
        // use next month's due date.
        // ------------------------------------------------------

        DateTime actualDueDate =
            dueDate;

        final todayOnly = DateTime(
          now.year,
          now.month,
          now.day,
        );

        if (actualDueDate
            .isBefore(todayOnly)) {
          actualDueDate =
              _getNextMonthDueDate(
            now,
            joiningDate.day,
          );
        }

        // ------------------------------------------------------
        // 7-DAY REMINDER RULE
        // ------------------------------------------------------
        //
        // A reminder is created exactly 7 days before
        // the due date. We also allow the app to create
        // the reminder during the remaining 7-day window
        // so a reminder is not missed if the app was not
        // opened on the exact 7th day.
        // ------------------------------------------------------

        final daysUntilDue =
            actualDueDate
                .difference(todayOnly)
                .inDays;

        if (daysUntilDue < 1 ||
            daysUntilDue > 7) {
          continue;
        }

        // ------------------------------------------------------
        // Check current month's paid rent
        // ------------------------------------------------------

        final paidThisMonth =
            _getTenantPaidThisMonth(
          tenantName,
          transactions,
          now,
        );

        final pendingAmount =
            monthlyRent -
                paidThisMonth;

        if (pendingAmount <= 0) {
          continue;
        }

        // ------------------------------------------------------
        // Room number
        // ------------------------------------------------------

        final roomNumber =
            await _getRoomNumber(
          propertyRef: propertyRef,
          bedId: tenant['bed_id']
              ?.toString(),
        );

        final dueDateText =
            _formatDate(actualDueDate);

        final amountText =
            _formatMoney(
          pendingAmount,
        );

        final message =
            'Rent reminder for $tenantName: '
            '₹$amountText rent is due on '
            '$dueDateText. '
            'Please make the payment by the due date.';

        const title =
            'Rent Payment Reminder';

        // ------------------------------------------------------
        // OWNER notification
        // ------------------------------------------------------

        await _insertReminderIfNotExists(
          propertyRef: propertyRef,
          tenantId: tenantId,
          tenantName: tenantName,
          roomNumber: roomNumber,
          amount: pendingAmount,
          dueDate: actualDueDate,
          audience: 'owner',
          title: title,
          message: message,
        );

        // ------------------------------------------------------
        // TENANT notification
        // ------------------------------------------------------

        await _insertReminderIfNotExists(
          propertyRef: propertyRef,
          tenantId: tenantId,
          tenantName: tenantName,
          roomNumber: roomNumber,
          amount: pendingAmount,
          dueDate: actualDueDate,
          audience: 'tenant',
          title: title,
          message: message,
        );
      } catch (_) {
        // One bad tenant record should not stop
        // reminders for other tenants.
        continue;
      }
    }
  }

  // ============================================================
  // INSERT REMINDER IF NOT EXISTS
  // ============================================================

  Future<void> _insertReminderIfNotExists({
    required DocumentReference<Map<String, dynamic>>
        propertyRef,
    required String tenantId,
    required String tenantName,
    required String roomNumber,
    required double amount,
    required DateTime dueDate,
    required String audience,
    required String title,
    required String message,
  }) async {
    final dueDateKey =
        _dateKey(dueDate);

    // Deterministic ID prevents duplicate reminders
    // when the screen is opened multiple times.
    final notificationId =
        'rent_${tenantId}_${dueDateKey}_$audience';

    final notificationRef =
        propertyRef
            .collection('notifications')
            .doc(notificationId);

    final existing =
        await notificationRef.get();

    if (existing.exists) {
      return;
    }

    await notificationRef.set({
      'title': title,
      'message': message,
      'type': 'rent_reminder',

      'tenant_id': tenantId,
      'tenant_name': tenantName,
      'room_number': roomNumber,

      'amount': amount,
      'due_date': dueDateKey,

      'audience': audience,

      'is_read': false,

      // Future WhatsApp/SMS integration
      'whatsapp_status': 'pending',
      'sms_status': 'pending',

      'owner_id': _ownerId,
      'property_id': _propertyId,

      'created_at':
          FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // GET TENANT PAID THIS MONTH
  // ============================================================

  double _getTenantPaidThisMonth(
    String tenantName,
    List transactions,
    DateTime now,
  ) {
    double total = 0;

    final normalizedTenant =
        tenantName.trim().toLowerCase();

    for (final transaction
        in transactions) {
      try {
        if (transaction.type.name !=
            'income') {
          continue;
        }

        if (transaction.date.year !=
                now.year ||
            transaction.date.month !=
                now.month) {
          continue;
        }

        final description =
            transaction.description
                .trim()
                .toLowerCase();

        if (description.contains(
          normalizedTenant,
        )) {
          total += transaction.amount;
        }
      } catch (_) {
        continue;
      }
    }

    return total;
  }

  // ============================================================
  // GET ROOM NUMBER
  // ============================================================

  Future<String> _getRoomNumber({
    required DocumentReference<Map<String, dynamic>>
        propertyRef,
    required String? bedId,
  }) async {
    if (bedId == null ||
        bedId.isEmpty) {
      return '';
    }

    try {
      final roomsSnapshot =
          await propertyRef
              .collection('rooms')
              .get();

      for (final roomDoc
          in roomsSnapshot.docs) {
        final bedSnapshot =
            await roomDoc.reference
                .collection('beds')
                .doc(bedId)
                .get();

        if (!bedSnapshot.exists) {
          continue;
        }

        final roomData =
            roomDoc.data();

        return roomData[
                    'room_number']
                ?.toString() ??
            roomData['name']
                ?.toString() ??
            '';
      }

      // Some existing Firebase data may use
      // the bed document ID as the bed ID but store
      // roomId inside the bed.
      for (final roomDoc
          in roomsSnapshot.docs) {
        final bedsSnapshot =
            await roomDoc.reference
                .collection('beds')
                .get();

        for (final bedDoc
            in bedsSnapshot.docs) {
          if (bedDoc.id != bedId) {
            continue;
          }

          final roomData =
              roomDoc.data();

          return roomData[
                      'room_number']
                  ?.toString() ??
              roomData['name']
                  ?.toString() ??
              '';
        }
      }
    } catch (_) {
      return '';
    }

    return '';
  }

  // ============================================================
  // GET MONTHLY DUE DATE
  // ============================================================

  DateTime _getMonthlyDueDate(
    int year,
    int month,
    int requestedDay,
  ) {
    final lastDay =
        DateTime(
      year,
      month + 1,
      0,
    ).day;

    final actualDay =
        requestedDay > lastDay
            ? lastDay
            : requestedDay;

    return DateTime(
      year,
      month,
      actualDay,
    );
  }

  // ============================================================
  // GET NEXT MONTH DUE DATE
  // ============================================================

  DateTime _getNextMonthDueDate(
    DateTime currentDate,
    int requestedDay,
  ) {
    final nextMonth =
        currentDate.month == 12
            ? 1
            : currentDate.month + 1;

    final nextYear =
        currentDate.month == 12
            ? currentDate.year + 1
            : currentDate.year;

    return _getMonthlyDueDate(
      nextYear,
      nextMonth,
      requestedDay,
    );
  }

  // ============================================================
  // LOAD NOTIFICATIONS
  // ============================================================

  Future<void> _loadNotifications() async {
    try {
      final collection =
          _notificationsCollection;

      if (collection == null) {
        if (!mounted) return;

        setState(() {
          _notifications = [];
          _loading = false;
        });

        return;
      }

      final snapshot =
          await collection
              .orderBy(
                'created_at',
                descending: true,
              )
              .get();

      final notifications =
          snapshot.docs.map((doc) {
        final data =
            doc.data();

        return <String, dynamic>{
          'id': doc.id,
          ...data,
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        _notifications =
            notifications;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refreshNotifications() async {
    try {
      await _generateRentReminders();

      await _loadNotifications();

      if (!mounted) return;

      _showMessage(
        'Notifications refreshed.',
      );
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        'Unable to refresh notifications.',
        isError: true,
      );
    }
  }

  // ============================================================
  // MARK AS READ
  // ============================================================

  Future<void> _markAsRead(
    Map<String, dynamic> notification,
  ) async {
    final id =
        notification['id']
            ?.toString();

    if (id == null ||
        id.isEmpty) {
      return;
    }

    try {
      final collection =
          _notificationsCollection;

      if (collection == null) {
        return;
      }

      await collection
          .doc(id)
          .update({
        'is_read': true,
        'read_at':
            FieldValue.serverTimestamp(),
      });

      await _loadNotifications();
    } catch (_) {
      // Ignore
    }
  }

  // ============================================================
  // DELETE NOTIFICATION
  // ============================================================

  Future<void> _deleteNotification(
    Map<String, dynamic> notification,
  ) async {
    final id =
        notification['id']
            ?.toString();

    if (id == null ||
        id.isEmpty) {
      return;
    }

    try {
      final collection =
          _notificationsCollection;

      if (collection == null) {
        return;
      }

      await collection
          .doc(id)
          .delete();

      await _loadNotifications();

      if (!mounted) return;

      _showMessage(
        'Notification deleted.',
      );
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        'Unable to delete notification.',
        isError: true,
      );
    }
  }

  // ============================================================
  // MARK ALL AS READ
  // ============================================================

  Future<void> _markAllAsRead() async {
    try {
      final collection =
          _notificationsCollection;

      if (collection == null) {
        return;
      }

      final snapshot =
          await collection.get();

      final batch =
          _firestore.batch();

      for (final doc
          in snapshot.docs) {
        batch.update(
          doc.reference,
          {
            'is_read': true,
            'read_at':
                FieldValue.serverTimestamp(),
          },
        );
      }

      if (snapshot.docs.isNotEmpty) {
        await batch.commit();
      }

      await _loadNotifications();

      if (!mounted) return;

      _showMessage(
        'All notifications marked as read.',
      );
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        'Unable to update notifications.',
        isError: true,
      );
    }
  }

  // ============================================================
  // CLEAR ALL
  // ============================================================

  Future<void> _clearAllNotifications() async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(18),
          ),
          title: const Text(
            'Clear Notifications?',
            style: TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          content: const Text(
            'All notifications will be removed from this PG.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
                  const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFFDC2626,
                ),
                foregroundColor:
                    Colors.white,
              ),
              child:
                  const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      final collection =
          _notificationsCollection;

      if (collection == null) {
        return;
      }

      final snapshot =
          await collection.get();

      final batch =
          _firestore.batch();

      for (final doc
          in snapshot.docs) {
        batch.delete(
          doc.reference,
        );
      }

      if (snapshot.docs.isNotEmpty) {
        await batch.commit();
      }

      await _loadNotifications();

      if (!mounted) return;

      _showMessage(
        'All notifications cleared.',
      );
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        'Unable to clear notifications.',
        isError: true,
      );
    }
  }

  Future<void> _showNotificationDetails(
    Map<String, dynamic> notification,
  ) async {
    await _markAsRead(notification);

    if (!mounted) return;

    final title =
        notification['title']
                ?.toString() ??
            'Notification';

    final message =
        notification['message']
                ?.toString() ??
            '';

    final tenantName =
        notification['tenant_name']
                ?.toString() ??
            '';

    final roomNumber =
        notification['room_number']
                ?.toString() ??
            '';

    final amount =
        (notification['amount'] as num?)
                ?.toDouble();

    final dueDate =
        notification['due_date']
                ?.toString() ??
            '';

    final whatsappStatus =
        notification[
                  'whatsapp_status']
                ?.toString() ??
            'pending';

    final smsStatus =
        notification['sms_status']
                ?.toString() ??
            'pending';

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              28,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration:
                            BoxDecoration(
                          color:
                              const Color(
                            0xFFFFF7ED,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            16,
                          ),
                        ),
                        child: const Icon(
                          Icons
                              .notifications_active_rounded,
                          color:
                              Color(
                            0xFFF59E0B,
                          ),
                          size: 28,
                        ),
                      ),
                      const SizedBox(
                        width: 13,
                      ),
                      Expanded(
                        child: Text(
                          title,
                          style:
                              const TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight
                                    .bold,
                            color:
                                Color(
                              0xFF111827,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 22,
                  ),

                  const Text(
                    'Message',
                    style:
                        TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w600,
                      color:
                          Color(
                        0xFF64748B,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 7,
                  ),

                  Text(
                    message,
                    style:
                        const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color:
                          Color(
                        0xFF111827,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  if (tenantName
                      .isNotEmpty)
                    _detailRow(
                      Icons.person_outline,
                      'Tenant',
                      tenantName,
                    ),

                  if (roomNumber
                      .isNotEmpty)
                    _detailRow(
                      Icons
                          .meeting_room_outlined,
                      'Room',
                      roomNumber,
                    ),

                  if (amount != null)
                    _detailRow(
                      Icons
                          .currency_rupee_rounded,
                      'Pending Rent',
                      '₹${_formatMoney(amount)}',
                    ),

                  if (dueDate
                      .isNotEmpty)
                    _detailRow(
                      Icons
                          .calendar_today_outlined,
                      'Due Date',
                      _formatStoredDate(
                        dueDate,
                      ),
                    ),

                  const SizedBox(
                    height: 12,
                  ),

                  _statusRow(
                    Icons
                        .chat_outlined,
                    'WhatsApp',
                    whatsappStatus,
                  ),

                  _statusRow(
                    Icons
                        .sms_outlined,
                    'SMS',
                    smsStatus,
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(
                      14,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFFF8FAFC,
                      ),
                      borderRadius:
                          BorderRadius
                              .circular(
                        14,
                      ),
                    ),
                    child:
                        const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color:
                              Color(
                            0xFF64748B,
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: Text(
                            'WhatsApp and SMS delivery will be connected through the messaging service.',
                            style:
                                TextStyle(
                              fontSize: 12,
                              height:
                                  1.4,
                              color:
                                  Color(
                                0xFF64748B,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F8FC),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor:
            const Color(0xFF111827),

        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 21,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value ==
                  'read_all') {
                _markAllAsRead();
              }

              if (value ==
                  'clear_all') {
                _clearAllNotifications();
              }
            },
            itemBuilder:
                (context) => const [
              PopupMenuItem(
                value: 'read_all',
                child: Row(
                  children: [
                    Icon(
                      Icons
                          .done_all_rounded,
                      size: 20,
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Text(
                      'Mark all as read',
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(
                      Icons
                          .delete_sweep_outlined,
                      size: 20,
                      color:
                          Color(
                        0xFFDC2626,
                      ),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Text(
                      'Clear all',
                    ),
                  ],
                ),
              ),
            ],
            icon: const Icon(
              Icons.more_vert_rounded,
            ),
          ),

          IconButton(
            onPressed:
                _refreshNotifications,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: _loading
            ? const Center(
                child:
                    CircularProgressIndicator(),
              )
            : _notifications.isEmpty
                ? _emptyState()
                : RefreshIndicator(
                    onRefresh:
                        _refreshNotifications,
                    child:
                        ListView.separated(
                      padding:
                          const EdgeInsets
                              .fromLTRB(
                        16,
                        18,
                        16,
                        30,
                      ),
                      itemCount:
                          _notifications
                              .length,
                      separatorBuilder:
                          (
                        context,
                        index,
                      ) =>
                              const SizedBox(
                        height: 12,
                      ),
                      itemBuilder:
                          (
                        context,
                        index,
                      ) {
                        return _notificationCard(
                          _notifications[
                              index],
                        );
                      },
                    ),
                  ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xFFEFF6FF,
                ),
                borderRadius:
                    BorderRadius.circular(
                  25,
                ),
              ),
              child: const Icon(
                Icons
                    .notifications_none_rounded,
                size: 45,
                color:
                    Color(0xFF2563EB),
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            const Text(
              'No Notifications Yet',
              style:
                  TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
                color:
                    Color(0xFF111827),
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            const Text(
              'Rent reminders, payment updates and important alerts will appear here.',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                fontSize: 13,
                height: 1.5,
                color:
                    Color(0xFF64748B),
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            OutlinedButton.icon(
              onPressed:
                  _refreshNotifications,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text(
                'Check for Reminders',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // NOTIFICATION CARD
  // ============================================================

  Widget _notificationCard(
    Map<String, dynamic> notification,
  ) {
    final title =
        notification['title']
                ?.toString() ??
            'Notification';

    final message =
        notification['message']
                ?.toString() ??
            '';

    final type =
        notification['type']
                ?.toString() ??
            '';

    final tenantName =
        notification['tenant_name']
                ?.toString() ??
            '';

    final roomNumber =
        notification['room_number']
                ?.toString() ??
            '';

    final amount =
        (notification['amount'] as num?)
                ?.toDouble();

    final dueDate =
        notification['due_date']
                ?.toString() ??
            '';

    final rawIsRead =
        notification['is_read'];

    final isRead =
        rawIsRead is bool
            ? rawIsRead
            : rawIsRead is num
                ? rawIsRead.toInt() == 1
                : rawIsRead
                        ?.toString()
                        .toLowerCase() ==
                    'true';

    final audience =
        notification['audience']
                ?.toString() ??
            'owner';

    final whatsappStatus =
        notification[
                  'whatsapp_status']
                ?.toString() ??
            'pending';

    final smsStatus =
        notification['sms_status']
                ?.toString() ??
            'pending';

    return Material(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(18),

      child: InkWell(
        onTap: () {
          _showNotificationDetails(
            notification,
          );
        },

        borderRadius:
            BorderRadius.circular(18),

        child: Container(
          padding:
              const EdgeInsets.all(15),

          decoration:
              BoxDecoration(
            color: isRead
                ? Colors.white
                : const Color(
                    0xFFFAFCFF,
                  ),
            borderRadius:
                BorderRadius.circular(
              18,
            ),
            border: Border.all(
              color:
                  isRead
                      ? const Color(
                          0xFFE5E7EB,
                        )
                      : const Color(
                          0xFFBFDBFE,
                        ),
            ),
          ),

          child: Column(
            children: [
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFFFFF7ED,
                      ),
                      borderRadius:
                          BorderRadius
                              .circular(
                        15,
                      ),
                    ),
                    child:
                        const Icon(
                      Icons
                          .notifications_active_rounded,
                      color:
                          Color(
                        0xFFF59E0B,
                      ),
                      size: 27,
                    ),
                  ),

                  const SizedBox(
                    width: 13,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child:
                                  Text(
                                title,
                                maxLines:
                                    1,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style:
                                    const TextStyle(
                                  fontSize:
                                      15,
                                  fontWeight:
                                      FontWeight
                                          .w600,
                                  color:
                                      Color(
                                    0xFF111827,
                                  ),
                                ),
                              ),
                            ),

                            if (!isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration:
                                    const BoxDecoration(
                                  color:
                                      Color(
                                    0xFF2563EB,
                                  ),
                                  shape:
                                      BoxShape
                                          .circle,
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(
                          height: 5,
                        ),

                        Text(
                          message,
                          maxLines: 3,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color:
                                Color(
                              0xFF64748B,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  PopupMenuButton<String>(
                    onSelected:
                        (value) {
                      if (value ==
                          'read') {
                        _markAsRead(
                          notification,
                        );
                      }

                      if (value ==
                          'delete') {
                        _deleteNotification(
                          notification,
                        );
                      }
                    },
                    itemBuilder:
                        (context) =>
                            [
                      if (!isRead)
                        const PopupMenuItem(
                          value:
                              'read',
                          child:
                              Row(
                            children: [
                              Icon(
                                Icons
                                    .done_rounded,
                                size:
                                    20,
                              ),
                              SizedBox(
                                width:
                                    10,
                              ),
                              Text(
                                'Mark as read',
                              ),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value:
                            'delete',
                        child:
                            Row(
                          children: [
                            Icon(
                              Icons
                                  .delete_outline_rounded,
                              size:
                                  20,
                              color:
                                  Color(
                                0xFFDC2626,
                              ),
                            ),
                            SizedBox(
                              width:
                                  10,
                            ),
                            Text(
                              'Delete',
                            ),
                          ],
                        ),
                      ),
                    ],
                    icon:
                        const Icon(
                      Icons
                          .more_vert_rounded,
                      color:
                          Color(
                        0xFF64748B,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 13,
              ),

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets
                        .all(11),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFF8FAFC,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 7,
                  children: [
                    if (tenantName
                        .isNotEmpty)
                      _smallInfo(
                        Icons
                            .person_outline,
                        tenantName,
                      ),

                    if (roomNumber
                        .isNotEmpty)
                      _smallInfo(
                        Icons
                            .meeting_room_outlined,
                        'Room $roomNumber',
                      ),

                    if (amount !=
                        null)
                      _smallInfo(
                        Icons
                            .currency_rupee_rounded,
                        '₹${_formatMoney(amount)}',
                      ),

                    if (dueDate
                        .isNotEmpty)
                      _smallInfo(
                        Icons
                            .calendar_today_outlined,
                        _formatStoredDate(
                          dueDate,
                        ),
                      ),

                    _smallInfo(
                      audience ==
                              'tenant'
                          ? Icons
                              .person_rounded
                          : Icons
                              .admin_panel_settings_outlined,
                      audience ==
                              'tenant'
                          ? 'Tenant'
                          : 'Owner',
                    ),
                  ],
                ),
              ),

              if (type ==
                  'rent_reminder') ...[
                const SizedBox(
                  height: 10,
                ),

                Row(
                  children: [
                    _deliveryStatus(
                      Icons
                          .chat_outlined,
                      'WhatsApp',
                      whatsappStatus,
                    ),

                    const SizedBox(
                      width: 8,
                    ),

                    _deliveryStatus(
                      Icons
                          .sms_outlined,
                      'SMS',
                      smsStatus,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SMALL INFO
  // ============================================================

  Widget _smallInfo(
    IconData icon,
    String text,
  ) {
    return Row(
      mainAxisSize:
          MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 15,
          color:
              const Color(
            0xFF64748B,
          ),
        ),
        const SizedBox(
          width: 4,
        ),
        Text(
          text,
          style:
              const TextStyle(
            fontSize: 11,
            color:
                Color(0xFF64748B),
            fontWeight:
                FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DELIVERY STATUS
  // ============================================================

  Widget _deliveryStatus(
    IconData icon,
    String label,
    String status,
  ) {
    final isSent =
        status == 'sent';

    return Expanded(
      child: Container(
        padding:
            const EdgeInsets
                .symmetric(
          horizontal: 10,
          vertical: 7,
        ),
        decoration:
            BoxDecoration(
          color:
              isSent
                  ? const Color(
                      0xFFF0FDF4,
                    )
                  : const Color(
                      0xFFFFFBEB,
                    ),
          borderRadius:
              BorderRadius.circular(
            9,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 15,
              color:
                  isSent
                      ? const Color(
                          0xFF16A34A,
                        )
                      : const Color(
                          0xFFD97706,
                        ),
            ),
            const SizedBox(
              width: 5,
            ),
            Expanded(
              child: Text(
                '$label: ${isSent ? 'Sent' : 'Pending'}',
                style:
                    TextStyle(
                  fontSize: 10,
                  fontWeight:
                      FontWeight.w600,
                  color:
                      isSent
                          ? const Color(
                              0xFF16A34A,
                            )
                          : const Color(
                              0xFFD97706,
                            ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _detailRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color:
                const Color(
              0xFF64748B,
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style:
                  const TextStyle(
                fontSize: 12,
                color:
                    Color(
                  0xFF64748B,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style:
                  const TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.w600,
                color:
                    Color(
                  0xFF111827,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS ROW
  // ============================================================

  Widget _statusRow(
    IconData icon,
    String label,
    String status,
  ) {
    final sent =
        status == 'sent';

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color:
                sent
                    ? const Color(
                        0xFF16A34A,
                      )
                    : const Color(
                        0xFFD97706,
                      ),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Text(
              label,
              style:
                  const TextStyle(
                fontSize: 13,
                color:
                    Color(
                  0xFF475569,
                ),
              ),
            ),
          ),
          Text(
            sent
                ? 'Sent'
                : 'Pending',
            style:
                TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.w600,
              color:
                  sent
                      ? const Color(
                          0xFF16A34A,
                        )
                      : const Color(
                          0xFFD97706,
                        ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FIREBASE VALUE HELPERS
  // ============================================================

  DateTime? _readFirebaseDate(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }

  double _readDouble(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0.0;
  }

  // ============================================================
  // DATE HELPERS
  // ============================================================

  String _dateKey(
    DateTime date,
  ) {
    final month =
        date.month
            .toString()
            .padLeft(2, '0');

    final day =
        date.day
            .toString()
            .padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  String _formatDate(
    DateTime date,
  ) {
    final day =
        date.day
            .toString()
            .padLeft(2, '0');

    final month =
        date.month
            .toString()
            .padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _formatStoredDate(
    String value,
  ) {
    final date =
        DateTime.tryParse(value);

    if (date == null) {
      return value;
    }

    return _formatDate(date);
  }

  String _formatMoney(
    double value,
  ) {
    if (value == value.roundToDouble()) {
      return value
          .toInt()
          .toString();
    }

    return value.toStringAsFixed(2);
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
              Text(message),
          behavior:
              SnackBarBehavior
                  .floating,
          backgroundColor:
              isError
                  ? const Color(
                      0xFFDC2626,
                    )
                  : null,
        ),
      );
  }
}