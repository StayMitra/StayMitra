import 'package:flutter/material.dart';

import 'building_model.dart';
import 'database_helper.dart';
import 'pg_manager_service.dart';

class AddPgScreen extends StatefulWidget {
  final String ownerId;

  const AddPgScreen({
    super.key,
    required this.ownerId,
  });

  @override
  State<AddPgScreen> createState() => _AddPgScreenState();
}

class _AddPgScreenState extends State<AddPgScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String _newId() {
    return 'building-${DateTime.now().microsecondsSinceEpoch}';
  }

  Future<void> _savePg() async {
    if (_saving) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      // ========================================================
      // CREATE NEW PG
      // ========================================================

      final pg = BuildingModel(
        id: _newId(),
        name: _nameController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        ownerId: widget.ownerId,
        createdAt: DateTime.now(),
      );

      // ========================================================
      // SAVE ONLY THIS NEW PG
      // ========================================================

      await DatabaseHelper.instance.insertBuilding(pg);

      // ========================================================
      // MAKE NEW PG ACTIVE
      // ========================================================
      //
      // Important:
      // Only the newly created PG becomes active.
      //
      // Existing PG data is NOT copied.
      // Existing floors/rooms/beds/tenants remain associated
      // with their original building ID.
      //
      // ========================================================

      await PgManagerService.selectPg(
        pg,
        ownerId: widget.ownerId,
      );

      if (!mounted) return;

      FocusScope.of(context).unfocus();

      // ========================================================
      // RETURN TO PREVIOUS SCREEN
      // ========================================================

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to add PG. ${e.toString()}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),

        leading: IconButton(
          onPressed: _saving
              ? null
              : () => Navigator.pop(context, false),
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
        ),

        title: const Text(
          'Add New PG',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // ==================================================
                // PG DETAILS CARD
                // ==================================================

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                    ),
                  ),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      // ------------------------------------------------
                      // ICON
                      // ------------------------------------------------

                      Container(
                        width: 56,
                        height: 56,

                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius:
                              BorderRadius.circular(16),
                        ),

                        child: const Icon(
                          Icons.apartment_rounded,
                          color: Color(0xFF2563EB),
                          size: 30,
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ------------------------------------------------
                      // TITLE
                      // ------------------------------------------------

                      const Text(
                        'Add your PG',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        'Enter your PG details. '
                        'You can create floors, rooms and beds later.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ==================================================
                      // PG NAME
                      // ==================================================

                      TextFormField(
                        controller: _nameController,
                        textCapitalization:
                            TextCapitalization.words,

                        decoration: InputDecoration(
                          labelText: 'PG Name',
                          hintText: 'Example: Sri Durga PG',

                          prefixIcon: const Icon(
                            Icons.home_work_outlined,
                          ),

                          filled: true,
                          fillColor:
                              const Color(0xFFF8FAFC),

                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),

                          enabledBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),

                          focusedBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFF2563EB),
                              width: 1.5,
                            ),
                          ),
                        ),

                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Please enter PG name';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // ==================================================
                      // ADDRESS
                      // ==================================================

                      TextFormField(
                        controller: _addressController,

                        textCapitalization:
                            TextCapitalization.sentences,

                        maxLines: 3,

                        decoration: InputDecoration(
                          labelText: 'Location / Address',

                          hintText:
                              'Example: Electronic City, Bangalore',

                          prefixIcon: const Icon(
                            Icons.location_on_outlined,
                          ),

                          filled: true,
                          fillColor:
                              const Color(0xFFF8FAFC),

                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),

                          enabledBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),

                          focusedBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFF2563EB),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ========================================================
                // SAVE BUTTON
                // ========================================================

                SizedBox(
                  width: double.infinity,
                  height: 54,

                  child: FilledButton.icon(
                    onPressed:
                        _saving ? null : _savePg,

                    icon: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,

                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.check_rounded,
                          ),

                    label: Text(
                      _saving
                          ? 'Saving PG...'
                          : 'Save PG',
                    ),

                    style: FilledButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF2563EB),

                      foregroundColor: Colors.white,

                      elevation: 0,

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}