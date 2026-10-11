
import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_access_service.dart';
import 'firestore_service.dart';

class DashboardFirebaseStats {
  final int totalRooms;
  final int totalBeds;
  final int occupiedBeds;
  final int availableBeds;
  final int activeTenants;

  final double pendingRent;
  final int pendingRentTenants;

  final double todayCollection;
  final int todayPaymentCount;

  final double monthIncome;
  final double monthExpense;

  final int totalBills;
  final int pendingBills;

  const DashboardFirebaseStats({
    required this.totalRooms,
    required this.totalBeds,
    required this.occupiedBeds,
    required this.availableBeds,
    required this.activeTenants,
    required this.pendingRent,
    required this.pendingRentTenants,
    required this.todayCollection,
    required this.todayPaymentCount,
    required this.monthIncome,
    required this.monthExpense,
    required this.totalBills,
    required this.pendingBills,
  });

  static const empty = DashboardFirebaseStats(
    totalRooms: 0,
    totalBeds: 0,
    occupiedBeds: 0,
    availableBeds: 0,
    activeTenants: 0,
    pendingRent: 0,
    pendingRentTenants: 0,
    todayCollection: 0,
    todayPaymentCount: 0,
    monthIncome: 0,
    monthExpense: 0,
    totalBills: 0,
    pendingBills: 0,
  );
}

class FirebaseDashboardService {
  FirebaseDashboardService._();

  static final FirebaseDashboardService instance =
      FirebaseDashboardService._();

  final UserAccessService _userAccess =
      UserAccessService.instance;

  final FirestoreService _firestore =
      FirestoreService.instance;

  // ============================================================
  // GET OWNER ID
  // ============================================================

  Future<String> _getOwnerId() async {
    final ownerId = await _userAccess.ownerId();

    if (ownerId == null || ownerId.trim().isEmpty) {
      throw Exception(
        'Owner ID is missing in the user profile.',
      );
    }

    return ownerId.trim();
  }

  // ============================================================
  // PROPERTY DOCUMENT
  // ============================================================

  DocumentReference<Map<String, dynamic>> _propertyDocument(
    String ownerId,
    String propertyId,
  ) {
    return _firestore
        .propertiesCollection(ownerId)
        .doc(propertyId);
  }

  // ============================================================
  // PROPERTY COLLECTION
  // ============================================================

  CollectionReference<Map<String, dynamic>> _propertyCollection(
    String ownerId,
    String propertyId,
    String collectionName,
  ) {
    return _propertyDocument(ownerId, propertyId)
        .collection(collectionName);
  }

  // ============================================================
  // GET PROPERTY STATISTICS
  // ============================================================

