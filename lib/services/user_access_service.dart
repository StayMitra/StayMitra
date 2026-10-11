
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ============================================================
/// STAY MITRA - USER ACCESS SERVICE
/// ============================================================
///
/// Firestore structure:
///
/// users/{uid}
///   role: owner | manager | warden | accountant | staff
///   ownerId: MAIN OWNER UID
///   assignedPropertyIds: [PG_ID_1, PG_ID_2]
///   status: active | inactive
///   permissions: {...}
///
/// IMPORTANT:
/// - Existing PG data is NOT deleted.
/// - Existing rooms/beds/tenants/payments are NOT deleted.
/// - This service only handles user access information.
/// ============================================================

class UserAccessService {
  UserAccessService._();

  static final UserAccessService instance =
      UserAccessService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // USERS COLLECTION
  // ============================================================

  CollectionReference<Map<String, dynamic>> get _users {
    return _firestore.collection('users');
  }

  // ============================================================
  // CURRENT USER UID
  // ============================================================

  String? get currentUid {
    return _auth.currentUser?.uid;
  }

  // ============================================================
  // USER DOCUMENT
  // ============================================================

  DocumentReference<Map<String, dynamic>> _userRef(
    String uid,
  ) {
    return _users.doc(uid);
  }

  // ============================================================
  // GET USER PROFILE
  // ============================================================

  Future<Map<String, dynamic>?> getUserProfile([
    String? uid,
  ]) async {
    final id = uid ?? currentUid;

    if (id == null || id.trim().isEmpty) {
      return null;
    }

    final snapshot = await _userRef(id).get();

    if (!snapshot.exists) {
      return null;
    }

    final data = snapshot.data();

    if (data == null) {
      return null;
    }

    return {
      'uid': id,
      ...data,
    };
  }

  // ============================================================
  // ENSURE OWNER PROFILE
  // ============================================================

  Future<void> ensureOwnerProfile({
    String? name,
    String? mobile,
    String? email,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'Firebase user is not logged in.',
      );
    }

    final ref = _userRef(user.uid);
    final existing = await ref.get();

    // PROFILE ALREADY EXISTS

