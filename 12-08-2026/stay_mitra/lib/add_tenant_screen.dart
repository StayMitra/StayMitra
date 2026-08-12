import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'building_model.dart';
import 'database_helper.dart';
import 'tenant_model.dart';

class AddTenantScreen extends StatefulWidget {
  const AddTenantScreen({super.key});

  @override
  State<AddTenantScreen> createState() => _AddTenantScreenState();
}

class _AddTenantScreenState extends State<AddTenantScreen> {
  final _formKey = GlobalKey<FormState>();

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _phoneController =
      TextEditingController();

  final TextEditingController _alternatePhoneController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _idProofNumberController =
      TextEditingController();

  final TextEditingController _rentController =
      TextEditingController();

  final TextEditingController _securityDepositController =
      TextEditingController();

  // ============================================================
  // IMAGE PICKER
  // ============================================================

  final ImagePicker _imagePicker = ImagePicker();

  File? _idProofPhoto;

  static const int _maxPhotoSizeBytes = 150 * 1024;

  // ============================================================
  // DATA
  // ============================================================

  List<BuildingModel> _buildings = [];
  List<FloorModel> _floors = [];
  List<RoomModel> _rooms = [];
  List<BedModel> _beds = [];

  BuildingModel? _selectedBuilding;
  FloorModel? _selectedFloor;
  RoomModel? _selectedRoom;
  BedModel? _selectedBed;

  String? _selectedIdProofType;

  DateTime _joiningDate = DateTime.now();

  bool _isLoading = true;
  bool _isSaving = false;

  // ============================================================
  // ID PROOF TYPES
  // ============================================================

  final List<String> _idProofTypes = [
    'Aadhaar',
    'PAN',
    'Passport',
    'Driving Licence',
    'Voter ID',
    'Other',
  ];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadBuildings();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _alternatePhoneController.dispose();
    _emailController.dispose();
    _idProofNumberController.dispose();
    _rentController.dispose();
    _securityDepositController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD BUILDINGS
  // ============================================================

