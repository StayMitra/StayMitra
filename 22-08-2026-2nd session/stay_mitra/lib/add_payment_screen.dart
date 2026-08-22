import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import 'database_helper.dart';
import 'transaction_model.dart';
import 'transaction_service.dart';
import 'pg_manager_service.dart';

class AddPaymentScreen extends StatefulWidget {
  const AddPaymentScreen({super.key});

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _amountController =
      TextEditingController();

  final TextEditingController _descriptionController =
      TextEditingController();

  PaymentMethod _paymentMethod = PaymentMethod.cash;

  DateTime _selectedDate = DateTime.now();

  // ------------------------------------------------------------
  // ROOM / TENANT DATA
  // ------------------------------------------------------------

  List<Map<String, dynamic>> _rooms = [];

  List<Map<String, dynamic>> _roomTenants = [];

  String? _selectedRoomId;

  String? _selectedRoomNumber;

  String? _selectedTenantId;

  String? _selectedTenantName;

  bool _isLoadingRooms = true;

  bool _isLoadingTenants = false;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD ROOMS
  // ============================================================

  Future<void> _loadRooms() async {
    if (!mounted) return;

    setState(() {
      _isLoadingRooms = true;
      _rooms = [];
    });

    try {
      // ----------------------------------------------------------
      // GET CURRENT ACTIVE PG
      // ----------------------------------------------------------

      final activePg = PgManagerService.activePg;

      if (activePg == null) {
        if (!mounted) return;

        setState(() {
          _rooms = [];
          _isLoadingRooms = false;
        });

        _showError(
          'No active PG selected. Please select a PG first.',
        );

        return;
      }

      // ----------------------------------------------------------
      // LOAD ONLY ROOMS BELONGING TO ACTIVE PG
      //
      // Building
      //    ↓
      // Floors
      //    ↓
      // Rooms
      // ----------------------------------------------------------

      final db =
          await DatabaseHelper.instance.database;

      final result = await db.rawQuery(
        '''
        SELECT
          r.id AS room_id,
          r.room_number AS room_number
        FROM rooms r
        INNER JOIN floors f
          ON f.id = r.floor_id
        WHERE f.building_id = ?
        ORDER BY
          CAST(r.room_number AS INTEGER) ASC,
          r.room_number ASC
        ''',
        [
          activePg.id,
        ],
      );

      if (!mounted) return;

      setState(() {
        _rooms = result;
        _isLoadingRooms = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _rooms = [];
        _isLoadingRooms = false;
      });

      _showError(
        'Unable to load rooms: $e',
      );
    }
  }

  // ============================================================
  // LOAD ACTIVE TENANTS FOR SELECTED ROOM
  // ============================================================

  Future<void> _loadTenantsForRoom(
    String roomId,
    String roomNumber,
  ) async {
    setState(() {
      _selectedRoomId = roomId;
      _selectedRoomNumber = roomNumber;

      _selectedTenantId = null;
      _selectedTenantName = null;

      _roomTenants = [];

      _isLoadingTenants = true;
    });

    try {
      final activePg = PgManagerService.activePg;

      if (activePg == null) {
        if (!mounted) return;

        setState(() {
          _isLoadingTenants = false;
        });

        _showError(
          'No active PG selected.',
        );

        return;
      }

      final db =
          await DatabaseHelper.instance.database;

      final result = await db.rawQuery(
        '''
        SELECT
          t.id AS tenant_id,
          t.full_name AS tenant_name,
          t.phone AS phone,
          t.monthly_rent AS monthly_rent,
          b.bed_number AS bed_number
        FROM tenants t
        INNER JOIN beds b
          ON b.id = t.bed_id
        INNER JOIN rooms r
          ON r.id = b.room_id
        INNER JOIN floors f
          ON f.id = r.floor_id
        WHERE
          r.id = ?
          AND f.building_id = ?
          AND t.status = 'active'
        ORDER BY t.full_name ASC
        ''',
        [
          roomId,
          activePg.id,
        ],
      );

      if (!mounted) return;

      setState(() {
        _roomTenants = result;
        _isLoadingTenants = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingTenants = false;
      });

      _showError(
        'Unable to load tenants: $e',
      );
    }
  }

