import 'package:flutter/material.dart';

import 'building_model.dart';
import 'database_helper.dart';
import 'tenant_model.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomEntry {
  final RoomModel room;
  final FloorModel floor;
  final List<_BedEntry> beds;

  _RoomEntry({
    required this.room,
    required this.floor,
    required this.beds,
  });

  int get totalBeds => beds.length;

  int get occupiedBeds =>
      beds.where((bed) => bed.bed.status == 'occupied').length;

  int get availableBeds =>
      beds.where((bed) => bed.bed.status == 'available').length;
}

class _BedEntry {
  final BedModel bed;
  final TenantModel? tenant;

  _BedEntry({
    required this.bed,
    required this.tenant,
  });
}

enum _RoomFilter {
  all,
  available,
  occupied,
}

class _RoomsScreenState extends State<RoomsScreen> {
  bool _loading = true;
  String? _error;

  List<_RoomEntry> _allRooms = [];
  _RoomFilter _filter = _RoomFilter.all;
  String _search = '';

  final Set<String> _expandedRooms = <String>{};

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final db = DatabaseHelper.instance;

      final buildings = await db.getBuildings();

      if (buildings.isEmpty) {
        if (!mounted) return;
        setState(() {
          _allRooms = [];
          _loading = false;
        });
        return;
      }

      final building = buildings.first;
      final floors = await db.getFloors(building.id);

      final entries = <_RoomEntry>[];

      for (final floor in floors) {
        final rooms = await db.getRooms(floor.id);

        for (final room in rooms) {
          final beds = await db.getBeds(room.id);
          final bedEntries = <_BedEntry>[];

          for (final bed in beds) {
            TenantModel? tenant;

            if (bed.status == 'occupied') {
              tenant = await db.getActiveTenantByBed(bed.id);
            }

            bedEntries.add(
              _BedEntry(
                bed: bed,
                tenant: tenant,
              ),
            );
          }

          entries.add(
            _RoomEntry(
              room: room,
              floor: floor,
              beds: bedEntries,
            ),
          );
        }
      }

      if (!mounted) return;

