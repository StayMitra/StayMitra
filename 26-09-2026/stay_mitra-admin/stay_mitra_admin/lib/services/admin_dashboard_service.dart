import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardStats {
  const AdminDashboardStats({
    required this.owners,
    required this.properties,
    required this.tenants,
    required this.activeSubscriptions,
    required this.trialSubscriptions,
    required this.expiredSubscriptions,
    required this.totalSupportRequests,
    required this.criticalSupportRequests,
    required this.highSupportRequests,
    required this.normalSupportRequests,
  });

  final int owners;
  final int properties;
  final int tenants;

  final int activeSubscriptions;
  final int trialSubscriptions;
  final int expiredSubscriptions;

  final int totalSupportRequests;
  final int criticalSupportRequests;
  final int highSupportRequests;
  final int normalSupportRequests;
}

class AdminDashboardService {
  AdminDashboardService._();

  static final AdminDashboardService instance =
      AdminDashboardService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Future<AdminDashboardStats> loadDashboardStats() async {
    final ownersSnapshot =
        await _firestore.collection('owners').get();

    int propertyCount = 0;
    int tenantCount = 0;

    int activeSubscriptions = 0;
    int trialSubscriptions = 0;
    int expiredSubscriptions = 0;

    int totalSupportRequests = 0;
    int criticalSupportRequests = 0;
    int highSupportRequests = 0;
    int normalSupportRequests = 0;

    for (final ownerDoc in ownersSnapshot.docs) {
      final ownerRef = ownerDoc.reference;

      // ----------------------------------------------------------
      // Properties
      // ----------------------------------------------------------
      final propertiesSnapshot =
          await ownerRef.collection('properties').get();

      propertyCount += propertiesSnapshot.size;

      // ----------------------------------------------------------
      // Tenants
      // ----------------------------------------------------------
      for (final propertyDoc in propertiesSnapshot.docs) {
        final tenantsSnapshot = await propertyDoc.reference
            .collection('tenants')
            .get();

        tenantCount += tenantsSnapshot.size;
      }

      // ----------------------------------------------------------
      // Subscription
      // ----------------------------------------------------------
      final subscriptionDoc = await ownerRef
          .collection('subscription')
          .doc('current')
          .get();

      if (subscriptionDoc.exists) {
        final data = subscriptionDoc.data() ?? {};

        final status =
            (data['status'] ?? '').toString().toLowerCase().trim();

        if (status == 'active') {
          activeSubscriptions++;
        } else if (status == 'trial') {
          trialSubscriptions++;
        } else if (status == 'expired') {
          expiredSubscriptions++;
        } else {
          // Also determine expiry from stored dates when possible.
          final trialEnd =
              _readDate(data['trial_end_date']);

          final subscriptionEnd =
              _readDate(data['subscription_end_date']);

          final endDate = subscriptionEnd ?? trialEnd;

          if (endDate != null &&
              endDate.isBefore(DateTime.now())) {
            expiredSubscriptions++;
          } else if (status == 'payment_pending') {
            // Payment pending is not counted as active/trial.
          }
        }
      }

      // ----------------------------------------------------------
      // Support Requests
      // ----------------------------------------------------------
      final supportSnapshot =
          await ownerRef.collection('support_requests').get();

      totalSupportRequests += supportSnapshot.size;

      for (final supportDoc in supportSnapshot.docs) {
        final data = supportDoc.data();

        final priority =
            (data['priority'] ?? 'normal')
                .toString()
                .toLowerCase()
                .trim();

        switch (priority) {
          case 'critical':
            criticalSupportRequests++;
            break;

          case 'high':
            highSupportRequests++;
            break;

          default:
            normalSupportRequests++;
            break;
        }
      }
    }

    return AdminDashboardStats(
      owners: ownersSnapshot.size,
      properties: propertyCount,
      tenants: tenantCount,
      activeSubscriptions: activeSubscriptions,
      trialSubscriptions: trialSubscriptions,
      expiredSubscriptions: expiredSubscriptions,
      totalSupportRequests: totalSupportRequests,
      criticalSupportRequests: criticalSupportRequests,
      highSupportRequests: highSupportRequests,
      normalSupportRequests: normalSupportRequests,
    );
  }

  DateTime? _readDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}