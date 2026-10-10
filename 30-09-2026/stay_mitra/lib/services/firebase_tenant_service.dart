import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../tenant_model.dart';
import '../building_model.dart';
import 'firestore_service.dart';

class FirebaseTenantService {
  FirebaseTenantService._();

  static final FirebaseTenantService instance =
      FirebaseTenantService._();

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final FirestoreService _firestore =
      FirestoreService.instance;

  final FirebaseStorage _storage =
      FirebaseStorage.instance;

  // ============================================================
  // OWNER
  // ============================================================

  String get _ownerId {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'Firebase user is not logged in.',
      );
    }

    return user.uid;
  }

  // ============================================================
  // TENANT COLLECTION
  // ============================================================

  CollectionReference<Map<String, dynamic>>
      _tenantCollection(
    String propertyId,
  ) {
    return _firestore
        .propertiesCollection(_ownerId)
        .doc(propertyId)
        .collection('tenants');
  }

  // ============================================================
  // BED DOCUMENT
  // ============================================================

  DocumentReference<Map<String, dynamic>>
      _bedDocument(
    String propertyId,
    String bedId,
  ) {
    return _firestore
        .propertiesCollection(_ownerId)
        .doc(propertyId)
        .collection('beds')
        .doc(bedId);
  }

  // ============================================================
  // BUILDING
  // ============================================================

  Future<List<BuildingModel>> getBuildings({
    required String propertyId,
  }) async {
    final doc = await _firestore
        .propertiesCollection(_ownerId)
        .doc(propertyId)
        .get();

    if (!doc.exists) {
      return [];
    }

    final data = doc.data() ?? {};

    return [
      BuildingModel(
        id: doc.id,
        name: (data['name'] ?? '').toString(),
        address: _nullableString(
          data['address'],
        ),
        ownerId: _ownerId,
        createdAt:
            _parseDate(
              data['createdAt'],
            ) ??
            DateTime.now(),
      ),
    ];
  }

  // ============================================================
  // FLOORS
  // ============================================================

  Future<List<FloorModel>> getFloors({
    required String propertyId,
  }) async {
    final snapshot = await _firestore
        .propertiesCollection(_ownerId)
        .doc(propertyId)
        .collection('floors')
        .get();

    final floors =
        snapshot.docs.map((doc) {
          final data = doc.data();

          return FloorModel(
            id: doc.id,
            buildingId:
                (
                  data['building_id'] ??
                  data['buildingId'] ??
                  propertyId
                ).toString(),
            name:
                (data['name'] ?? '').toString(),
            floorOrder: _toInt(
              data['floor_order'] ??
                  data['floorOrder'],
            ),
            createdAt:
                _parseDate(
                  data['created_at'] ??
                      data['createdAt'],
                ) ??
                DateTime.now(),
          );
        }).toList();

    floors.sort(
      (a, b) =>
          a.floorOrder.compareTo(
            b.floorOrder,
          ),
    );

    return floors;
  }

  // ============================================================
  // ROOMS
  // ============================================================

  Future<List<RoomModel>> getRooms({
    required String propertyId,
    required String floorId,
  }) async {
    final snapshot = await _firestore
        .propertiesCollection(_ownerId)
        .doc(propertyId)
        .collection('rooms')
        .where(
          'floor_id',
          isEqualTo: floorId,
        )
        .get();

    final rooms =
        snapshot.docs.map((doc) {
          final data = doc.data();

          return RoomModel(
            id: doc.id,
            floorId:
                (
                  data['floor_id'] ??
                  data['floorId'] ??
                  floorId
                ).toString(),
            roomNumber:
                (
                  data['room_number'] ??
                  data['roomNumber'] ??
                  ''
                ).toString(),
            bedCount: _toInt(
              data['bed_count'] ??
                  data['bedCount'],
            ),
            createdAt:
                _parseDate(
                  data['created_at'] ??
                      data['createdAt'],
                ) ??
                DateTime.now(),
          );
        }).toList();

    rooms.sort(
      (a, b) =>
          a.roomNumber.compareTo(
            b.roomNumber,
          ),
    );

    return rooms;
  }

  // ============================================================
  // AVAILABLE BEDS
  // ============================================================

  Future<List<BedModel>> getAvailableBeds({
    required String propertyId,
    required String roomId,
  }) async {
    final snapshot = await _firestore
        .propertiesCollection(_ownerId)
        .doc(propertyId)
        .collection('beds')
        .where(
          'room_id',
          isEqualTo: roomId,
        )
        .where(
          'status',
          isEqualTo: 'available',
        )
        .get();

    final beds =
        snapshot.docs.map((doc) {
          final data = doc.data();

          return BedModel(
            id: doc.id,
            roomId:
                (
                  data['room_id'] ??
                  data['roomId'] ??
                  roomId
                ).toString(),
            bedNumber:
                (
                  data['bed_number'] ??
                  data['bedNumber'] ??
                  ''
                ).toString(),
            status:
                (
                  data['status'] ??
                  'available'
                ).toString(),
            createdAt:
                _parseDate(
                  data['created_at'] ??
                      data['createdAt'],
                ) ??
                DateTime.now(),
          );
        }).toList();

    beds.sort(
      (a, b) =>
          a.bedNumber.compareTo(
            b.bedNumber,
          ),
    );

    return beds;
  }

  // ============================================================
  // UPLOAD TENANT ID PROOF
  //
  // Any selected proof can be uploaded:
  //
  // Aadhaar
  // PAN
  // Passport
  // Driving Licence
  // Voter ID
  // Other
  //
  // Firebase Storage:
  //
  // owners/
  //   {ownerId}/
  //     properties/
  //       {propertyId}/
  //         tenants/
  //           {tenantId}/
  //             id_proof/
  //               proof_timestamp.jpg
  //
  // ============================================================

  Future<String?> uploadTenantIdProof({
    required String propertyId,
    required String tenantId,
    required String proofType,
    required Uint8List bytes,
  }) async {
    if (bytes.isEmpty) {
      return null;
    }

    // Convert selected proof type into a safe
    // Firebase Storage file-name format.
    //
    // Examples:
    //
    // Aadhaar        -> aadhaar
    // PAN            -> pan
    // Passport       -> passport
    // Driving Licence -> driving_licence
    // Voter ID       -> voter_id
    // Other          -> other
    //

    final safeProofType =
        proofType
            .trim()
            .toLowerCase()
            .replaceAll(
              RegExp(r'[^a-z0-9]+'),
              '_',
            )
            .replaceAll(
              RegExp(r'^_+|_+$'),
              '',
            );

    final fileName =
        '${safeProofType.isEmpty ? 'id_proof' : safeProofType}_'
        '${DateTime.now().millisecondsSinceEpoch}.jpg';

    final storagePath =
        'owners/$_ownerId/'
        'properties/$propertyId/'
        'tenants/$tenantId/'
        'id_proof/$fileName';

    final storageRef =
        _storage.ref().child(
          storagePath,
        );

    try {
      await storageRef.putData(
        bytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          cacheControl:
              'private,max-age=3600',
        ),
      );

      final downloadUrl =
          await storageRef.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception(
        'Unable to upload tenant ID proof: $e',
      );
    }
  }

  // ============================================================
  // SAVE TENANT
  //
  // Existing tenant fields are preserved.
  //
  // NEW:
  //
  // id_proof_url
  // id_proof_uploaded_at
  //
  // ============================================================

  Future<void> addTenant({
    required String propertyId,
    required TenantModel tenant,
    String? idProofUrl,
  }) async {
    final tenantRef =
        _tenantCollection(propertyId)
            .doc(tenant.id);

    final bedRef =
        _bedDocument(
          propertyId,
          tenant.bedId,
        );

    await _firestore.db.runTransaction(
      (transaction) async {
        final bedSnapshot =
            await transaction.get(
          bedRef,
        );

        if (!bedSnapshot.exists) {
          throw Exception(
            'Selected bed does not exist.',
          );
        }

        final bedData =
            bedSnapshot.data() ?? {};

        final status =
            (
              bedData['status'] ?? ''
            )
                .toString()
                .trim()
                .toLowerCase();

        if (status != 'available') {
          throw Exception(
            'Selected bed is already occupied.',
          );
        }

        // --------------------------------------------------------
        // EXISTING TENANT DATA
        // --------------------------------------------------------

        final tenantData =
            <String, dynamic>{
          'bed_id':
              tenant.bedId,

          'full_name':
              tenant.fullName,

          'phone':
              tenant.phone,

          'alternate_phone':
              tenant.alternatePhone,

          'email':
              tenant.email,

          'id_proof_type':
              tenant.idProofType,

          'id_proof_number':
              tenant.idProofNumber,

          'joining_date':
              tenant.joiningDate
                  .toIso8601String(),

          'monthly_rent':
              tenant.monthlyRent,

          'security_deposit':
              tenant.securityDeposit,

          'status':
              'active',

          'created_at':
              tenant.createdAt
                  .toIso8601String(),
        };

        // --------------------------------------------------------
        // ID PROOF DATA
        // --------------------------------------------------------

        if (idProofUrl != null &&
            idProofUrl.trim().isNotEmpty) {
          tenantData[
              'id_proof_url'] =
              idProofUrl.trim();

          tenantData[
              'id_proof_uploaded_at'] =
              FieldValue.serverTimestamp();
        }

        // --------------------------------------------------------
        // SAVE TENANT
        // --------------------------------------------------------

        transaction.set(
          tenantRef,
          tenantData,
        );

        // --------------------------------------------------------
        // MARK BED OCCUPIED
        // --------------------------------------------------------

        transaction.update(
          bedRef,
          {
            'status': 'occupied',
          },
        );
      },
    );
  }

  // ============================================================
  // GET TENANTS
  // ============================================================

  Future<List<TenantModel>> getTenants({
    required String propertyId,
  }) async {
    if (propertyId.trim().isEmpty) {
      return [];
    }

final snapshot = await _tenantCollection(propertyId).get(
  const GetOptions(
    source: Source.server,
  ),
);

    final tenants =
        snapshot.docs
            .map(
              (doc) =>
                  _tenantFromFirestore(
                    doc.id,
                    doc.data(),
                  ),
            )
            .toList();

    tenants.sort(
      (a, b) =>
          b.createdAt.compareTo(
            a.createdAt,
          ),
    );

    return tenants;
  }

  // ============================================================
  // GET ID PROOF URL
  //
  // Useful later for View ID Proof.
  // ============================================================

  Future<String?> getTenantIdProofUrl({
    required String propertyId,
    required String tenantId,
  }) async {
    final doc =
        await _tenantCollection(
          propertyId,
        ).doc(tenantId).get();

    if (!doc.exists) {
      return null;
    }

    return _nullableString(
      doc.data()?['id_proof_url'],
    );
  }

  // ============================================================
  // VACATE TENANT
  // ============================================================

  Future<void> vacateTenant({
    required String propertyId,
    required String tenantId,
  }) async {
    final tenantRef =
        _tenantCollection(propertyId)
            .doc(tenantId);

    await _firestore.db.runTransaction(
      (transaction) async {
        final tenantSnapshot =
            await transaction.get(
          tenantRef,
        );

        if (!tenantSnapshot.exists) {
          throw Exception(
            'Tenant not found.',
          );
        }

        final data =
            tenantSnapshot.data() ?? {};

        final status =
            (
              data['status'] ?? ''
            )
                .toString()
                .trim()
                .toLowerCase();

        if (status != 'active') {
          return;
        }

        final bedId =
            (
              data['bed_id'] ?? ''
            )
                .toString()
                .trim();

        if (bedId.isEmpty) {
          throw Exception(
            'Tenant bed is missing.',
          );
        }

        final bedRef =
            _bedDocument(
              propertyId,
              bedId,
            );

        transaction.update(
          tenantRef,
          {
            'status': 'vacated',
          },
        );

        transaction.update(
          bedRef,
          {
            'status': 'available',
          },
        );
      },
    );
  }

  // ============================================================
  // DELETE TENANT
  // ============================================================

  Future<void> deleteTenant({
    required String propertyId,
    required String tenantId,
  }) async {
    final tenantRef =
        _tenantCollection(propertyId)
            .doc(tenantId);

    await _firestore.db.runTransaction(
      (transaction) async {
        final tenantSnapshot =
            await transaction.get(
          tenantRef,
        );

        if (!tenantSnapshot.exists) {
          return;
        }

        final data =
            tenantSnapshot.data() ?? {};

        final status =
            (
              data['status'] ?? ''
            )
                .toString()
                .trim()
                .toLowerCase();

        final bedId =
            (
              data['bed_id'] ?? ''
            )
                .toString()
                .trim();

        transaction.delete(
          tenantRef,
        );

        if (status == 'active' &&
            bedId.isNotEmpty) {
          transaction.update(
            _bedDocument(
              propertyId,
              bedId,
            ),
            {
              'status': 'available',
            },
          );
        }
      },
    );
  }

  // ============================================================
  // FIRESTORE → TENANT MODEL
  // ============================================================

  TenantModel _tenantFromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return TenantModel(
      id: id,

      bedId:
          (data['bed_id'] ?? '')
              .toString(),

      fullName:
          (data['full_name'] ?? '')
              .toString(),

      phone:
          (data['phone'] ?? '')
              .toString(),

      alternatePhone:
          _nullableString(
        data['alternate_phone'],
      ),

      email:
          _nullableString(
        data['email'],
      ),

      idProofType:
          _nullableString(
        data['id_proof_type'],
      ),

      idProofNumber:
          _nullableString(
        data['id_proof_number'],
      ),
      idProofUrl: _nullableString(data['id_proof_url']),
      joiningDate:
          _parseDate(
            data['joining_date'],
          ) ??
          DateTime.now(),

      monthlyRent:
          _toDouble(
        data['monthly_rent'],
      ),

      securityDeposit:
          _toDouble(
        data['security_deposit'],
      ),

      status:
          (
            data['status'] ??
            'active'
          ).toString(),

      createdAt:
          _parseDate(
            data['created_at'],
          ) ??
          DateTime.now(),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String? _nullableString(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    final text =
        value.toString().trim();

    return text.isEmpty
        ? null
        : text;
  }

  int _toInt(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
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