    if (existing.exists) {
      final data = existing.data() ?? {};

      final role = (data['role'] ?? '')
          .toString()
          .trim()
          .toLowerCase();

      // Don't convert an existing staff account into owner.
      if (role.isNotEmpty && role != 'owner') {
        return;
      }

      await ref.set(
        {
          'uid': user.uid,
          'role': 'owner',
          'ownerId': user.uid,
          'assignedPropertyIds': const <String>[],
          'status': 'active',
          if (name != null && name.trim().isNotEmpty)
            'name': name.trim(),
          if (mobile != null && mobile.trim().isNotEmpty)
            'mobile': mobile.trim(),
          if (email != null && email.trim().isNotEmpty)
            'email': email.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      return;
    }

    // CREATE NEW OWNER PROFILE

    await ref.set(
      {
        'uid': user.uid,
        'role': 'owner',
        'ownerId': user.uid,
        'assignedPropertyIds': const <String>[],
        'status': 'active',
        'name': name?.trim() ?? '',
        'mobile': mobile?.trim() ?? '',
        'email': (email ?? user.email ?? '').trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
  }

  // ============================================================
  // GET CURRENT ROLE
  // ============================================================

  Future<String> currentRole() async {
    final profile = await getUserProfile();

    return (profile?['role'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
  }

  // ============================================================
  // CHECK OWNER
  // ============================================================

  Future<bool> isOwner() async {
    final role = await currentRole();

    return role == 'owner';
  }

  // ============================================================
  // GET OWNER ID
  // ============================================================

  Future<String?> ownerId() async {
    final profile = await getUserProfile();

    final profileOwnerId =
        profile?['ownerId']?.toString().trim();

    if (profileOwnerId != null &&
        profileOwnerId.isNotEmpty) {
      return profileOwnerId;
    }

    // For an owner, Firebase UID itself is the ownerId.
    return currentUid;
  }

  // ============================================================
  // GET ASSIGNED PG IDS
  // ============================================================

  Future<List<String>> assignedPropertyIds() async {
    final profile = await getUserProfile();
    final raw = profile?['assignedPropertyIds'];

    if (raw is! List) {
      return const <String>[];
    }

    return raw
        .map((value) => value.toString().trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  // ============================================================
  // GET ACCOUNT STATUS
  // ============================================================

  Future<bool> isActiveUser() async {
    final profile = await getUserProfile();

    if (profile == null) {
      return false;
    }

    final status = (profile['status'] ?? 'active')
        .toString()
        .trim()
        .toLowerCase();

    return status == 'active';
  }

  // ============================================================
  // CHECK PROPERTY ACCESS
  // ============================================================
  //
  // OWNER:
  //   Can access any PG under their own owner document.
  //
  // STAFF:
  //   Can access ONLY assignedPropertyIds.
  //
  // ============================================================

  Future<bool> canAccessProperty(
    String propertyId,
  ) async {
    final normalizedPropertyId = propertyId.trim();

    if (normalizedPropertyId.isEmpty) {
      return false;
    }

    final profile = await getUserProfile();

    if (profile == null) {
      return false;
    }

    final status = (profile['status'] ?? 'active')
        .toString()
        .trim()
        .toLowerCase();

    if (status != 'active') {
      return false;
    }

    final role = (profile['role'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    final profileOwnerId = (profile['ownerId'] ?? '')
        .toString()
        .trim();

    // OWNER ACCESS

    if (role == 'owner') {
      final owner = profileOwnerId.isNotEmpty
          ? profileOwnerId
          : currentUid;

      if (owner == null || owner.isEmpty) {
        return false;
      }

      final propertySnapshot = await _firestore
          .collection('owners')
          .doc(owner)
          .collection('properties')
          .doc(normalizedPropertyId)
          .get();

      return propertySnapshot.exists;
    }

    // STAFF ACCESS

    final assignedIds = await assignedPropertyIds();

    if (!assignedIds.contains(normalizedPropertyId)) {
      return false;
    }

    if (profileOwnerId.isEmpty) {
      return false;
    }

    final propertySnapshot = await _firestore
        .collection('owners')
        .doc(profileOwnerId)
        .collection('properties')
        .doc(normalizedPropertyId)
        .get();

    return propertySnapshot.exists;
  }

  // ============================================================
  // GET ALLOWED PROPERTY IDS
  // ============================================================
  //
  // OWNER:
  //   Returns all PG IDs.
  //
  // STAFF:
  //   Returns assigned PG IDs only.
  //
  // ============================================================

  Future<List<String>> allowedPropertyIds() async {
    final profile = await getUserProfile();

    if (profile == null) {
      return const <String>[];
    }

    final status = (profile['status'] ?? 'active')
        .toString()
        .trim()
        .toLowerCase();

    if (status != 'active') {
      return const <String>[];
    }

    final role = (profile['role'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    // OWNER

    if (role == 'owner') {
      final owner = (profile['ownerId'] ?? currentUid ?? '')
          .toString()
          .trim();

      if (owner.isEmpty) {
        return const <String>[];
      }

      final snapshot = await _firestore
          .collection('owners')
          .doc(owner)
          .collection('properties')
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    }

    // STAFF

    return assignedPropertyIds();
  }

  // ============================================================
  // GET ALLOWED PG DOCUMENTS
  // ============================================================
  //
  // OWNER:
  //   Loads all PG documents belonging to the owner.
  //
  // STAFF:
  //   Fetches only the PG documents explicitly assigned
  //   in users/{uid}.assignedPropertyIds.
  //
  // ============================================================

  Future<List<DocumentSnapshot<Map<String, dynamic>>>>
      getAllowedProperties() async {
    final profile = await getUserProfile();

    if (profile == null) {
      return [];
    }

    final status = (profile['status'] ?? 'active')
        .toString()
        .trim()
        .toLowerCase();

    if (status != 'active') {
      return [];
    }

    final role = (profile['role'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    final owner = (profile['ownerId'] ?? '')
        .toString()
        .trim();

    if (owner.isEmpty) {
      return [];
    }

    final propertiesRef = _firestore
        .collection('owners')
        .doc(owner)
        .collection('properties');

    // OWNER: Load all PGs belonging to this owner.
    if (role == 'owner') {
      final snapshot = await propertiesRef.get();
      return snapshot.docs;
    }

    // STAFF: Load only explicitly assigned PGs.
    if (![
      'manager',
      'warden',
      'accountant',
      'staff',
    ].contains(role)) {
      return [];
    }

    final assignedIds = await assignedPropertyIds();

    final allowedDocuments =
        <DocumentSnapshot<Map<String, dynamic>>>[];

    for (final propertyId in assignedIds.toSet()) {
      if (propertyId.isEmpty) {
        continue;
      }

      final document = await propertiesRef
          .doc(propertyId)
          .get();

      if (document.exists && document.data() != null) {
        allowedDocuments.add(document);
      }
    }

    return allowedDocuments;
  }
}
