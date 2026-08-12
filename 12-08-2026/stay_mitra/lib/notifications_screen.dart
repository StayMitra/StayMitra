import 'package:flutter/material.dart';

import 'database_helper.dart';

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
      final db =
          await DatabaseHelper.instance.database;

      await db.execute('''
        CREATE TABLE IF NOT EXISTS notifications (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          message TEXT NOT NULL,
          type TEXT NOT NULL,
          tenant_name TEXT,
          room_number TEXT,
          amount REAL,
          due_date TEXT,
          is_read INTEGER NOT NULL DEFAULT 0,
          whatsapp_status TEXT NOT NULL DEFAULT 'pending',
          sms_status TEXT NOT NULL DEFAULT 'pending',
          created_at TEXT NOT NULL
        )
      ''');

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
  // LOAD NOTIFICATIONS
  // ============================================================

  Future<void> _loadNotifications() async {
    try {
      final db =
          await DatabaseHelper.instance.database;

      final result = await db.query(
        'notifications',
        orderBy: 'created_at DESC',
      );

      if (!mounted) return;

      setState(() {
        _notifications = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  // ============================================================
  // MARK AS READ
  // ============================================================

  Future<void> _markAsRead(
    Map<String, dynamic> notification,
  ) async {
    final id = notification['id'];

    try {
      final db =
          await DatabaseHelper.instance.database;

      await db.update(
        'notifications',
        {
          'is_read': 1,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      await _loadNotifications();
    } catch (e) {
      // Ignore read-status error.
    }
  }

  // ============================================================
  // MARK ALL AS READ
  // ============================================================

  Future<void> _markAllAsRead() async {
    try {
      final db =
          await DatabaseHelper.instance.database;

      await db.update(
        'notifications',
        {
          'is_read': 1,
        },
        where: 'is_read = ?',
        whereArgs: [0],
      );

      await _loadNotifications();

      if (!mounted) return;

      _showMessage(
        'All notifications marked as read.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to update notifications.',
        isError: true,
      );
    }
  }

  // ============================================================
  // DELETE NOTIFICATION
  // ============================================================

  Future<void> _deleteNotification(
    Map<String, dynamic> notification,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(18),
          ),
          title: const Text(
            'Delete Notification?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to delete this notification?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final db =
          await DatabaseHelper.instance.database;

      await db.delete(
        'notifications',
        where: 'id = ?',
        whereArgs: [
          notification['id'],
        ],
      );

      await _loadNotifications();

      if (!mounted) return;

      _showMessage(
        'Notification deleted.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to delete notification.',
        isError: true,
      );
    }
  }

  // ============================================================
  // CLEAR ALL
  // ============================================================

  Future<void> _clearAllNotifications() async {
    if (_notifications.isEmpty) {
      _showMessage(
        'There are no notifications to clear.',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(18),
          ),
          title: const Text(
            'Clear All Notifications?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'All notifications will be removed from this device.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Clear All',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final db =
          await DatabaseHelper.instance.database;

      await db.delete(
        'notifications',
      );

      await _loadNotifications();

      if (!mounted) return;

      _showMessage(
        'All notifications cleared.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to clear notifications.',
        isError: true,
      );
    }
  }

  // ============================================================
  // SHOW NOTIFICATION DETAIL
  // ============================================================

  Future<void> _showNotificationDetail(
    Map<String, dynamic> notification,
  ) async {
    await _markAsRead(notification);

    if (!mounted) return;

    final title =
        notification['title']?.toString() ??
            'Notification';

    final message =
        notification['message']?.toString() ??
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
        notification['amount'];

    final dueDate =
        notification['due_date']
                ?.toString() ??
            '';

    final type =
        notification['type']?.toString() ??
            'general';

    final whatsappStatus =
        notification['whatsapp_status']
                ?.toString() ??
            'pending';

    final smsStatus =
        notification['sms_status']
                ?.toString() ??
            'pending';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(
            20,
            14,
            20,
            28,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFFD1D5DB),
                      borderRadius:
                          BorderRadius.circular(
                        10,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    _notificationIcon(
                      type,
                      size: 52,
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                          color:
                              Color(0xFF111827),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color:
                        Color(0xFF475569),
                  ),
                ),

                if (tenantName.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _detailRow(
                    Icons.person_outline_rounded,
                    'Tenant',
                    tenantName,
                  ),
                ],

                if (roomNumber.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _detailRow(
                    Icons.meeting_room_outlined,
                    'Room',
                    roomNumber,
                  ),
                ],

                if (amount != null) ...[
                  const SizedBox(height: 12),
                  _detailRow(
                    Icons.currency_rupee_rounded,
                    'Rent',
                    '₹${_formatAmount(amount)}',
                  ),
                ],

                if (dueDate.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _detailRow(
                    Icons.calendar_today_outlined,
                    'Due Date',
                    _formatDate(dueDate),
                  ),
                ],

                const SizedBox(height: 20),

                const Text(
                  'Message Status',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color:
                        Color(0xFF111827),
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _statusCard(
                        icon: Icons
                            .chat_rounded,
                        title: 'WhatsApp',
                        status:
                            whatsappStatus,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _statusCard(
                        icon: Icons
                            .sms_rounded,
                        title: 'SMS',
                        status: smsStatus,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Close',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // ICON
  // ============================================================

  Widget _notificationIcon(
    String type, {
    double size = 48,
  }) {
    IconData icon;
    Color color;
    Color background;

    switch (type) {
      case 'rent_due':
        icon = Icons
            .calendar_month_rounded;
        color = const Color(0xFFF59E0B);
        background =
            const Color(0xFFFFF7ED);
        break;

      case 'rent_overdue':
        icon = Icons
            .warning_amber_rounded;
        color = const Color(0xFFDC2626);
        background =
            const Color(0xFFFEF2F2);
        break;

      case 'payment_received':
        icon = Icons
            .payments_rounded;
        color = const Color(0xFF16A34A);
        background =
            const Color(0xFFF0FDF4);
        break;

      case 'tenant_added':
        icon = Icons
            .person_add_alt_1_rounded;
        color = const Color(0xFF2563EB);
        background =
            const Color(0xFFEFF6FF);
        break;

      default:
        icon = Icons
            .notifications_rounded;
        color = const Color(0xFF7C3AED);
        background =
            const Color(0xFFF5F3FF);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius:
            BorderRadius.circular(
          size * 0.30,
        ),
      ),
      child: Icon(
        icon,
        color: color,
        size: size * 0.52,
      ),
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _detailRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color:
              const Color(0xFF64748B),
        ),
        const SizedBox(width: 10),
        Text(
          '$title:',
          style: const TextStyle(
            fontSize: 13,
            color:
                Color(0xFF64748B),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            textAlign:
                TextAlign.end,
            style: const TextStyle(
              fontSize: 14,
              fontWeight:
                  FontWeight.w600,
              color:
                  Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATUS CARD
  // ============================================================

  Widget _statusCard({
    required IconData icon,
    required String title,
    required String status,
  }) {
    final bool sent =
        status.toLowerCase() == 'sent';

    return Container(
      padding:
          const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: sent
            ? const Color(0xFFF0FDF4)
            : const Color(0xFFF8FAFC),
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: sent
              ? const Color(0xFFBBF7D0)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: sent
                ? const Color(0xFF16A34A)
                : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  sent ? 'Sent' : 'Pending',
                  style: TextStyle(
                    fontSize: 11,
                    color: sent
                        ? const Color(
                            0xFF16A34A,
                          )
                        : const Color(
                            0xFF94A3B8,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
          content: Text(message),
          behavior:
              SnackBarBehavior.floating,
          backgroundColor: isError
              ? const Color(0xFFDC2626)
              : null,
        ),
      );
  }

  // ============================================================
  // FORMAT AMOUNT
  // ============================================================

  String _formatAmount(dynamic value) {
    final amount =
        double.tryParse(
              value.toString(),
            ) ??
            0;

    return amount
        .toStringAsFixed(0);
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(String value) {
    final date =
        DateTime.tryParse(value);

    if (date == null) {
      return value;
    }

    final day =
        date.day.toString().padLeft(
              2,
              '0',
            );

    final month =
        date.month.toString().padLeft(
              2,
              '0',
            );

    final year =
        date.year.toString();

    return '$day/$month/$year';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final unreadCount =
        _notifications.where(
      (notification) =>
          notification['is_read'] == 0,
    ).length;

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
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          if (unreadCount > 0)
            IconButton(
              tooltip:
                  'Mark all as read',
              onPressed:
                  _markAllAsRead,
              icon: const Icon(
                Icons
                    .done_all_rounded,
              ),
            ),

          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') {
                _clearAllNotifications();
              }
            },
            itemBuilder:
                (context) => const [
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(
                      Icons
                          .delete_sweep_rounded,
                      color:
                          Color(0xFFDC2626),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Clear All',
                    ),
                  ],
                ),
              ),
            ],
          ),

          IconButton(
            onPressed:
                _loadNotifications,
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
                        _loadNotifications,
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
              decoration: BoxDecoration(
                color:
                    const Color(0xFFEFF6FF),
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

            const SizedBox(height: 18),

            const Text(
              'No Notifications Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
                color:
                    Color(0xFF111827),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Rent reminders, payment updates and important alerts will appear here.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color:
                    Color(0xFF64748B),
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
        notification['title']?.toString() ??
            'Notification';

    final message =
        notification['message']?.toString() ??
            '';

    final type =
        notification['type']?.toString() ??
            'general';

    final tenantName =
        notification['tenant_name']
                ?.toString() ??
            '';

    final roomNumber =
        notification['room_number']
                ?.toString() ??
            '';

    final createdAt =
        notification['created_at']
                ?.toString() ??
            '';

    final isRead =
        notification['is_read'] == 1;

    final amount =
        notification['amount'];

    return Material(
      color: isRead
          ? Colors.white
          : const Color(0xFFEFF6FF),
      borderRadius:
          BorderRadius.circular(18),
      child: InkWell(
        onTap: () {
          _showNotificationDetail(
            notification,
          );
        },
        borderRadius:
            BorderRadius.circular(18),
        child: Container(
          padding:
              const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(18),
            border: Border.all(
              color: isRead
                  ? const Color(
                      0xFFE5E7EB,
                    )
                  : const Color(
                      0xFFBFDBFE,
                    ),
            ),
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _notificationIcon(
                type,
                size: 48,
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                const TextStyle(
                              fontSize: 15,
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
                      maxLines: 2,
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

                    const SizedBox(
                      height: 8,
                    ),

                    Wrap(
                      spacing: 8,
                      runSpacing: 5,
                      children: [
                        if (tenantName
                            .isNotEmpty)
                          _smallInfo(
                            Icons
                                .person_outline_rounded,
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
                            '₹${_formatAmount(amount)}',
                          ),
                      ],
                    ),

                    const SizedBox(
                      height: 7,
                    ),

                    Text(
                      _formatDateTime(
                        createdAt,
                      ),
                      style:
                          const TextStyle(
                        fontSize: 10,
                        color:
                            Color(
                          0xFF94A3B8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'read') {
                    _markAsRead(
                      notification,
                    );
                  }

                  if (value == 'delete') {
                    _deleteNotification(
                      notification,
                    );
                  }
                },
                itemBuilder:
                    (context) => const [
                  PopupMenuItem(
                    value: 'read',
                    child: Row(
                      children: [
                        Icon(
                          Icons
                              .done_rounded,
                          size: 20,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          'Mark as read',
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons
                              .delete_outline_rounded,
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
                          'Delete',
                        ),
                      ],
                    ),
                  ),
                ],
                icon: const Icon(
                  Icons
                      .more_vert_rounded,
                  color:
                      Color(0xFF64748B),
                ),
              ),
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
          size: 13,
          color:
              const Color(0xFF94A3B8),
        ),
        const SizedBox(width: 3),
        Text(
          text,
          style: const TextStyle(
            fontSize: 10,
            color:
                Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DATE TIME
  // ============================================================

  String _formatDateTime(
    String value,
  ) {
    final date =
        DateTime.tryParse(value);

    if (date == null) {
      return '';
    }

    final day =
        date.day.toString().padLeft(
              2,
              '0',
            );

    final month =
        date.month.toString().padLeft(
              2,
              '0',
            );

    final year =
        date.year.toString();

    final hour =
        date.hour % 12 == 0
            ? 12
            : date.hour % 12;

    final minute =
        date.minute.toString().padLeft(
              2,
              '0',
            );

    final period =
        date.hour >= 12
            ? 'PM'
            : 'AM';

    return '$day/$month/$year • $hour:$minute $period';
  }
}