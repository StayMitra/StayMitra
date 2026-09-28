import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminAuthService {
  AdminAuthService._();

  static final AdminAuthService instance = AdminAuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<AdminProfile?> getCurrentAdminProfile() async {
    final user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    final doc = await _firestore
        .collection('admin_users')
        .doc(user.uid)
        .get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return AdminProfile.fromMap(
      user.uid,
      doc.data()!,
    );
  }

  Future<AdminProfile> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Unable to sign in.',
      );
    }

    final profile = await getCurrentAdminProfile();

    if (profile == null) {
      await _auth.signOut();

      throw Exception(
        'This account is not registered as a Stay Mitra admin.',
      );
    }

    return profile;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(
      email: email.trim(),
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}

class AdminProfile {
  const AdminProfile({
    required this.uid,
    required this.role,
    required this.permissions,
    this.name,
    this.email,
  });

  final String uid;
  final String role;
  final List<String> permissions;
  final String? name;
  final String? email;

  bool hasPermission(String permission) {
    if (role == 'super_admin') {
      return true;
    }

    return permissions.contains(permission);
  }

  factory AdminProfile.fromMap(
    String uid,
    Map<String, dynamic> data,
  ) {
    final rawPermissions = data['permissions'];

    final permissions = rawPermissions is List
        ? rawPermissions
            .map((item) => item.toString())
            .toList()
        : <String>[];

    return AdminProfile(
      uid: uid,
      role: (data['role'] ?? 'admin').toString(),
      permissions: permissions,
      name: data['name']?.toString(),
      email: data['email']?.toString(),
    );
  }
}