      setState(() {
        _allRooms = entries;
        _loading = false;

        final validIds = entries.map((e) => e.room.id).toSet();
        _expandedRooms.removeWhere(
          (id) => !validIds.contains(id),
        );
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  List<_RoomEntry> get _filteredRooms {
    final query = _search.trim().toLowerCase();

    return _allRooms.where((entry) {
      final matchesSearch = query.isEmpty ||
          entry.room.roomNumber.toLowerCase().contains(query) ||
          entry.floor.name.toLowerCase().contains(query) ||
          entry.beds.any(
            (bed) =>
                bed.tenant?.fullName.toLowerCase().contains(query) ?? false,
          );

      if (!matchesSearch) return false;

      switch (_filter) {
        case _RoomFilter.all:
          return true;
        case _RoomFilter.available:
          return entry.availableBeds > 0;
        case _RoomFilter.occupied:
          return entry.occupiedBeds > 0;
      }
    }).toList();
  }

  int get _totalRooms => _allRooms.length;

  int get _totalBeds =>
      _allRooms.fold(0, (sum, room) => sum + room.totalBeds);

  int get _occupiedBeds =>
      _allRooms.fold(0, (sum, room) => sum + room.occupiedBeds);

  int get _availableBeds =>
      _allRooms.fold(0, (sum, room) => sum + room.availableBeds);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'Rooms & Beds',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadRooms,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadRooms,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _error != null
                ? _errorView()
                : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final rooms = _filteredRooms;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _summaryCards(),
        const SizedBox(height: 18),
        _searchField(),
        const SizedBox(height: 12),
        _filterBar(),
        const SizedBox(height: 18),
        if (_allRooms.isEmpty)
          _emptyState()
        else if (rooms.isEmpty)
          _noResultsState()
        else
          ...rooms.map(_roomCard),
      ],
    );
  }

  Widget _summaryCards() {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            icon: Icons.meeting_room_rounded,
            value: '$_totalRooms',
            label: 'Rooms',
            color: const Color(0xFF2563EB),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryCard(
            icon: Icons.bed_rounded,
            value: '$_totalBeds',
            label: 'Beds',
            color: const Color(0xFF7C3AED),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryCard(
            icon: Icons.check_circle_rounded,
            value: '$_occupiedBeds',
            label: 'Occupied',
            color: const Color(0xFF16A34A),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryCard(
            icon: Icons.event_available_rounded,
            value: '$_availableBeds',
            label: 'Vacant',
            color: const Color(0xFFF97316),
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 104),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: color,
              size: 21,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      onChanged: (value) {
        setState(() {
          _search = value;
        });
      },
      decoration: InputDecoration(
        hintText: 'Search room, floor or tenant',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _search.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear',
                onPressed: () {
                  setState(() {
                    _search = '';
                  });
                },
                icon: const Icon(Icons.clear_rounded),
              ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Color(0xFF2563EB),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _filterBar() {
    return Row(
      children: [
        _filterChip(
          label: 'All',
          filter: _RoomFilter.all,
        ),
        const SizedBox(width: 8),
        _filterChip(
          label: 'Vacant',
          filter: _RoomFilter.available,
        ),
        const SizedBox(width: 8),
        _filterChip(
          label: 'Occupied',
          filter: _RoomFilter.occupied,
        ),
      ],
    );
  }

  Widget _filterChip({
    required String label,
    required _RoomFilter filter,
  }) {
    final selected = _filter == filter;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _filter = filter;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF2563EB)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? const Color(0xFF2563EB)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? Colors.white
                  : const Color(0xFF374151),
            ),
          ),
        ),
      ),
    );
  }

  Widget _roomCard(_RoomEntry entry) {
    final expanded = _expandedRooms.contains(entry.room.id);
    final occupancyText =
        '${entry.occupiedBeds}/${entry.totalBeds} Occupied';

    final Color statusColor = entry.availableBeds > 0
        ? const Color(0xFF16A34A)
        : const Color(0xFFDC2626);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (expanded) {
                  _expandedRooms.remove(entry.room.id);
                } else {
                  _expandedRooms.add(entry.room.id);
                }
              });
            },
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.meeting_room_rounded,
                      color: Color(0xFF2563EB),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Room ${entry.room.roomNumber}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          entry.floor.name,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _statusPill(
                              '${entry.availableBeds} Vacant',
                              statusColor,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              occupancyText,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF374151),
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(
              height: 1,
              color: Color(0xFFE5E7EB),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              child: Column(
                children: entry.beds.map(_bedCard).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _bedCard(_BedEntry entry) {
    final occupied = entry.bed.status == 'occupied';
    final tenant = entry.tenant;

    final color = occupied
        ? const Color(0xFF16A34A)
        : const Color(0xFF2563EB);

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: occupied
              ? const Color(0xFFDCFCE7)
              : const Color(0xFFDBEAFE),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.bed_rounded,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.bed.bedNumber,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 3),
                if (occupied && tenant != null) ...[
                  Text(
                    tenant.fullName,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tenant.phone,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Rent: ₹${_money(tenant.monthlyRent)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                ] else ...[
                  const Text(
                    'Available for tenant',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ],
            ),
          ),
          _statusPill(
            occupied ? 'Occupied' : 'Available',
            color,
          ),
        ],
      ),
    );
  }

  String _money(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  Widget _emptyState() {
    return _messageCard(
      icon: Icons.meeting_room_outlined,
      title: 'No rooms found',
      message:
          'Create rooms from More → PG Structure. They will appear here automatically.',
    );
  }

  Widget _noResultsState() {
    return _messageCard(
      icon: Icons.search_off_rounded,
      title: 'No matching rooms',
      message: 'Try a different room number, floor or tenant name.',
    );
  }

  Widget _errorView() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        _messageCard(
          icon: Icons.error_outline_rounded,
          title: 'Unable to load rooms',
          message: _error ?? 'Unknown error',
          action: ElevatedButton.icon(
            onPressed: _loadRooms,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
          ),
        ),
      ],
    );
  }

  Widget _messageCard({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 42,
            color: const Color(0xFF2563EB),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              height: 1.4,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 16),
            action,
          ],
        ],
      ),
    );
  }
}
