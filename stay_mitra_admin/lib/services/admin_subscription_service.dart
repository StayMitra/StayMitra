import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSubscriptionPlan {
  const AdminSubscriptionPlan({required this.id, required this.title, required this.duration, required this.price, required this.originalPrice, required this.saveText, required this.description, required this.popular});
  final String id;
  final String title;
  final String duration;
  final int price;
  final int? originalPrice;
  final String? saveText;
  final String description;
  final bool popular;
}

class AdminSubscriptionRequest {
  const AdminSubscriptionRequest({required this.id, required this.ownerId, required this.ownerName, required this.ownerEmail, required this.planTitle, required this.planDuration, required this.planPrice, required this.planOriginalPrice, required this.paymentStatus, required this.status, required this.requestedAt});
  final String id;
  final String ownerId;
  final String ownerName;
  final String ownerEmail;
  final String planTitle;
  final String planDuration;
  final int planPrice;
  final int? planOriginalPrice;
  final String paymentStatus;
  final String status;
  final DateTime? requestedAt;
}

class AdminSubscriptionService {
  AdminSubscriptionService._();
  static final AdminSubscriptionService instance = AdminSubscriptionService._();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<AdminSubscriptionPlan> getPlans() => const [
        AdminSubscriptionPlan(id: 'monthly', title: 'Monthly', duration: '1 Month', price: 499, originalPrice: null, saveText: null, description: 'Flexible monthly subscription', popular: false),
        AdminSubscriptionPlan(id: 'quarterly', title: 'Quarterly', duration: '3 Months', price: 1299, originalPrice: 1497, saveText: 'Save ₹198', description: 'Good for growing PGs', popular: false),
        AdminSubscriptionPlan(id: 'half_yearly', title: 'Half-Yearly', duration: '6 Months', price: 2399, originalPrice: 2994, saveText: 'Save ₹595', description: 'Better value for PG owners', popular: false),
        AdminSubscriptionPlan(id: 'yearly', title: 'Yearly', duration: '12 Months', price: 3999, originalPrice: 5988, saveText: 'Save ₹1,989', description: 'Best value for your PG', popular: true),
      ];

  Future<List<AdminSubscriptionRequest>> getSubscriptionRequests() async {
    final owners = await _firestore.collection('owners').get();
    final requests = <AdminSubscriptionRequest>[];
    for (final ownerDoc in owners.docs) {
      final ownerData = ownerDoc.data();
      final ownerName = _string(ownerData['name'] ?? ownerData['full_name'] ?? ownerData['owner_name'], 'Owner');
      final ownerEmail = _string(ownerData['email'] ?? ownerData['owner_email'], '');
      final snapshot = await ownerDoc.reference.collection('subscription_requests').get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        requests.add(AdminSubscriptionRequest(
          id: doc.id,
          ownerId: ownerDoc.id,
          ownerName: ownerName,
          ownerEmail: ownerEmail,
          planTitle: _string(data['plan_title'], ''),
          planDuration: _string(data['plan_duration'], ''),
          planPrice: _int(data['plan_price']),
          planOriginalPrice: _nullableInt(data['plan_original_price']),
          paymentStatus: _string(data['payment_status'], 'pending').toLowerCase(),
          status: _string(data['status'], 'payment_pending').toLowerCase(),
          requestedAt: _date(data['requested_at']),
        ));
      }
    }
    requests.sort((a, b) {
      if (a.requestedAt == null && b.requestedAt == null) return 0;
      if (a.requestedAt == null) return 1;
      if (b.requestedAt == null) return -1;
      return b.requestedAt!.compareTo(a.requestedAt!);
    });
    return requests;
  }

  Future<Map<String, dynamic>?> getOwnerCurrentSubscription(String ownerId) async {
    final doc = await _firestore.collection('owners').doc(ownerId).collection('subscription').doc('current').get();
    return doc.data();
  }

  String _string(dynamic value, String fallback) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  int? _nullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
