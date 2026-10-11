import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../database_helper.dart';

/// ============================================================
/// FIREBASE MIGRATION RESULT
/// ============================================================
///
/// Contains a summary of the SQLite -> Firebase migration.
///
/// This is useful for showing the user exactly how many
/// buildings, floors, rooms, beds, tenants, transactions
/// and bills were migrated.
///
/// ============================================================

class FirebaseMigrationResult {
  final int buildings;
  final int floors;
  final int rooms;
  final int beds;
  final int tenants;
  final int transactions;
  final int bills;

  const FirebaseMigrationResult({
    required this.buildings,
    required this.floors,
    required this.rooms,
    required this.beds,
    required this.tenants,
    required this.transactions,
    required this.bills,
  });

  int get total =>
      buildings +
      floors +
      rooms +
      beds +
      tenants +
      transactions +
      bills;

  @override
  String toString() {
    return '''
Firebase Migration Completed

Buildings: $buildings
Floors: $floors
Rooms: $rooms
Beds: $beds
Tenants: $tenants
Transactions: $transactions
Bills: $bills

Total records: $total
''';
  }
}

/// ============================================================
/// FIREBASE MIGRATION SERVICE
/// ============================================================
///
/// Purpose:
///
/// Existing SQLite
///        ↓
/// Firebase Firestore
///
/// This service does NOT delete anything from SQLite.
///
/// Existing IDs are preserved.
///
/// Firestore structure:
///
/// owners/{firebaseUid}
///   └── properties/{buildingId}
///         ├── floors/{floorId}
///         ├── rooms/{roomId}
///         ├── beds/{bedId}
///         ├── tenants/{tenantId}
///         ├── transactions/{transactionId}
///         └── bills/{billId}
///
/// ============================================================

class FirebaseMigrationService {
  FirebaseMigrationService._();

  static final FirebaseMigrationService instance =
      FirebaseMigrationService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final DatabaseHelper _database =
      DatabaseHelper.instance;

  // ============================================================
  // LOGGED-IN FIREBASE OWNER UID
  // ============================================================

