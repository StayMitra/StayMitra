import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Upload Register
///
/// This screen is designed for PG owners who already maintain their
/// tenant/register details in a physical book.
/// The owner can upload/capture register photos, review the extracted
/// tenant information, edit it, and finally add the confirmed tenants.
///
/// OCR/AI extraction is intentionally kept behind a small local method so
/// that a real OCR/API service can be connected later without changing
/// the screen flow.
class UploadRegisterScreen extends StatefulWidget {
  const UploadRegisterScreen({super.key});

  @override
  State<UploadRegisterScreen> createState() =>
      _UploadRegisterScreenState();
}

class _UploadRegisterScreenState extends State<UploadRegisterScreen> {
  final ImagePicker _picker = ImagePicker();

  final List<XFile> _registerImages = [];
  final List<_ExtractedTenant> _tenants = [];

  bool _isProcessing = false;

  // ------------------------------------------------------------
  // IMAGE PICKING
  // ------------------------------------------------------------

  Future<void> _showImageSourceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Upload Register',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Take a clear photo of your tenant register or select photos from your phone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 20),

                // CAMERA OPTION
                _sourceOption(
                  icon: Icons.camera_alt_rounded,
                  title: 'Take Photo',
                  subtitle: 'Capture a register page using camera',
                  onTap: () {
                    Navigator.pop(context);
                    _takePhoto();
                  },
                ),

                const SizedBox(height: 10),

