import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  // FIREBASE HELPERS
  // ============================================================

  String get _firebaseOwnerId {
    return FirebaseAuth.instance.currentUser?.uid ?? ownerId;
  }

  DocumentReference<Map<String, dynamic>> _propertyRef(String propertyId) {
    return FirebaseFirestore.instance
        .collection('owners')
        .doc(_firebaseOwnerId)
        .collection('properties')
        .doc(propertyId);
  }

  DateTime _firebaseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  String _dateString(dynamic value) {
    return _firebaseDate(value).toIso8601String();
  }

  BuildingModel _buildingFromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return BuildingModel(
      id: id,
      name: (data['name'] ?? 'PG').toString(),
      address: data['address']?.toString(),
      ownerId: (data['ownerId'] ?? data['owner_id'] ?? _firebaseOwnerId).toString(),
      createdAt: _firebaseDate(data['createdAt'] ?? data['created_at']),
    );
  }

  // ============================================================
  // LOAD PGs
  // ============================================================

  Future<void> _loadBuildings() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('owners')
        .doc(_firebaseOwnerId)
        .collection('properties')
        .get();

    final rows = snapshot.docs.map((doc) {
      final data = doc.data();
      return <String, dynamic>{
        'id': doc.id,
        'name': data['name'] ?? 'PG',
        'address': data['address'],
        'owner_id': data['ownerId'] ?? data['owner_id'] ?? _firebaseOwnerId,
        'created_at': _dateString(data['createdAt'] ?? data['created_at']),
      };
    }).toList();

    rows.sort((a, b) =>
        (a['name']?.toString() ?? '').toLowerCase().compareTo(
              (b['name']?.toString() ?? '').toLowerCase(),
            ));

    if (!mounted) return;

    setState(() {
      _buildings = rows;
    });

    final activePg = PgManagerService.activePg;

    if (activePg != null &&
        rows.any((row) => row['id']?.toString() == activePg.id.toString())) {
      _selectedBuildingId = activePg.id.toString();
      return;
    }

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
      ownerId: row['owner_id']?.toString() ?? _firebaseOwnerId,
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

      final propertyRef = _propertyRef(buildingId);
      final tenantSnapshot = await propertyRef.collection('tenants').get();

      final rows = <Map<String, dynamic>>[];

      for (final tenantDoc in tenantSnapshot.docs) {
        final tenant = tenantDoc.data();
        final status = (tenant['status'] ?? '').toString().trim().toLowerCase();

        if (status != 'active') continue;

        final bedId = (tenant['bed_id'] ?? tenant['bedId'] ?? '').toString();
        Map<String, dynamic> bed = {};
        Map<String, dynamic> room = {};
        Map<String, dynamic> floor = {};

        if (bedId.isNotEmpty) {
          final bedSnap = await propertyRef.collection('beds').doc(bedId).get();
          if (bedSnap.exists) {
            bed = bedSnap.data() ?? {};
          }
        }

        final roomId = (bed['room_id'] ?? bed['roomId'] ?? '').toString();
        if (roomId.isNotEmpty) {
          final roomSnap = await propertyRef.collection('rooms').doc(roomId).get();
          if (roomSnap.exists) {
            room = roomSnap.data() ?? {};
          }
        }

        final floorId = (room['floor_id'] ?? room['floorId'] ?? '').toString();
        if (floorId.isNotEmpty) {
          final floorSnap = await propertyRef.collection('floors').doc(floorId).get();
          if (floorSnap.exists) {
            floor = floorSnap.data() ?? {};
          }
        }

        rows.add({
          'id': tenantDoc.id,
          'full_name': tenant['full_name'] ?? tenant['fullName'] ?? 'Tenant',
          'phone': tenant['phone'] ?? '',
          'monthly_rent': tenant['monthly_rent'] ?? tenant['monthlyRent'] ?? 0,
          'bed_id': bedId,
          'joining_date': _dateString(tenant['joining_date'] ?? tenant['joiningDate']),
          'status': tenant['status'] ?? 'active',
          'bed_number': bed['bed_number'] ?? bed['bedNumber'] ?? '',
          'room_number': room['room_number'] ?? room['roomNumber'] ?? '',
          'floor_name': floor['name'] ?? '',
          'building_id': buildingId,
          'building_name': _selectedBuildingName,
        });
      }

      rows.sort((a, b) =>
          (a['full_name']?.toString() ?? '').toLowerCase().compareTo(
                (b['full_name']?.toString() ?? '').toLowerCase(),
              ));

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

    final snapshot = await _propertyRef(buildingId)
        .collection('check_ins')
        .where('tenant_id', isEqualTo: tenantId)
        .where('status', isEqualTo: 'Checked In')
        .get();

    return snapshot.docs.any((doc) {
      final data = doc.data();
      final checkoutDate = data['checkout_date'];
      return checkoutDate == null || checkoutDate.toString().trim().isEmpty;
    });
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

      final checkInId = 'checkin-${DateTime.now().microsecondsSinceEpoch}';

      await _propertyRef(buildingId).collection('check_ins').doc(checkInId).set({
        'id': checkInId,
        'tenant_id': tenantId,
        'tenant_name': tenant['full_name']?.toString() ?? 'Tenant',
        'building_id': buildingId,
        'check_in_date': _checkInDate.toIso8601String(),
        'status': 'Checked In',
        'note': _noteController.text.trim(),
        'checkout_date': null,
        'checkout_note': null,
        'check_out_date': null,
        'created_at': DateTime.now().toIso8601String(),
      });

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
      final buildingId = _selectedBuildingId;
      if (buildingId == null || buildingId.isEmpty) {
        throw Exception('Please select a PG first.');
      }

      final checkInRef = _propertyRef(buildingId)
          .collection('check_ins')
          .doc(checkInId.toString());
      final snapshot = await checkInRef.get();

      if (!snapshot.exists) {
        throw Exception(
          'Check-in record is already checked out or does not exist.',
        );
      }

      final current = snapshot.data() ?? <String, dynamic>{};
      if (current['status']?.toString() != 'Checked In') {
        throw Exception(
          'Check-in record is already checked out or does not exist.',
        );
      }

      final checkoutDate = DateTime.now().toIso8601String();

      await checkInRef.update({
        'status': 'Checked Out',
        'checkout_date': checkoutDate,
        'checkout_note': checkoutNote,
        'check_out_date': checkoutDate,
        'updated_at': checkoutDate,
      });

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

      final snapshot = await _propertyRef(buildingId)
          .collection('check_ins')
          .get();

      final rows = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final tenantId = (data['tenant_id'] ?? data['tenantId'] ?? '').toString();

        Map<String, dynamic> tenant = {};
        Map<String, dynamic> bed = {};
        Map<String, dynamic> room = {};

        if (tenantId.isNotEmpty) {
          final tenantSnap = await _propertyRef(buildingId)
              .collection('tenants')
              .doc(tenantId)
              .get();
          if (tenantSnap.exists) {
            tenant = tenantSnap.data() ?? {};
          }
        }

        final bedId = (tenant['bed_id'] ?? tenant['bedId'] ?? '').toString();
        if (bedId.isNotEmpty) {
          final bedSnap = await _propertyRef(buildingId)
              .collection('beds')
              .doc(bedId)
              .get();
          if (bedSnap.exists) {
            bed = bedSnap.data() ?? {};
          }
        }

        final roomId = (bed['room_id'] ?? bed['roomId'] ?? '').toString();
        if (roomId.isNotEmpty) {
          final roomSnap = await _propertyRef(buildingId)
              .collection('rooms')
              .doc(roomId)
              .get();
          if (roomSnap.exists) {
            room = roomSnap.data() ?? {};
          }
        }

        rows.add({
          'id': doc.id,
          'tenant_id': tenantId,
          'tenant_name': data['tenant_name'] ?? data['tenantName'] ?? tenant['full_name'] ?? tenant['fullName'] ?? 'Tenant',
          'building_id': data['building_id'] ?? data['buildingId'] ?? buildingId,
          'check_in_date': _dateString(data['check_in_date'] ?? data['checkInDate']),
          'status': data['status'] ?? 'Checked In',
          'note': data['note'] ?? '',
          'checkout_date': data['checkout_date'] ?? data['checkoutDate'],
          'checkout_note': data['checkout_note'] ?? data['checkoutNote'] ?? '',
          'created_at': _dateString(data['created_at'] ?? data['createdAt']),
          'building_name': _selectedBuildingName,
          'bed_number': bed['bed_number'] ?? bed['bedNumber'] ?? '',
          'room_number': room['room_number'] ?? room['roomNumber'] ?? '',
        });
      }

      rows.sort((a, b) {
        final ad = _firebaseDate(a['check_in_date']);
        final bd = _firebaseDate(b['check_in_date']);
        final byDate = bd.compareTo(ad);
        if (byDate != 0) return byDate;
        return (b['id']?.toString() ?? '').compareTo(a['id']?.toString() ?? '');
      });

      final limitedRows = rows.take(100).toList();

      if (!mounted) return;

      setState(() {
        _recentCheckIns = limitedRows;
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