  String get _firebaseOwnerId {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'No user is logged in. Please login first.',
      );
    }

    return user.uid;
  }

  // ============================================================
  // OWNER DOCUMENT
  // ============================================================

  DocumentReference<Map<String, dynamic>>
      _ownerDocument(
    String ownerId,
  ) {
    return _firestore
        .collection('owners')
        .doc(ownerId);
  }

  // ============================================================
  // PROPERTIES COLLECTION
  // ============================================================

  CollectionReference<Map<String, dynamic>>
      _propertiesCollection(
    String ownerId,
  ) {
    return _ownerDocument(ownerId)
        .collection('properties');
  }

  // ============================================================
  // PROPERTY DOCUMENT
  // ============================================================

  DocumentReference<Map<String, dynamic>>
      _propertyDocument(
    String ownerId,
    String buildingId,
  ) {
    return _propertiesCollection(ownerId)
        .doc(buildingId);
  }

  // ============================================================
  // MIGRATE ALL BUILDINGS
  // ============================================================
  //
  // localOwnerId:
  //
  // This is the existing SQLite owner ID.
  //
  // Current app still uses the old local owner ID
  // such as "default_owner".
  //
  // We DO NOT change that local data during migration.
  //
  // Firebase uses the currently authenticated Firebase UID.
  //
  // ============================================================

  Future<FirebaseMigrationResult>
      migrateAllData({
    required String localOwnerId,
  }) async {
    final firebaseOwnerId =
        _firebaseOwnerId;

    // ----------------------------------------------------------
    // ENSURE OWNER DOCUMENT EXISTS
    // ----------------------------------------------------------

    await _ownerDocument(
      firebaseOwnerId,
    ).set(
      {
        'uid': firebaseOwnerId,
        'email': _auth.currentUser?.email ?? '',
        'name':
            _auth.currentUser?.displayName ?? '',
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    // ----------------------------------------------------------
    // GET LOCAL BUILDINGS
    // ----------------------------------------------------------

    final buildings =
        await _database.getBuildings(
      ownerId: localOwnerId,
    );

    if (buildings.isEmpty) {
      return const FirebaseMigrationResult(
        buildings: 0,
        floors: 0,
        rooms: 0,
        beds: 0,
        tenants: 0,
        transactions: 0,
        bills: 0,
      );
    }

    int buildingCount = 0;
    int floorCount = 0;
    int roomCount = 0;
    int bedCount = 0;
    int tenantCount = 0;
    int transactionCount = 0;
    int billCount = 0;

    // ----------------------------------------------------------
    // MIGRATE EACH BUILDING / PG
    // ----------------------------------------------------------

    for (final building in buildings) {
      try {
        final result =
            await _migrateBuilding(
          firebaseOwnerId: firebaseOwnerId,
          buildingId: building.id,
        );

        buildingCount += result.buildings;
        floorCount += result.floors;
        roomCount += result.rooms;
        bedCount += result.beds;
        tenantCount += result.tenants;
        transactionCount +=
            result.transactions;
        billCount += result.bills;
      } catch (e) {
        throw Exception(
          'Migration failed for PG '
          '"${building.name}" '
          '(ID: ${building.id}). '
          '$e',
        );
      }
    }

    return FirebaseMigrationResult(
      buildings: buildingCount,
      floors: floorCount,
      rooms: roomCount,
      beds: bedCount,
      tenants: tenantCount,
      transactions: transactionCount,
      bills: billCount,
    );
  }

  // ============================================================
  // MIGRATE ONE BUILDING
  // ============================================================

  Future<FirebaseMigrationResult>
      _migrateBuilding({
    required String firebaseOwnerId,
    required String buildingId,
  }) async {
    final db =
        await _database.database;

    // ----------------------------------------------------------
    // GET BUILDING
    // ----------------------------------------------------------

    final buildingRows =
        await db.query(
      'buildings',
      where: 'id = ?',
      whereArgs: [buildingId],
      limit: 1,
    );

    if (buildingRows.isEmpty) {
      throw Exception(
        'Building not found in SQLite.',
      );
    }

    final building =
        buildingRows.first;

    // ----------------------------------------------------------
    // CREATE / UPDATE FIRESTORE PROPERTY
    // ----------------------------------------------------------

    await _propertyDocument(
      firebaseOwnerId,
      buildingId,
    ).set(
      {
        'ownerId': firebaseOwnerId,
        'name':
            building['name']?.toString() ?? '',
        'type': 'PG',
        'address':
            building['address']?.toString() ?? '',
        'city': '',
        'state': '',
        'createdAt':
            building['created_at']?.toString() ??
                DateTime.now()
                    .toIso8601String(),
        'migratedFrom':
            'sqlite',
        'migratedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    // ----------------------------------------------------------
    // MIGRATE FLOORS
    // ----------------------------------------------------------

    final floorCount =
        await _migrateFloors(
      firebaseOwnerId: firebaseOwnerId,
      buildingId: buildingId,
    );

    // ----------------------------------------------------------
    // MIGRATE TRANSACTIONS
    // ----------------------------------------------------------

    final transactionCount =
        await _migrateTransactions(
      firebaseOwnerId: firebaseOwnerId,
      buildingId: buildingId,
    );

    // ----------------------------------------------------------
    // MIGRATE BILLS
    // ----------------------------------------------------------

    final billCount =
        await _migrateBills(
      firebaseOwnerId: firebaseOwnerId,
      buildingId: buildingId,
    );

    return FirebaseMigrationResult(
      buildings: 1,
      floors: floorCount.floors,
      rooms: floorCount.rooms,
      beds: floorCount.beds,
      tenants: floorCount.tenants,
      transactions: transactionCount,
      bills: billCount,
    );
  }

  // ============================================================
  // MIGRATE FLOORS
  // ============================================================

  Future<_HierarchyMigrationResult>
      _migrateFloors({
    required String firebaseOwnerId,
    required String buildingId,
  }) async {
    final db =
        await _database.database;

    final floors =
        await db.query(
      'floors',
      where: 'building_id = ?',
      whereArgs: [buildingId],
      orderBy: 'floor_order ASC',
    );

    int floorCount = 0;
    int roomCount = 0;
    int bedCount = 0;
    int tenantCount = 0;

    for (final floor in floors) {
      final floorId =
          floor['id']?.toString();

      if (floorId == null ||
          floorId.isEmpty) {
        continue;
      }

      // --------------------------------------------------------
      // FLOOR
      // --------------------------------------------------------

      await _propertyDocument(
        firebaseOwnerId,
        buildingId,
      )
          .collection('floors')
          .doc(floorId)
          .set(
        {
          'id': floorId,
          'propertyId': buildingId,
          'name':
              floor['name']?.toString() ?? '',
          'floorOrder':
              _toInt(floor['floor_order']),
          'createdAt':
              floor['created_at']?.toString() ??
                  DateTime.now()
                      .toIso8601String(),
          'migratedFrom':
              'sqlite',
          'migratedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      floorCount++;

      // --------------------------------------------------------
      // ROOMS
      // --------------------------------------------------------

      final roomResult =
          await _migrateRooms(
        firebaseOwnerId: firebaseOwnerId,
        buildingId: buildingId,
        floorId: floorId,
      );

      roomCount += roomResult.rooms;
      bedCount += roomResult.beds;
      tenantCount += roomResult.tenants;
    }

    return _HierarchyMigrationResult(
      floors: floorCount,
      rooms: roomCount,
      beds: bedCount,
      tenants: tenantCount,
    );
  }

  // ============================================================
  // MIGRATE ROOMS
  // ============================================================

  Future<_HierarchyMigrationResult>
      _migrateRooms({
    required String firebaseOwnerId,
    required String buildingId,
    required String floorId,
  }) async {
    final db =
        await _database.database;

    final rooms =
        await db.query(
      'rooms',
      where: 'floor_id = ?',
      whereArgs: [floorId],
      orderBy: 'room_number ASC',
    );

    int roomCount = 0;
    int bedCount = 0;
    int tenantCount = 0;

    for (final room in rooms) {
      final roomId =
          room['id']?.toString();

      if (roomId == null ||
          roomId.isEmpty) {
        continue;
      }

      // --------------------------------------------------------
      // ROOM
      // --------------------------------------------------------

      await _propertyDocument(
        firebaseOwnerId,
        buildingId,
      )
          .collection('rooms')
          .doc(roomId)
          .set(
        {
          'id': roomId,
          'propertyId': buildingId,
          'floorId': floorId,
          'roomNumber':
              room['room_number']
                      ?.toString() ??
                  '',
          'bedCount':
              _toInt(room['bed_count']),
          'createdAt':
              room['created_at']?.toString() ??
                  DateTime.now()
                      .toIso8601String(),
          'migratedFrom':
              'sqlite',
          'migratedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      roomCount++;

      // --------------------------------------------------------
      // BEDS
      // --------------------------------------------------------

      final bedResult =
          await _migrateBeds(
        firebaseOwnerId: firebaseOwnerId,
        buildingId: buildingId,
        roomId: roomId,
      );

      bedCount += bedResult.beds;
      tenantCount += bedResult.tenants;
    }

    return _HierarchyMigrationResult(
      floors: 0,
      rooms: roomCount,
      beds: bedCount,
      tenants: tenantCount,
    );
  }

  // ============================================================
  // MIGRATE BEDS
  // ============================================================

  Future<_HierarchyMigrationResult>
      _migrateBeds({
    required String firebaseOwnerId,
    required String buildingId,
    required String roomId,
  }) async {
    final db =
        await _database.database;

    final beds =
        await db.query(
      'beds',
      where: 'room_id = ?',
      whereArgs: [roomId],
      orderBy: 'created_at ASC',
    );

    int bedCount = 0;
    int tenantCount = 0;

    for (final bed in beds) {
      final bedId =
          bed['id']?.toString();

      if (bedId == null ||
          bedId.isEmpty) {
        continue;
      }

      // --------------------------------------------------------
      // BED
      // --------------------------------------------------------

      await _propertyDocument(
        firebaseOwnerId,
        buildingId,
      )
          .collection('beds')
          .doc(bedId)
          .set(
        {
          'id': bedId,
          'propertyId': buildingId,
          'roomId': roomId,
          'bedNumber':
              bed['bed_number']
                      ?.toString() ??
                  '',
          'status':
              bed['status']?.toString() ??
                  'available',
          'createdAt':
              bed['created_at']?.toString() ??
                  DateTime.now()
                      .toIso8601String(),
          'migratedFrom':
              'sqlite',
          'migratedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      bedCount++;

      // --------------------------------------------------------
      // TENANT(S) FOR THIS BED
      // --------------------------------------------------------

      final tenants =
          await db.query(
        'tenants',
        where: 'bed_id = ?',
        whereArgs: [bedId],
        orderBy: 'created_at DESC',
      );

      for (final tenant in tenants) {
        final tenantId =
            tenant['id']?.toString();

        if (tenantId == null ||
            tenantId.isEmpty) {
          continue;
        }

        await _propertyDocument(
          firebaseOwnerId,
          buildingId,
        )
            .collection('tenants')
            .doc(tenantId)
            .set(
          {
            'id': tenantId,
            'propertyId': buildingId,
            'bedId': bedId,
            'fullName':
                tenant['full_name']
                        ?.toString() ??
                    '',
            'phone':
                tenant['phone']
                        ?.toString() ??
                    '',
            'alternatePhone':
                tenant['alternate_phone']
                    ?.toString(),
            'email':
                tenant['email']?.toString(),
            'idProofType':
                tenant['id_proof_type']
                    ?.toString(),
            'idProofNumber':
                tenant['id_proof_number']
                    ?.toString(),
            'joiningDate':
                tenant['joining_date']
                    ?.toString() ??
                    '',
            'monthlyRent':
                _toDouble(
              tenant['monthly_rent'],
            ),
            'securityDeposit':
                _toDouble(
              tenant['security_deposit'],
            ),
            'status':
                tenant['status']
                        ?.toString() ??
                    'active',
            'createdAt':
                tenant['created_at']
                        ?.toString() ??
                    DateTime.now()
                        .toIso8601String(),
            'migratedFrom':
                'sqlite',
            'migratedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(
            merge: true,
          ),
        );

        tenantCount++;
      }
    }

    return _HierarchyMigrationResult(
      floors: 0,
      rooms: 0,
      beds: bedCount,
      tenants: tenantCount,
    );
  }

  // ============================================================
  // MIGRATE TRANSACTIONS
  // ============================================================

  Future<int> _migrateTransactions({
    required String firebaseOwnerId,
    required String buildingId,
  }) async {
    final db =
        await _database.database;

    final transactions =
        await db.query(
      'transactions',
      where: 'building_id = ?',
      whereArgs: [buildingId],
      orderBy: 'date DESC',
    );

    int count = 0;

    for (final transaction
        in transactions) {
      final transactionId =
          transaction['id']?.toString();

      if (transactionId == null ||
          transactionId.isEmpty) {
        continue;
      }

      await _propertyDocument(
        firebaseOwnerId,
        buildingId,
      )
          .collection('transactions')
          .doc(transactionId)
          .set(
        {
          'id': transactionId,
          'propertyId': buildingId,
          'buildingId': buildingId,
          'tenantId':
              transaction['tenant_id']
                  ?.toString(),
          'type':
              transaction['type']
                      ?.toString() ??
                  'income',
          'paymentMethod':
              transaction['payment_method']
                      ?.toString() ??
                  'cash',
          'amount':
              _toDouble(
            transaction['amount'],
          ),
          'date':
              transaction['date']
                      ?.toString() ??
                  '',
          'description':
              transaction['description']
                      ?.toString() ??
                  '',
          'expenseCategory':
              transaction[
                'expense_category'
              ]?.toString(),
          'customExpenseCategory':
              transaction[
                'custom_expense_category'
              ]?.toString(),
          'migratedFrom':
              'sqlite',
          'migratedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      count++;
    }

    return count;
  }

  // ============================================================
  // MIGRATE BILLS
  // ============================================================

  Future<int> _migrateBills({
    required String firebaseOwnerId,
    required String buildingId,
  }) async {
    final db =
        await _database.database;

    final bills =
        await db.query(
      'bills',
      where: 'building_id = ?',
      whereArgs: [buildingId],
      orderBy: 'created_at DESC',
    );

    int count = 0;

    for (final bill in bills) {
      final billId =
          bill['id']?.toString();

      if (billId == null ||
          billId.isEmpty) {
        continue;
      }

      await _propertyDocument(
        firebaseOwnerId,
        buildingId,
      )
          .collection('bills')
          .doc(billId)
          .set(
        {
          'id': billId,
          'propertyId': buildingId,
          'buildingId': buildingId,
          'tenantId':
              bill['tenant_id']
                  ?.toString(),
          'tenantName':
              bill['tenant_name']
                  ?.toString(),
          'billType':
              bill['bill_type']
                      ?.toString() ??
                  'Monthly Rent',
          'amount':
              _toDouble(
            bill['amount'],
          ),
          'dueDate':
              bill['due_date']
                      ?.toString() ??
                  '',
          'note':
              bill['note']?.toString(),
          'status':
              bill['status']
                      ?.toString() ??
                  'pending',
          'createdAt':
              bill['created_at']
                      ?.toString() ??
                  DateTime.now()
                      .toIso8601String(),
          'migratedFrom':
              'sqlite',
          'migratedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      count++;
    }

    return count;
  }

  // ============================================================
  // INTEGER CONVERSION
  // ============================================================

  int _toInt(
    Object? value,
  ) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value.toString(),
        ) ??
        0;
  }

  // ============================================================
  // DOUBLE CONVERSION
  // ============================================================

  double _toDouble(
    Object? value,
  ) {
    if (value == null) {
      return 0;
    }

    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value.toString(),
        ) ??
        0;
  }
}

/// ============================================================
/// INTERNAL HIERARCHY RESULT
/// ============================================================

class _HierarchyMigrationResult {
  final int floors;
  final int rooms;
  final int beds;
  final int tenants;

  const _HierarchyMigrationResult({
    required this.floors,
    required this.rooms,
    required this.beds,
    required this.tenants,
  });
}