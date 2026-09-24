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

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

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

      if (isExpense) {
        if (date.year == now.year &&
            date.month == now.month) {
          monthExpense += amount;
        }
      }
    }

    double pendingRent = 0;
    int pendingRentTenants = 0;

    for (final doc
        in tenantsSnapshot.docs) {
      final data = doc.data();

      final tenantId =
          doc.id;

      final monthlyRent =
          _toDouble(
        data['monthly_rent'],
      );

      final paid =
          tenantPaidThisMonth[
                  tenantId] ??
              0;

      final pending =
          monthlyRent - paid;

      if (pending > 0) {
        pendingRent += pending;
        pendingRentTenants++;
      }
    }

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