  Future<void> _loadBuildings() async {
    try {
      final buildings =
          await DatabaseHelper.instance.getBuildings();

      if (!mounted) {
        return;
      }

      setState(() {
        _buildings = buildings;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showError(
        'Unable to load buildings.',
      );
    }
  }

  // ============================================================
  // SELECT BUILDING
  // ============================================================

  Future<void> _selectBuilding(
    BuildingModel? building,
  ) async {
    if (building == null) {
      setState(() {
        _selectedBuilding = null;
        _selectedFloor = null;
        _selectedRoom = null;
        _selectedBed = null;

        _floors = [];
        _rooms = [];
        _beds = [];
      });

      return;
    }

    setState(() {
      _selectedBuilding = building;

      _selectedFloor = null;
      _selectedRoom = null;
      _selectedBed = null;

      _floors = [];
      _rooms = [];
      _beds = [];
    });

    try {
      final floors =
          await DatabaseHelper.instance.getFloors(
        building.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _floors = floors;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(
        'Unable to load floors.',
      );
    }
  }

  // ============================================================
  // SELECT FLOOR
  // ============================================================

  Future<void> _selectFloor(
    FloorModel? floor,
  ) async {
    if (floor == null) {
      setState(() {
        _selectedFloor = null;
        _selectedRoom = null;
        _selectedBed = null;

        _rooms = [];
        _beds = [];
      });

      return;
    }

    setState(() {
      _selectedFloor = floor;

      _selectedRoom = null;
      _selectedBed = null;

      _rooms = [];
      _beds = [];
    });

    try {
      final rooms =
          await DatabaseHelper.instance.getRooms(
        floor.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _rooms = rooms;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(
        'Unable to load rooms.',
      );
    }
  }

  // ============================================================
  // SELECT ROOM
  // ============================================================

  Future<void> _selectRoom(
    RoomModel? room,
  ) async {
    if (room == null) {
      setState(() {
        _selectedRoom = null;
        _selectedBed = null;
        _beds = [];
      });

      return;
    }

    setState(() {
      _selectedRoom = room;
      _selectedBed = null;
      _beds = [];
    });

    try {
      final beds =
          await DatabaseHelper.instance.getAvailableBeds(
        room.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _beds = beds;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(
        'Unable to load available beds.',
      );
    }
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _pickJoiningDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _joiningDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _joiningDate = selectedDate;
    });
  }

  // ============================================================
  // ID PROOF PHOTO
  // ============================================================

  Future<void> _showPhotoSourceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              18,
              20,
              20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'Select ID Proof Photo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Photos above 150 KB will be compressed automatically',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      child: _photoSourceButton(
                        icon: Icons.camera_alt_rounded,
                        title: 'Camera',
                        onTap: () {
                          Navigator.pop(context);
                          _pickIdProofPhoto(
                            ImageSource.camera,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _photoSourceButton(
                        icon: Icons.photo_library_rounded,
                        title: 'Gallery',
                        onTap: () {
                          Navigator.pop(context);
                          _pickIdProofPhoto(
                            ImageSource.gallery,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _photoSourceButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 18,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: const Color(0xFF2563EB),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickIdProofPhoto(
    ImageSource source,
  ) async {
    try {
      // Pick the original photo first.
      // Photos larger than 150 KB are compressed automatically.
      final XFile? pickedFile =
          await _imagePicker.pickImage(
        source: source,
      );

      if (pickedFile == null) {
        return;
      }

      final originalFile = File(pickedFile.path);
      final originalSize = await originalFile.length();

      // If already <= 150 KB, keep the original file.
      if (originalSize <= _maxPhotoSizeBytes) {
        if (!mounted) {
          return;
        }

        setState(() {
          _idProofPhoto = originalFile;
        });

        return;
      }

      // If larger than 150 KB, compress automatically.
      final compressedFile =
          await _compressPhotoTo150KB(originalFile);

      if (compressedFile == null) {
        if (!mounted) {
          return;
        }

        _showError(
          'Unable to compress the photo below 150 KB. Please select another photo.',
        );
        return;
      }

      final compressedSize =
          await compressedFile.length();

      if (compressedSize > _maxPhotoSizeBytes) {
        if (!mounted) {
          return;
        }

        _showError(
          'Unable to prepare the photo within 150 KB.',
        );
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _idProofPhoto = compressedFile;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Photo compressed to ${_formatPhotoSize(compressedSize)}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(
        'Unable to select ID proof photo.',
      );
    }
  }

  // ============================================================
  // COMPRESS PHOTO TO <= 150 KB
  // ============================================================

  Future<File?> _compressPhotoTo150KB(
    File originalFile,
  ) async {
    try {
      final tempDirectory =
          await getTemporaryDirectory();

      final timestamp =
          DateTime.now().millisecondsSinceEpoch;

      final outputPath =
          '${tempDirectory.path}/id_proof_$timestamp.jpg';

      const qualities = [
        90,
        85,
        80,
        75,
        70,
        65,
        60,
        55,
        50,
        45,
        40,
        35,
        30,
      ];

      const dimensions = [
        1600,
        1400,
        1200,
        1000,
        900,
        800,
        700,
      ];

      for (final maxDimension in dimensions) {
        for (final quality in qualities) {
          final compressedBytes =
              await FlutterImageCompress.compressWithFile(
            originalFile.path,
            quality: quality,
            format: CompressFormat.jpeg,
            minWidth: maxDimension,
            minHeight: maxDimension,
          );

          if (compressedBytes == null ||
              compressedBytes.isEmpty) {
            continue;
          }

          final compressedFile = File(outputPath);

          await compressedFile.writeAsBytes(
            compressedBytes,
            flush: true,
          );

          final compressedSize =
              await compressedFile.length();

          if (compressedSize <= _maxPhotoSizeBytes) {
            return compressedFile;
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  void _removeIdProofPhoto() {
    setState(() {
      _idProofPhoto = null;
    });
  }

  String _formatPhotoSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }

    final kb = bytes / 1024;

    return '${kb.toStringAsFixed(1)} KB';
  }

  // ============================================================
  // MONEY PARSER
  // ============================================================

  double _parseAmount(
    String value,
  ) {
    return double.tryParse(
          value.trim().replaceAll(',', ''),
        ) ??
        0;
  }

  // ============================================================
  // SAVE TENANT
  // ============================================================

  Future<void> _saveTenant() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedBuilding == null) {
      _showError(
        'Please select a building.',
      );
      return;
    }

    if (_selectedFloor == null) {
      _showError(
        'Please select a floor.',
      );
      return;
    }

    if (_selectedRoom == null) {
      _showError(
        'Please select a room.',
      );
      return;
    }

    if (_selectedBed == null) {
      _showError(
        'Please select an available bed.',
      );
      return;
    }

    // ----------------------------------------------------------
    // FINAL PHOTO SIZE CHECK
    // ----------------------------------------------------------
    // Normally the photo is already <= 150 KB because compression
    // happens immediately after selection. This is an additional
    // safety check before saving.

    if (_idProofPhoto != null) {
      final photoSize =
          await _idProofPhoto!.length();

      if (photoSize > _maxPhotoSizeBytes) {
        final compressedFile =
            await _compressPhotoTo150KB(
          _idProofPhoto!,
        );

        if (compressedFile == null) {
          _showError(
            'ID proof photo could not be prepared within 150 KB.',
          );
          return;
        }

        final compressedSize =
            await compressedFile.length();

        if (compressedSize > _maxPhotoSizeBytes) {
          _showError(
            'ID proof photo could not be prepared within 150 KB.',
          );
          return;
        }

        _idProofPhoto = compressedFile;
      }
    }

    final monthlyRent =
        _parseAmount(
      _rentController.text,
    );

    final securityDeposit =
        _parseAmount(
      _securityDepositController.text,
    );

    if (monthlyRent <= 0) {
      _showError(
        'Please enter a valid monthly rent.',
      );
      return;
    }

    if (securityDeposit < 0) {
      _showError(
        'Please enter a valid security deposit.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final tenant = TenantModel(
        id: DateTime.now()
            .microsecondsSinceEpoch
            .toString(),

        bedId:
            _selectedBed!.id,

        fullName:
            _nameController.text.trim(),

        phone:
            _phoneController.text.trim(),

        alternatePhone:
            _alternatePhoneController.text
                    .trim()
                    .isEmpty
                ? null
                : _alternatePhoneController
                    .text
                    .trim(),

        email:
            _emailController.text
                    .trim()
                    .isEmpty
                ? null
                : _emailController.text
                    .trim(),

        idProofType:
            _selectedIdProofType,

        idProofNumber:
            _idProofNumberController.text
                    .trim()
                    .isEmpty
                ? null
                : _idProofNumberController
                    .text
                    .trim(),

        joiningDate:
            _joiningDate,

        monthlyRent:
            monthlyRent,

        securityDeposit:
            securityDeposit,

        status:
            'active',

        createdAt:
            DateTime.now(),
      );

      await DatabaseHelper.instance.insertTenant(
        tenant,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${tenant.fullName} added successfully',
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      String message =
          'Unable to add tenant.';

      final error =
          e.toString().toLowerCase();

      if (error.contains(
        'already occupied',
      )) {
        message =
            'This bed is already occupied. Please select another bed.';
      } else if (error.contains(
        'does not exist',
      )) {
        message =
            'The selected bed no longer exists. Please select another bed.';
      } else if (error.contains(
        'unique',
      )) {
        message =
            'This bed already has an active tenant.';
      }

      _showError(message);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  void _showError(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
        backgroundColor:
            const Color(0xFFDC2626),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F9FC),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor:
            const Color(0xFF111827),

        title: const Text(
          'Add Tenant',
          style: TextStyle(
            fontSize: 20,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : Form(
              key: _formKey,

              child:
                  SingleChildScrollView(
                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  18,
                  16,
                  30,
                ),

                child: Center(
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(
                      maxWidth: 900,
                    ),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [
                        _buildLocationSection(),

                        const SizedBox(
                          height: 18,
                        ),

                        _buildTenantDetailsSection(),

                        const SizedBox(
                          height: 18,
                        ),

                        _buildIdProofSection(),

                        const SizedBox(
                          height: 18,
                        ),

                        _buildRentSection(),

                        const SizedBox(
                          height: 24,
                        ),

                        _buildSaveButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  // ============================================================
  // LOCATION SECTION
  // ============================================================

  Widget _buildLocationSection() {
    return _sectionCard(
      icon:
          Icons.location_city_rounded,
      iconColor:
          const Color(0xFF2563EB),
      title:
          'Room Allocation',
      subtitle:
          'Select the building, floor, room and available bed.',
      children: [
        _buildDropdown<BuildingModel>(
          label: 'Building',
          hint: 'Select Building',
          value:
              _selectedBuilding,
          items:
              _buildings,
          itemLabel:
              (building) =>
                  building.name,
          icon:
              Icons.apartment_rounded,
          onChanged:
              _selectBuilding,
        ),

        const SizedBox(
          height: 14,
        ),

        _buildDropdown<FloorModel>(
          label: 'Floor',
          hint:
              _selectedBuilding == null
                  ? 'Select building first'
                  : _floors.isEmpty
                      ? 'No floors available'
                      : 'Select Floor',
          value:
              _selectedFloor,
          items:
              _floors,
          itemLabel:
              (floor) =>
                  floor.name,
          icon:
              Icons.layers_rounded,
          enabled:
              _selectedBuilding !=
                      null &&
                  _floors.isNotEmpty,
          onChanged:
              _selectFloor,
        ),

        const SizedBox(
          height: 14,
        ),

        _buildDropdown<RoomModel>(
          label: 'Room',
          hint:
              _selectedFloor == null
                  ? 'Select floor first'
                  : _rooms.isEmpty
                      ? 'No rooms available'
                      : 'Select Room',
          value:
              _selectedRoom,
          items:
              _rooms,
          itemLabel:
              (room) =>
                  'Room ${room.roomNumber}',
          icon:
              Icons.meeting_room_rounded,
          enabled:
              _selectedFloor !=
                      null &&
                  _rooms.isNotEmpty,
          onChanged:
              _selectRoom,
        ),

        const SizedBox(
          height: 14,
        ),

        // --------------------------------------------------------
        // AVAILABLE BED
        // --------------------------------------------------------

        _buildDropdown<BedModel>(
          label:
              'Available Bed',
          hint:
              _selectedRoom == null
                  ? 'Select room first'
                  : _beds.isEmpty
                      ? 'No available beds'
                      : 'Select Bed',
          value:
              _selectedBed,
          items:
              _beds,

          // IMPORTANT:
          // bed.bedNumber already contains "Bed 1".
          // So do not add "Bed " again.
          itemLabel:
              (bed) =>
                  bed.bedNumber,

          icon:
              Icons.bed_rounded,

          enabled:
              _selectedRoom !=
                      null &&
                  _beds.isNotEmpty,

          onChanged:
              (bed) async {
            setState(() {
              _selectedBed = bed;
            });
          },
        ),

        if (_selectedRoom != null &&
            _beds.isEmpty)
          Padding(
            padding:
                const EdgeInsets.only(
              top: 12,
            ),
            child:
                Container(
              width:
                  double.infinity,
              padding:
                  const EdgeInsets.all(
                12,
              ),
              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xFFFEF2F2,
                ),
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
                border:
                    Border.all(
                  color:
                      const Color(
                    0xFFFECACA,
                  ),
                ),
              ),
              child:
                  const Row(
                children: [
                  Icon(
                    Icons
                        .info_outline_rounded,
                    size:
                        20,
                    color:
                        Color(
                      0xFFDC2626,
                    ),
                  ),
                  SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child:
                        Text(
                      'There are no available beds in this room.',
                      style:
                          TextStyle(
                        fontSize:
                            12,
                        color:
                            Color(
                          0xFF991B1B,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        if (_selectedBed != null)
          Padding(
            padding:
                const EdgeInsets.only(
              top: 12,
            ),
            child:
                _selectedBedSummary(),
          ),
      ],
    );
  }

  // ============================================================
  // SELECTED BED SUMMARY
  // ============================================================

  Widget _selectedBedSummary() {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(
        13,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(
          0xFFF0FDF4,
        ),
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        border:
            Border.all(
          color:
              const Color(
            0xFFBBF7D0,
          ),
        ),
      ),
      child:
          Row(
        children: [
          const Icon(
            Icons
                .check_circle_rounded,
            color:
                Color(
              0xFF16A34A,
            ),
            size:
                22,
          ),
          const SizedBox(
            width: 9,
          ),
          Expanded(
            child:
                Text(
              '${_selectedBuilding!.name} • '
              '${_selectedFloor!.name} • '
              'Room ${_selectedRoom!.roomNumber} • '
              '${_selectedBed!.bedNumber}',
              style:
                  const TextStyle(
                fontSize:
                    12,
                fontWeight:
                    FontWeight.w600,
                color:
                    Color(
                  0xFF166534,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TENANT DETAILS SECTION
  // ============================================================

  Widget _buildTenantDetailsSection() {
    return _sectionCard(
      icon:
          Icons.person_rounded,
      iconColor:
          const Color(
        0xFF16A34A,
      ),
      title:
          'Tenant Details',
      subtitle:
          "Enter the tenant's basic contact information.",
      children: [
        _buildTextField(
          controller:
              _nameController,
          label:
              'Full Name',
          hint:
              'Enter tenant full name',
          icon:
              Icons.person_outline_rounded,
          requiredField:
              true,
          textCapitalization:
              TextCapitalization.words,
          validator:
              (value) {
            if (value ==
                    null ||
                value
                    .trim()
                    .isEmpty) {
              return 'Please enter full name';
            }

            if (value
                    .trim()
                    .length <
                2) {
              return 'Please enter a valid name';
            }

            return null;
          },
        ),

        const SizedBox(
          height: 14,
        ),

        _buildTextField(
          controller:
              _phoneController,
          label:
              'Phone Number',
          hint:
              'Enter 10-digit phone number',
          icon:
              Icons.phone_outlined,
          requiredField:
              true,
          keyboardType:
              TextInputType.phone,
          maxLength:
              10,
          validator:
              (value) {
            final phone =
                value?.trim() ??
                    '';

            if (phone.isEmpty) {
              return 'Please enter phone number';
            }

            if (!RegExp(
              r'^[6-9][0-9]{9}$',
            ).hasMatch(phone)) {
              return 'Enter a valid 10-digit phone number';
            }

            return null;
          },
        ),

        const SizedBox(
          height: 14,
        ),

        _buildTextField(
          controller:
              _alternatePhoneController,
          label:
              'Alternate Phone',
          hint:
              'Optional',
          icon:
              Icons.phone_in_talk_outlined,
          keyboardType:
              TextInputType.phone,
          maxLength:
              10,
          validator:
              (value) {
            final phone =
                value?.trim() ??
                    '';

            if (phone.isEmpty) {
              return null;
            }

            if (!RegExp(
              r'^[6-9][0-9]{9}$',
            ).hasMatch(phone)) {
              return 'Enter a valid 10-digit phone number';
            }

            return null;
          },
        ),

        const SizedBox(
          height: 14,
        ),

        _buildTextField(
          controller:
              _emailController,
          label:
              'Email',
          hint:
              'Optional',
          icon:
              Icons.email_outlined,
          keyboardType:
              TextInputType.emailAddress,
          validator:
              (value) {
            final email =
                value?.trim() ??
                    '';

            if (email.isEmpty) {
              return null;
            }

            if (!RegExp(
              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
            ).hasMatch(email)) {
              return 'Enter a valid email address';
            }

            return null;
          },
        ),

        const SizedBox(
          height: 14,
        ),

        _buildJoiningDate(),
      ],
    );
  }

  // ============================================================
  // ID PROOF SECTION
  // ============================================================

  Widget _buildIdProofSection() {
    return _sectionCard(
      icon:
          Icons.badge_rounded,
      iconColor:
          const Color(
        0xFF7C3AED,
      ),
      title:
          'ID Proof',
      subtitle:
          'Add identification details and photo if available.',
      children: [
        _buildDropdown<String>(
          label:
              'ID Proof Type',
          hint:
              'Select ID proof',
          value:
              _selectedIdProofType,
          items:
              _idProofTypes,
          itemLabel:
              (type) => type,
          icon:
              Icons.badge_outlined,
          onChanged:
              (value) async {
            setState(() {
              _selectedIdProofType =
                  value;
            });
          },
        ),

        const SizedBox(
          height: 14,
        ),

        _buildTextField(
          controller:
              _idProofNumberController,
          label:
              'ID Proof Number',
          hint:
              _selectedIdProofType ==
                      null
                  ? 'Optional'
                  : 'Enter $_selectedIdProofType number',
          icon:
              Icons.numbers_rounded,
          textCapitalization:
              TextCapitalization.characters,
          validator:
              (value) {
            if (_selectedIdProofType !=
                    null &&
                (value ==
                        null ||
                    value
                        .trim()
                        .isEmpty)) {
              return 'Please enter ID proof number';
            }

            return null;
          },
        ),

        const SizedBox(
          height: 14,
        ),

        _buildIdProofPhotoPicker(),
      ],
    );
  }

  // ============================================================
  // ID PROOF PHOTO PICKER
  // ============================================================

  Widget _buildIdProofPhotoPicker() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'ID Proof Photo',
          style: TextStyle(
            fontSize: 13,
            fontWeight:
                FontWeight.w600,
            color:
                Color(0xFF374151),
          ),
        ),

        const SizedBox(
          height: 7,
        ),

        if (_idProofPhoto == null)
          InkWell(
            borderRadius:
                BorderRadius.circular(
              14,
            ),
            onTap:
                _showPhotoSourceSheet,
            child:
                Container(
              width:
                  double.infinity,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 16,
              ),
              decoration:
                  BoxDecoration(
                color:
                    Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
                border:
                    Border.all(
                  color:
                      const Color(
                    0xFFD1D5DB,
                  ),
                ),
              ),
              child:
                  Row(
                children: [
                  Container(
                    width:
                        42,
                    height:
                        42,
                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFFF3E8FF,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                    child:
                        const Icon(
                      Icons
                          .add_a_photo_rounded,
                      color:
                          Color(
                        0xFF7C3AED,
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  const Expanded(
                    child:
                        Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          'Add ID Proof Photo',
                          style:
                              TextStyle(
                            fontSize:
                                14,
                            fontWeight:
                                FontWeight.w600,
                            color:
                                Color(
                              0xFF111827,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 3,
                        ),
                        Text(
                          'Camera or Gallery • Auto-compressed to 150 KB',
                          style:
                              TextStyle(
                            fontSize:
                                11,
                            color:
                                Color(
                              0xFF6B7280,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons
                        .chevron_right_rounded,
                    color:
                        Color(
                      0xFF6B7280,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          _selectedPhotoPreview(),

        const SizedBox(
          height: 6,
        ),

        const Text(
          'Photo is optional. Photos above 150 KB are automatically compressed to 150 KB or less.',
          style: TextStyle(
            fontSize: 11,
            color:
                Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SELECTED PHOTO PREVIEW
  // ============================================================

  Widget _selectedPhotoPreview() {
    return FutureBuilder<int>(
      future:
          _idProofPhoto!.length(),
      builder:
          (context, snapshot) {
        final size =
            snapshot.data ?? 0;

        return Container(
          width:
              double.infinity,
          padding:
              const EdgeInsets.all(
            12,
          ),
          decoration:
              BoxDecoration(
            color:
                const Color(
              0xFFF8FAFC,
            ),
            borderRadius:
                BorderRadius.circular(
              14,
            ),
            border:
                Border.all(
              color:
                  const Color(
                0xFFD1D5DB,
              ),
            ),
          ),
          child:
              Row(
            children: [
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
                child:
                    Image.file(
                  _idProofPhoto!,
                  width:
                      72,
                  height:
                      72,
                  fit:
                      BoxFit.cover,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    const Text(
                      'ID Proof Photo Selected',
                      style:
                          TextStyle(
                        fontSize:
                            13,
                        fontWeight:
                            FontWeight.w600,
                        color:
                            Color(
                          0xFF111827,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      snapshot
                                  .hasData &&
                              size >
                                  0
                          ? _formatPhotoSize(
                              size,
                            )
                          : 'Checking size...',
                      style:
                          const TextStyle(
                        fontSize:
                            11,
                        color:
                            Color(
                          0xFF6B7280,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    const Text(
                      '150 KB or less',
                      style:
                          TextStyle(
                        fontSize:
                            11,
                        color:
                            Color(
                          0xFF16A34A,
                        ),
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                tooltip:
                    'Remove photo',
                onPressed:
                    _removeIdProofPhoto,
                icon:
                    const Icon(
                  Icons
                      .delete_outline_rounded,
                  color:
                      Color(
                    0xFFDC2626,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // RENT SECTION
  // ============================================================

  Widget _buildRentSection() {
    return _sectionCard(
      icon:
          Icons.currency_rupee_rounded,
      iconColor:
          const Color(
        0xFFF97316,
      ),
      title:
          'Rent & Deposit',
      subtitle:
          "Enter the tenant's monthly rent and security deposit.",
      children: [
        _buildTextField(
          controller:
              _rentController,
          label:
              'Monthly Rent',
          hint:
              'Example: 8000',
          icon:
              Icons.currency_rupee_rounded,
          requiredField:
              true,
          keyboardType:
              const TextInputType
                  .numberWithOptions(
            decimal: true,
          ),
          validator:
              (value) {
            final amount =
                _parseAmount(
              value ?? '',
            );

            if (value ==
                    null ||
                value
                    .trim()
                    .isEmpty) {
              return 'Please enter monthly rent';
            }

            if (amount <=
                0) {
              return 'Enter a valid rent amount';
            }

            return null;
          },
        ),

        const SizedBox(
          height: 14,
        ),

        _buildTextField(
          controller:
              _securityDepositController,
          label:
              'Security Deposit',
          hint:
              'Example: 10000',
          icon:
              Icons.account_balance_wallet_outlined,
          keyboardType:
              const TextInputType
                  .numberWithOptions(
            decimal: true,
          ),
          validator:
              (value) {
            if (value ==
                    null ||
                value
                    .trim()
                    .isEmpty) {
              return null;
            }

            final amount =
                _parseAmount(
              value,
            );

            if (amount <
                0) {
              return 'Enter a valid deposit amount';
            }

            return null;
          },
        ),

        const SizedBox(
          height: 14,
        ),

        Container(
          width:
              double.infinity,
          padding:
              const EdgeInsets.all(
            13,
          ),
          decoration:
              BoxDecoration(
            color:
                const Color(
              0xFFFFF7ED,
            ),
            borderRadius:
                BorderRadius.circular(
              12,
            ),
            border:
                Border.all(
              color:
                  const Color(
                0xFFFED7AA,
              ),
            ),
          ),
          child:
              const Row(
            children: [
              Icon(
                Icons
                    .info_outline_rounded,
                size:
                    20,
                color:
                    Color(
                  0xFFEA580C,
                ),
              ),
              SizedBox(
                width: 8,
              ),
              Expanded(
                child:
                    Text(
                  'The selected bed will automatically be marked as Occupied after saving.',
                  style:
                      TextStyle(
                    fontSize:
                        12,
                    color:
                        Color(
                      0xFF9A3412,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // JOINING DATE
  // ============================================================

  Widget _buildJoiningDate() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Joining Date',
          style:
              TextStyle(
            fontSize:
                13,
            fontWeight:
                FontWeight.w600,
            color:
                Color(
              0xFF374151,
            ),
          ),
        ),

        const SizedBox(
          height: 7,
        ),

        InkWell(
          borderRadius:
              BorderRadius.circular(
            14,
          ),
          onTap:
              _pickJoiningDate,
          child:
              Container(
            width:
                double.infinity,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 15,
            ),
            decoration:
                BoxDecoration(
              color:
                  Colors.white,
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
              border:
                  Border.all(
                color:
                    const Color(
                  0xFFD1D5DB,
                ),
              ),
            ),
            child:
                Row(
              children: [
                const Icon(
                  Icons
                      .calendar_today_rounded,
                  size:
                      20,
                  color:
                      Color(
                    0xFF2563EB,
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child:
                      Text(
                    _formatDate(
                      _joiningDate,
                    ),
                    style:
                        const TextStyle(
                      fontSize:
                          14,
                      color:
                          Color(
                        0xFF111827,
                      ),
                    ),
                  ),
                ),

                const Icon(
                  Icons
                      .keyboard_arrow_down_rounded,
                  color:
                      Color(
                    0xFF6B7280,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SAVE BUTTON
  // ============================================================

  Widget _buildSaveButton() {
    return SizedBox(
      width:
          double.infinity,
      height:
          52,
      child:
          FilledButton.icon(
        onPressed:
            _isSaving
                ? null
                : _saveTenant,
        icon:
            _isSaving
                ? const SizedBox(
                    width:
                        20,
                    height:
                        20,
                    child:
                        CircularProgressIndicator(
                      strokeWidth:
                          2,
                      color:
                          Colors.white,
                    ),
                  )
                : const Icon(
                    Icons
                        .person_add_alt_1_rounded,
                  ),
        label:
            Text(
          _isSaving
              ? 'Saving Tenant...'
              : 'Add Tenant',
          style:
              const TextStyle(
            fontSize:
                15,
            fontWeight:
                FontWeight.w600,
          ),
        ),
        style:
            FilledButton.styleFrom(
          backgroundColor:
              const Color(
            0xFF2563EB,
          ),
          foregroundColor:
              Colors.white,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              14,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _sectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(
        18,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.white,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        border:
            Border.all(
          color:
              const Color(
            0xFFE5E7EB,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha:
                  0.02,
            ),
            blurRadius:
                8,
            offset:
                const Offset(
              0,
              2,
            ),
          ),
        ],
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
        children: [
          Row(
            children: [
              Container(
                width:
                    42,
                height:
                    42,
                decoration:
                    BoxDecoration(
                  color:
                      iconColor.withValues(
                    alpha:
                        0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
                child:
                    Icon(
                  icon,
                  color:
                      iconColor,
                  size:
                      22,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      title,
                      style:
                          const TextStyle(
                        fontSize:
                            17,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Color(
                          0xFF111827,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      subtitle,
                      style:
                          const TextStyle(
                        fontSize:
                            11,
                        color:
                            Color(
                          0xFF6B7280,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 18,
          ),

          ...children,
        ],
      ),
    );
  }

  // ============================================================
  // DROPDOWN
  // ============================================================

  Widget _buildDropdown<T>({
    required String label,
    required String hint,
    required T? value,
    required List<T> items,
    required String Function(T item) itemLabel,
    required IconData icon,
    required Future<void> Function(T? value) onChanged,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
              const TextStyle(
            fontSize:
                13,
            fontWeight:
                FontWeight.w600,
            color:
                Color(
              0xFF374151,
            ),
          ),
        ),

        const SizedBox(
          height: 7,
        ),

        DropdownButtonFormField<T>(
          initialValue:
              value,
          isExpanded:
              true,
          decoration:
              InputDecoration(
            prefixIcon:
                Icon(
              icon,
              size:
                  20,
              color:
                  const Color(
                0xFF6B7280,
              ),
            ),
            hintText:
                hint,
            hintStyle:
                const TextStyle(
              fontSize:
                  13,
              color:
                  Color(
                0xFF9CA3AF,
              ),
            ),
            filled:
                true,
            fillColor:
                enabled
                    ? Colors.white
                    : const Color(
                        0xFFF3F4F6,
                      ),
            contentPadding:
                const EdgeInsets
                    .symmetric(
              horizontal:
                  12,
              vertical:
                  4,
            ),
            border:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
              borderSide:
                  const BorderSide(
                color:
                    Color(
                  0xFFD1D5DB,
                ),
              ),
            ),
            enabledBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
              borderSide:
                  const BorderSide(
                color:
                    Color(
                  0xFFD1D5DB,
                ),
              ),
            ),
            focusedBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
              borderSide:
                  const BorderSide(
                color:
                    Color(
                  0xFF2563EB,
                ),
                width:
                    1.5,
              ),
            ),
          ),
          items:
              enabled
                  ? items
                      .map(
                        (
                          item,
                        ) {
                          return DropdownMenuItem<T>(
                            value:
                                item,
                            child:
                                Text(
                              itemLabel(
                                item,
                              ),
                              overflow:
                                  TextOverflow.ellipsis,
                              style:
                                  const TextStyle(
                                fontSize:
                                    14,
                                color:
                                    Color(
                                  0xFF111827,
                                ),
                              ),
                            ),
                          );
                        },
                      )
                      .toList()
                  : null,
          onChanged:
              enabled
                  ? (
                      value,
                    ) async {
                      await onChanged(
                        value,
                      );
                    }
                  : null,
        ),
      ],
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool requiredField = false,
    TextInputType? keyboardType,
    int? maxLength,
    TextCapitalization textCapitalization =
        TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        RichText(
          text:
              TextSpan(
            text:
                label,
            style:
                const TextStyle(
              fontSize:
                  13,
              fontWeight:
                  FontWeight.w600,
              color:
                  Color(
                0xFF374151,
              ),
            ),
            children:
                requiredField
                    ? const [
                        TextSpan(
                          text:
                              ' *',
                          style:
                              TextStyle(
                            color:
                                Color(
                              0xFFDC2626,
                            ),
                          ),
                        ),
                      ]
                    : null,
          ),
        ),

        const SizedBox(
          height: 7,
        ),

        TextFormField(
          controller:
              controller,
          keyboardType:
              keyboardType,
          textCapitalization:
              textCapitalization,
          maxLength:
              maxLength,
          validator:
              validator,
          decoration:
              InputDecoration(
            prefixIcon:
                Icon(
              icon,
              size:
                  20,
              color:
                  const Color(
                0xFF6B7280,
              ),
            ),
            hintText:
                hint,
            hintStyle:
                const TextStyle(
              fontSize:
                  13,
              color:
                  Color(
                0xFF9CA3AF,
              ),
            ),
            counterText:
                maxLength !=
                        null
                    ? ''
                    : null,
            filled:
                true,
            fillColor:
                Colors.white,
            contentPadding:
                const EdgeInsets
                    .symmetric(
              horizontal:
                  12,
              vertical:
                  15,
            ),
            border:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
              borderSide:
                  const BorderSide(
                color:
                    Color(
                  0xFFD1D5DB,
                ),
              ),
            ),
            enabledBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
              borderSide:
                  const BorderSide(
                color:
                    Color(
                  0xFFD1D5DB,
                ),
              ),
            ),
            focusedBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
              borderSide:
                  const BorderSide(
                color:
                    Color(
                  0xFF2563EB,
                ),
                width:
                    1.5,
              ),
            ),
            errorBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
              borderSide:
                  const BorderSide(
                color:
                    Color(
                  0xFFDC2626,
                ),
              ),
            ),
            focusedErrorBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
              borderSide:
                  const BorderSide(
                color:
                    Color(
                  0xFFDC2626,
                ),
                width:
                    1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDate(
    DateTime date,
  ) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} '
        '${months[date.month - 1]} '
        '${date.year}';
  }
}