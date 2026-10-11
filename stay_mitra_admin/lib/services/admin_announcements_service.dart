import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAnnouncement {
  const AdminAnnouncement({
    required this.id,
    required this.title,
    required this.message,
    required this.target,
    required this.status,
    required this.createdAt,
    required this.createdBy,
  });

  final String id;
  final String title;
  final String message;
  final String target;
  final String status;
  final DateTime? createdAt;
  final String createdBy;
}

class AdminAnnouncementsService {
  AdminAnnouncementsService._();

  static final AdminAnnouncementsService instance =
      AdminAnnouncementsService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('announcements');

  Future<List<AdminAnnouncement>> getAnnouncements() async {
    final snapshot = await _collection.get();

    final items = snapshot.docs.map((doc) {
      final data = doc.data();

      return AdminAnnouncement(
        id: doc.id,
        title: _readString(data['title']),
        message: _readString(data['message']),
        target: _readString(
          data['target'],
          fallback: 'all',
        ).toLowerCase(),
        status: _readString(
          data['status'],
          fallback: 'published',
        ).toLowerCase(),
        createdAt: _readDate(data['created_at']),
        createdBy: _readString(data['created_by']),
      );
    }).toList();

    items.sort((a, b) {
      final aDate = a.createdAt;
      final bDate = b.createdAt;

      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;

      return bDate.compareTo(aDate);
    });

    return items;
  }

  Future<String> createAnnouncement({
    required String title,
    required String message,
    required String target,
    required String createdBy,
  }) async {
    final ref = await _collection.add({
      'title': title.trim(),
      'message': message.trim(),
      'target': target.trim().toLowerCase(),
      'status': 'published',
      'created_by': createdBy,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });

    return ref.id;
  }

  Future<void> updateAnnouncement({
    required String announcementId,
    required String title,
    required String message,
    required String target,
  }) async {
    await _collection.doc(announcementId).update({
      'title': title.trim(),
      'message': message.trim(),
      'target': target.trim().toLowerCase(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteAnnouncement(
    String announcementId,
  ) async {
    await _collection.doc(announcementId).delete();
  }

  String _readString(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) return fallback;

    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
