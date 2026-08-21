import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'building_model.dart';
import 'tenant_model.dart';
import 'transaction_model.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();

  static final DatabaseHelper instance =
      DatabaseHelper._privateConstructor();

  static Database? _database;

  // ============================================================
  // DATABASE INSTANCE
  // ============================================================

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();

    return _database!;
  }

  // ============================================================
  // INITIALIZE DATABASE
  // ============================================================

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();

    final path = join(
      databasePath,
      'stay_mitra.db',
    );

    return openDatabase(
      path,
      version: 5,

      onConfigure: (db) async {
        await db.execute(
          'PRAGMA foreign_keys = ON',
        );
      },

      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ============================================================
  // CREATE DATABASE
  // ============================================================

  Future<void> _onCreate(
    Database db,
    int version,
  ) async {
    // ----------------------------------------------------------
    // TRANSACTIONS
    // ----------------------------------------------------------

    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,

        type TEXT NOT NULL,

        payment_method TEXT NOT NULL,

        amount REAL NOT NULL,

        date TEXT NOT NULL,

        description TEXT NOT NULL,

        expense_category TEXT,

        custom_expense_category TEXT,

        tenant_id TEXT,

        FOREIGN KEY (tenant_id)
          REFERENCES tenants(id)
          ON DELETE SET NULL
      )
    ''');

    // ----------------------------------------------------------
    // BUILDINGS
    // ----------------------------------------------------------

    await db.execute('''
      CREATE TABLE buildings (
        id TEXT PRIMARY KEY,

        name TEXT NOT NULL,

        address TEXT,

        created_at TEXT NOT NULL
      )
    ''');

    // ----------------------------------------------------------
    // FLOORS
    // ----------------------------------------------------------

    await db.execute('''
      CREATE TABLE floors (
        id TEXT PRIMARY KEY,

        building_id TEXT NOT NULL,

        name TEXT NOT NULL,

        floor_order INTEGER NOT NULL,

        created_at TEXT NOT NULL,

        FOREIGN KEY (building_id)
          REFERENCES buildings(id)
          ON DELETE CASCADE
      )
    ''');

    // ----------------------------------------------------------
    // ROOMS
    // ----------------------------------------------------------

    await db.execute('''
      CREATE TABLE rooms (
        id TEXT PRIMARY KEY,

        floor_id TEXT NOT NULL,

        room_number TEXT NOT NULL,

        bed_count INTEGER NOT NULL DEFAULT 0,

        created_at TEXT NOT NULL,

        FOREIGN KEY (floor_id)
          REFERENCES floors(id)
          ON DELETE CASCADE
      )
    ''');

    // ----------------------------------------------------------
    // BEDS
    // ----------------------------------------------------------

    await db.execute('''
      CREATE TABLE beds (
        id TEXT PRIMARY KEY,

        room_id TEXT NOT NULL,

        bed_number TEXT NOT NULL,

        status TEXT NOT NULL DEFAULT 'available',

        created_at TEXT NOT NULL,

        FOREIGN KEY (room_id)
          REFERENCES rooms(id)
          ON DELETE CASCADE
      )
    ''');

    // ----------------------------------------------------------
    // TENANTS
    // ----------------------------------------------------------

    await db.execute('''
      CREATE TABLE tenants (
        id TEXT PRIMARY KEY,

        bed_id TEXT NOT NULL,

        full_name TEXT NOT NULL,

        phone TEXT NOT NULL,

        alternate_phone TEXT,

        email TEXT,

        id_proof_type TEXT,

        id_proof_number TEXT,

        joining_date TEXT NOT NULL,

        monthly_rent REAL NOT NULL DEFAULT 0,

        security_deposit REAL NOT NULL DEFAULT 0,

        status TEXT NOT NULL DEFAULT 'active',

        created_at TEXT NOT NULL,

        FOREIGN KEY (bed_id)
          REFERENCES beds(id)
          ON DELETE RESTRICT
      )
    ''');

    // ----------------------------------------------------------
    // INDEXES
    // ----------------------------------------------------------

    await db.execute('''
      CREATE INDEX idx_floors_building_id
      ON floors(building_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_rooms_floor_id
      ON rooms(floor_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_beds_room_id
      ON beds(room_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_tenants_bed_id
      ON tenants(bed_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_tenants_status
      ON tenants(status)
    ''');

    await db.execute('''
      CREATE INDEX idx_transactions_tenant_id
      ON transactions(tenant_id)
    ''');

    // ----------------------------------------------------------
    // ONLY ONE ACTIVE TENANT PER BED
    // ----------------------------------------------------------

    await db.execute('''
      CREATE UNIQUE INDEX idx_one_active_tenant_per_bed
      ON tenants(bed_id)
      WHERE status = 'active'
    ''');
  }

  // ============================================================
  // DATABASE MIGRATION
  // ============================================================

  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // ----------------------------------------------------------
    // VERSION 1 → VERSION 2
    // TRANSACTION EXPENSE COLUMNS
    // ----------------------------------------------------------

    if (oldVersion < 2) {
      await _addColumnIfNotExists(
        db,
        'transactions',
        'expense_category',
        'TEXT',
      );

      await _addColumnIfNotExists(
        db,
        'transactions',
        'custom_expense_category',
        'TEXT',
      );
    }

    // ----------------------------------------------------------
    // VERSION 2 → VERSION 3
    // BUILDINGS
    // FLOORS
    // ROOMS
    // BEDS
    // ----------------------------------------------------------

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS buildings (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          address TEXT,
          created_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS floors (
          id TEXT PRIMARY KEY,
          building_id TEXT NOT NULL,
          name TEXT NOT NULL,
          floor_order INTEGER NOT NULL,
          created_at TEXT NOT NULL,

          FOREIGN KEY (building_id)
            REFERENCES buildings(id)
            ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS rooms (
          id TEXT PRIMARY KEY,
          floor_id TEXT NOT NULL,
          room_number TEXT NOT NULL,
          bed_count INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,

          FOREIGN KEY (floor_id)
            REFERENCES floors(id)
            ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS beds (
          id TEXT PRIMARY KEY,
          room_id TEXT NOT NULL,
          bed_number TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'available',
          created_at TEXT NOT NULL,

          FOREIGN KEY (room_id)
            REFERENCES rooms(id)
            ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_floors_building_id
        ON floors(building_id)
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_rooms_floor_id
        ON rooms(floor_id)
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_beds_room_id
        ON beds(room_id)
      ''');
    }

    // ----------------------------------------------------------
    // VERSION 3 → VERSION 4
    // TENANT MANAGEMENT
    // ----------------------------------------------------------

    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS tenants (
          id TEXT PRIMARY KEY,

          bed_id TEXT NOT NULL,

          full_name TEXT NOT NULL,

          phone TEXT NOT NULL,

          alternate_phone TEXT,

          email TEXT,

          id_proof_type TEXT,

          id_proof_number TEXT,

          joining_date TEXT NOT NULL,

          monthly_rent REAL NOT NULL DEFAULT 0,

          security_deposit REAL NOT NULL DEFAULT 0,

          status TEXT NOT NULL DEFAULT 'active',

          created_at TEXT NOT NULL,

          FOREIGN KEY (bed_id)
            REFERENCES beds(id)
            ON DELETE RESTRICT
        )
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_tenants_bed_id
        ON tenants(bed_id)
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_tenants_status
        ON tenants(status)
      ''');

      await db.execute('''
        CREATE UNIQUE INDEX IF NOT EXISTS
        idx_one_active_tenant_per_bed
        ON tenants(bed_id)
        WHERE status = 'active'
      ''');
    }

    // ----------------------------------------------------------
    // VERSION 4 → VERSION 5
    // TENANT PAYMENT LINK
    // ----------------------------------------------------------

    if (oldVersion < 5) {
      await _addColumnIfNotExists(
        db,
        'transactions',
        'tenant_id',
        'TEXT',
      );

      await db.execute('''
        CREATE INDEX IF NOT EXISTS
        idx_transactions_tenant_id
        ON transactions(tenant_id)
      ''');
    }
  }

  // ============================================================
  // ADD COLUMN IF IT DOES NOT EXIST
  // ============================================================

  Future<void> _addColumnIfNotExists(
    Database db,
    String tableName,
    String columnName,
    String columnDefinition,
  ) async {
    final result = await db.rawQuery(
      'PRAGMA table_info($tableName)',
    );

    final exists = result.any(
      (column) => column['name'] == columnName,
    );

    if (!exists) {
      await db.execute(
        'ALTER TABLE $tableName '
        'ADD COLUMN $columnName $columnDefinition',
      );
    }
  }

  // ============================================================
  // TRANSACTION METHODS
  // ============================================================

  Future<void> insertTransaction(
    TransactionModel transaction,
  ) async {
    final db = await database;

    await db.insert(
      'transactions',
      {
        'id': transaction.id,
        'type': transaction.type.name,
        'payment_method': transaction.paymentMethod.name,
        'amount': transaction.amount,
        'date': transaction.date.toIso8601String(),
        'description': transaction.description,
        'expense_category':
            transaction.expenseCategory?.name,
        'custom_expense_category':
            transaction.customExpenseCategory,
        'tenant_id': null,
      },
      conflictAlgorithm:
          ConflictAlgorithm.replace,
    );
  }

  // ============================================================
  // RECORD TENANT RENT PAYMENT
  // ============================================================

  Future<void> recordTenantPayment({
    required String tenantId,
    required double amount,
    required PaymentMethod paymentMethod,
    required DateTime date,
    String description = 'Rent payment',
  }) async {
    final db = await database;

    if (amount <= 0) {
      throw Exception(
        'Payment amount must be greater than zero.',
      );
    }

    await db.transaction(
      (txn) async {
        // ------------------------------------------------------
        // VERIFY TENANT
        // ------------------------------------------------------

        final tenantResult = await txn.query(
          'tenants',
          where: 'id = ?',
          whereArgs: [tenantId],
          limit: 1,
        );

        if (tenantResult.isEmpty) {
          throw Exception(
            'Tenant not found.',
          );
        }

        final tenant =
            tenantResult.first;

        final status =
            tenant['status'] as String;

        if (status != 'active') {
          throw Exception(
            'Payment cannot be added for a vacated tenant.',
          );
        }

        // ------------------------------------------------------
        // INSERT PAYMENT TRANSACTION
        // ------------------------------------------------------

        final paymentId =
            'PAY_${DateTime.now().microsecondsSinceEpoch}';

        await txn.insert(
          'transactions',
          {
            'id': paymentId,
            'type': TransactionType.income.name,
            'payment_method':
                paymentMethod.name,
            'amount': amount,
            'date': date.toIso8601String(),
            'description': description,
            'expense_category': null,
            'custom_expense_category': null,
            'tenant_id': tenantId,
          },
        );
      },
    );
  }

  // ============================================================
  // GET ALL TRANSACTIONS
  // ============================================================

  Future<List<TransactionModel>>
      getTransactions() async {
    final db = await database;

    final result = await db.query(
      'transactions',
      orderBy: 'date DESC',
    );

    return result.map((row) {
      return TransactionModel(
        id: row['id'] as String,

        type: _transactionTypeFromString(
          row['type'] as String,
        ),

        paymentMethod:
            _paymentMethodFromString(
          row['payment_method'] as String,
        ),

        amount:
            (row['amount'] as num).toDouble(),

        date: DateTime.parse(
          row['date'] as String,
        ),

        description:
            row['description'] as String,

        expenseCategory:
            _expenseCategoryFromString(
          row['expense_category'] as String?,
        ),

        customExpenseCategory:
            row['custom_expense_category']
                as String?,
      );
    }).toList();
  }

  // ============================================================
  // GET TRANSACTION BY ID
  // ============================================================

  Future<TransactionModel?>
      getTransactionById(
    String id,
  ) async {
    final db = await database;

    final result = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    final row = result.first;

    return TransactionModel(
      id: row['id'] as String,

      type: _transactionTypeFromString(
        row['type'] as String,
      ),

      paymentMethod:
          _paymentMethodFromString(
        row['payment_method'] as String,
      ),

      amount:
          (row['amount'] as num).toDouble(),

      date: DateTime.parse(
        row['date'] as String,
      ),

      description:
          row['description'] as String,

      expenseCategory:
          _expenseCategoryFromString(
        row['expense_category'] as String?,
      ),

      customExpenseCategory:
          row['custom_expense_category']
              as String?,
    );
  }

  // ============================================================
  // DELETE TRANSACTION
  // ============================================================

  Future<void> deleteTransaction(
    String id,
  ) async {
    final db = await database;

    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // CLEAR TRANSACTIONS
  // ============================================================

  Future<void> clearTransactions() async {
    final db = await database;

    await db.delete(
      'transactions',
    );
  }

  // ============================================================
  // GET TENANT PAYMENTS FOR CURRENT MONTH
  // ============================================================

  Future<double> getTenantCurrentMonthPaidAmount(
    String tenantId,
  ) async {
    final db = await database;

    final now = DateTime.now();

    final startOfMonth = DateTime(
      now.year,
      now.month,
      1,
    );

    final startOfNextMonth = DateTime(
      now.year,
      now.month + 1,
      1,
    );

    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM transactions
      WHERE tenant_id = ?
        AND type = ?
        AND date >= ?
        AND date < ?
      ''',
      [
        tenantId,
        TransactionType.income.name,
        startOfMonth.toIso8601String(),
        startOfNextMonth.toIso8601String(),
      ],
    );

    return ((result.first['total'] as num?) ?? 0)
        .toDouble();
  }

  // ============================================================
  // GET TENANT BALANCE
  // ============================================================

  Future<double> getTenantBalance(
    String tenantId,
  ) async {
    final tenant =
        await getTenantById(tenantId);

    if (tenant == null) {
      return 0;
    }

    final monthlyRent =
        tenant.monthlyRent;

    final paid =
        await getTenantCurrentMonthPaidAmount(
      tenantId,
    );

    final balance =
        monthlyRent - paid;

    if (balance <= 0) {
      return 0;
    }

    return balance;
  }

  // ============================================================
  // GET TENANT PAYMENT SUMMARY
  // ============================================================

  Future<Map<String, double>>
      getTenantPaymentSummary(
    String tenantId,
  ) async {
    final tenant =
        await getTenantById(tenantId);

    if (tenant == null) {
      return {
        'rent': 0,
        'paid': 0,
        'balance': 0,
      };
    }

    final rent =
        tenant.monthlyRent;

    final paid =
        await getTenantCurrentMonthPaidAmount(
      tenantId,
    );

    final balance =
        (rent - paid) > 0
            ? rent - paid
            : 0;

    return {
      'rent': rent,
      'paid': paid,
      'balance': balance.toDouble(),
    };
  }

  // ============================================================
  // GET ACTIVE TENANTS BY ROOM
  // ============================================================

  Future<List<TenantModel>>
      getActiveTenantsByRoom(
    String roomId,
  ) async {
    final db = await database;

    final result = await db.rawQuery(
      '''
      SELECT t.*
      FROM tenants t
      INNER JOIN beds b
        ON t.bed_id = b.id
      WHERE b.room_id = ?
        AND t.status = ?
      ORDER BY t.full_name COLLATE NOCASE ASC
      ''',
      [
        roomId,
        'active',
      ],
    );

    return result.map((row) {
      return _tenantFromRow(row);
    }).toList();
  }

  // ============================================================
  // GET ACTIVE TENANTS BY BUILDING
  // ============================================================

  Future<List<TenantModel>>
      getActiveTenantsByBuilding(
    String buildingId,
  ) async {
    final db = await database;

    final result = await db.rawQuery(
      '''
      SELECT t.*
      FROM tenants t
      INNER JOIN beds b
        ON t.bed_id = b.id
      INNER JOIN rooms r
        ON b.room_id = r.id
      INNER JOIN floors f
        ON r.floor_id = f.id
      WHERE f.building_id = ?
        AND t.status = ?
      ORDER BY t.full_name COLLATE NOCASE ASC
      ''',
      [
        buildingId,
        'active',
      ],
    );

    return result.map((row) {
      return _tenantFromRow(row);
    }).toList();
  }

  // ============================================================
  // GET ACTIVE TENANTS BY ROOM NUMBER
  // ============================================================

  Future<List<TenantModel>>
      getActiveTenantsByRoomNumber(
    String roomNumber,
  ) async {
    final db = await database;

    final result = await db.rawQuery(
      '''
      SELECT t.*
      FROM tenants t
      INNER JOIN beds b
        ON t.bed_id = b.id
      INNER JOIN rooms r
        ON b.room_id = r.id
      WHERE r.room_number = ?
        AND t.status = ?
      ORDER BY t.full_name COLLATE NOCASE ASC
      ''',
      [
        roomNumber,
        'active',
      ],
    );

    return result.map((row) {
      return _tenantFromRow(row);
    }).toList();
  }

  // ============================================================
  // GET ROOM + ACTIVE TENANTS
  // ============================================================

  Future<List<Map<String, dynamic>>>
      getRoomsWithActiveTenants() async {
    final db = await database;

    final result = await db.rawQuery(
      '''
      SELECT
        r.id AS room_id,
        r.room_number,
        b.id AS bed_id,
        b.bed_number,
        t.id AS tenant_id,
        t.full_name,
        t.phone,
        t.monthly_rent
      FROM rooms r
      INNER JOIN beds b
        ON r.id = b.room_id
      LEFT JOIN tenants t
        ON b.id = t.bed_id
        AND t.status = ?
      ORDER BY
        r.room_number COLLATE NOCASE ASC,
        b.bed_number COLLATE NOCASE ASC
      ''',
      ['active'],
    );

    return result;
  }

  // ============================================================
  // BUILDING METHODS
  // ============================================================

  Future<void> insertBuilding(
    BuildingModel building,
  ) async {
    final db = await database;

    await db.insert(
      'buildings',
      {
        'id': building.id,
        'name': building.name,
        'address': building.address,
        'created_at':
            building.createdAt.toIso8601String(),
      },
      conflictAlgorithm:
          ConflictAlgorithm.replace,
    );
  }

  Future<List<BuildingModel>>
      getBuildings() async {
    final db = await database;

    final result = await db.query(
      'buildings',
      orderBy: 'created_at ASC',
    );

    return result.map((row) {
      return BuildingModel(
        id: row['id'] as String,
        name: row['name'] as String,
        address:
            row['address'] as String?,
        createdAt: DateTime.parse(
          row['created_at'] as String,
        ),
      );
    }).toList();
  }

  Future<void> deleteBuilding(
    String id,
  ) async {
    final db = await database;

    await db.delete(
      'buildings',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // FLOOR METHODS
  // ============================================================

  Future<void> insertFloor(
    FloorModel floor,
  ) async {
    final db = await database;

    await db.insert(
      'floors',
      {
        'id': floor.id,
        'building_id': floor.buildingId,
        'name': floor.name,
        'floor_order': floor.floorOrder,
        'created_at':
            floor.createdAt.toIso8601String(),
      },
      conflictAlgorithm:
          ConflictAlgorithm.replace,
    );
  }

  Future<List<FloorModel>> getFloors(
    String buildingId,
  ) async {
    final db = await database;

    final result = await db.query(
      'floors',
      where: 'building_id = ?',
      whereArgs: [buildingId],
      orderBy: 'floor_order ASC',
    );

    return result.map((row) {
      return FloorModel(
        id: row['id'] as String,
        buildingId:
            row['building_id'] as String,
        name: row['name'] as String,
        floorOrder:
            row['floor_order'] as int,
        createdAt: DateTime.parse(
          row['created_at'] as String,
        ),
      );
    }).toList();
  }

  Future<void> deleteFloor(
    String id,
  ) async {
    final db = await database;

    await db.delete(
      'floors',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // ROOM METHODS
  // ============================================================

  Future<void> insertRoom(
    RoomModel room,
  ) async {
    final db = await database;

    await db.insert(
      'rooms',
      {
        'id': room.id,
        'floor_id': room.floorId,
        'room_number': room.roomNumber,
        'bed_count': room.bedCount,
        'created_at':
            room.createdAt.toIso8601String(),
      },
      conflictAlgorithm:
          ConflictAlgorithm.replace,
    );
  }

  Future<List<RoomModel>> getRooms(
    String floorId,
  ) async {
    final db = await database;

    final result = await db.query(
      'rooms',
      where: 'floor_id = ?',
      whereArgs: [floorId],
      orderBy: 'room_number ASC',
    );

    return result.map((row) {
      return RoomModel(
        id: row['id'] as String,
        floorId:
            row['floor_id'] as String,
        roomNumber:
            row['room_number'] as String,
        bedCount:
            row['bed_count'] as int,
        createdAt: DateTime.parse(
          row['created_at'] as String,
        ),
      );
    }).toList();
  }

  Future<void> updateRoom(
    RoomModel room,
  ) async {
    final db = await database;

    await db.update(
      'rooms',
      {
        'floor_id': room.floorId,
        'room_number': room.roomNumber,
        'bed_count': room.bedCount,
      },
      where: 'id = ?',
      whereArgs: [room.id],
    );
  }

  Future<void> deleteRoom(
    String id,
  ) async {
    final db = await database;

    await db.delete(
      'rooms',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // BED METHODS
  // ============================================================

  Future<void> insertBed(
    BedModel bed,
  ) async {
    final db = await database;

    await db.insert(
      'beds',
      {
        'id': bed.id,
        'room_id': bed.roomId,
        'bed_number': bed.bedNumber,
        'status': bed.status,
        'created_at':
            bed.createdAt.toIso8601String(),
      },
      conflictAlgorithm:
          ConflictAlgorithm.replace,
    );
  }

  Future<List<BedModel>> getBeds(
    String roomId,
  ) async {
    final db = await database;

    final result = await db.query(
      'beds',
      where: 'room_id = ?',
      whereArgs: [roomId],
      orderBy: 'created_at ASC',
    );

    return result.map((row) {
      return BedModel(
        id: row['id'] as String,
        roomId:
            row['room_id'] as String,
        bedNumber:
            row['bed_number'] as String,
        status:
            row['status'] as String,
        createdAt: DateTime.parse(
          row['created_at'] as String,
        ),
      );
    }).toList();
  }

  // ============================================================
  // GET AVAILABLE BEDS
  // ============================================================

  Future<List<BedModel>>
      getAvailableBeds(
    String roomId,
  ) async {
    final db = await database;

    final result = await db.query(
      'beds',
      where:
          'room_id = ? AND status = ?',
      whereArgs: [
        roomId,
        'available',
      ],
      orderBy: 'created_at ASC',
    );

    return result.map((row) {
      return BedModel(
        id: row['id'] as String,
        roomId:
            row['room_id'] as String,
        bedNumber:
            row['bed_number'] as String,
        status:
            row['status'] as String,
        createdAt: DateTime.parse(
          row['created_at'] as String,
        ),
      );
    }).toList();
  }

  // ============================================================
  // UPDATE BED STATUS
  // ============================================================

  Future<void> updateBedStatus(
    String bedId,
    String status,
  ) async {
    final db = await database;

    await db.update(
      'beds',
      {
        'status': status,
      },
      where: 'id = ?',
      whereArgs: [bedId],
    );
  }

  Future<void> deleteBed(
    String id,
  ) async {
    final db = await database;

    await db.delete(
      'beds',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // TENANT METHODS
  // ============================================================

  // ------------------------------------------------------------
  // INSERT TENANT + OCCUPY BED
  // ------------------------------------------------------------

  Future<void> insertTenant(
    TenantModel tenant,
  ) async {
    final db = await database;

    await db.transaction(
      (txn) async {
        // ----------------------------------------------
        // VERIFY BED EXISTS
        // ----------------------------------------------

        final bedResult =
            await txn.query(
          'beds',
          columns: [
            'id',
            'status',
          ],
          where: 'id = ?',
          whereArgs: [tenant.bedId],
          limit: 1,
        );

        if (bedResult.isEmpty) {
          throw Exception(
            'Selected bed does not exist.',
          );
        }

        final bedStatus =
            bedResult.first['status']
                as String;

        // ----------------------------------------------
        // BED MUST BE AVAILABLE
        // ----------------------------------------------

        if (bedStatus != 'available') {
          throw Exception(
            'Selected bed is already occupied.',
          );
        }

        // ----------------------------------------------
        // INSERT TENANT
        // ----------------------------------------------

        await txn.insert(
          'tenants',
          {
            'id': tenant.id,
            'bed_id': tenant.bedId,
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
          },
        );

        // ----------------------------------------------
        // MARK BED OCCUPIED
        // ----------------------------------------------

        final updated =
            await txn.update(
          'beds',
          {
            'status': 'occupied',
          },
          where:
              'id = ? AND status = ?',
          whereArgs: [
            tenant.bedId,
            'available',
          ],
        );

        if (updated != 1) {
          throw Exception(
            'Unable to occupy selected bed.',
          );
        }
      },
    );
  }

  // ============================================================
  // GET ALL TENANTS
  // ============================================================

  Future<List<TenantModel>>
      getTenants() async {
    final db = await database;

    final result = await db.query(
      'tenants',
      orderBy:
          'created_at DESC',
    );

    return result.map((row) {
      return _tenantFromRow(row);
    }).toList();
  }

  // ============================================================
  // GET ACTIVE TENANTS
  // ============================================================

  Future<List<TenantModel>>
      getActiveTenants() async {
    final db = await database;

    final result = await db.query(
      'tenants',
      where: 'status = ?',
      whereArgs: ['active'],
      orderBy:
          'created_at DESC',
    );

    return result.map((row) {
      return _tenantFromRow(row);
    }).toList();
  }

  // ============================================================
  // GET VACATED TENANTS
  // ============================================================

  Future<List<TenantModel>>
      getVacatedTenants() async {
    final db = await database;

    final result = await db.query(
      'tenants',
      where: 'status = ?',
      whereArgs: ['vacated'],
      orderBy:
          'created_at DESC',
    );

    return result.map((row) {
      return _tenantFromRow(row);
    }).toList();
  }

  // ============================================================
  // GET TENANT BY ID
  // ============================================================

  Future<TenantModel?>
      getTenantById(
    String id,
  ) async {
    final db = await database;

    final result = await db.query(
      'tenants',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return _tenantFromRow(
      result.first,
    );
  }

  // ============================================================
  // GET ACTIVE TENANT BY BED
  // ============================================================

  Future<TenantModel?>
      getActiveTenantByBed(
    String bedId,
  ) async {
    final db = await database;

    final result = await db.query(
      'tenants',
      where:
          'bed_id = ? AND status = ?',
      whereArgs: [
        bedId,
        'active',
      ],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return _tenantFromRow(
      result.first,
    );
  }

  // ============================================================
  // VACATE TENANT
  // ============================================================

  Future<void> vacateTenant(
    String tenantId,
  ) async {
    final db = await database;

    await db.transaction(
      (txn) async {
        final result =
            await txn.query(
          'tenants',
          columns: [
            'id',
            'bed_id',
            'status',
          ],
          where: 'id = ?',
          whereArgs: [tenantId],
          limit: 1,
        );

        if (result.isEmpty) {
          throw Exception(
            'Tenant not found.',
          );
        }

        final tenant =
            result.first;

        final status =
            tenant['status'] as String;

        final bedId =
            tenant['bed_id'] as String;

        if (status != 'active') {
          return;
        }

        await txn.update(
          'tenants',
          {
            'status': 'vacated',
          },
          where: 'id = ?',
          whereArgs: [tenantId],
        );

        await txn.update(
          'beds',
          {
            'status': 'available',
          },
          where: 'id = ?',
          whereArgs: [bedId],
        );
      },
    );
  }

  // ============================================================
  // DELETE TENANT
  // ============================================================

  Future<void> deleteTenant(
    String tenantId,
  ) async {
    final db = await database;

    await db.transaction(
      (txn) async {
        final result =
            await txn.query(
          'tenants',
          columns: [
            'id',
            'bed_id',
            'status',
          ],
          where: 'id = ?',
          whereArgs: [tenantId],
          limit: 1,
        );

        if (result.isEmpty) {
          return;
        }

        final tenant =
            result.first;

        final bedId =
            tenant['bed_id'] as String;

        final status =
            tenant['status'] as String;

        await txn.delete(
          'tenants',
          where: 'id = ?',
          whereArgs: [tenantId],
        );

        if (status == 'active') {
          await txn.update(
            'beds',
            {
              'status': 'available',
            },
            where: 'id = ?',
            whereArgs: [bedId],
          );
        }
      },
    );
  }

  // ============================================================
  // SEARCH TENANTS
  // ============================================================

  Future<List<TenantModel>>
      searchTenants(
    String query,
  ) async {
    final db = await database;

    final value =
        query.trim();

    if (value.isEmpty) {
      return getTenants();
    }

    final result =
        await db.query(
      'tenants',
      where: '''
        full_name LIKE ?
        OR phone LIKE ?
        OR alternate_phone LIKE ?
        OR email LIKE ?
        OR id_proof_number LIKE ?
      ''',
      whereArgs: [
        '%$value%',
        '%$value%',
        '%$value%',
        '%$value%',
        '%$value%',
      ],
      orderBy:
          'created_at DESC',
    );

    return result.map((row) {
      return _tenantFromRow(row);
    }).toList();
  }

  // ============================================================
  // TENANT COUNT
  // ============================================================

  Future<int>
      getActiveTenantCount() async {
    final db = await database;

    final result =
        await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM tenants
      WHERE status = ?
      ''',
      ['active'],
    );

    return Sqflite.firstIntValue(
          result,
        ) ??
        0;
  }

  // ============================================================
  // TENANT MODEL FROM DATABASE ROW
  // ============================================================

  TenantModel _tenantFromRow(
    Map<String, Object?> row,
  ) {
    return TenantModel(
      id: row['id'] as String,

      bedId:
          row['bed_id'] as String,

      fullName:
          row['full_name'] as String,

      phone:
          row['phone'] as String,

      alternatePhone:
          row['alternate_phone']
              as String?,

      email:
          row['email'] as String?,

      idProofType:
          row['id_proof_type']
              as String?,

      idProofNumber:
          row['id_proof_number']
              as String?,

      joiningDate:
          DateTime.parse(
        row['joining_date']
            as String,
      ),

      monthlyRent:
          (row['monthly_rent']
                  as num)
              .toDouble(),

      securityDeposit:
          (row['security_deposit']
                  as num)
              .toDouble(),

      status:
          row['status'] as String,

      createdAt:
          DateTime.parse(
        row['created_at']
            as String,
      ),
    );
  }

  // ============================================================
  // COUNT HELPERS
  // ============================================================

  Future<int>
      getTotalRoomCount() async {
    final db = await database;

    final result =
        await db.rawQuery(
      'SELECT COUNT(*) AS count FROM rooms',
    );

    return Sqflite.firstIntValue(
          result,
        ) ??
        0;
  }

  Future<int>
      getTotalBedCount() async {
    final db = await database;

    final result =
        await db.rawQuery(
      'SELECT COUNT(*) AS count FROM beds',
    );

    return Sqflite.firstIntValue(
          result,
        ) ??
        0;
  }

  Future<int>
      getOccupiedBedCount() async {
    final db = await database;

    final result =
        await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM beds
      WHERE status = ?
      ''',
      ['occupied'],
    );

    return Sqflite.firstIntValue(
          result,
        ) ??
        0;
  }

  Future<int>
      getAvailableBedCount() async {
    final db = await database;

    final result =
        await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM beds
      WHERE status = ?
      ''',
      ['available'],
    );

    return Sqflite.firstIntValue(
          result,
        ) ??
        0;
  }

  // ============================================================
  // TRANSACTION CONVERSION HELPERS
  // ============================================================

  TransactionType
      _transactionTypeFromString(
    String value,
  ) {
    switch (value) {
      case 'income':
        return TransactionType.income;

      case 'expense':
        return TransactionType.expense;

      default:
        return TransactionType.income;
    }
  }

  PaymentMethod
      _paymentMethodFromString(
    String value,
  ) {
    switch (value) {
      case 'cash':
        return PaymentMethod.cash;

      case 'upi':
        return PaymentMethod.upi;

      case 'bank':
        return PaymentMethod.bank;

      default:
        return PaymentMethod.cash;
    }
  }

  ExpenseCategory?
      _expenseCategoryFromString(
    String? value,
  ) {
    if (value == null ||
        value.isEmpty) {
      return null;
    }

    for (final category
        in ExpenseCategory.values) {
      if (category.name == value) {
        return category;
      }
    }

    return null;
  }
}