                // GALLERY OPTION
                _sourceOption(
                  icon: Icons.photo_library_rounded,
                  title: 'Choose from Gallery',
                  subtitle: 'Select one or more register photos',
                  onTap: () {
                    Navigator.pop(context);
                    _pickFromGallery();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sourceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
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
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // CAMERA
  // ------------------------------------------------------------

  Future<void> _takePhoto() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image == null) return;

      if (!mounted) return;

      setState(() {
        _registerImages.add(image);
      });

      await _processRegister();
    } catch (e) {
      _showMessage(
        'Unable to open camera. Please check camera permission and try again.',
      );
    }
  }

  // ------------------------------------------------------------
  // GALLERY
  // ------------------------------------------------------------

  Future<void> _pickFromGallery() async {
    try {
      final images = await _picker.pickMultiImage(
        imageQuality: 90,
      );

      if (images.isEmpty) return;

      if (!mounted) return;

      setState(() {
        _registerImages.addAll(images);
      });

      await _processRegister();
    } catch (e) {
      _showMessage(
        'Unable to select register photos.',
      );
    }
  }

  // ------------------------------------------------------------
  // REGISTER PROCESSING
  // ------------------------------------------------------------

  Future<void> _processRegister() async {
    if (_registerImages.isEmpty) return;

    if (!mounted) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Placeholder for OCR/AI processing.
      //
      // Later this method can:
      // 1. Send each image to OCR.
      // 2. Read tenant names, rooms, beds, rent, phone numbers, etc.
      // 3. Convert the response into _ExtractedTenant objects.
      //
      // For now we create editable rows so the complete UI flow can
      // be tested without an external OCR service.

      await Future<void>.delayed(
        const Duration(milliseconds: 700),
      );

      if (!mounted) return;

      if (_tenants.isEmpty) {
        _tenants.add(
          _ExtractedTenant(
            name: '',
            phone: '',
            room: '',
            bed: '',
            rent: '',
          ),
        );
      }

      setState(() {
        _isProcessing = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      _showMessage(
        'Register processing failed. Please try again.',
      );
    }
  }

  // ------------------------------------------------------------
  // TENANT EDITING
  // ------------------------------------------------------------

  void _addTenantRow() {
    setState(() {
      _tenants.add(
        _ExtractedTenant(
          name: '',
          phone: '',
          room: '',
          bed: '',
          rent: '',
        ),
      );
    });
  }

  void _removeTenant(int index) {
    setState(() {
      _tenants.removeAt(index);
    });
  }

  Future<void> _editTenant(int index) async {
    final tenant = _tenants[index];

    final nameController = TextEditingController(
      text: tenant.name,
    );

    final phoneController = TextEditingController(
      text: tenant.phone,
    );

    final roomController = TextEditingController(
      text: tenant.room,
    );

    final bedController = TextEditingController(
      text: tenant.bed,
    );

    final rentController = TextEditingController(
      text: tenant.rent,
    );

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Review Tenant',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Check the extracted information and correct anything that is not accurate.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _field(
                    controller: nameController,
                    label: 'Tenant Name',
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    controller: phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          controller: roomController,
                          label: 'Room',
                          icon: Icons.meeting_room_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          controller: bedController,
                          label: 'Bed',
                          icon: Icons.bed_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _field(
                    controller: rentController,
                    label: 'Monthly Rent',
                    icon: Icons.currency_rupee_rounded,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _tenants[index]
                          ..name = nameController.text.trim()
                          ..phone = phoneController.text.trim()
                          ..room = roomController.text.trim()
                          ..bed = bedController.text.trim()
                          ..rent = rentController.text.trim();

                        Navigator.pop(context, true);
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Save Tenant',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();
    roomController.dispose();
    bedController.dispose();
    rentController.dispose();

    if (result == true && mounted) {
      setState(() {});
    }
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
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
      ),
    );
  }

  // ------------------------------------------------------------
  // CONFIRM IMPORT
  // ------------------------------------------------------------

  Future<void> _confirmImport() async {
    if (_tenants.isEmpty) {
      _showMessage(
        'Please upload a register first.',
      );
      return;
    }

    final validTenants = _tenants
        .where(
          (tenant) => tenant.name.trim().isNotEmpty,
        )
        .toList();

    if (validTenants.isEmpty) {
      _showMessage(
        'Please add at least one tenant name before importing.',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Import Tenants?',
          ),
          content: Text(
            '${validTenants.length} tenant(s) are ready to be added. '
            'Please make sure the details have been reviewed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(
                context,
                false,
              ),
              child: const Text(
                'Review',
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(
                context,
                true,
              ),
              child: const Text(
                'Import',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    // This is the integration point for your existing tenant database.
    // Once your Tenant model/database is connected, insert the confirmed
    // tenants here and perform duplicate checking.
    //
    // We return the imported records to the previous screen for now.

    Navigator.pop(
      context,
      validTenants
          .map(
            (tenant) => {
              'full_name': tenant.name,
              'phone': tenant.phone,
              'room': tenant.room,
              'bed': tenant.bed,
              'monthly_rent': tenant.rent,
            },
          )
          .toList(),
    );
  }

  // ------------------------------------------------------------
  // REGISTER IMAGE CARD
  // ------------------------------------------------------------

  Widget _imageSection() {
    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(
                Icons.document_scanner_rounded,
                const Color(0xFF2563EB),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Register Photos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Upload clear pages from your tenant register.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_registerImages.isEmpty)
            _emptyUploadArea()
          else
            _imagePreviewGrid(),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // EMPTY UPLOAD AREA
  // ------------------------------------------------------------

  Widget _emptyUploadArea() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 24,
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD1D5DB),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.document_scanner_rounded,
              size: 31,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Add Register Photos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Take a photo using camera or choose from gallery',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 18),

          // DIRECT CAMERA BUTTON
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _takePhoto,
              icon: const Icon(
                Icons.camera_alt_rounded,
              ),
              label: const Text(
                'Take Photo',
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // DIRECT GALLERY BUTTON
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pickFromGallery,
              icon: const Icon(
                Icons.photo_library_rounded,
              ),
              label: const Text(
                'Choose from Gallery',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                foregroundColor: const Color(0xFF2563EB),
                side: const BorderSide(
                  color: Color(0xFFBFDBFE),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // MORE OPTIONS
          TextButton.icon(
            onPressed: _showImageSourceSheet,
            icon: const Icon(
              Icons.more_horiz_rounded,
              size: 19,
            ),
            label: const Text(
              'More Options',
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // IMAGE PREVIEW GRID
  // ------------------------------------------------------------

  Widget _imagePreviewGrid() {
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _registerImages.length,
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            final image = _registerImages[index];

            return Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(image.path),
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _registerImages.removeAt(index);
                      });
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 17,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _showImageSourceSheet,
          icon: const Icon(
            Icons.add_rounded,
          ),
          label: const Text(
            'Add More Photos',
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // PROCESSING CARD
  // ------------------------------------------------------------

  Widget _processingCard() {
    if (!_isProcessing) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFBFDBFE),
        ),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Color(0xFF2563EB),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Preparing your register for review...',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF1E40AF),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // TENANT REVIEW
  // ------------------------------------------------------------

  Widget _tenantSection() {
    if (_registerImages.isEmpty) {
      return const SizedBox.shrink();
    }

    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(
                Icons.people_alt_rounded,
                const Color(0xFF16A34A),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Review Tenants',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Check and edit the details before importing.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _addTenantRow,
                child: const Text(
                  'Add',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_tenants.isEmpty)
            _noTenants()
          else
            Column(
              children: List.generate(
                _tenants.length,
                (index) => _tenantTile(
                  _tenants[index],
                  index,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _noTenants() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        'No tenant rows found yet. Tap Add to enter a tenant manually.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }

  Widget _tenantTile(
    _ExtractedTenant tenant,
    int index,
  ) {
    final hasName = tenant.name.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
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
              color: hasName
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              hasName
                  ? Icons.person_rounded
                  : Icons.person_search_rounded,
              color: hasName
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFD97706),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasName
                      ? tenant.name
                      : 'Tenant details needed',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _tenantSubtitle(tenant),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _editTenant(index),
            tooltip: 'Edit',
            icon: const Icon(
              Icons.edit_rounded,
              size: 20,
              color: Color(0xFF2563EB),
            ),
          ),
          IconButton(
            onPressed: () => _removeTenant(index),
            tooltip: 'Remove',
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: Color(0xFFDC2626),
            ),
          ),
        ],
      ),
    );
  }

  String _tenantSubtitle(
    _ExtractedTenant tenant,
  ) {
    final parts = <String>[];

    if (tenant.room.isNotEmpty) {
      parts.add(
        'Room ${tenant.room}',
      );
    }

    if (tenant.bed.isNotEmpty) {
      parts.add(
        'Bed ${tenant.bed}',
      );
    }

    if (tenant.rent.isNotEmpty) {
      parts.add(
        'Rent ₹${tenant.rent}',
      );
    }

    if (tenant.phone.isNotEmpty) {
      parts.add(
        tenant.phone,
      );
    }

    if (parts.isEmpty) {
      return 'Tap edit to enter tenant details';
    }

    return parts.join(' • ');
  }

  // ------------------------------------------------------------
  // INFO CARD
  // ------------------------------------------------------------

  Widget _howItWorksCard() {
    return _whiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How it works',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          _step(
            number: '1',
            title: 'Upload register photos',
            description:
                'Take clear photos of each page of your existing tenant register.',
          ),
          _step(
            number: '2',
            title: 'Review details',
            description:
                'Review the tenant information and correct any mistakes.',
          ),
          _step(
            number: '3',
            title: 'Import tenants',
            description:
                'Confirm the details and add them to your Stay Mitra tenant list.',
          ),
        ],
      ),
    );
  }

  Widget _step({
    required String number,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // COMMON UI
  // ------------------------------------------------------------

  Widget _whiteCard({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: child,
    );
  }

  Widget _iconBox(
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.10,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: color,
      ),
    );
  }

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        title: const Text(
          'Upload Register',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            30,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _introCard(),
              const SizedBox(height: 16),
              _imageSection(),
              _processingCard(),
              if (!_isProcessing &&
                  _registerImages.isNotEmpty) ...[
                const SizedBox(height: 16),
                _tenantSection(),
                const SizedBox(height: 16),
                _howItWorksCard(),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _confirmImport,
                    icon: const Icon(
                      Icons.people_alt_rounded,
                    ),
                    label: const Text(
                      'Import Tenants',
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize:
                          const Size.fromHeight(54),
                      backgroundColor:
                          const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _introCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEFF6FF),
            Color(0xFFF8FAFC),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFDBEAFE),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF2563EB),
              size: 28,
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Import your existing register',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Already have tenant details in a book? Upload photos instead of entering every tenant manually.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Temporary local model for the register-review flow.
///
/// Keep this model independent from the application's final Tenant model.
/// When the existing tenant database is connected, map this object to that
/// model during _confirmImport().
class _ExtractedTenant {
  String name;
  String phone;
  String room;
  String bed;
  String rent;

  _ExtractedTenant({
    required this.name,
    required this.phone,
    required this.room,
    required this.bed,
    required this.rent,
  });
}