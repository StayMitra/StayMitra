import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirestoreService _firestore =
      FirestoreService.instance;

  String get _ownerId {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'Firebase user is not logged in.',
      );
    }

    return user.uid;
  }

  DocumentReference<Map<String, dynamic>>
      _propertyDocument(
    String propertyId,
  ) {
    return _firestore
        .propertiesCollection(_ownerId)
        .doc(propertyId);
  }

  CollectionReference<Map<String, dynamic>>
      _propertyCollection(
    String propertyId,
    String collectionName,
  ) {
    return _propertyDocument(propertyId)
        .collection(collectionName);
  }

  Future<DashboardFirebaseStats>
      getPropertyStats(
    String propertyId,
  ) async {
    if (propertyId.trim().isEmpty) {
      return DashboardFirebaseStats.empty;
    }

    final roomsFuture = _propertyCollection(
      propertyId,
      'rooms',
    ).get();

    final bedsFuture = _propertyCollection(
      propertyId,
      'beds',
    ).get();

    final tenantsFuture = _propertyCollection(
      propertyId,
      'tenants',
    )
        .where(
          'status',
          isEqualTo: 'active',
        )
        .get();

    final transactionsFuture =
        _propertyCollection(
      propertyId,
      'transactions',
    ).get();

    final billsFuture = _propertyCollection(
      propertyId,
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
        results[0]
            as QuerySnapshot<
                Map<String, dynamic>>;

    final bedsSnapshot =
        results[1]
            as QuerySnapshot<
                Map<String, dynamic>>;

    final tenantsSnapshot =
        results[2]
            as QuerySnapshot<
                Map<String, dynamic>>;

    final transactionsSnapshot =
        results[3]
            as QuerySnapshot<
                Map<String, dynamic>>;

    final billsSnapshot =
        results[4]
            as QuerySnapshot<
                Map<String, dynamic>>;

    // ==========================================================
    // BED STATUS
    // ==========================================================

    int occupiedBeds = 0;
    int availableBeds = 0;

    for (final doc in bedsSnapshot.docs) {
      final data = doc.data();

      final status =
          (data['status'] ?? '')
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

    final Map<String, double>
        tenantPaidThisMonth = {};

    for (final doc
        in transactionsSnapshot.docs) {
      final data = doc.data();

      final type =
          (data['type'] ?? '')
              .toString()
              .trim()
              .toLowerCase();

      final amount =
          _toDouble(data['amount']);

      final date =
          _parseDate(data['date']);

      if (date == null) {
        continue;
      }

      final isIncome =
          type == 'income';

      final isExpense =
          type == 'expense';

      // ========================================================
      // INCOME
      // ========================================================

      if (isIncome) {
        if (date.year == now.year &&
            date.month == now.month) {
          monthIncome += amount;

          final tenantId =
              (data['tenant_id'] ?? '')
                  .toString()
                  .trim();

          if (tenantId.isNotEmpty) {
            tenantPaidThisMonth[tenantId] =
                (tenantPaidThisMonth[
                        tenantId] ??
                    0) +
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
    // IMPORTANT:
    //
    // Current month rent is NOT added automatically.
    //
    // Example:
    //
    // September rent = ₹6000
    // September paid  = ₹6000
    // October 1       = Pending ₹0
    //
    // September rent = ₹6000
    // September paid  = ₹4000
    // October 1       = Pending ₹2000
    //
    // Older unpaid balances are also carried forward.
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
        data['joining_date'] ??
            data['joiningDate'],
      );

      if (joiningDate == null) {
        continue;
      }

      // ========================================================
      // START MONTH
      //
      // Rent calculation starts from tenant joining month.
      // We calculate only months BEFORE the current month.
      // ========================================================

      DateTime startMonth = DateTime(
        joiningDate.year,
        joiningDate.month,
        1,
      );

      // If tenant joined in the future, there is no previous
      // rent due.
      if (!startMonth.isBefore(
        currentMonthStart,
      )) {
        continue;
      }

      // ========================================================
      // TOTAL RENT DUE UNTIL PREVIOUS MONTH
      // ========================================================

      double previousRentDue = 0;

      DateTime monthCursor = startMonth;

      while (monthCursor.isBefore(
        currentMonthStart,
      )) {
        previousRentDue += monthlyRent;

        monthCursor = DateTime(
          monthCursor.year,
          monthCursor.month + 1,
          1,
        );
      }

      // ========================================================
      // TOTAL PAYMENTS MADE BEFORE CURRENT MONTH
      //
      // Payments are taken from Firebase transactions using:
      //
      // tenant_id
      // type = income
      // date
      // amount
      //
      // This matches the existing payment-save structure.
      // ========================================================

      double previousPayments = 0;

      for (final transactionDoc
          in transactionsSnapshot.docs) {
        final transactionData =
            transactionDoc.data();

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

        final transactionDate =
            _parseDate(
          transactionData['date'],
        );

        if (transactionDate == null) {
          continue;
        }

        // Only payments made before the current month
        if (transactionDate.isBefore(
          currentMonthStart,
        )) {
          previousPayments += _toDouble(
            transactionData['amount'],
          );
        }
      }

      // ========================================================
      // PREVIOUS BALANCE
      //
      // Previous rent due
      //        -
      // Previous payments
      //        =
      // Previous balance
      // ========================================================

      final previousBalance =
          previousRentDue -
          previousPayments;

      // ========================================================
      // FINAL PENDING
      //
      // IMPORTANT:
      // Current month rent is intentionally NOT added here.
      //
      // This prevents ₹6000 appearing automatically on October 1.
      // ========================================================

      final pending =
          previousBalance > 0
              ? previousBalance
              : 0;

      if (pending > 0) {
        pendingRent += pending;
        pendingRentTenants++;
      }
    }

    // ==========================================================
    // PENDING BILLS
    // ==========================================================

    int pendingBills = 0;

    for (final doc
        in billsSnapshot.docs) {
      final data = doc.data();

      final status =
          (data['status'] ?? '')
              .toString()
              .trim()
              .toLowerCase();

      if (status == 'pending') {
        pendingBills++;
      }
    }

    // ==========================================================
    // RETURN DASHBOARD STATS
    // ==========================================================

    return DashboardFirebaseStats(
      totalRooms:
          roomsSnapshot.docs.length,
      totalBeds:
          bedsSnapshot.docs.length,
      occupiedBeds:
          occupiedBeds,
      availableBeds:
          availableBeds,
      activeTenants:
          tenantsSnapshot.docs.length,
      pendingRent:
          pendingRent,
      pendingRentTenants:
          pendingRentTenants,
      todayCollection:
          todayCollection,
      todayPaymentCount:
          todayPaymentCount,
      monthIncome:
          monthIncome,
      monthExpense:
          monthExpense,
      totalBills:
          billsSnapshot.docs.length,
      pendingBills:
          pendingBills,
    );
  }

  // ============================================================
  // DOUBLE CONVERSION
  // ============================================================

  double _toDouble(
    dynamic value,
  ) {
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

  DateTime? _parseDate(
    dynamic value,
  ) {
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