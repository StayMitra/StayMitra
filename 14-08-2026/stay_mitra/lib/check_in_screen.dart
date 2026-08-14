import 'package:flutter/material.dart';

import 'database_helper.dart';
import 'add_tenant_screen.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  bool _loading = true;
  bool _saving = false;

  List<Map<String, dynamic>> _tenants = [];
  List<Map<String, dynamic>> _recentCheckIns = [];

  // Keep only the tenant ID in the dropdown value.
  // This avoids the DropdownButton Map equality/duplicate-value issue.
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
  // INITIALIZE
  // ============================================================

  Future<void> _initializeCheckIns() async {
    try {
      final db = await DatabaseHelper.instance.database;

      await db.execute('''
        CREATE TABLE IF NOT EXISTS check_ins (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          tenant_id TEXT NOT NULL,
          tenant_name TEXT NOT NULL,
          check_in_date TEXT NOT NULL,
          status TEXT NOT NULL,
          note TEXT,
          created_at TEXT NOT NULL
        )
      ''');

      await Future.wait([
        _loadTenants(),
        _loadRecentCheckIns(),
      ]);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showMessage(
        'Unable to load check-in information.',
        isError: true,
      );
    }
  }

  // ============================================================
  // LOAD ACTIVE TENANTS
  // ============================================================

  Future<void> _loadTenants() async {
    try {
      final db = await DatabaseHelper.instance.database;

      final rows = await db.query(
        'tenants',
        columns: [
          'id',
          'full_name',
          'phone',
          'monthly_rent',
          'bed_id',
          'joining_date',
        ],
        where: 'status = ?',
        whereArgs: ['active'],
        orderBy: 'full_name ASC',
      );

      if (!mounted) return;

      setState(() {
        _tenants = rows;
        _loading = false;

        // Clear a stale selected tenant if the list changed.
        if (_selectedTenantId != null &&
            !_tenants.any(
              (tenant) =>
                  tenant['id'].toString() == _selectedTenantId,
            )) {
          _selectedTenantId = null;
        }
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showMessage(
        'Unable to load active tenants.',
        isError: true,
      );
    }
  }

  // ============================================================
  // LOAD RECENT CHECK-INS
  // ============================================================

  Future<void> _loadRecentCheckIns() async {
    try {
      final db = await DatabaseHelper.instance.database;

      final rows = await db.query(
        'check_ins',
        orderBy: 'check_in_date DESC, id DESC',
        limit: 30,
      );

      if (!mounted) return;

      setState(() {
        _recentCheckIns = rows;
      });
    } catch (_) {
      // The table is created before this method is called.
      // Keep the screen usable even if recent history cannot load.
    }
  }

  // ============================================================
  // SELECTED TENANT
  // ============================================================

  Map<String, dynamic>? get _selectedTenant {
    final id = _selectedTenantId;

    if (id == null) return null;

    for (final tenant in _tenants) {
      if (tenant['id'].toString() == id) {
        return tenant;
      }
    }

    return null;
  }

  // ============================================================
  // PICK DATE
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
  // SAVE CHECK-IN
  // ============================================================

  Future<void> _saveCheckIn() async {
    final tenant = _selectedTenant;

    if (tenant == null) {
      _showMessage(
        'Please select a tenant.',
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

    setState(() {
      _saving = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;

      // Re-create safely in case the database was upgraded from an older build.
      await db.execute('''
        CREATE TABLE IF NOT EXISTS check_ins (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          tenant_id TEXT NOT NULL,
          tenant_name TEXT NOT NULL,
          check_in_date TEXT NOT NULL,
          status TEXT NOT NULL,
          note TEXT,
          created_at TEXT NOT NULL
        )
      ''');

      await db.insert(
        'check_ins',
        {
          'tenant_id': tenant['id'].toString(),
          'tenant_name': tenant['full_name']?.toString() ?? 'Tenant',
          'check_in_date': _checkInDate.toIso8601String(),
          'status': 'Checked In',
          'note': _noteController.text.trim(),
          'created_at': DateTime.now().toIso8601String(),
        },
      );

      await _loadRecentCheckIns();

      if (!mounted) return;

      _noteController.clear();

      setState(() {
        _selectedTenantId = null;
        _status = 'Checked In';
      });

      _showMessage('Check-in saved successfully.');
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to save check-in.',
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
  // OPEN ADD TENANT
  // ============================================================

  Future<void> _openAddTenant() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddTenantScreen(),
      ),
    );

    if (result == true) {
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
          backgroundColor:
              isError ? const Color(0xFFDC2626) : null,
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
  // HEADER CARD
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Record Tenant Check-in',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Record the arrival of an active tenant and keep a check-in history.',
                  style: TextStyle(
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
  // FORM CARD
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
            'Tenant',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          if (_tenants.isEmpty)
            _noTenantBox()
          else
            DropdownButtonFormField<String>(
              value: _selectedTenantId,
              isExpanded: true,
              decoration: InputDecoration(
                hintText: 'Select active tenant',
                prefixIcon: const Icon(
                  Icons.person_outline_rounded,
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
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFF2563EB),
                    width: 1.4,
                  ),
                ),
              ),
              items: _tenants.map((tenant) {
                final id = tenant['id'].toString();
                final name =
                    tenant['full_name']?.toString() ?? 'Tenant';
                final phone = tenant['phone']?.toString() ?? '';

                return DropdownMenuItem<String>(
                  value: id,
                  child: Text(
                    phone.isEmpty ? name : '$name • $phone',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
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
            onTap: _pickCheckInDate,
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
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.verified_rounded,
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
            onChanged: (value) {
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
                  onPressed: _openAddTenant,
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
                  onPressed: _saving ? null : _saveCheckIn,
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
        ],
      ),
    );
  }

  // ============================================================
  // NO TENANT
  // ============================================================

  Widget _noTenantBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFDE68A),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFD97706),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'No active tenants found. Add a tenant first.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF92400E),
              ),
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
  // RECENT CHECK-INS
  // ============================================================

  Widget _recentCheckInsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Check-ins',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        if (_recentCheckIns.isEmpty)
          _emptyHistory()
        else
          Column(
            children: _recentCheckIns
                .map(_checkInCard)
                .toList(),
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
            'No check-ins recorded yet',
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
    final date = DateTime.tryParse(
          record['check_in_date']?.toString() ?? '',
        ) ??
        DateTime.now();
    final note = record['note']?.toString() ?? '';

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
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.login_rounded,
              color: Color(0xFF16A34A),
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
                  _formatDate(date),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    note,
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
          _statusChip(),
        ],
      ),
    );
  }

  Widget _statusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(9),
      ),
      child: const Text(
        'Checked In',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Color(0xFF16A34A),
        ),
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
  // REFRESH
  // ============================================================

  Future<void> _refresh() async {
    await _loadTenants();
    await _loadRecentCheckIns();
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }
}
