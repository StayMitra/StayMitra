import 'package:flutter/material.dart';

import 'database_helper.dart';
import 'building_model.dart';
import 'add_tenant_screen.dart';
import 'pg_manager_service.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  static const String ownerId = 'default_owner';

  bool _loading = true;
  bool _saving = false;
  bool _checkingOut = false;
  bool _switchingPg = false;

  List<Map<String, dynamic>> _buildings = [];
  List<Map<String, dynamic>> _tenants = [];
  List<Map<String, dynamic>> _recentCheckIns = [];

  String? _selectedBuildingId;
  String? _selectedTenantId;

  DateTime _checkInDate = DateTime.now();
  String _status = 'Checked In';

  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    _initializeCheckIns();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // ============================================================
  // SELECTED PG
  // ============================================================

  Map<String, dynamic>? get _selectedBuilding {
    final id = _selectedBuildingId;
    if (id == null) return null;

    for (final building in _buildings) {
      if (building['id']?.toString() == id) {
        return building;
      }
    }

    return null;
  }

  String get _selectedBuildingName {
    return _selectedBuilding?['name']?.toString() ?? 'No PG selected';
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> _initializeCheckIns() async {
    try {
      final db = await DatabaseHelper.instance.database;

      await _ensureCheckInsTable(db);
      await _loadBuildings();
      await _loadTenants();
      await _loadRecentCheckIns();

      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showMessage(
        'Unable to load check-in information. $e',
        isError: true,
      );
    }
  }

  // ============================================================
  // CHECK-IN TABLE
  // ============================================================

  Future<void> _ensureCheckInsTable(dynamic db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS check_ins (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tenant_id TEXT NOT NULL,
        tenant_name TEXT NOT NULL,
        building_id TEXT,
        check_in_date TEXT NOT NULL,
        status TEXT NOT NULL,
        note TEXT,
        checkout_date TEXT,
        checkout_note TEXT,
        check_out_date TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await _addColumnIfNotExists(db, 'check_ins', 'building_id', 'TEXT');
    await _addColumnIfNotExists(db, 'check_ins', 'checkout_date', 'TEXT');
    await _addColumnIfNotExists(db, 'check_ins', 'checkout_note', 'TEXT');

    // Older versions used check_out_date. Keep old data and copy it to
    // the new checkout_date column instead of deleting anything.
    await _addColumnIfNotExists(db, 'check_ins', 'check_out_date', 'TEXT');

    try {
      await db.execute('''
        UPDATE check_ins
        SET checkout_date = check_out_date
        WHERE (checkout_date IS NULL OR checkout_date = '')
          AND check_out_date IS NOT NULL
          AND check_out_date != ''
      ''');
    } catch (_) {
      // Keep the app usable even if the legacy column is unavailable.
    }
  }

  Future<void> _addColumnIfNotExists(
    dynamic db,
    String table,
    String column,
    String definition,
  ) async {
    final result = await db.rawQuery('PRAGMA table_info($table)');

    final exists = result.any(
      (row) => row['name']?.toString() == column,
    );

    if (!exists) {
      await db.execute(
        'ALTER TABLE $table ADD COLUMN $column $definition',
      );
    }
  }

  // ============================================================
  // LOAD PGs
  // ============================================================

  Future<void> _loadBuildings() async {
    final db = await DatabaseHelper.instance.database;

    final rows = await db.query(
      'buildings',
      columns: [
        'id',
        'name',
        'address',
        'owner_id',
        'created_at',
      ],
      where: 'owner_id = ?',
      whereArgs: [ownerId],
      orderBy: 'name COLLATE NOCASE ASC',
    );

    if (!mounted) return;

    setState(() {
      _buildings = rows;
    });

    // First preference: the PG already selected in the app.
    final activePg = PgManagerService.activePg;

    if (activePg != null &&
        rows.any((row) => row['id']?.toString() == activePg.id.toString())) {
      _selectedBuildingId = activePg.id.toString();
      return;
    }

    // If no PG is active, automatically select the first PG.
    if (rows.isNotEmpty) {
      final firstId = rows.first['id']?.toString();

      if (firstId != null && firstId.isNotEmpty) {
        _selectedBuildingId = firstId;

        final firstPg = rows.first;

        try {
          await PgManagerService.selectPg(
            _buildingFromRow(firstPg),
            ownerId: ownerId,
          );
        } catch (_) {
          // The screen can still use the selected building ID.
        }
      }
    } else {
      _selectedBuildingId = null;
    }
  }

  BuildingModel _buildingFromRow(Map<String, dynamic> row) {
    return BuildingModel(
      id: row['id']?.toString() ?? '',
      name: row['name']?.toString() ?? 'PG',
      address: row['address']?.toString(),
      ownerId: row['owner_id']?.toString() ?? ownerId,
      createdAt: DateTime.tryParse(
            row['created_at']?.toString() ?? '',
          ) ??
          DateTime.now(),
    );
  }

  // ============================================================
  // LOAD ACTIVE TENANTS - SELECTED PG ONLY
  // ============================================================

  Future<void> _loadTenants() async {
    try {
      final buildingId = _selectedBuildingId;

      if (buildingId == null || buildingId.isEmpty) {
        if (!mounted) return;

        setState(() {
          _tenants = [];
          _selectedTenantId = null;
        });
        return;
      }

      final db = await DatabaseHelper.instance.database;

      // IMPORTANT:
      // Tenant does not store building_id directly.
      // The correct PG is resolved through:
      // Tenant -> Bed -> Room -> Floor -> Building.
      final rows = await db.rawQuery(
        '''
        SELECT
          t.id AS id,
          t.full_name AS full_name,
          t.phone AS phone,
          t.monthly_rent AS monthly_rent,
          t.bed_id AS bed_id,
          t.joining_date AS joining_date,
          t.status AS status,
          b.bed_number AS bed_number,
          r.room_number AS room_number,
          f.name AS floor_name,
          bl.id AS building_id,
          bl.name AS building_name
        FROM tenants t
        INNER JOIN beds b
          ON b.id = t.bed_id
        INNER JOIN rooms r
          ON r.id = b.room_id
        INNER JOIN floors f
          ON f.id = r.floor_id
        INNER JOIN buildings bl
          ON bl.id = f.building_id
        WHERE t.status = ?
          AND f.building_id = ?
        ORDER BY t.full_name COLLATE NOCASE ASC
        ''',
        ['active', buildingId],
      );

      if (!mounted) return;

      setState(() {
        _tenants = rows;

        if (_selectedTenantId != null &&
            !_tenants.any(
              (tenant) => tenant['id']?.toString() == _selectedTenantId,
            )) {
          _selectedTenantId = null;
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _tenants = [];
        _selectedTenantId = null;
      });

      _showMessage(
        'Unable to load active tenants. $e',
        isError: true,
      );
    }
  }

  // ============================================================
  // SELECT TENANT
  // ============================================================

  Map<String, dynamic>? get _selectedTenant {
    final id = _selectedTenantId;
    if (id == null) return null;

    for (final tenant in _tenants) {
      if (tenant['id']?.toString() == id) {
        return tenant;
      }
    }

    return null;
  }

  // ============================================================
  // SWITCH PG
  // ============================================================

  Future<void> _selectBuilding(String? value) async {
    if (value == null || value.isEmpty || _switchingPg) return;

    if (!_buildings.any((building) => building['id']?.toString() == value)) {
      return;
    }

    setState(() {
      _switchingPg = true;
      _selectedBuildingId = value;
      _selectedTenantId = null;
      _tenants = [];
      _recentCheckIns = [];
    });

    try {
      final row = _buildings.firstWhere(
        (building) => building['id']?.toString() == value,
      );

      await PgManagerService.selectPg(
        _buildingFromRow(row),
        ownerId: ownerId,
      );

      await _loadTenants();
      await _loadRecentCheckIns();
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to switch PG. $e',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _switchingPg = false;
        });
      }
    }
  }

  // ============================================================
  // DATE
  // ============================================================

  Future<void> _pickCheckInDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkInDate,
      firstDate: DateTime.now().subtract(
        const Duration(days: 3650),
      ),
      lastDate: DateTime.now().add(
        const Duration(days: 3650),
      ),
    );

    if (picked == null || !mounted) return;

    setState(() {
      _checkInDate = picked;
    });
  }

  // ============================================================
  // OPEN CHECK-IN
  // ============================================================

  Future<bool> _hasOpenCheckIn(String tenantId) async {
    final buildingId = _selectedBuildingId;
    if (buildingId == null || buildingId.isEmpty) return false;

    final db = await DatabaseHelper.instance.database;

    final rows = await db.rawQuery(
      '''
      SELECT ci.id
      FROM check_ins ci
      WHERE ci.tenant_id = ?
        AND ci.building_id = ?
        AND ci.status = 'Checked In'
        AND (
          ci.checkout_date IS NULL
          OR ci.checkout_date = ''
        )
      ORDER BY ci.id DESC
      LIMIT 1
      ''',
      [tenantId, buildingId],
    );

    return rows.isNotEmpty;
  }

  // ============================================================
  // SAVE CHECK-IN
  // ============================================================

  Future<void> _saveCheckIn() async {
    final tenant = _selectedTenant;
    final buildingId = _selectedBuildingId;

    if (buildingId == null || buildingId.isEmpty) {
      _showMessage(
        'Please select a PG first.',
        isError: true,
      );
      return;
    }

    if (tenant == null) {
      _showMessage(
        'Please select a tenant.',
        isError: true,
      );
      return;
    }

    // Final safety check. A tenant from another PG can never be saved.
    if (tenant['building_id']?.toString() != buildingId) {
      _showMessage(
        'Selected tenant does not belong to $_selectedBuildingName.',
        isError: true,
      );
      return;
    }

    if (_status == 'Cancelled') {
      _showMessage(
        'Cancelled check-ins are not saved as a check-in record.',
        isError: true,
      );
      return;
    }

    if (_saving || _checkingOut) return;

    setState(() {
      _saving = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;
      await _ensureCheckInsTable(db);

      final tenantId = tenant['id']?.toString() ?? '';

      if (tenantId.isEmpty) {
        throw Exception('Invalid tenant ID.');
      }

      final alreadyCheckedIn = await _hasOpenCheckIn(tenantId);

      if (alreadyCheckedIn) {
        if (!mounted) return;

        _showMessage(
          '${tenant['full_name'] ?? 'This tenant'} is already checked in. '
          'Please check out first.',
          isError: true,
        );
        return;
      }

      await db.insert(
        'check_ins',
        {
          'tenant_id': tenantId,
          'tenant_name': tenant['full_name']?.toString() ?? 'Tenant',
          'building_id': buildingId,
          'check_in_date': _checkInDate.toIso8601String(),
          'status': 'Checked In',
          'note': _noteController.text.trim(),
          'checkout_date': null,
          'checkout_note': null,
          'created_at': DateTime.now().toIso8601String(),
        },
      );

      await _loadRecentCheckIns();

      if (!mounted) return;

      _noteController.clear();

      setState(() {
        _selectedTenantId = null;
        _status = 'Checked In';
        _checkInDate = DateTime.now();
      });

      _showMessage(
        '${tenant['full_name'] ?? 'Tenant'} checked in successfully in $_selectedBuildingName.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to save check-in. $e',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // ============================================================
  // CHECK-OUT
  // ============================================================

  Future<void> _checkoutRecord(
    Map<String, dynamic> record,
  ) async {
    if (_checkingOut || _saving) return;

    final tenantId = record['tenant_id']?.toString();
    final checkInId = record['id'];
    final tenantName = record['tenant_name']?.toString() ?? 'Tenant';
    final recordBuildingId = record['building_id']?.toString() ?? '';

    if (tenantId == null || tenantId.isEmpty || checkInId == null) {
      _showMessage(
        'Invalid check-in record.',
        isError: true,
      );
      return;
    }

    if (_selectedBuildingId == null ||
        recordBuildingId != _selectedBuildingId) {
      _showMessage(
        'This check-in does not belong to the selected PG.',
        isError: true,
      );
      return;
    }

    final noteController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Check-out'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to check out $tenantName?',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Checkout note',
                  hintText: 'Optional',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Check-out'),
            ),
          ],
        );
      },
    );

    final checkoutNote = noteController.text.trim();
    noteController.dispose();

    if (confirmed != true || !mounted) return;

    setState(() {
      _checkingOut = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;
      await _ensureCheckInsTable(db);

      final checkoutDate = DateTime.now().toIso8601String();

      final updated = await db.update(
        'check_ins',
        {
          'status': 'Checked Out',
          'checkout_date': checkoutDate,
          'checkout_note': checkoutNote,
          'check_out_date': checkoutDate,
        },
        where: 'id = ? AND building_id = ? AND status = ?',
        whereArgs: [
          checkInId,
          _selectedBuildingId,
          'Checked In',
        ],
      );

      if (updated != 1) {
        throw Exception(
          'Check-in record is already checked out or does not exist.',
        );
      }

      await _loadRecentCheckIns();

      if (!mounted) return;

      _showMessage(
        '$tenantName checked out successfully. History has been retained.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to check out $tenantName. $e',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _checkingOut = false;
        });
      }
    }
  }

  // ============================================================
  // LOAD HISTORY - SELECTED PG ONLY
  // ============================================================

  Future<void> _loadRecentCheckIns() async {
    try {
      final buildingId = _selectedBuildingId;

      if (buildingId == null || buildingId.isEmpty) {
        if (!mounted) return;

        setState(() {
          _recentCheckIns = [];
        });
        return;
      }

      final db = await DatabaseHelper.instance.database;
      await _ensureCheckInsTable(db);

      // The PG is filtered using the building_id saved at check-in time.
      // This is important because a tenant may later be moved/vacated.
      // Therefore old history cannot accidentally move to another PG.
      final rows = await db.rawQuery(
        '''
        SELECT
          ci.id AS id,
          ci.tenant_id AS tenant_id,
          ci.tenant_name AS tenant_name,
          ci.building_id AS building_id,
          ci.check_in_date AS check_in_date,
          ci.status AS status,
          ci.note AS note,
          ci.checkout_date AS checkout_date,
          ci.checkout_note AS checkout_note,
          ci.created_at AS created_at,
          bl.name AS building_name,
          b.bed_number AS bed_number,
          r.room_number AS room_number,
          f.name AS floor_name
        FROM check_ins ci
        LEFT JOIN buildings bl
          ON bl.id = ci.building_id
        LEFT JOIN tenants t
          ON t.id = ci.tenant_id
        LEFT JOIN beds b
          ON b.id = t.bed_id
        LEFT JOIN rooms r
          ON r.id = b.room_id
        LEFT JOIN floors f
          ON f.id = r.floor_id
        WHERE ci.building_id = ?
           OR (ci.building_id IS NULL AND f.building_id = ?)
        ORDER BY ci.check_in_date DESC, ci.id DESC
        LIMIT 100
        ''',
        [buildingId, buildingId],
      );

      if (!mounted) return;

      setState(() {
        _recentCheckIns = rows;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _recentCheckIns = [];
      });

      _showMessage(
        'Unable to load check-in history. $e',
        isError: true,
      );
    }
  }

  // ============================================================
  // ADD TENANT
  // ============================================================

  Future<void> _openAddTenant() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddTenantScreen(),
      ),
    );

    if (result == true) {
      await _loadBuildings();
      await _loadTenants();
      await _loadRecentCheckIns();
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError
              ? const Color(0xFFDC2626)
              : null,
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        title: const Text(
          'Check-in',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : RefreshIndicator(
                onRefresh: _refresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    18,
                    16,
                    30,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 760,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _headerCard(),
                          const SizedBox(height: 18),
                          _checkInFormCard(),
                          const SizedBox(height: 24),
                          _recentCheckInsSection(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _headerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFDBEAFE),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.login_rounded,
              color: Color(0xFF2563EB),
              size: 29,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Record Tenant Check-in',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_selectedBuildingName • Only tenants from this PG are shown. '
                  'Check-in, check-out and history stay within this PG.',
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FORM
  // ============================================================

  Widget _checkInFormCard() {
    return _sectionCard(
      title: 'Check-in Details',
      icon: Icons.fact_check_rounded,
      iconColor: const Color(0xFF2563EB),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PG / Building',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          if (_buildings.isEmpty)
            _noPgBox()
          else
            DropdownButtonFormField<String>(
              value: _selectedBuildingId,
              isExpanded: true,
              decoration: _inputDecoration(
                hintText: 'Select PG',
                icon: Icons.apartment_rounded,
              ),
              items: _buildings.map((building) {
                final id = building['id']?.toString() ?? '';
                final name = building['name']?.toString() ?? 'PG';

                return DropdownMenuItem<String>(
                  value: id,
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: _switchingPg ? null : _selectBuilding,
            ),

          if (_selectedBuilding != null) ...[
            const SizedBox(height: 12),
            _buildingSummary(_selectedBuilding!),
          ],

          const SizedBox(height: 18),

          const Text(
            'Tenant',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          if (_selectedBuildingId == null)
            _selectPgFirstBox()
          else if (_tenants.isEmpty)
            _noTenantBox()
          else
            DropdownButtonFormField<String>(
              value: _tenants.any(
                (tenant) => tenant['id']?.toString() == _selectedTenantId,
              )
                  ? _selectedTenantId
                  : null,
              isExpanded: true,
              decoration: _inputDecoration(
                hintText: 'Select tenant from $_selectedBuildingName',
                icon: Icons.person_outline_rounded,
              ),
              items: _tenants.map((tenant) {
                final id = tenant['id']?.toString() ?? '';
                final name = tenant['full_name']?.toString() ?? 'Tenant';
                final phone = tenant['phone']?.toString() ?? '';
                final room = tenant['room_number']?.toString() ?? '';
                final bed = tenant['bed_number']?.toString() ?? '';

                final details = <String>[
                  if (phone.isNotEmpty) phone,
                  if (room.isNotEmpty) 'Room $room',
                  if (bed.isNotEmpty) 'Bed $bed',
                ].join(' • ');

                return DropdownMenuItem<String>(
                  value: id,
                  child: Text(
                    details.isEmpty ? name : '$name • $details',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (_saving || _checkingOut)
                  ? null
                  : (value) {
                      setState(() {
                        _selectedTenantId = value;
                      });
                    },
            ),

          if (_selectedTenant != null) ...[
            const SizedBox(height: 12),
            _tenantSummary(_selectedTenant!),
          ],

          const SizedBox(height: 18),

          const Text(
            'Check-in Date',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: (_saving || _checkingOut) ? null : _pickCheckInDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 15,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    color: Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _formatDate(_checkInDate),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'Status',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _status,
            decoration: _inputDecoration(
              hintText: 'Status',
              icon: Icons.verified_rounded,
            ),
            items: const [
              DropdownMenuItem(
                value: 'Checked In',
                child: Text('Checked In'),
              ),
              DropdownMenuItem(
                value: 'Cancelled',
                child: Text('Cancelled'),
              ),
            ],
            onChanged: (_saving || _checkingOut)
                ? null
                : (value) {
                    if (value == null) return;
                    setState(() {
                      _status = value;
                    });
                  },
          ),

          const SizedBox(height: 18),

          const Text(
            'Notes',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            maxLines: 3,
            enabled: !_saving && !_checkingOut,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Optional check-in notes',
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 42),
                child: Icon(Icons.notes_rounded),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFFE5E7EB),
                ),
              ),
            ),
          ),

          const SizedBox(height: 22),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saving || _checkingOut
                      ? null
                      : _openAddTenant,
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Add Tenant'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _saving || _checkingOut
                      ? null
                      : _saveCheckIn,
                  icon: _saving
                      ? const SizedBox(
                          width: 19,
                          height: 19,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.login_rounded),
                  label: Text(
                    _saving ? 'Saving...' : 'Confirm Check-in',
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (_switchingPg) ...[
            const SizedBox(height: 12),
            const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Loading PG data...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // BUILDING SUMMARY
  // ============================================================

  Widget _buildingSummary(Map<String, dynamic> building) {
    final name = building['name']?.toString() ?? 'PG';
    final address = building['address']?.toString() ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.apartment_rounded,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TENANT SUMMARY
  // ============================================================

  Widget _tenantSummary(Map<String, dynamic> tenant) {
    final rent = tenant['monthly_rent'];
    final phone = tenant['phone']?.toString() ?? '';
    final room = tenant['room_number']?.toString() ?? '';
    final bed = tenant['bed_number']?.toString() ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tenant['full_name']?.toString() ?? 'Tenant',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    phone,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
                if (room.isNotEmpty || bed.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    [
                      if (room.isNotEmpty) 'Room $room',
                      if (bed.isNotEmpty) 'Bed $bed',
                    ].join(' • '),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (rent is num)
            Text(
              '₹${rent.toStringAsFixed(0)}/month',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF16A34A),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // HISTORY
  // ============================================================

  Widget _recentCheckInsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Check-in / Check-out History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            if (_selectedBuilding != null)
              Container(
                constraints: const BoxConstraints(maxWidth: 140),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _selectedBuildingName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_recentCheckIns.isEmpty)
          _emptyHistory()
        else
          Column(
            children: _recentCheckIns.map(_checkInCard).toList(),
          ),
      ],
    );
  }

  Widget _emptyHistory() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.history_rounded,
            size: 40,
            color: Color(0xFF94A3B8),
          ),
          SizedBox(height: 10),
          Text(
            'No check-in / check-out records found for this PG',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkInCard(Map<String, dynamic> record) {
    final name = record['tenant_name']?.toString() ?? 'Tenant';
    final status = record['status']?.toString() ?? 'Checked In';

    final checkInDate = DateTime.tryParse(
          record['check_in_date']?.toString() ?? '',
        ) ??
        DateTime.now();

    final checkoutDate = DateTime.tryParse(
      record['checkout_date']?.toString() ?? '',
    );

    final note = record['note']?.toString() ?? '';
    final checkoutNote = record['checkout_note']?.toString() ?? '';
    final room = record['room_number']?.toString() ?? '';
    final bed = record['bed_number']?.toString() ?? '';

    final isCheckedIn = status == 'Checked In' && checkoutDate == null;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isCheckedIn
                      ? const Color(0xFFF0FDF4)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  isCheckedIn
                      ? Icons.login_rounded
                      : Icons.logout_rounded,
                  color: isCheckedIn
                      ? const Color(0xFF16A34A)
                      : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Check-in: ${_formatDateTime(checkInDate)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    if (room.isNotEmpty || bed.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        [
                          if (room.isNotEmpty) 'Room $room',
                          if (bed.isNotEmpty) 'Bed $bed',
                        ].join(' • '),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                    if (note.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Note: $note',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                    if (checkoutDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Check-out: ${_formatDateTime(checkoutDate)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                    if (checkoutNote.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        'Checkout note: $checkoutNote',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _statusChip(status),
            ],
          ),
          if (isCheckedIn) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _checkingOut || _saving
                    ? null
                    : () => _checkoutRecord(record),
                icon: _checkingOut
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.logout_rounded),
                label: Text(
                  _checkingOut
                      ? 'Checking out...'
                      : 'Check-out $name',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(
                    color: Color(0xFFFCA5A5),
                  ),
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final checkedIn = status == 'Checked In';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: checkedIn
            ? const Color(0xFFF0FDF4)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: checkedIn
              ? const Color(0xFF16A34A)
              : const Color(0xFF64748B),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATES
  // ============================================================

  Widget _noPgBox() {
    return _infoBox(
      icon: Icons.info_outline_rounded,
      color: const Color(0xFFD97706),
      background: const Color(0xFFFFFBEB),
      borderColor: const Color(0xFFFDE68A),
      text: 'No PG found. Add a PG first.',
    );
  }

  Widget _selectPgFirstBox() {
    return _infoBox(
      icon: Icons.arrow_upward_rounded,
      color: const Color(0xFF2563EB),
      background: const Color(0xFFEFF6FF),
      borderColor: const Color(0xFFBFDBFE),
      text: 'Please select the PG first. Only tenants from that PG will be shown.',
    );
  }

  Widget _noTenantBox() {
    return _infoBox(
      icon: Icons.info_outline_rounded,
      color: const Color(0xFFD97706),
      background: const Color(0xFFFFFBEB),
      borderColor: const Color(0xFFFDE68A),
      text: 'No active tenants found in this PG. Add a tenant first.',
    );
  }

  Widget _infoBox({
    required IconData icon,
    required Color color,
    required Color background,
    required Color borderColor,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: color == const Color(0xFF2563EB)
                    ? const Color(0xFF1D4ED8)
                    : const Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 11),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE5E7EB),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF2563EB),
          width: 1.4,
        ),
      ),
    );
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refresh() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      await _loadBuildings();
      await _loadTenants();
      await _loadRecentCheckIns();
    } catch (e) {
      if (mounted) {
        _showMessage(
          'Unable to refresh check-in data. $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    final dateText = _formatDate(date);

    final hour12 = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;

    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$dateText $hour12:$minute $period';
  }
}