  Future<DashboardFirebaseStats> getPropertyStats(
    String propertyId,
  ) async {
    if (propertyId.trim().isEmpty) {
      return DashboardFirebaseStats.empty;
    }

    final normalizedPropertyId = propertyId.trim();

    // Resolve the main owner's UID for both owner and staff.
    final ownerId = await _getOwnerId();

    // Ensure the current user can access this PG.
    final hasAccess =
        await _userAccess.canAccessProperty(
      normalizedPropertyId,
    );

    if (!hasAccess) {
      throw Exception(
        'You do not have access to this PG.',
      );
    }

    // ==========================================================
    // FIRESTORE QUERIES
    // ==========================================================

    final roomsFuture = _propertyCollection(
      ownerId,
      normalizedPropertyId,
      'rooms',
    ).get();

    final bedsFuture = _propertyCollection(
      ownerId,
      normalizedPropertyId,
      'beds',
    ).get();

    final tenantsFuture = _propertyCollection(
      ownerId,
      normalizedPropertyId,
      'tenants',
    )
        .where(
          'status',
          isEqualTo: 'active',
        )
        .get();

    final transactionsFuture = _propertyCollection(
      ownerId,
      normalizedPropertyId,
      'transactions',
    ).get();

    final billsFuture = _propertyCollection(
      ownerId,
      normalizedPropertyId,
      'bills',
    ).get();

    final results = await Future.wait([
      roomsFuture,
      bedsFuture,
      tenantsFuture,
      transactionsFuture,
      billsFuture,
    ]);

    final roomsSnapshot =
        results[0] as QuerySnapshot<Map<String, dynamic>>;

    final bedsSnapshot =
        results[1] as QuerySnapshot<Map<String, dynamic>>;

    final tenantsSnapshot =
        results[2] as QuerySnapshot<Map<String, dynamic>>;

    final transactionsSnapshot =
        results[3] as QuerySnapshot<Map<String, dynamic>>;

    final billsSnapshot =
        results[4] as QuerySnapshot<Map<String, dynamic>>;

    // ==========================================================
    // BED STATUS
    // ==========================================================

    int occupiedBeds = 0;
    int availableBeds = 0;

    for (final doc in bedsSnapshot.docs) {
      final data = doc.data();

      final status = (data['status'] ?? '')
          .toString()
          .trim()
          .toLowerCase();

      if (status == 'occupied') {
        occupiedBeds++;
      } else if (status == 'available') {
        availableBeds++;
      }
    }

    final now = DateTime.now();

    // ==========================================================
    // COLLECTION / INCOME / EXPENSE
    // ==========================================================

    double todayCollection = 0;
    int todayPaymentCount = 0;

    double monthIncome = 0;
    double monthExpense = 0;

    final Map<String, double> tenantPaidThisMonth = {};

    for (final doc in transactionsSnapshot.docs) {
      final data = doc.data();

      final type = (data['type'] ?? '')
          .toString()
          .trim()
          .toLowerCase();

      final amount = _toDouble(data['amount']);
      final date = _parseDate(data['date']);

      if (date == null) {
        continue;
      }

      final isIncome = type == 'income';
      final isExpense = type == 'expense';

      // ========================================================
      // INCOME
      // ========================================================

      if (isIncome) {
        if (date.year == now.year &&
            date.month == now.month) {
          monthIncome += amount;

          final tenantId = (data['tenant_id'] ?? '')
              .toString()
              .trim();

          if (tenantId.isNotEmpty) {
            tenantPaidThisMonth[tenantId] =
                (tenantPaidThisMonth[tenantId] ?? 0) +
                    amount;
          }
        }

        if (date.year == now.year &&
            date.month == now.month &&
            date.day == now.day) {
          todayCollection += amount;
          todayPaymentCount++;
        }
      }

      // ========================================================
      // EXPENSE
      // ========================================================

      if (isExpense) {
        if (date.year == now.year &&
            date.month == now.month) {
          monthExpense += amount;
        }
      }
    }

    // ==========================================================
    // PENDING RENT
    //
    // Current month rent is NOT added automatically.
    // Only rent due for months before the current month is
    // included. Previous unpaid balances are carried forward.
    // ==========================================================

    double pendingRent = 0;
    int pendingRentTenants = 0;

    final currentMonthStart = DateTime(
      now.year,
      now.month,
      1,
    );

    for (final doc in tenantsSnapshot.docs) {
      final data = doc.data();
      final tenantId = doc.id;

      final monthlyRent = _toDouble(
        data['monthly_rent'],
      );

      if (monthlyRent <= 0) {
        continue;
      }

      final joiningDate = _parseDate(
        data['joining_date'] ?? data['joiningDate'],
      );

      if (joiningDate == null) {
        continue;
      }

      // ========================================================
      // START MONTH
      // ========================================================

      final DateTime startMonth = DateTime(
        joiningDate.year,
        joiningDate.month,
        1,
      );

      // A tenant who joined during the current or a future month
      // has no previous-month rent due under this calculation.
      if (!startMonth.isBefore(currentMonthStart)) {
        continue;
      }

      // ========================================================
      // TOTAL RENT DUE UNTIL PREVIOUS MONTH
      // ========================================================

      double previousRentDue = 0;
      DateTime monthCursor = startMonth;

      while (monthCursor.isBefore(currentMonthStart)) {
        previousRentDue += monthlyRent;

        monthCursor = DateTime(
          monthCursor.year,
          monthCursor.month + 1,
          1,
        );
      }

      // ========================================================
      // TOTAL PAYMENTS MADE BEFORE CURRENT MONTH
      // ========================================================

      double previousPayments = 0;

      for (final transactionDoc
          in transactionsSnapshot.docs) {
        final transactionData = transactionDoc.data();

        final transactionTenantId =
            (transactionData['tenant_id'] ?? '')
                .toString()
                .trim();

        if (transactionTenantId != tenantId) {
          continue;
        }

        final transactionType =
            (transactionData['type'] ?? '')
                .toString()
                .trim()
                .toLowerCase();

        if (transactionType != 'income') {
          continue;
        }

        final transactionDate = _parseDate(
          transactionData['date'],
        );

        if (transactionDate == null) {
          continue;
        }

        if (transactionDate.isBefore(currentMonthStart)) {
          previousPayments += _toDouble(
            transactionData['amount'],
          );
        }
      }

      // ========================================================
      // PREVIOUS BALANCE
      // ========================================================

      final previousBalance =
          previousRentDue - previousPayments;

      // ========================================================
      // FINAL PENDING
      // ========================================================

      final pending =
          previousBalance > 0 ? previousBalance : 0.0;

      if (pending > 0) {
        pendingRent += pending;
        pendingRentTenants++;
      }
    }

    // ==========================================================
    // PENDING BILLS
    // ==========================================================

    int pendingBills = 0;

    for (final doc in billsSnapshot.docs) {
      final data = doc.data();

      final status = (data['status'] ?? '')
          .toString()
          .trim()
          .toLowerCase();

      if (status == 'pending') {
        pendingBills++;
      }
    }

    // ==========================================================
    // RETURN DASHBOARD STATISTICS
    // ==========================================================

    return DashboardFirebaseStats(
      totalRooms: roomsSnapshot.docs.length,
      totalBeds: bedsSnapshot.docs.length,
      occupiedBeds: occupiedBeds,
      availableBeds: availableBeds,
      activeTenants: tenantsSnapshot.docs.length,
      pendingRent: pendingRent,
      pendingRentTenants: pendingRentTenants,
      todayCollection: todayCollection,
      todayPaymentCount: todayPaymentCount,
      monthIncome: monthIncome,
      monthExpense: monthExpense,
      totalBills: billsSnapshot.docs.length,
      pendingBills: pendingBills,
    );
  }

  // ============================================================
  // DOUBLE CONVERSION
  // ============================================================

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  // ============================================================
  // DATE PARSER
  // ============================================================

  DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }
}