  // ============================================================
  // SELECT TENANT
  // ============================================================

  void _selectTenant(
    Map<String, dynamic> tenant,
  ) {
    setState(() {
      _selectedTenantId =
          tenant['tenant_id'] as String;

      _selectedTenantName =
          tenant['tenant_name'] as String;
    });

    // Automatically fill the monthly rent.
    final monthlyRent =
        (tenant['monthly_rent'] as num?)
                ?.toDouble() ??
            0;

    if (monthlyRent > 0) {
      _amountController.text =
          monthlyRent.toStringAsFixed(0);
    }
  }

  // ============================================================
  // SAVE PAYMENT
  // ============================================================

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedRoomId == null) {
      _showError(
        'Please select a room.',
      );
      return;
    }

    if (_selectedTenantId == null) {
      _showError(
        'Please select a tenant.',
      );
      return;
    }

    final amount = double.tryParse(
      _amountController.text.trim(),
    );

    if (amount == null || amount <= 0) {
      _showError(
        'Please enter a valid payment amount.',
      );
      return;
    }

    if (_isSaving) {
      return;
    }

    // ----------------------------------------------------------
    // GET CURRENT ACTIVE PG
    // ----------------------------------------------------------

    final activePg = PgManagerService.activePg;

    if (activePg == null) {
      _showError(
        'No active PG selected. Please select a PG first.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final tenantName =
          _selectedTenantName ?? 'Tenant';

      final description =
          _descriptionController.text.trim();

      // --------------------------------------------------------
      // CREATE TRANSACTION
      // --------------------------------------------------------

      final transaction = TransactionModel(
        id: DateTime.now()
            .microsecondsSinceEpoch
            .toString(),

        // ------------------------------------------------------
        // ACTIVE PG / BUILDING
        // ------------------------------------------------------

        buildingId: activePg.id,

        // ------------------------------------------------------
        // TRANSACTION TYPE
        // ------------------------------------------------------

        type: TransactionType.income,

        // ------------------------------------------------------
        // PAYMENT METHOD
        // ------------------------------------------------------

        paymentMethod: _paymentMethod,

        // ------------------------------------------------------
        // AMOUNT
        // ------------------------------------------------------

        amount: amount,

        // ------------------------------------------------------
        // PAYMENT DATE
        // ------------------------------------------------------

        date: _selectedDate,

        // ------------------------------------------------------
        // DESCRIPTION
        // ------------------------------------------------------

        description: description.isEmpty
            ? 'Rent payment - $tenantName - Room $_selectedRoomNumber'
            : '$tenantName - $description',

        // ------------------------------------------------------
        // TENANT
        // ------------------------------------------------------

        tenantId: _selectedTenantId!,

        // ------------------------------------------------------
        // ROOM
        // ------------------------------------------------------

        roomId: _selectedRoomId!,
      );

      // --------------------------------------------------------
      // SAVE THROUGH TRANSACTION SERVICE
      // --------------------------------------------------------

      TransactionService.addTransaction(
        transaction,
      );

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Payment saved successfully',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showError(
        'Unable to save payment: $e',
      );
    }
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Select Payment Date',
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _selectedDate = picked;
    });
  }

  // ============================================================
  // PAYMENT METHOD NAME
  // ============================================================

  String _paymentMethodName(
    PaymentMethod method,
  ) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash';

      case PaymentMethod.upi:
        return 'UPI';

      case PaymentMethod.bank:
        return 'Bank';
    }
  }

  // ============================================================
  // PAYMENT METHOD ICON
  // ============================================================

  IconData _paymentMethodIcon(
    PaymentMethod method,
  ) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.payments_rounded;

      case PaymentMethod.upi:
        return Icons.qr_code_rounded;

      case PaymentMethod.bank:
        return Icons.account_balance_rounded;
    }
  }

  // ============================================================
  // PAYMENT METHOD COLOR
  // ============================================================

  Color _paymentMethodColor(
    PaymentMethod method,
  ) {
    switch (method) {
      case PaymentMethod.cash:
        return const Color(0xFF16A34A);

      case PaymentMethod.upi:
        return const Color(0xFF7C3AED);

      case PaymentMethod.bank:
        return const Color(0xFF2563EB);
    }
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  void _showError(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            const Color(0xFFDC2626),
        behavior:
            SnackBarBehavior.floating,
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
          'Add Payment',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: Form(
          key: _formKey,

          child: SingleChildScrollView(
            padding:
                const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              30,
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                _paymentInfoCard(),

                const SizedBox(
                  height: 20,
                ),

                const Text(
                  'Payment Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Color(0xFF111827),
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                _roomSelector(),

                const SizedBox(
                  height: 14,
                ),

                _tenantSelector(),

                const SizedBox(
                  height: 14,
                ),

                _amountField(),

                const SizedBox(
                  height: 14,
                ),

                _dateField(),

                const SizedBox(
                  height: 22,
                ),

                const Text(
                  'Payment Method',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Color(0xFF111827),
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                _paymentMethodSelector(),

                const SizedBox(
                  height: 22,
                ),

                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Color(0xFF111827),
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                _descriptionField(),

                const SizedBox(
                  height: 28,
                ),

                SizedBox(
                  width: double.infinity,

                  child:
                      ElevatedButton.icon(
                    onPressed:
                        _isSaving
                            ? null
                            : _savePayment,

                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color:
                                  Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons
                                .save_rounded,
                          ),

                    label: Text(
                      _isSaving
                          ? 'Saving...'
                          : 'Save Payment',

                      style:
                          const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    style:
                        ElevatedButton.styleFrom(
                      minimumSize:
                          const Size
                              .fromHeight(
                        54,
                      ),

                      backgroundColor:
                          const Color(
                        0xFF2563EB,
                      ),

                      disabledBackgroundColor:
                          const Color(
                        0xFF93C5FD,
                      ),

                      foregroundColor:
                          Colors.white,

                      elevation: 0,

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          14,
                        ),
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

  // ============================================================
  // PAYMENT INFO CARD
  // ============================================================

  Widget _paymentInfoCard() {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color:
            const Color(0xFFEFF6FF),

        borderRadius:
            BorderRadius.circular(18),

        border: Border.all(
          color:
              const Color(0xFFDBEAFE),
        ),
      ),

      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,

            decoration:
                BoxDecoration(
              color: Colors.white,

              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),

            child: const Icon(
              Icons
                  .currency_rupee_rounded,

              color:
                  Color(0xFF2563EB),

              size: 25,
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [
                Text(
                  'Record a Payment',

                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Color(0xFF1E3A8A),
                  ),
                ),

                SizedBox(
                  height: 4,
                ),

                Text(
                  'Select a room and tenant, then record the rent payment.',

                  style: TextStyle(
                    fontSize: 12,
                    color:
                        Color(0xFF64748B),
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
  // ROOM SELECTOR
  // ============================================================

  Widget _roomSelector() {
    if (_isLoadingRooms) {
      return _loadingBox(
        label: 'Loading rooms...',
      );
    }

    if (_rooms.isEmpty) {
      return _emptyBox(
        icon:
            Icons.meeting_room_outlined,
        message:
            'No rooms available. Please create a room first.',
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedRoomId,

      isExpanded: true,

      decoration:
          _inputDecoration(
        labelText: 'Room Number',
        hintText:
            'Select room',
        prefixIcon:
            const Icon(
          Icons
              .meeting_room_outlined,
        ),
      ),

      items: _rooms.map((room) {
        final roomId =
            room['room_id']
                as String;

        final roomNumber =
            room['room_number']
                as String;

        return DropdownMenuItem<
            String>(
          value: roomId,

          child: Text(
            'Room $roomNumber',
            style:
                const TextStyle(
              fontSize: 15,
              color:
                  Color(0xFF111827),
            ),
          ),
        );
      }).toList(),

      onChanged: (value) {
        if (value == null) {
          return;
        }

        final room = _rooms.firstWhere(
          (item) =>
              item['room_id'] ==
              value,
        );

        _loadTenantsForRoom(
          value,
          room['room_number']
              as String,
        );
      },

      validator: (value) {
        if (value == null ||
            value.isEmpty) {
          return 'Please select a room';
        }

        return null;
      },
    );
  }

  // ============================================================
  // TENANT SELECTOR
  // ============================================================

  Widget _tenantSelector() {
    if (_selectedRoomId == null) {
      return _disabledField(
        label:
            'Tenant',
        hint:
            'Select a room first',
        icon:
            Icons.person_outline_rounded,
      );
    }

    if (_isLoadingTenants) {
      return _loadingBox(
        label:
            'Loading tenants...',
      );
    }

    if (_roomTenants.isEmpty) {
      return _emptyBox(
        icon:
            Icons.person_off_outlined,
        message:
            'No active tenant found in Room $_selectedRoomNumber.',
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedTenantId,

      isExpanded: true,

      decoration:
          _inputDecoration(
        labelText:
            'Tenant Name',
        hintText:
            'Select tenant',
        prefixIcon:
            const Icon(
          Icons
              .person_outline_rounded,
        ),
      ),

      items:
          _roomTenants.map((tenant) {
        final tenantId =
            tenant['tenant_id']
                as String;

        final tenantName =
            tenant['tenant_name']
                as String;

        final bedNumber =
            tenant['bed_number']
                as String;

        return DropdownMenuItem<
            String>(
          value: tenantId,

          child: Row(
            children: [
              Expanded(
                child: Text(
                  tenantName,
                  overflow:
                      TextOverflow
                          .ellipsis,

                  style:
                      const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w500,
                    color:
                        Color(
                      0xFF111827,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Text(
                'Bed $bedNumber',

                style:
                    const TextStyle(
                  fontSize: 12,
                  color:
                      Color(
                    0xFF64748B,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),

      onChanged: (value) {
        if (value == null) {
          return;
        }

        final tenant =
            _roomTenants.firstWhere(
          (item) =>
              item['tenant_id'] ==
              value,
        );

        _selectTenant(tenant);
      },

      validator: (value) {
        if (value == null ||
            value.isEmpty) {
          return 'Please select a tenant';
        }

        return null;
      },
    );
  }

  // ============================================================
  // AMOUNT FIELD
  // ============================================================

  Widget _amountField() {
    return TextFormField(
      controller:
          _amountController,

      keyboardType:
          const TextInputType
              .numberWithOptions(
        decimal: true,
      ),

      decoration:
          _inputDecoration(
        labelText:
            'Amount',
        hintText:
            'Enter amount',
        prefixIcon:
            const Icon(
          Icons
              .currency_rupee_rounded,
        ),
      ),

      validator: (value) {
        if (value == null ||
            value.trim().isEmpty) {
          return 'Please enter amount';
        }

        final amount =
            double.tryParse(
          value.trim(),
        );

        if (amount == null ||
            amount <= 0) {
          return 'Enter a valid amount';
        }

        return null;
      },
    );
  }

  // ============================================================
  // DATE FIELD
  // ============================================================

  Widget _dateField() {
    return InkWell(
      onTap:
          _selectDate,

      borderRadius:
          BorderRadius.circular(
        14,
      ),

      child: InputDecorator(
        decoration:
            _inputDecoration(
          labelText:
              'Payment Date',
          prefixIcon:
              const Icon(
            Icons
                .calendar_today_rounded,
          ),
          suffixIcon:
              const Icon(
            Icons
                .arrow_drop_down_rounded,
          ),
        ),

        child: Text(
          '${_selectedDate.day} '
          '${_monthName(_selectedDate.month)} '
          '${_selectedDate.year}',

          style:
              const TextStyle(
            fontSize: 15,
            color:
                Color(0xFF111827),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PAYMENT METHOD SELECTOR
  // ============================================================

  Widget _paymentMethodSelector() {
    return Row(
      children: [
        Expanded(
          child:
              _methodCard(
            PaymentMethod.cash,
          ),
        ),

        const SizedBox(
          width: 10,
        ),

        Expanded(
          child:
              _methodCard(
            PaymentMethod.upi,
          ),
        ),

        const SizedBox(
          width: 10,
        ),

        Expanded(
          child:
              _methodCard(
            PaymentMethod.bank,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PAYMENT METHOD CARD
  // ============================================================

  Widget _methodCard(
    PaymentMethod method,
  ) {
    final selected =
        _paymentMethod ==
            method;

    final color =
        _paymentMethodColor(
      method,
    );

    return InkWell(
      onTap: () {
        setState(() {
          _paymentMethod =
              method;
        });
      },

      borderRadius:
          BorderRadius.circular(
        14,
      ),

      child: Container(
        padding:
            const EdgeInsets
                .symmetric(
          vertical: 15,
          horizontal: 6,
        ),

        decoration:
            BoxDecoration(
          color: selected
              ? color.withValues(
                  alpha: 0.08,
                )
              : Colors.white,

          borderRadius:
              BorderRadius.circular(
            14,
          ),

          border: Border.all(
            color: selected
                ? color
                : const Color(
                    0xFFE5E7EB,
                  ),

            width:
                selected ? 1.5 : 1,
          ),
        ),

        child: Column(
          children: [
            Icon(
              _paymentMethodIcon(
                method,
              ),
              color: color,
              size: 25,
            ),

            const SizedBox(
              height: 7,
            ),

            Text(
              _paymentMethodName(
                method,
              ),

              style:
                  TextStyle(
                fontSize: 12,
                fontWeight:
                    selected
                        ? FontWeight
                            .bold
                        : FontWeight
                            .w500,
                color: selected
                    ? color
                    : const Color(
                        0xFF374151,
                      ),
              ),
            ),

            if (selected) ...[
              const SizedBox(
                height: 5,
              ),

              Icon(
                Icons
                    .check_circle_rounded,
                size: 16,
                color: color,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DESCRIPTION
  // ============================================================

  Widget _descriptionField() {
    return TextFormField(
      controller:
          _descriptionController,

      maxLines: 3,

      textCapitalization:
          TextCapitalization
              .sentences,

      decoration:
          _inputDecoration(
        hintText:
            'Example: August rent payment',
        prefixIcon:
            const Padding(
          padding:
              EdgeInsets.only(
            bottom: 45,
          ),
          child: Icon(
            Icons.notes_rounded,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // COMMON INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({
    String? labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText:
          labelText,

      hintText:
          hintText,

      prefixIcon:
          prefixIcon,

      suffixIcon:
          suffixIcon,

      filled: true,

      fillColor:
          Colors.white,

      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        borderSide:
            const BorderSide(
          color:
              Color(0xFFE5E7EB),
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
              Color(0xFFE5E7EB),
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
              Color(0xFF2563EB),
          width: 1.5,
        ),
      ),
    );
  }

  // ============================================================
  // DISABLED FIELD
  // ============================================================

  Widget _disabledField({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecorator(
      decoration:
          _inputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon:
            Icon(
          icon,
          color:
              const Color(
            0xFF9CA3AF,
          ),
        ),
      ),

      child: Text(
        hint,
        style:
            const TextStyle(
          fontSize: 14,
          color:
              Color(0xFF9CA3AF),
        ),
      ),
    );
  }

  // ============================================================
  // LOADING BOX
  // ============================================================

  Widget _loadingBox({
    required String label,
  }) {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets
              .symmetric(
        horizontal: 16,
        vertical: 17,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          14,
        ),

        border: Border.all(
          color:
              const Color(
            0xFFE5E7EB,
          ),
        ),
      ),

      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child:
                CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Text(
            label,
            style:
                const TextStyle(
              color:
                  Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY BOX
  // ============================================================

  Widget _emptyBox({
    required IconData icon,
    required String message,
  }) {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(
        16,
      ),

      decoration:
          BoxDecoration(
        color:
            const Color(0xFFFFFBEB),

        borderRadius:
            BorderRadius.circular(
          14,
        ),

        border: Border.all(
          color:
              const Color(
            0xFFFDE68A,
          ),
        ),
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,

        children: [
          Icon(
            icon,
            color:
                const Color(
              0xFFD97706,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Text(
              message,
              style:
                  const TextStyle(
                fontSize: 13,
                color:
                    Color(
                  0xFF92400E,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MONTH NAME
  // ============================================================

  String _monthName(
    int month,
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

    return months[month - 1];
  }
}