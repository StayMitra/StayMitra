import 'package:cloud_firestore/cloud_firestore.dart';

class AdminOwnerSummary {
  const AdminOwnerSummary({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.pgCount,
    required this.tenantCount,
    required this.subscriptionStatus,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final int pgCount;
  final int tenantCount;
  final String subscriptionStatus;
  final DateTime? createdAt;
}

class AdminOwnerDetails {
  const AdminOwnerDetails({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.pgCount,
    required this.tenantCount,
    required this.subscriptionStatus,
    required this.createdAt,
    required this.ownerData,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final int pgCount;
  final int tenantCount;
  final String subscriptionStatus;
  final DateTime? createdAt;
  final Map<String, dynamic> ownerData;
}

class AdminOwnersService {
  AdminOwnersService._();

  static final AdminOwnersService instance =
      AdminOwnersService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Future<List<AdminOwnerSummary>> getOwners() async {
    final snapshot =
        await _firestore.collection('owners').get();

    final owners = <AdminOwnerSummary>[];

    for (final ownerDoc in snapshot.docs) {
      final data = ownerDoc.data();

      final propertiesSnapshot = await ownerDoc.reference
          .collection('properties')
          .get();

      int tenantCount = 0;

      for (final propertyDoc in propertiesSnapshot.docs) {
        final tenantsSnapshot = await propertyDoc.reference
            .collection('tenants')
            .get();

        tenantCount += tenantsSnapshot.size;
      }

      final subscriptionDoc = await ownerDoc.reference
          .collection('subscription')
          .doc('current')
          .get();

      final subscriptionData =
          subscriptionDoc.data() ?? {};

      final status =
          (subscriptionData['status'] ?? 'unknown')
              .toString()
              .trim();

      owners.add(
        AdminOwnerSummary(
          id: ownerDoc.id,
          name: _readOwnerName(data),
          email: _readString(
            data,
            ['email'],
          ),
          phone: _readString(
            data,
            ['phone', 'mobile'],
          ),
          pgCount: propertiesSnapshot.size,
          tenantCount: tenantCount,
          subscriptionStatus:
              status.isEmpty ? 'unknown' : status,
          createdAt: _readDate(
            data['created_at'] ??
                data['createdAt'],
          ),
        ),
      );
    }

    owners.sort(
      (a, b) => a.name
          .toLowerCase()
          .compareTo(
            b.name.toLowerCase(),
          ),
    );

    return owners;
  }

  Future<AdminOwnerDetails?> getOwnerDetails(
    String ownerId,
  ) async {
    final ownerDoc =
        await _firestore.collection('owners').doc(ownerId).get();

    if (!ownerDoc.exists) {
      return null;
    }

    final data = ownerDoc.data() ?? {};

    final propertiesSnapshot =
        await ownerDoc.reference.collection('properties').get();

    int tenantCount = 0;

    for (final propertyDoc in propertiesSnapshot.docs) {
      final tenantsSnapshot = await propertyDoc.reference
          .collection('tenants')
          .get();

      tenantCount += tenantsSnapshot.size;
    }

    final subscriptionDoc = await ownerDoc.reference
        .collection('subscription')
        .doc('current')
        .get();

    final subscriptionData =
        subscriptionDoc.data() ?? {};

    final status =
        (subscriptionData['status'] ?? 'unknown')
            .toString()
            .trim();

    return AdminOwnerDetails(
      id: ownerDoc.id,
      name: _readOwnerName(data),
      email: _readString(
        data,
        ['email'],
      ),
      phone: _readString(
        data,
        ['phone', 'mobile'],
      ),
      pgCount: propertiesSnapshot.size,
      tenantCount: tenantCount,
      subscriptionStatus:
          status.isEmpty ? 'unknown' : status,
      createdAt: _readDate(
        data['created_at'] ??
            data['createdAt'],
      ),
      ownerData: data,
    );
  }

  // ============================================================
  // OWNER PROPERTIES
  // ============================================================

  Future<List<Map<String, dynamic>>> getOwnerProperties(
    String ownerId,
  ) async {
    final snapshot = await _firestore
        .collection('owners')
        .doc(ownerId)
        .collection('properties')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        ...data,
      };
    }).toList();
  }

  // ============================================================
  // OWNER TENANTS
  // ============================================================

  Future<List<Map<String, dynamic>>> getOwnerTenants(
    String ownerId,
  ) async {
    final propertiesSnapshot = await _firestore
        .collection('owners')
        .doc(ownerId)
        .collection('properties')
        .get();

    final tenants = <Map<String, dynamic>>[];

    for (final propertyDoc
        in propertiesSnapshot.docs) {
      final tenantsSnapshot = await propertyDoc.reference
          .collection('tenants')
          .get();

      for (final tenantDoc
          in tenantsSnapshot.docs) {
        final data = tenantDoc.data();

        tenants.add({
          'id': tenantDoc.id,
          'property_id': propertyDoc.id,
          'property_name':
              propertyDoc.data()['name'] ??
                  propertyDoc.data()['pg_name'] ??
                  'PG',
          ...data,
        });
      }
    }

    return tenants;
  }

  // ============================================================
  // OWNER NAME
  // ============================================================

  String _readOwnerName(
    Map<String, dynamic> data,
  ) {
    final candidates = [
      data['name'],
      data['owner_name'],
      data['ownerName'],
      data['displayName'],
    ];

    for (final value in candidates) {
      final text = value?.toString().trim() ?? '';

      if (text.isNotEmpty) {
        return text;
      }
    }

    return 'Unnamed Owner';
  }

  // ============================================================
  // STRING READER
  // ============================================================

  String _readString(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = data[key];

      if (value != null) {
        final text = value.toString().trim();

        if (text.isNotEmpty) {
          return text;
        }
      }
    }

    return '-';
  }

  // ============================================================
  // DATE READER
  // ============================================================

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