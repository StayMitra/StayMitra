import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSupportRequest {
  const AdminSupportRequest({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.ownerEmail,
    required this.ownerPhone,
    required this.subject,
    required this.message,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerId;

  final String ownerName;
  final String ownerEmail;
  final String ownerPhone;

  final String subject;
  final String message;

  final String status;
  final String priority;

  final DateTime? createdAt;
  final DateTime? updatedAt;
}

class AdminSupportService {
  AdminSupportService._();

  static final AdminSupportService instance = AdminSupportService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  /// Load all support requests from all owners.
  Future<List<AdminSupportRequest>> getSupportRequests() async {
    final ownersSnapshot =
        await _firestore.collection('owners').get();

    final requests = <AdminSupportRequest>[];

    for (final ownerDoc in ownersSnapshot.docs) {
      final ownerData = ownerDoc.data();

      final ownerId = ownerDoc.id;

      final ownerName = _readString(
        ownerData['name'] ??
            ownerData['full_name'] ??
            ownerData['owner_name'],
      );

      final ownerEmail = _readString(
        ownerData['email'] ??
            ownerData['owner_email'],
      );

      final ownerPhone = _readString(
        ownerData['phone'] ??
            ownerData['phone_number'] ??
            ownerData['mobile'],
      );

      final supportSnapshot = await ownerDoc.reference
          .collection('support_requests')
          .get();

      for (final supportDoc in supportSnapshot.docs) {
        final data = supportDoc.data();

        requests.add(
          AdminSupportRequest(
            id: supportDoc.id,
            ownerId: ownerId,
            ownerName: ownerName.isEmpty ? 'Owner' : ownerName,
            ownerEmail: ownerEmail,
            ownerPhone: ownerPhone,
            subject: _readString(data['subject']),
            message: _readString(data['message']),
            status: _readString(
              data['status'],
              fallback: 'open',
            ).toLowerCase(),
            priority: _readString(
              data['priority'],
              fallback: 'normal',
            ).toLowerCase(),
            createdAt: _readDate(data['created_at']),
            updatedAt: _readDate(data['updated_at']),
          ),
        );
      }
    }

    requests.sort((a, b) {
      final aDate = a.createdAt;
      final bDate = b.createdAt;

      if (aDate == null && bDate == null) {
        return 0;
      }

      if (aDate == null) {
        return 1;
      }

      if (bDate == null) {
        return -1;
      }

      return bDate.compareTo(aDate);
    });

    return requests;
  }

  /// Update support request status.
  Future<void> updateStatus({
    required String ownerId,
    required String requestId,
    required String status,
  }) async {
    await _firestore
        .collection('owners')
        .doc(ownerId)
        .collection('support_requests')
        .doc(requestId)
        .update({
      'status': status,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Update support request priority.
  Future<void> updatePriority({
    required String ownerId,
    required String requestId,
    required String priority,
  }) async {
    await _firestore
        .collection('owners')
        .doc(ownerId)
        .collection('support_requests')
        .doc(requestId)
        .update({
      'priority': priority,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  String _readString(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();

    return text.isEmpty ? fallback : text;
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