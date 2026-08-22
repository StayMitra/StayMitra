import 'package:flutter/material.dart';

import 'building_model.dart';
import 'database_helper.dart';

class BuildingSetupScreen extends StatefulWidget {
  final String ownerId;

  const BuildingSetupScreen({
    super.key,
    required this.ownerId,
  });

  @override
  State<BuildingSetupScreen> createState() =>
      _BuildingSetupScreenState();
}

class _BuildingSetupScreenState
    extends State<BuildingSetupScreen> {
  bool _isLoading = true;

  BuildingModel? _building;
  List<FloorModel> _floors = [];

  // Floor cards are expanded by default.
  final Map<String, bool> _expandedFloors = {};

  // ------------------------------------------------------------
  // INIT
  // ------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _loadStructure();
  }

// ------------------------------------------------------------
// LOAD STRUCTURE
// ------------------------------------------------------------

Future<void> _loadStructure() async {
  setState(() {
    _isLoading = true;
  });

  try {
    final buildings =
        await DatabaseHelper.instance.getBuildings(
      ownerId: widget.ownerId,
    );

    BuildingModel? building;

    if (buildings.isNotEmpty) {
      building = buildings.first;
    }

    List<FloorModel> floors = [];

    if (building != null) {
      floors = await DatabaseHelper.instance.getFloors(
        building.id,
      );
    }

    if (!mounted) return;

    setState(() {
      _building = building;
      _floors = floors;
      _isLoading = false;

      for (final floor in floors) {
        _expandedFloors.putIfAbsent(
          floor.id,
          () => true,
        );
      }

      _expandedFloors.removeWhere(
        (id, _) => !floors.any(
          (floor) => floor.id == id,
        ),
      );
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      _building = null;
      _floors = [];
      _isLoading = false;
    });
  }
}

  // ------------------------------------------------------------
  // MONEY-LIKE ID GENERATOR
  // ------------------------------------------------------------

  String _newId(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}';
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),

        title: const Text(
          'PG Structure',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            onPressed: _loadStructure,
            tooltip: 'Refresh',
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),

      floatingActionButton: _building == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _showAddFloorDialog,
              backgroundColor:
                  const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              icon: const Icon(
                Icons.add_rounded,
              ),
              label: const Text(
                'Add Floor',
              ),
            ),

      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadStructure,

              child: SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),

                padding: const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  100,
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    _buildingCard(),

                    const SizedBox(height: 22),

                    _sectionHeader(),

                    const SizedBox(height: 12),

                    if (_building == null)
                      _emptyBuildingState()
                    else if (_floors.isEmpty)
                      _emptyFloorState()
                    else
                      _floorList(),
                  ],
                ),
              ),
            ),
    );
  }

  // ------------------------------------------------------------
  // BUILDING CARD
  // ------------------------------------------------------------

  Widget _buildingCard() {
    final building = _building;

    if (building == null) {
      return _createBuildingCard();
    }

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(20),

        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,

            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),

              borderRadius:
                  BorderRadius.circular(16),
            ),

            child: const Icon(
              Icons.apartment_rounded,
              color: Color(0xFF2563EB),
              size: 29,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  building.name,

                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Color(0xFF111827),
                  ),
                ),

                if (building.address != null &&
                    building.address!
                        .trim()
                        .isNotEmpty) ...[
                  const SizedBox(height: 5),

                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 15,
                        color:
                            Color(0xFF6B7280),
                      ),

                      const SizedBox(width: 4),

                      Expanded(
                        child: Text(
                          building.address!,

                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,

                          style:
                              const TextStyle(
                            fontSize: 12,
                            color:
                                Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          IconButton(
            onPressed:
                _showEditBuildingDialog,
            tooltip: 'Edit PG',
            icon: const Icon(
              Icons.edit_outlined,
              color: Color(0xFF2563EB),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // CREATE BUILDING CARD
  // ------------------------------------------------------------

  Widget _createBuildingCard() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(20),

        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),

      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,

            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),

              borderRadius:
                  BorderRadius.circular(20),
            ),

            child: const Icon(
              Icons.apartment_rounded,
              size: 34,
              color: Color(0xFF2563EB),
            ),
          ),

          const SizedBox(height: 14),

          const Text(
            'Set Up Your PG',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Add your PG name and address to start configuring floors, rooms and beds.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              height: 1.4,
            ),
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,

            child: FilledButton.icon(
              onPressed:
                  _showAddBuildingDialog,

              icon: const Icon(
                Icons.add_business_rounded,
              ),

              label: const Text(
                'Set Up PG',
              ),

              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    const Color(0xFF2563EB),

                foregroundColor:
                    Colors.white,

                minimumSize:
                    const Size.fromHeight(
                  50,
                ),

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // SECTION HEADER
  // ------------------------------------------------------------

  Widget _sectionHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Floors & Rooms',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
        ),

        if (_building != null)
          Text(
            '${_floors.length} ${_floors.length == 1 ? 'Floor' : 'Floors'}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  // ------------------------------------------------------------
  // EMPTY BUILDING STATE
  // ------------------------------------------------------------

  Widget _emptyBuildingState() {
    return const SizedBox.shrink();
  }

  // ------------------------------------------------------------
  // EMPTY FLOOR STATE
  // ------------------------------------------------------------

  Widget _emptyFloorState() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(28),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(18),

        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),

      child: Column(
        children: [
          const Icon(
            Icons.layers_outlined,
            size: 48,
            color: Color(0xFF9CA3AF),
          ),

          const SizedBox(height: 12),

          const Text(
            'No floors added yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Add your Ground Floor, 1st Floor, 2nd Floor and so on.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              height: 1.4,
            ),
          ),

          const SizedBox(height: 16),

          FilledButton.icon(
            onPressed: _showAddFloorDialog,
            icon: const Icon(
              Icons.add_rounded,
            ),
            label: const Text(
              'Add First Floor',
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // FLOOR LIST
  // ------------------------------------------------------------

  Widget _floorList() {
    return Column(
      children: _floors.map((floor) {
        return _floorCard(floor);
      }).toList(),
    );
  }

  // ------------------------------------------------------------
  // FLOOR CARD
  // ------------------------------------------------------------

  Widget _floorCard(
    FloorModel floor,
  ) {
    return FutureBuilder<List<RoomModel>>(
      future:
          DatabaseHelper.instance.getRooms(
        floor.id,
      ),

      builder: (context, snapshot) {
        final rooms =
            snapshot.data ?? [];

        return Container(
          width: double.infinity,

          margin:
              const EdgeInsets.only(
            bottom: 14,
          ),

          decoration: BoxDecoration(
            color: Colors.white,

            borderRadius:
                BorderRadius.circular(18),

            border: Border.all(
              color: const Color(0xFFE5E7EB),
            ),
          ),

          child: Column(
            children: [
              // ------------------------------------------------
              // FLOOR HEADER
              // ------------------------------------------------

              Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  14,
                  10,
                  14,
                ),

                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,

                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFFEFF6FF,
                        ),

                        borderRadius:
                            BorderRadius
                                .circular(
                          12,
                        ),
                      ),

                      child: const Icon(
                        Icons.layers_rounded,
                        color:
                            Color(0xFF2563EB),
                        size: 22,
                      ),
                    ),

                    const SizedBox(width: 11),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [
                          Text(
                            floor.name,

                            style:
                                const TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold,
                              color:
                                  Color(0xFF111827),
                            ),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            '${rooms.length} ${rooms.length == 1 ? 'Room' : 'Rooms'}',

                            style:
                                const TextStyle(
                              fontSize: 11,
                              color:
                                  Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),

                    IconButton(
                      tooltip: _expandedFloors[floor.id] == true
                          ? 'Collapse floor'
                          : 'Expand floor',
                      onPressed: () {
                        setState(() {
                          _expandedFloors[floor.id] =
                              !(_expandedFloors[floor.id] ?? true);
                        });
                      },
                      icon: Icon(
                        _expandedFloors[floor.id] == true
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 28,
                        color: const Color(0xFF374151),
                      ),
                    ),

                    IconButton(
                      onPressed: () {
                        _showFloorMenu(
                          floor,
                        );
                      },

                      icon:
                          const Icon(
                        Icons.more_vert_rounded,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(
                height: 1,
                color: Color(0xFFF1F5F9),
              ),

              // ------------------------------------------------
              // ROOMS
              // ------------------------------------------------

              if (_expandedFloors[floor.id] != true)
                const SizedBox.shrink()
              else if (rooms.isEmpty)
                Padding(
                  padding:
                      const EdgeInsets.all(
                    18,
                  ),

                  child: Column(
                    children: [
                      const Text(
                        'No rooms on this floor.',
                        style:
                            TextStyle(
                          fontSize: 12,
                          color:
                              Color(0xFF6B7280),
                        ),
                      ),

                      const SizedBox(height: 10),

                      OutlinedButton.icon(
                        onPressed: () {
                          _showAddRoomDialog(
                            floor,
                          );
                        },

                        icon:
                            const Icon(
                          Icons.add_rounded,
                          size: 18,
                        ),

                        label:
                            const Text(
                          'Add Room',
                        ),
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding:
                      const EdgeInsets.all(
                    12,
                  ),

                  child: Column(
                    children: [
                      ...rooms.map(
                        (room) {
                          return _roomCard(
                            room,
                          );
                        },
                      ),

                      const SizedBox(height: 2),

                      SizedBox(
                        width:
                            double.infinity,

                        child:
                            OutlinedButton
                                .icon(
                          onPressed: () {
                            _showAddRoomDialog(
                              floor,
                            );
                          },

                          icon:
                              const Icon(
                            Icons.add_rounded,
                            size: 18,
                          ),

                          label:
                              const Text(
                            'Add Room',
                          ),

                          style:
                              OutlinedButton
                                  .styleFrom(
                            foregroundColor:
                                const Color(
                              0xFF2563EB,
                            ),

                            side:
                                const BorderSide(
                              color:
                                  Color(
                                0xFFBFDBFE,
                              ),
                            ),

                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // ROOM CARD
  // ------------------------------------------------------------

  Widget _roomCard(
    RoomModel room,
  ) {
    return FutureBuilder<List<BedModel>>(
      future:
          DatabaseHelper.instance.getBeds(
        room.id,
      ),

      builder: (context, snapshot) {
        final beds =
            snapshot.data ?? [];

        final available =
            beds.where(
          (bed) => bed.isAvailable,
        ).length;

        final occupied =
            beds.where(
          (bed) => bed.isOccupied,
        ).length;

        return Container(
          margin:
              const EdgeInsets.only(
            bottom: 10,
          ),

          padding:
              const EdgeInsets.all(
            12,
          ),

          decoration: BoxDecoration(
            color:
                const Color(0xFFF8FAFC),

            borderRadius:
                BorderRadius.circular(
              14,
            ),

            border: Border.all(
              color:
                  const Color(0xFFE5E7EB),
            ),
          ),

          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,

                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFEFF6FF,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),

                child: const Icon(
                  Icons.meeting_room_rounded,
                  color:
                      Color(0xFF2563EB),
                  size: 22,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      'Room ${room.roomNumber}',

                      style:
                          const TextStyle(
                        fontSize: 14,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Color(0xFF111827),
                      ),
                    ),

                    const SizedBox(height: 4),

                    if (beds.isEmpty)
                      Text(
                        '${room.bedCount} ${room.bedCount == 1 ? 'Bed' : 'Beds'} configured',

                        style:
                            const TextStyle(
                          fontSize: 11,
                          color:
                              Color(0xFF6B7280),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,

                        children: [
                          _bedStatusTag(
                            '$available Available',
                            const Color(
                              0xFF16A34A,
                            ),
                          ),

                          if (occupied > 0)
                            _bedStatusTag(
                              '$occupied Occupied',
                              const Color(
                                0xFFDC2626,
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),

              IconButton(
                onPressed: () {
                  _showRoomMenu(
                    room,
                  );
                },

                tooltip: 'Room options',

                icon: const Icon(
                  Icons.more_vert_rounded,
                  color:
                      Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // BED STATUS TAG
  // ------------------------------------------------------------

  Widget _bedStatusTag(
    String text,
    Color color,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),

      decoration: BoxDecoration(
        color:
            color.withValues(alpha: 0.08),

        borderRadius:
            BorderRadius.circular(7),
      ),

      child: Text(
        text,

        style: TextStyle(
          fontSize: 10,
          fontWeight:
              FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  // ============================================================
  // BUILDING DIALOG
  // ============================================================

  Future<void> _showAddBuildingDialog() async {
    final nameController =
        TextEditingController();

    final addressController =
        TextEditingController();

    final result =
        await showDialog<bool>(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Add PG',
          ),

          content: SingleChildScrollView(
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,

              children: [
                TextField(
                  controller:
                      nameController,

                  textCapitalization:
                      TextCapitalization.words,

                  decoration:
                      const InputDecoration(
                    labelText: 'PG Name',
                    hintText:
                        'Example: Sri Sai PG',
                    prefixIcon: Icon(
                      Icons.apartment_rounded,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller:
                      addressController,

                  maxLines: 2,

                  textCapitalization:
                      TextCapitalization.sentences,

                  decoration:
                      const InputDecoration(
                    labelText:
                        'Address (Optional)',
                    hintText:
                        'Enter PG address',
                    prefixIcon: Icon(
                      Icons.location_on_outlined,
                    ),
                  ),
                ),
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                FocusScope.of(context).unfocus();
                Navigator.pop(
                  context,
                  false,
                );
              },

              child:
                  const Text('Cancel'),
            ),

            FilledButton(
              onPressed: () async {
                final name =
                    nameController.text
                        .trim();

                if (name.isEmpty) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter PG name',
                      ),
                    ),
                  );

                  return;
                }

                final building =
                    BuildingModel(
                  id: _newId('building'),

                  name: name,

                  address:
                      addressController
                              .text
                              .trim()
                              .isEmpty
                          ? null
                          : addressController
                              .text
                              .trim(),

                  createdAt:
                      DateTime.now(),
                  ownerId: widget.ownerId,    
                );

                await DatabaseHelper
                    .instance
                    .insertBuilding(
                  building,
                );

                if (!context.mounted) {
                  return;
                }

                FocusScope.of(context).unfocus();
                Navigator.pop(
                  context,
                  true,
                );
              },

              child:
                  const Text('Save'),
            ),
          ],
        );
      },
    );

    // Wait for the dialog's focus/keyboard notifications to finish
    // before disposing controllers.
    await Future<void>.delayed(const Duration(milliseconds: 100));

    nameController.dispose();
    addressController.dispose();

    if (result == true) {
      await _loadStructure();
    }
  }

  // ------------------------------------------------------------
  // EDIT BUILDING
  // ------------------------------------------------------------

  Future<void>
      _showEditBuildingDialog() async {
    final building = _building;

    if (building == null) {
      return;
    }

    final nameController =
        TextEditingController(
      text: building.name,
    );

    final addressController =
        TextEditingController(
      text: building.address ?? '',
    );

    final result =
        await showDialog<bool>(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Edit PG',
          ),

          content: SingleChildScrollView(
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,

              children: [
                TextField(
                  controller:
                      nameController,

                  decoration:
                      const InputDecoration(
                    labelText:
                        'PG Name',
                    prefixIcon:
                        Icon(
                      Icons.apartment_rounded,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller:
                      addressController,

                  maxLines: 2,

                  decoration:
                      const InputDecoration(
                    labelText:
                        'Address',
                    prefixIcon:
                        Icon(
                      Icons.location_on_outlined,
                    ),
                  ),
                ),
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                FocusScope.of(context).unfocus();
                Navigator.pop(
                  context,
                  false,
                );
              },

              child:
                  const Text('Cancel'),
            ),

            FilledButton(
              onPressed: () async {
                final name =
                    nameController.text
                        .trim();

                if (name.isEmpty) {
                  return;
                }

                final updated =
                    BuildingModel(
                  id: building.id,

                  name: name,

                  address:
                      addressController
                              .text
                              .trim()
                              .isEmpty
                          ? null
                          : addressController
                              .text
                              .trim(),

                  createdAt:
                      building.createdAt,
                  ownerId: widget.ownerId,    
                );

                await DatabaseHelper
                    .instance
                    .insertBuilding(
                  updated,
                );

                if (!context.mounted) {
                  return;
                }

                FocusScope.of(context).unfocus();
                Navigator.pop(
                  context,
                  true,
                );
              },

              child:
                  const Text('Save'),
            ),
          ],
        );
      },
    );

    // Wait for the dialog's focus/keyboard notifications to finish
    // before disposing controllers.
    await Future<void>.delayed(const Duration(milliseconds: 100));

    nameController.dispose();
    addressController.dispose();

    if (result == true) {
      await _loadStructure();
    }
  }

  // ============================================================
  // FLOOR DIALOG
  // ============================================================

  Future<void>
      _showAddFloorDialog() async {
    if (_building == null) {
      return;
    }

    final controller =
        TextEditingController();

    final result =
        await showDialog<bool>(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Add Floor',
          ),

          content: TextField(
            controller:
                controller,

            autofocus: true,

            textCapitalization:
                TextCapitalization.words,

            decoration:
                const InputDecoration(
              labelText:
                  'Floor Name',
              hintText:
                  'Example: Ground Floor',
              prefixIcon:
                  Icon(
                Icons.layers_rounded,
              ),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                FocusScope.of(context).unfocus();
                Navigator.pop(
                  context,
                  false,
                );
              },

              child:
                  const Text('Cancel'),
            ),

            FilledButton(
              onPressed: () async {
                final name =
                    controller.text
                        .trim();

                if (name.isEmpty) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter floor name',
                      ),
                    ),
                  );

                  return;
                }

                final floor =
                    FloorModel(
                  id: _newId('floor'),

                  buildingId:
                      _building!.id,

                  name: name,

                  floorOrder:
                      _floors.length,

                  createdAt:
                      DateTime.now(),
                );

                await DatabaseHelper
                    .instance
                    .insertFloor(
                  floor,
                );

                if (!context.mounted) {
                  return;
                }

                FocusScope.of(context).unfocus();
                Navigator.pop(
                  context,
                  true,
                );
              },

              child:
                  const Text('Save'),
            ),
          ],
        );
      },
    );

    // Wait for the dialog's focus/keyboard notifications to finish
    // before disposing the controller.
    await Future<void>.delayed(const Duration(milliseconds: 100));

    controller.dispose();

    if (result == true) {
      await _loadStructure();
    }
  }

  // ------------------------------------------------------------
  // FLOOR MENU
  // ------------------------------------------------------------

  Future<void> _showFloorMenu(
    FloorModel floor,
  ) async {
    final action =
        await showModalBottomSheet<String>(
      context: context,

      showDragHandle: true,

      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize:
                MainAxisSize.min,

            children: [
              ListTile(
                leading:
                    const Icon(
                  Icons.add_home_work_rounded,
                ),

                title:
                    const Text(
                  'Add Room',
                ),

                onTap: () {
                  Navigator.pop(
                    context,
                    'add_room',
                  );
                },
              ),

              ListTile(
                leading:
                    const Icon(
                  Icons.edit_outlined,
                ),

                title:
                    const Text(
                  'Rename Floor',
                ),

                onTap: () {
                  Navigator.pop(
                    context,
                    'rename',
                  );
                },
              ),

              ListTile(
                leading:
                    const Icon(
                  Icons.delete_outline_rounded,
                  color:
                      Color(0xFFDC2626),
                ),

                title:
                    const Text(
                  'Delete Floor',
                  style:
                      TextStyle(
                    color:
                        Color(0xFFDC2626),
                  ),
                ),

                onTap: () {
                  Navigator.pop(
                    context,
                    'delete',
                  );
                },
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (action == 'add_room') {
      await _showAddRoomDialog(
        floor,
      );
    }

    if (action == 'rename') {
      await _renameFloor(
        floor,
      );
    }

    if (action == 'delete') {
      await _deleteFloor(
        floor,
      );
    }
  }

  // ------------------------------------------------------------
  // RENAME FLOOR
  // ------------------------------------------------------------

  Future<void> _renameFloor(
    FloorModel floor,
  ) async {
    final controller =
        TextEditingController(
      text: floor.name,
    );

    final result =
        await showDialog<bool>(
      context: context,

      builder: (context) {
        return AlertDialog(
          title:
              const Text(
            'Rename Floor',
          ),

          content:
              TextField(
            controller:
                controller,

            autofocus:
                true,

            decoration:
                const InputDecoration(
              labelText:
                  'Floor Name',
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                FocusScope.of(context).unfocus();
                Navigator.pop(
                  context,
                  false,
                );
              },

              child:
                  const Text(
                'Cancel',
              ),
            ),

            FilledButton(
              onPressed: () async {
                final name =
                    controller.text
                        .trim();

                if (name.isEmpty) {
                  return;
                }

                final updated =
                    FloorModel(
                  id: floor.id,

                  buildingId:
                      floor.buildingId,

                  name: name,

                  floorOrder:
                      floor.floorOrder,

                  createdAt:
                      floor.createdAt,
                );

                await DatabaseHelper
                    .instance
                    .insertFloor(
                  updated,
                );

                if (!context.mounted) {
                  return;
                }

                FocusScope.of(context).unfocus();
                Navigator.pop(
                  context,
                  true,
                );
              },

              child:
                  const Text(
                'Save',
              ),
            ),
          ],
        );
      },
    );

    // Wait for the dialog's focus/keyboard notifications to finish
    // before disposing the controller.
    await Future<void>.delayed(const Duration(milliseconds: 100));

    controller.dispose();

    if (result == true) {
      await _loadStructure();
    }
  }

  // ------------------------------------------------------------
  // DELETE FLOOR
  // ------------------------------------------------------------

  Future<void> _deleteFloor(
    FloorModel floor,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,

      builder: (context) {
        return AlertDialog(
          title:
              const Text(
            'Delete Floor?',
          ),

          content:
              const Text(
            'All rooms and beds under this floor will also be removed.',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },

              child:
                  const Text(
                'Cancel',
              ),
            ),

            FilledButton(
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFFDC2626,
                ),
              ),

              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },

              child:
                  const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await DatabaseHelper
        .instance
        .deleteFloor(
      floor.id,
    );

await _loadStructure();

if (!mounted) {
  return;
}

final messenger = ScaffoldMessenger.of(context);

messenger.showSnackBar(
  const SnackBar(
    content: Text(
      'Floor deleted successfully',
    ),
  ),
);
  }

  // ============================================================
  // ROOM DIALOG
  // ============================================================

  Future<void> _showAddRoomDialog(
    FloorModel floor,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return _AddRoomsDialog(
          floor: floor,
          onSave: (
            String startRoomNumber,
            int roomCount,
            int bedCount,
          ) {
            return _createRooms(
              floor,
              startRoomNumber,
              roomCount,
              bedCount,
            );
          },
        );
      },
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  // ------------------------------------------------------------
  // CREATE SINGLE / MULTIPLE ROOMS
  // ------------------------------------------------------------

  Future<bool> _createRooms(
    FloorModel floor,
    String startRoomNumber,
    int roomCount,
    int bedCount,
  ) async {
    final existingRooms =
        await DatabaseHelper.instance.getRooms(
      floor.id,
    );

    final existingNumbers = existingRooms
        .map(
          (room) => room.roomNumber.toLowerCase(),
        )
        .toSet();

    final roomNumbers = _generateRoomNumbers(
      startRoomNumber,
      roomCount,
    );

    final duplicateInBatch =
        roomNumbers.toSet().length != roomNumbers.length;

    final alreadyExists = roomNumbers.any(
      (number) => existingNumbers.contains(
        number.toLowerCase(),
      ),
    );

    if (duplicateInBatch || alreadyExists) {
      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'One or more room numbers already exist on this floor',
          ),
        ),
      );

      return false;
    }

    for (final roomNumber in roomNumbers) {
      final room = RoomModel(
        id: _newId('room'),
        floorId: floor.id,
        roomNumber: roomNumber,
        bedCount: bedCount,
        createdAt: DateTime.now(),
      );

      await DatabaseHelper.instance.insertRoom(
        room,
      );

      for (int i = 1; i <= bedCount; i++) {
        final bed = BedModel(
          id: _newId('bed'),
          roomId: room.id,
          bedNumber: 'Bed $i',
          status: 'available',
          createdAt: DateTime.now(),
        );

        await DatabaseHelper.instance.insertBed(
          bed,
        );
      }
    }

    return true;
  }

  List<String> _generateRoomNumbers(
    String startRoomNumber,
    int count,
  ) {
    final match = RegExp(
      r'^(.*?)(\d+)$',
    ).firstMatch(startRoomNumber);

    if (match == null) {
      if (count == 1) {
        return [startRoomNumber];
      }

      return List.generate(
        count,
        (index) => '$startRoomNumber ${index + 1}',
      );
    }

    final prefix = match.group(1) ?? '';
    final numberPart = match.group(2)!;
    final startNumber = int.parse(numberPart);
    final width = numberPart.length;

    return List.generate(
      count,
      (index) {
        final number =
            (startNumber + index).toString().padLeft(
                  width,
                  '0',
                );

        return '$prefix$number';
      },
    );
  }

  // ============================================================
  // ROOM MENU
  // ============================================================

  Future<void> _showRoomMenu(
    RoomModel room,
  ) async {
    final action =
        await showModalBottomSheet<String>(
      context: context,

      showDragHandle: true,

      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize:
                MainAxisSize.min,

            children: [
              ListTile(
                leading:
                    const Icon(
                  Icons.bed_rounded,
                ),

                title:
                    const Text(
                  'View Beds',
                ),

                onTap: () {
                  Navigator.pop(
                    context,
                    'beds',
                  );
                },
              ),

              ListTile(
                leading:
                    const Icon(
                  Icons.edit_outlined,
                ),

                title:
                    const Text(
                  'Edit Room',
                ),

                onTap: () {
                  Navigator.pop(
                    context,
                    'edit',
                  );
                },
              ),

              ListTile(
                leading:
                    const Icon(
                  Icons.delete_outline_rounded,
                  color:
                      Color(0xFFDC2626),
                ),

                title:
                    const Text(
                  'Delete Room',
                  style:
                      TextStyle(
                    color:
                        Color(0xFFDC2626),
                  ),
                ),

                onTap: () {
                  Navigator.pop(
                    context,
                    'delete',
                  );
                },
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (action == 'beds') {
      await _showBedsDialog(
        room,
      );
    }

    if (action == 'edit') {
      await _showEditRoomDialog(
        room,
      );
    }

    if (action == 'delete') {
      await _deleteRoom(
        room,
      );
    }
  }

  // ============================================================
  // VIEW BEDS
  // ============================================================

  Future<void> _showBedsDialog(
    RoomModel room,
  ) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _BedManagementDialog(
          room: room,
        );
      },
    );

    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // EDIT ROOM
  // ============================================================

  Future<void> _showEditRoomDialog(
    RoomModel room,
  ) async {
    final roomController =
        TextEditingController(
      text: room.roomNumber,
    );

    final result =
        await showDialog<bool>(
      context: context,

      builder: (context) {
        return AlertDialog(
          title:
              const Text(
            'Edit Room',
          ),

          content:
              TextField(
            controller:
                roomController,

            textCapitalization:
                TextCapitalization.characters,

            decoration:
                const InputDecoration(
              labelText:
                  'Room Number',
              prefixIcon:
                  Icon(
                Icons.meeting_room_outlined,
              ),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                FocusScope.of(context).unfocus();
                Navigator.pop(
                  context,
                  false,
                );
              },

              child:
                  const Text(
                'Cancel',
              ),
            ),

            FilledButton(
              onPressed: () async {
                final roomNumber =
                    roomController.text
                        .trim();

                if (roomNumber.isEmpty) {
                  return;
                }

                final updated =
                    RoomModel(
                  id: room.id,

                  floorId:
                      room.floorId,

                  roomNumber:
                      roomNumber,

                  bedCount:
                      room.bedCount,

                  createdAt:
                      room.createdAt,
                );

                await DatabaseHelper
                    .instance
                    .updateRoom(
                  updated,
                );

                if (!context.mounted) {
                  return;
                }

                FocusScope.of(context).unfocus();
                Navigator.pop(
                  context,
                  true,
                );
              },

              child:
                  const Text(
                'Save',
              ),
            ),
          ],
        );
      },
    );

    // Wait for the dialog's focus/keyboard notifications to finish
    // before disposing the controller.
    await Future<void>.delayed(const Duration(milliseconds: 100));

    roomController.dispose();

    if (result == true) {
      setState(() {});
    }
  }

  // ============================================================
  // DELETE ROOM
  // ============================================================

  Future<void> _deleteRoom(
    RoomModel room,
  ) async {
    final beds =
        await DatabaseHelper
            .instance
            .getBeds(
      room.id,
    );

    final hasOccupiedBed =
        beds.any(
      (bed) => bed.isOccupied,
    );

    if (hasOccupiedBed) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot delete a room with occupied beds.',
          ),
        ),
      );

      return;
    }

    // The database call above is an async gap.
    // Check the State before using this State's BuildContext again.
    if (!mounted) {
      return;
    }

    final confirmed =
        await showDialog<bool>(
      context: context,

      builder: (context) {
        return AlertDialog(
          title:
              const Text(
            'Delete Room?',
          ),

          content:
              Text(
            'Room ${room.roomNumber} and its beds will be removed.',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },

              child:
                  const Text(
                'Cancel',
              ),
            ),

            FilledButton(
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFFDC2626,
                ),
              ),

              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },

              child:
                  const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await DatabaseHelper
        .instance
        .deleteRoom(
      room.id,
    );

    if (!mounted) {
      return;
    }

    setState(() {});

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content:
            Text(
          'Room deleted successfully',
        ),
      ),
    );
  }
}

class _BedManagementDialog extends StatefulWidget {
  final RoomModel room;

  const _BedManagementDialog({
    required this.room,
  });

  @override
  State<_BedManagementDialog> createState() =>
      _BedManagementDialogState();
}

class _BedManagementDialogState extends State<_BedManagementDialog> {
  late Future<List<BedModel>> _bedsFuture;
  String? _updatingBedId;

  @override
  void initState() {
    super.initState();
    _reloadBeds();
  }

  void _reloadBeds() {
    _bedsFuture = DatabaseHelper.instance.getBeds(widget.room.id);
  }

  Future<void> _toggleBedStatus(BedModel bed) async {
    if (_updatingBedId != null) return;

    final newStatus = bed.isOccupied ? 'available' : 'occupied';

    setState(() {
      _updatingBedId = bed.id;
    });

    try {
      await DatabaseHelper.instance.updateBedStatus(
        bed.id,
        newStatus,
      );

      if (!mounted) return;

      setState(() {
        _updatingBedId = null;
        _reloadBeds();
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _updatingBedId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to update bed status.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Room ${widget.room.roomNumber} – Beds',
      ),
      content: SizedBox(
        width: 380,
        child: FutureBuilder<List<BedModel>>(
          future: _bedsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 120,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Unable to load beds. Please try again.',
                  textAlign: TextAlign.center,
                ),
              );
            }

            final beds = snapshot.data ?? <BedModel>[];

            if (beds.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'No beds configured for this room.',
                  textAlign: TextAlign.center,
                ),
              );
            }

            final available =
                beds.where((bed) => bed.isAvailable).length;
            final occupied =
                beds.where((bed) => bed.isOccupied).length;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _summaryItem(
                          'Available',
                          available.toString(),
                          const Color(0xFF16A34A),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: const Color(0xFFE5E7EB),
                      ),
                      Expanded(
                        child: _summaryItem(
                          'Occupied',
                          occupied.toString(),
                          const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: beds.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final bed = beds[index];
                      final occupied = bed.isOccupied;
                      final updating = _updatingBedId == bed.id;

                      return InkWell(
                        onTap: updating
                            ? null
                            : () => _toggleBedStatus(bed),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: occupied
                                ? const Color(0xFFFEF2F2)
                                : const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: occupied
                                  ? const Color(0xFFFECACA)
                                  : const Color(0xFFBBF7D0),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: occupied
                                      ? const Color(0xFFFEE2E2)
                                      : const Color(0xFFDCFCE7),
                                  borderRadius:
                                      BorderRadius.circular(11),
                                ),
                                child: Icon(
                                  Icons.bed_rounded,
                                  color: occupied
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFF16A34A),
                                  size: 21,
                                ),
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      bed.bedNumber,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      occupied
                                          ? 'Currently occupied'
                                          : 'Ready for allotment',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (updating)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: occupied
                                        ? const Color(0xFFFEE2E2)
                                        : const Color(0xFFDCFCE7),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    occupied
                                        ? 'Occupied'
                                        : 'Available',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: occupied
                                          ? const Color(0xFFDC2626)
                                          : const Color(0xFF16A34A),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Tap a bed to change its status. Tenant allotment will use the same status automatically in Step 8.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }

  Widget _summaryItem(
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}

class _AddRoomsDialog extends StatefulWidget {
  final FloorModel floor;

  // The dialog is displayed as a separate route. Passing the save
  // callback directly is reliable; using findAncestorStateOfType()
  // from the dialog context can return null because the dialog's
  // BuildContext is not a descendant of BuildingSetupScreen's State.
  final Future<bool> Function(
    String startRoomNumber,
    int roomCount,
    int bedCount,
  ) onSave;

  const _AddRoomsDialog({
    required this.floor,
    required this.onSave,
  });

  @override
  State<_AddRoomsDialog> createState() =>
      _AddRoomsDialogState();
}

class _AddRoomsDialogState
    extends State<_AddRoomsDialog> {
  late final TextEditingController _roomController;
  late final TextEditingController _roomCountController;
  late final TextEditingController _bedController;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _roomController = TextEditingController();
    _roomCountController = TextEditingController(text: '1');
    _bedController = TextEditingController(text: '2');
  }

  @override
  void dispose() {
    _roomController.dispose();
    _roomCountController.dispose();
    _bedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomCount =
        int.tryParse(
              _roomCountController.text.trim(),
            ) ??
            1;

    final preview =
        roomCount > 0 &&
                roomCount <= 50 &&
                _roomController.text.trim().isNotEmpty
            ? _generatePreview(
                _roomController.text.trim(),
                roomCount,
              )
            : <String>[];

    return AlertDialog(
      title: const Text('Add Rooms'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Floor',
                prefixIcon: Icon(
                  Icons.layers_outlined,
                ),
              ),
              child: Text(
                widget.floor.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: _roomController,
              textCapitalization:
                  TextCapitalization.characters,
              onChanged: (_) {
                setState(() {});
              },
              decoration: const InputDecoration(
                labelText: 'Starting Room Number',
                hintText: 'Example: G01 or 101',
                prefixIcon: Icon(
                  Icons.meeting_room_outlined,
                ),
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: _roomCountController,
              keyboardType: TextInputType.number,
              onChanged: (_) {
                setState(() {});
              },
              decoration: const InputDecoration(
                labelText: 'Number of Rooms',
                hintText: 'Example: 5',
                prefixIcon: Icon(
                  Icons.meeting_room_rounded,
                ),
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: _bedController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Beds per Room',
                hintText: 'Example: 4',
                prefixIcon: Icon(
                  Icons.bed_outlined,
                ),
              ),
            ),

            if (preview.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rooms to be created',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: preview.map(
                        (room) {
                          return Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFFEFF6FF),
                              borderRadius:
                                  BorderRadius.circular(7),
                            ),
                            child: Text(
                              room,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight:
                                    FontWeight.w600,
                                color:
                                    Color(0xFF2563EB),
                              ),
                            ),
                          );
                        },
                      ).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving
              ? null
              : () {
                  FocusScope.of(context).unfocus();
                  Navigator.pop(
                    context,
                    false,
                  );
                },
          child: const Text('Cancel'),
        ),

        FilledButton(
          onPressed: _saving
              ? null
              : _saveRooms,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save Rooms'),
        ),
      ],
    );
  }

  List<String> _generatePreview(
    String start,
    int count,
  ) {
    final match = RegExp(
      r'^(.*?)(\d+)$',
    ).firstMatch(start);

    if (match == null) {
      if (count == 1) {
        return [start];
      }

      return List.generate(
        count,
        (index) => '$start ${index + 1}',
      );
    }

    final prefix = match.group(1) ?? '';
    final numberPart = match.group(2)!;
    final startNumber = int.parse(numberPart);
    final width = numberPart.length;

    return List.generate(
      count,
      (index) {
        final number =
            (startNumber + index).toString().padLeft(
                  width,
                  '0',
                );

        return '$prefix$number';
      },
    );
  }

  Future<void> _saveRooms() async {
    final startRoomNumber =
        _roomController.text.trim();

    final roomCount =
        int.tryParse(
      _roomCountController.text.trim(),
    );

    final bedCount =
        int.tryParse(
      _bedController.text.trim(),
    );

    if (startRoomNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter starting room number',
          ),
        ),
      );
      return;
    }

    if (roomCount == null ||
        roomCount < 1 ||
        roomCount > 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Number of rooms must be between 1 and 50',
          ),
        ),
      );
      return;
    }

    if (bedCount == null ||
        bedCount < 1 ||
        bedCount > 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Beds must be between 1 and 20',
          ),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    // Use the callback supplied by BuildingSetupScreen.
    // Do not try to find the parent State from the dialog context.
    final success = await widget.onSave(
      startRoomNumber,
      roomCount,
      bedCount,
    );

    if (!mounted) return;

    if (success) {
      FocusScope.of(context).unfocus();
      Navigator.pop(
        context,
        true,
      );
    } else {
      setState(() {
        _saving = false;
      });
    }
  }
}
