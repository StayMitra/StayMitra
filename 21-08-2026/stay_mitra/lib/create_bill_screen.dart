import 'package:flutter/material.dart';

import 'database_helper.dart';
import 'tenant_model.dart';

class CreateBillScreen extends StatefulWidget {
  /// Selected PG / Building ID.
  ///
  /// If provided:
  /// Only active tenants belonging to this PG will be shown.
  ///
  /// If null:
  /// For backward compatibility, active tenants from all PGs
  /// will be loaded.
  final String? buildingId;

  const CreateBillScreen({
    super.key,
    this.buildingId,
  });

  @override
  State<CreateBillScreen> createState() =>
      _CreateBillScreenState();
}

class _CreateBillScreenState
    extends State<CreateBillScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController rentController =
      TextEditingController();

  final TextEditingController electricityController =
      TextEditingController();

  final TextEditingController foodController =
      TextEditingController();

  final TextEditingController maintenanceController =
      TextEditingController();

  final TextEditingController otherController =
      TextEditingController();

  final TextEditingController discountController =
      TextEditingController();

  final TextEditingController notesController =
      TextEditingController();

  // ============================================================
  // TENANTS
  // ============================================================

  List<TenantModel> _tenants = [];

  /// Actual database tenant ID.
  ///
  /// This is NEVER changed or shortened.
  String? selectedTenantId;

  /// Separate value used only by the Flutter dropdown.
  ///
  /// We do NOT use tenant.id directly as DropdownButton value.
  /// This prevents duplicate-value assertion errors.
  String? _selectedTenantDropdownValue;

  bool _isLoadingTenants = false;

  String get selectedTenantName {
    if (selectedTenantId == null) {
      return 'Select Tenant';
    }

    for (final tenant in _tenants) {
      if (tenant.id == selectedTenantId) {
        return tenant.fullName;
      }
    }

    return 'Select Tenant';
  }

  // ============================================================
  // BILLING MONTH
  // ============================================================

  String selectedMonth = 'August 2026';

  DateTime? dueDate;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadTenants();

    rentController.addListener(_refreshTotal);
    electricityController.addListener(_refreshTotal);
    foodController.addListener(_refreshTotal);
    maintenanceController.addListener(_refreshTotal);
    otherController.addListener(_refreshTotal);
    discountController.addListener(_refreshTotal);
  }

  // ============================================================
  // LOAD TENANTS
  // ============================================================

  Future<void> _loadTenants() async {
    if (!mounted) return;

    setState(() {
      _isLoadingTenants = true;
    });

    try {
      List<TenantModel> tenants;

      if (widget.buildingId != null &&
          widget.buildingId!.trim().isNotEmpty) {
        // ======================================================
        // SELECTED PG ONLY
        // ======================================================

        tenants = await DatabaseHelper.instance
            .getActiveTenantsByBuilding(
          widget.buildingId!,
        );
      } else {
        // ======================================================
        // BACKWARD COMPATIBILITY
        //
        // If buildingId is not passed, load all active tenants.
        // ======================================================

        tenants = await DatabaseHelper.instance
            .getActiveTenants();
      }

      // ========================================================
      // REMOVE DUPLICATE TENANT IDs
      //
      // Database ID remains unchanged.
      // This only removes duplicate records from the dropdown.
      // ========================================================

      final Map<String, TenantModel> uniqueTenants = {};

      for (final tenant in tenants) {
        uniqueTenants[tenant.id] = tenant;
      }

      final uniqueTenantList =
          uniqueTenants.values.toList();

      uniqueTenantList.sort(
        (a, b) => a.fullName
            .toLowerCase()
            .compareTo(
              b.fullName.toLowerCase(),
            ),
      );

      if (!mounted) return;

      setState(() {
        _tenants = uniqueTenantList;
        _isLoadingTenants = false;

        // If currently selected tenant no longer exists,
        // reset both actual tenant selection and dropdown selection.
        if (selectedTenantId != null &&
            !_tenants.any(
              (tenant) =>
                  tenant.id == selectedTenantId,
            )) {
          selectedTenantId = null;
          _selectedTenantDropdownValue = null;
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingTenants = false;
        _tenants = [];
        selectedTenantId = null;
        _selectedTenantDropdownValue = null;
      });

      _showMessage(
        'Unable to load tenants.',
        isError: true,
      );
    }
  }

  // ============================================================
  // SELECTED TENANT
  // ============================================================

  TenantModel? get _selectedTenant {
    if (selectedTenantId == null) {
      return null;
    }

    for (final tenant in _tenants) {
      if (tenant.id == selectedTenantId) {
        return tenant;
      }
    }

    return null;
  }

  // ============================================================
  // SHORT TENANT ID
  // ============================================================

  /// Returns only the last 6 characters of the actual tenant ID
  /// for display purposes.
  ///
  /// Example:
  ///
  /// Database ID:
  /// 1786469627364963
  ///
  /// Display:
  /// 364963
  ///
  /// IMPORTANT:
  /// This does NOT change the database ID.
  String _shortTenantId(String tenantId) {
    final value = tenantId.trim();

    if (value.length <= 6) {
      return value;
    }

    return value.substring(value.length - 6);
  }

  // ============================================================
  // DROPDOWN UNIQUE VALUE
  // ============================================================

  /// Creates a unique value for the Flutter dropdown.
  ///
  /// We intentionally do not use tenant.id directly because
  /// duplicate IDs can cause DropdownButton assertion errors.
  String _dropdownValueForTenant(
    TenantModel tenant,
    int index,
  ) {
    return 'tenant_dropdown_${index}_${tenant.id}';
  }

  // ============================================================
  // CALCULATE TOTAL
  // ============================================================

  double _amount(String value) {
    return double.tryParse(value.trim()) ?? 0;
  }

  double get _subtotal {
    return _amount(rentController.text) +
        _amount(electricityController.text) +
        _amount(foodController.text) +
        _amount(maintenanceController.text) +
        _amount(otherController.text);
  }

  double get _discount {
    return _amount(discountController.text);
  }

  double get _total {
    final total = _subtotal - _discount;
    return total < 0 ? 0 : total;
  }

  void _refreshTotal() {
    if (!mounted) return;
    setState(() {});
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _selectDueDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: dueDate ?? now,
      firstDate: now,
      lastDate: DateTime(
        now.year + 2,
        12,
        31,
      ),
    );

    if (picked == null) return;

    setState(() {
      dueDate = picked;
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Select due date';
    }

    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  // ============================================================
  // GENERATE BILL
  // ============================================================

  void _generateBill() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedTenantId == null ||
        _selectedTenant == null) {
      _showMessage(
        'Please select a tenant.',
        isError: true,
      );
      return;
    }

    if (dueDate == null) {
      _showMessage(
        'Please select a due date.',
        isError: true,
      );
      return;
    }

    final tenant = _selectedTenant!;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          title: const Text(
            'Bill Created',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Bill has been created successfully.',
                style: TextStyle(
                  color: Color(0xFF475569),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Tenant: ${tenant.fullName}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Tenant ID: ${_shortTenantId(tenant.id)}',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Month: $selectedMonth',
              ),

              const SizedBox(height: 6),

              Text(
                'Due Date: ${_formatDate(dueDate)}',
              ),

              const SizedBox(height: 6),

              Text(
                'Total: ₹${_total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
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
          behavior:
              SnackBarBehavior.floating,
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
      backgroundColor:
          const Color(0xFFF7F8FC),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor:
            const Color(0xFF111827),
        title: const Text(
          'Create Bill',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              16,
              18,
              16,
              30,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // ==================================================
                // BILL INFORMATION
                // ==================================================

                const Text(
                  'Bill Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),

                const SizedBox(height: 12),

                _card(
                  child: Column(
                    children: [
                      _tenantDropdown(),

                      const SizedBox(height: 16),

                      _dropdownField(
                        label: 'Billing Month',
                        icon:
                            Icons.calendar_month_rounded,
                        value: selectedMonth,
                        items: const [
                          'August 2026',
                          'September 2026',
                          'October 2026',
                          'November 2026',
                          'December 2026',
                        ],
                        onChanged: (value) {
                          if (value == null) return;

                          setState(() {
                            selectedMonth = value;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      InkWell(
                        onTap: _selectDueDate,
                        borderRadius:
                            BorderRadius.circular(14),
                        child: InputDecorator(
                          decoration:
                              _inputDecoration(
                            label: 'Due Date',
                            icon: Icons.event_rounded,
                          ),
                          child: Text(
                            _formatDate(dueDate),
                            style: TextStyle(
                              fontSize: 14,
                              color: dueDate == null
                                  ? const Color(
                                      0xFF94A3B8,
                                    )
                                  : const Color(
                                      0xFF111827,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ==================================================
                // CHARGES
                // ==================================================

                const Text(
                  'Charges',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),

                const SizedBox(height: 12),

                _card(
                  child: Column(
                    children: [
                      _amountField(
                        controller: rentController,
                        label: 'Rent',
                        icon:
                            Icons.home_work_outlined,
                        requiredField: true,
                      ),

                      const SizedBox(height: 14),

                      _amountField(
                        controller:
                            electricityController,
                        label: 'Electricity',
                        icon:
                            Icons.bolt_rounded,
                      ),

                      const SizedBox(height: 14),

                      _amountField(
                        controller:
                            foodController,
                        label: 'Food / Mess',
                        icon:
                            Icons.restaurant_rounded,
                      ),

                      const SizedBox(height: 14),

                      _amountField(
                        controller:
                            maintenanceController,
                        label: 'Maintenance',
                        icon:
                            Icons.build_rounded,
                      ),

                      const SizedBox(height: 14),

                      _amountField(
                        controller:
                            otherController,
                        label: 'Other Charges',
                        icon:
                            Icons.add_card_rounded,
                      ),

                      const SizedBox(height: 14),

                      _amountField(
                        controller:
                            discountController,
                        label: 'Discount',
                        icon:
                            Icons.discount_rounded,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ==================================================
                // TOTAL
                // ==================================================

                _totalCard(),

                const SizedBox(height: 24),

                // ==================================================
                // NOTES
                // ==================================================

                const Text(
                  'Notes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),

                const SizedBox(height: 12),

                _card(
                  child: TextField(
                    controller: notesController,
                    maxLines: 4,
                    decoration:
                        _inputDecoration(
                      label: 'Additional Notes',
                      icon:
                          Icons.notes_rounded,
                    ).copyWith(
                      alignLabelWithHint: true,
                      hintText:
                          'Add any notes for this bill...',
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ==================================================
                // GENERATE BUTTON
                // ==================================================

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    onPressed:
                        _isLoadingTenants
                            ? null
                            : _generateBill,
                    icon: const Icon(
                      Icons.receipt_long_rounded,
                    ),
                    label: const Text(
                      'Generate Bill',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                const Center(
                  child: Text(
                    'You can review the bill before sharing it with the tenant.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
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

  // ============================================================
  // TENANT DROPDOWN
  // ============================================================

  Widget _tenantDropdown() {
    if (_isLoadingTenants) {
      return InputDecorator(
        decoration: _inputDecoration(
          label: 'Tenant',
          icon: Icons.person_outline_rounded,
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Loading tenants...',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    if (_tenants.isEmpty) {
      return InputDecorator(
        decoration: _inputDecoration(
          label: 'Tenant',
          icon: Icons.person_outline_rounded,
        ),
        child: const Text(
          'No active tenants found',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF94A3B8),
          ),
        ),
      );
    }

    // ==========================================================
    // IMPORTANT
    //
    // Dropdown internal value is NOT tenant.id.
    //
    // We create a unique dropdown value using:
    //
    // tenant_dropdown_INDEX_DATABASE_ID
    //
    // This prevents Flutter's duplicate DropdownButton value
    // assertion error.
    //
    // Actual tenant.id is still stored in selectedTenantId.
    // ==========================================================

    final dropdownItems =
        _tenants.asMap().entries.map((entry) {
      final index = entry.key;
      final tenant = entry.value;

      final dropdownValue =
          _dropdownValueForTenant(
        tenant,
        index,
      );

      final shortId =
          _shortTenantId(tenant.id);

      return DropdownMenuItem<String>(
        value: dropdownValue,
        child: Row(
          children: [
            Expanded(
              child: Text(
                tenant.fullName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
            ),

            const SizedBox(width: 8),

            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color:
                    const Color(0xFFEFF6FF),
                borderRadius:
                    BorderRadius.circular(8),
              ),
              child: Text(
                shortId,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w600,
                  color:
                      Color(0xFF2563EB),
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();

    // ==========================================================
    // SAFETY CHECK
    //
    // If selected dropdown value is no longer available,
    // use null so Flutter will not throw an assertion.
    // ==========================================================

    final availableValues =
        dropdownItems
            .map((item) => item.value)
            .whereType<String>()
            .toSet();

    final safeDropdownValue =
        availableValues.contains(
      _selectedTenantDropdownValue,
    )
            ? _selectedTenantDropdownValue
            : null;

    return DropdownButtonFormField<String>(
      initialValue: safeDropdownValue,
      decoration: _inputDecoration(
        label: 'Tenant',
        icon: Icons.person_outline_rounded,
      ),
      isExpanded: true,
      items: dropdownItems,

      onChanged: (dropdownValue) {
        if (dropdownValue == null) {
          return;
        }

        // Find the exact dropdown item.
        final selectedIndex =
            dropdownItems.indexWhere(
          (item) =>
              item.value == dropdownValue,
        );

        if (selectedIndex < 0 ||
            selectedIndex >= _tenants.length) {
          return;
        }

        final tenant =
            _tenants[selectedIndex];

        setState(() {
          // ====================================================
          // IMPORTANT:
          // Store ORIGINAL database tenant ID.
          // Never store the 5/6 digit display ID.
          // ====================================================

          selectedTenantId = tenant.id;

          // Store only the unique dropdown value
          // for Flutter UI state.
          _selectedTenantDropdownValue =
              dropdownValue;

          // Automatically fill rent from tenant's
          // monthly rent.
          rentController.text =
              tenant.monthlyRent
                  .toStringAsFixed(2);
        });
      },

      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a tenant';
        }

        return null;
      },
    );
  }

  // ============================================================
  // CARD
  // ============================================================

  Widget _card({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: child,
    );
  }

  // ============================================================
  // DROPDOWN
  // ============================================================

  Widget _dropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String?>
        onChanged,
  }) {
    // Make absolutely sure dropdown items are unique.
    final uniqueItems = <String>[];

    for (final item in items) {
      if (!uniqueItems.contains(item)) {
        uniqueItems.add(item);
      }
    }

    // Make sure current value actually exists in items.
    final safeValue =
        uniqueItems.contains(value)
            ? value
            : null;

    return DropdownButtonFormField<String>(
      initialValue: safeValue,
      decoration:
          _inputDecoration(
        label: label,
        icon: icon,
      ),
      isExpanded: true,
      items: uniqueItems.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  // ============================================================
  // AMOUNT FIELD
  // ============================================================

  Widget _amountField({
    required TextEditingController
        controller,
    required String label,
    required IconData icon,
    bool requiredField = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType:
          const TextInputType.numberWithOptions(
        decimal: true,
      ),
      validator: requiredField
          ? (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'Please enter $label';
              }

              final amount =
                  double.tryParse(
                value.trim(),
              );

              if (amount == null ||
                  amount < 0) {
                return 'Enter a valid amount';
              }

              return null;
            }
          : (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return null;
              }

              final amount =
                  double.tryParse(
                value.trim(),
              );

              if (amount == null ||
                  amount < 0) {
                return 'Enter a valid amount';
              }

              return null;
            },
      decoration:
          _inputDecoration(
        label: label,
        icon: icon,
        prefixText: '₹ ',
      ),
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? prefixText,
  }) {
    return InputDecoration(
      labelText: label,
      prefixText: prefixText,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
      ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide:
            const BorderSide(
          color: Color(0xFFE5E7EB),
        ),
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide:
            const BorderSide(
          color: Color(0xFF2563EB),
          width: 1.5,
        ),
      ),
      filled: true,
      fillColor:
          const Color(0xFFFAFBFD),
    );
  }

  // ============================================================
  // TOTAL CARD
  // ============================================================

  Widget _totalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2563EB),
            Color(0xFF1D4ED8),
          ],
        ),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            'Bill Summary',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            '₹${_total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _summaryItem(
                  'Subtotal',
                  '₹${_subtotal.toStringAsFixed(2)}',
                ),
              ),

              Container(
                width: 1,
                height: 35,
                color: Colors.white24,
              ),

              Expanded(
                child: _summaryItem(
                  'Discount',
                  '₹${_discount.toStringAsFixed(2)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY ITEM
  // ============================================================

  Widget _summaryItem(
    String title,
    String value,
  ) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    rentController.dispose();
    electricityController.dispose();
    foodController.dispose();
    maintenanceController.dispose();
    otherController.dispose();
    discountController.dispose();
    notesController.dispose();

    super.dispose();
  }
}