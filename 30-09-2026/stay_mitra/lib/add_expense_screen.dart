import 'package:flutter/material.dart';

import 'transaction_model.dart';
import 'transaction_service.dart';

class AddExpenseScreen extends StatefulWidget {
  // ============================================================
  // BUILDING / PG ID
  // ============================================================
  //
  // This screen is opened for a specific PG / Building.
  //
  // Example:
  //
  // AddExpenseScreen(
  //   buildingId: selectedBuildingId,
  // )
  //
  // The expense will be stored against this building only.
  // ============================================================

  final String buildingId;

  const AddExpenseScreen({
    super.key,
    required this.buildingId,
  });

  @override
  State<AddExpenseScreen> createState() =>
      _AddExpenseScreenState();
}

class _AddExpenseScreenState
    extends State<AddExpenseScreen> {
  // ============================================================
  // FORM
  // ============================================================

  final _formKey =
      GlobalKey<FormState>();

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController
      _amountController =
      TextEditingController();

  final TextEditingController
      _descriptionController =
      TextEditingController();

  final TextEditingController
      _customCategoryController =
      TextEditingController();

  // ============================================================
  // PAYMENT METHOD
  // ============================================================

  PaymentMethod _paymentMethod =
      PaymentMethod.cash;

  // ============================================================
  // DATE
  // ============================================================

  DateTime _selectedDate =
      DateTime.now();

  // ============================================================
  // EXPENSE CATEGORY
  // ============================================================

  ExpenseCategory?
      _selectedExpenseCategory;

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _amountController.dispose();

    _descriptionController.dispose();

    _customCategoryController.dispose();

    super.dispose();
  }

  // ============================================================
  // SAVE EXPENSE
  // ============================================================

  void _saveExpense() {
    // ----------------------------------------------------------
    // VALIDATE FORM
    // ----------------------------------------------------------

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // ----------------------------------------------------------
    // PARSE AMOUNT
    // ----------------------------------------------------------

    final amount = double.tryParse(
      _amountController.text.trim(),
    );

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid expense amount',
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );

      return;
    }

    // ----------------------------------------------------------
    // CATEGORY VALIDATION
    // ----------------------------------------------------------

    if (_selectedExpenseCategory == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please select an expense category',
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );

      return;
    }

    // ----------------------------------------------------------
    // CUSTOM CATEGORY VALIDATION
    // ----------------------------------------------------------

    if (_selectedExpenseCategory ==
            ExpenseCategory.other &&
        _customCategoryController.text
            .trim()
            .isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter the custom expense category',
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );

      return;
    }

    // ----------------------------------------------------------
    // DESCRIPTION
    // ----------------------------------------------------------

    final description =
        _descriptionController.text.trim();

    // ----------------------------------------------------------
    // CUSTOM CATEGORY
    // ----------------------------------------------------------

    final customCategory =
        _selectedExpenseCategory ==
                ExpenseCategory.other
            ? _customCategoryController
                .text
                .trim()
            : null;

    // ==========================================================
    // CREATE TRANSACTION
    // ==========================================================
    //
    // IMPORTANT:
    //
    // buildingId is now stored here.
    //
    // This makes the transaction belong to the current PG /
    // Building and prevents data from different PGs mixing.
    // ==========================================================

    final transaction =
        TransactionModel(
      id: DateTime.now()
          .microsecondsSinceEpoch
          .toString(),

      type:
          TransactionType.expense,

      paymentMethod:
          _paymentMethod,

      amount: amount,

      date: _selectedDate,

      description:
          description.isEmpty
              ? 'Expense'
              : description,

      // --------------------------------------------------------
      // MULTI-BUILDING SUPPORT
      // --------------------------------------------------------

      buildingId:
          widget.buildingId,

      // --------------------------------------------------------
      // EXPENSE CATEGORY
      // --------------------------------------------------------

      expenseCategory:
          _selectedExpenseCategory,

      customExpenseCategory:
          customCategory,
    );

    // ==========================================================
    // SAVE
    // ==========================================================

    TransactionService.addTransaction(
      transaction,
    );

    // ==========================================================
    // SUCCESS MESSAGE
    // ==========================================================

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Expense saved successfully',
        ),
        behavior:
            SnackBarBehavior.floating,
      ),
    );

    // ==========================================================
    // RETURN TO PREVIOUS PAGE
    // ==========================================================

    Navigator.pop(
      context,
      true,
    );
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _selectDate() async {
    final picked =
        await showDatePicker(
      context: context,

      initialDate:
          _selectedDate,

      firstDate:
          DateTime(2020),

      lastDate:
          DateTime(2100),

      helpText:
          'Select Expense Date',
    );

    if (picked != null &&
        mounted) {
      setState(() {
        _selectedDate =
            DateTime(
          picked.year,
          picked.month,
          picked.day,
        );
      });
    }
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
  // EXPENSE CATEGORY NAME
  // ============================================================

  String _expenseCategoryName(
    ExpenseCategory category,
  ) {
    switch (category) {
      case ExpenseCategory.rent:
        return 'Property Rent';

      case ExpenseCategory.propertyMaintenance:
        return 'Property Maintenance';

      case ExpenseCategory.buildingRepair:
        return 'Building Repair';

      case ExpenseCategory.plumbing:
        return 'Plumbing';

      case ExpenseCategory.electricalRepair:
        return 'Electrical Repair';

      case ExpenseCategory.painting:
        return 'Painting';

      case ExpenseCategory.furniture:
        return 'Furniture';

      case ExpenseCategory.mattressBed:
        return 'Mattress / Bed';

      case ExpenseCategory.appliances:
        return 'Appliances';

      case ExpenseCategory.pestControl:
        return 'Pest Control';

      case ExpenseCategory.electricity:
        return 'Electricity';

      case ExpenseCategory.water:
        return 'Water';

      case ExpenseCategory.gas:
        return 'Gas';

      case ExpenseCategory.internet:
        return 'Internet';

      case ExpenseCategory.dthCable:
        return 'DTH / Cable';

      case ExpenseCategory.garbage:
        return 'Garbage';

      case ExpenseCategory.groceries:
        return 'Groceries';

      case ExpenseCategory.vegetables:
        return 'Vegetables';

      case ExpenseCategory.milk:
        return 'Milk';

      case ExpenseCategory.kitchenSupplies:
        return 'Kitchen Supplies';

      case ExpenseCategory.drinkingWater:
        return 'Drinking Water';

      case ExpenseCategory.cleaningSupplies:
        return 'Cleaning Supplies';

      case ExpenseCategory.laundry:
        return 'Laundry';

      case ExpenseCategory.housekeepingSalary:
        return 'Housekeeping Salary';

      case ExpenseCategory.staffSalary:
        return 'Staff Salary';

      case ExpenseCategory.caretakerSalary:
        return 'Caretaker Salary';

      case ExpenseCategory.wardenSalary:
        return 'Warden Salary';

      case ExpenseCategory.securitySalary:
        return 'Security Salary';

      case ExpenseCategory.bonus:
        return 'Bonus';

      case ExpenseCategory.phoneRecharge:
        return 'Phone Recharge';

      case ExpenseCategory.printingStationery:
        return 'Printing / Stationery';

      case ExpenseCategory.transportation:
        return 'Transportation';

      case ExpenseCategory.deliveryCourier:
        return 'Delivery / Courier';

      case ExpenseCategory.bankCharges:
        return 'Bank Charges';

      case ExpenseCategory.advertising:
        return 'Advertising';

      case ExpenseCategory.onlineListing:
        return 'Online Listing';

      case ExpenseCategory.referralCommission:
        return 'Referral Commission';

      case ExpenseCategory.propertyTax:
        return 'Property Tax';

      case ExpenseCategory.licenseFee:
        return 'License Fee';

      case ExpenseCategory.registrationFee:
        return 'Registration Fee';

      case ExpenseCategory.legalProfessionalFee:
        return 'Legal / Professional Fee';

      case ExpenseCategory.insurance:
        return 'Insurance';

      case ExpenseCategory.loanEmi:
        return 'Loan EMI';

      case ExpenseCategory.loanInterest:
        return 'Loan Interest';

      case ExpenseCategory
          .paymentGatewayCharges:
        return 'Payment Gateway Charges';

      case ExpenseCategory.other:
        return 'Other';
    }
  }

  // ============================================================
  // CATEGORY GROUPS
  // ============================================================

  List<ExpenseCategory>
      _propertyMaintenanceCategories() {
    return [
      ExpenseCategory.rent,
      ExpenseCategory.propertyMaintenance,
      ExpenseCategory.buildingRepair,
      ExpenseCategory.plumbing,
      ExpenseCategory.electricalRepair,
      ExpenseCategory.painting,
      ExpenseCategory.furniture,
      ExpenseCategory.mattressBed,
      ExpenseCategory.appliances,
      ExpenseCategory.pestControl,
    ];
  }

  List<ExpenseCategory>
      _utilityCategories() {
    return [
      ExpenseCategory.electricity,
      ExpenseCategory.water,
      ExpenseCategory.gas,
      ExpenseCategory.internet,
      ExpenseCategory.dthCable,
      ExpenseCategory.garbage,
    ];
  }

  List<ExpenseCategory>
      _foodKitchenCategories() {
    return [
      ExpenseCategory.groceries,
      ExpenseCategory.vegetables,
      ExpenseCategory.milk,
      ExpenseCategory.kitchenSupplies,
      ExpenseCategory.drinkingWater,
    ];
  }

  List<ExpenseCategory>
      _housekeepingCategories() {
    return [
      ExpenseCategory.cleaningSupplies,
      ExpenseCategory.laundry,
      ExpenseCategory.housekeepingSalary,
    ];
  }

  List<ExpenseCategory>
      _staffCategories() {
    return [
      ExpenseCategory.staffSalary,
      ExpenseCategory.caretakerSalary,
      ExpenseCategory.wardenSalary,
      ExpenseCategory.securitySalary,
      ExpenseCategory.bonus,
    ];
  }

  List<ExpenseCategory>
      _operationsCategories() {
    return [
      ExpenseCategory.phoneRecharge,
      ExpenseCategory.printingStationery,
      ExpenseCategory.transportation,
      ExpenseCategory.deliveryCourier,
      ExpenseCategory.bankCharges,
    ];
  }

  List<ExpenseCategory>
      _marketingCategories() {
    return [
      ExpenseCategory.advertising,
      ExpenseCategory.onlineListing,
      ExpenseCategory.referralCommission,
    ];
  }

  List<ExpenseCategory>
      _legalCategories() {
    return [
      ExpenseCategory.propertyTax,
      ExpenseCategory.licenseFee,
      ExpenseCategory.registrationFee,
      ExpenseCategory.legalProfessionalFee,
      ExpenseCategory.insurance,
    ];
  }

  List<ExpenseCategory>
      _financialCategories() {
    return [
      ExpenseCategory.loanEmi,
      ExpenseCategory.loanInterest,
      ExpenseCategory.paymentGatewayCharges,
    ];
  }

  // ============================================================
  // EXPENSE CATEGORY ICON
  // ============================================================

  IconData _expenseCategoryIcon(
    ExpenseCategory category,
  ) {
    switch (category) {
      case ExpenseCategory.rent:
        return Icons.home_work_rounded;

      case ExpenseCategory.propertyMaintenance:
      case ExpenseCategory.buildingRepair:
      case ExpenseCategory.plumbing:
      case ExpenseCategory.electricalRepair:
      case ExpenseCategory.painting:
        return Icons.build_rounded;

      case ExpenseCategory.furniture:
      case ExpenseCategory.mattressBed:
        return Icons.bed_rounded;

      case ExpenseCategory.appliances:
        return Icons.kitchen_rounded;

      case ExpenseCategory.pestControl:
        return Icons.pest_control_rounded;

      case ExpenseCategory.electricity:
        return Icons.bolt_rounded;

      case ExpenseCategory.water:
      case ExpenseCategory.drinkingWater:
        return Icons.water_drop_rounded;

      case ExpenseCategory.gas:
        return Icons.local_fire_department_rounded;

      case ExpenseCategory.internet:
        return Icons.wifi_rounded;

      case ExpenseCategory.dthCable:
        return Icons.tv_rounded;

      case ExpenseCategory.garbage:
      case ExpenseCategory.cleaningSupplies:
        return Icons.cleaning_services_rounded;

      case ExpenseCategory.groceries:
      case ExpenseCategory.vegetables:
      case ExpenseCategory.milk:
      case ExpenseCategory.kitchenSupplies:
        return Icons.shopping_cart_rounded;

      case ExpenseCategory.laundry:
        return Icons.local_laundry_service_rounded;

      case ExpenseCategory.housekeepingSalary:
      case ExpenseCategory.staffSalary:
      case ExpenseCategory.caretakerSalary:
      case ExpenseCategory.wardenSalary:
      case ExpenseCategory.securitySalary:
        return Icons.badge_rounded;

      case ExpenseCategory.bonus:
        return Icons.card_giftcard_rounded;

      case ExpenseCategory.phoneRecharge:
        return Icons.phone_android_rounded;

      case ExpenseCategory.printingStationery:
        return Icons.print_rounded;

      case ExpenseCategory.transportation:
        return Icons.directions_car_rounded;

      case ExpenseCategory.deliveryCourier:
        return Icons.local_shipping_rounded;

      case ExpenseCategory.bankCharges:
        return Icons.account_balance_rounded;

      case ExpenseCategory.advertising:
      case ExpenseCategory.onlineListing:
        return Icons.campaign_rounded;

      case ExpenseCategory.referralCommission:
        return Icons.people_alt_rounded;

      case ExpenseCategory.propertyTax:
        return Icons.receipt_long_rounded;

      case ExpenseCategory.licenseFee:
      case ExpenseCategory.registrationFee:
      case ExpenseCategory.legalProfessionalFee:
        return Icons.description_rounded;

      case ExpenseCategory.insurance:
        return Icons.security_rounded;

      case ExpenseCategory.loanEmi:
      case ExpenseCategory.loanInterest:
        return Icons.credit_card_rounded;

      case ExpenseCategory.paymentGatewayCharges:
        return Icons.payment_rounded;

      case ExpenseCategory.other:
        return Icons.more_horiz_rounded;
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F8FC),

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        elevation: 0,

        backgroundColor:
            Colors.white,

        foregroundColor:
            const Color(0xFF111827),

        title: const Text(
          'Add Expense',
          style: TextStyle(
            fontSize: 20,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: Form(
          key: _formKey,

          child:
              SingleChildScrollView(
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
                // ------------------------------------------------
                // INFO CARD
                // ------------------------------------------------

                _expenseInfoCard(),

                const SizedBox(
                  height: 20,
                ),

                // ------------------------------------------------
                // EXPENSE DETAILS
                // ------------------------------------------------

                const Text(
                  'Expense Details',
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

                // Amount

                _amountField(),

                const SizedBox(
                  height: 14,
                ),

                // Category

                _categoryField(),

                // Custom category

                if (_selectedExpenseCategory ==
                    ExpenseCategory.other) ...[
                  const SizedBox(
                    height: 14,
                  ),
                  _customCategoryField(),
                ],

                const SizedBox(
                  height: 14,
                ),

                // Date

                _dateField(),

                const SizedBox(
                  height: 22,
                ),

                // ------------------------------------------------
                // PAYMENT METHOD
                // ------------------------------------------------

                const Text(
                  'Paid From',
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

                // ------------------------------------------------
                // DESCRIPTION
                // ------------------------------------------------

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

                // ------------------------------------------------
                // SAVE BUTTON
                // ------------------------------------------------

                SizedBox(
                  width:
                      double.infinity,

                  child:
                      ElevatedButton.icon(
                    onPressed:
                        _saveExpense,

                    icon: const Icon(
                      Icons.save_rounded,
                    ),

                    label: const Text(
                      'Save Expense',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    style:
                        ElevatedButton
                            .styleFrom(
                      minimumSize:
                          const Size
                              .fromHeight(
                        54,
                      ),

                      backgroundColor:
                          const Color(
                        0xFFDC2626,
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
  // INFO CARD
  // ============================================================

  Widget _expenseInfoCard() {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(
        16,
      ),

      decoration:
          BoxDecoration(
        color:
            const Color(0xFFFEF2F2),

        borderRadius:
            BorderRadius.circular(
          18,
        ),

        border:
            Border.all(
          color:
              const Color(0xFFFECACA),
        ),
      ),

      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,

            decoration:
                BoxDecoration(
              color:
                  Colors.white,

              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),

            child: const Icon(
              Icons.receipt_long_rounded,

              color:
                  Color(0xFFDC2626),

              size: 25,
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  'Record an Expense',

                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Color(0xFF991B1B),
                  ),
                ),

                SizedBox(
                  height: 4,
                ),

                Text(
                  'Track electricity, maintenance, food, staff and other PG expenses.',

                  style: TextStyle(
                    fontSize: 12,
                    color:
                        Color(0xFF7F1D1D),
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
          InputDecoration(
        labelText:
            'Amount',

        hintText:
            'Enter expense amount',

        prefixIcon:
            const Icon(
          Icons.currency_rupee_rounded,
        ),

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
                Color(0xFFDC2626),
            width: 1.5,
          ),
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
  // EXPENSE CATEGORY FIELD
  // ============================================================

  Widget _categoryField() {
    return DropdownButtonFormField<
        Object>(
      initialValue:
          _selectedExpenseCategory,

      isExpanded: true,

      decoration:
          InputDecoration(
        labelText:
            'Expense Category',

        hintText:
            'Select expense category',

        prefixIcon:
            const Icon(
          Icons.category_rounded,
        ),

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
                Color(0xFFDC2626),
            width: 1.5,
          ),
        ),
      ),

      items: [
        _categoryHeader(
          'Property & Maintenance',
        ),

        ..._propertyMaintenanceCategories()
            .map(
          _categoryItem,
        ),

        _categoryHeader(
          'Utilities',
        ),

        ..._utilityCategories()
            .map(
          _categoryItem,
        ),

        _categoryHeader(
          'Food & Kitchen',
        ),

        ..._foodKitchenCategories()
            .map(
          _categoryItem,
        ),

        _categoryHeader(
          'Housekeeping',
        ),

        ..._housekeepingCategories()
            .map(
          _categoryItem,
        ),

        _categoryHeader(
          'Staff',
        ),

        ..._staffCategories()
            .map(
          _categoryItem,
        ),

        _categoryHeader(
          'Operations',
        ),

        ..._operationsCategories()
            .map(
          _categoryItem,
        ),

        _categoryHeader(
          'Marketing',
        ),

        ..._marketingCategories()
            .map(
          _categoryItem,
        ),

        _categoryHeader(
          'Legal & Property',
        ),

        ..._legalCategories()
            .map(
          _categoryItem,
        ),

        _categoryHeader(
          'Financial',
        ),

        ..._financialCategories()
            .map(
          _categoryItem,
        ),

        _categoryHeader(
          'Other',
        ),

        _categoryItem(
          ExpenseCategory.other,
        ),
      ],

      onChanged: (value) {
        if (value
            is ExpenseCategory) {
          setState(() {
            _selectedExpenseCategory =
                value;

            if (value !=
                ExpenseCategory
                    .other) {
              _customCategoryController
                  .clear();
            }
          });
        }
      },

      validator: (value) {
        if (value
            is! ExpenseCategory) {
          return 'Please select expense category';
        }

        return null;
      },
    );
  }

  // ============================================================
  // CATEGORY HEADER
  // ============================================================

  DropdownMenuItem<Object>
      _categoryHeader(
    String title,
  ) {
    return DropdownMenuItem<Object>(
      enabled: false,

      value:
          'header_$title',

      child: Text(
        title,

        style:
            const TextStyle(
          fontSize: 13,
          fontWeight:
              FontWeight.bold,
          color:
              Color(0xFF6B7280),
        ),
      ),
    );
  }

  // ============================================================
  // CATEGORY ITEM
  // ============================================================

  DropdownMenuItem<Object>
      _categoryItem(
    ExpenseCategory category,
  ) {
    return DropdownMenuItem<Object>(
      value: category,

      child: Row(
        children: [
          Icon(
            _expenseCategoryIcon(
              category,
            ),

            size: 19,

            color:
                const Color(
              0xFFDC2626,
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Text(
              _expenseCategoryName(
                category,
              ),

              overflow:
                  TextOverflow
                      .ellipsis,

              style:
                  const TextStyle(
                fontSize: 14,
                color:
                    Color(
                  0xFF111827,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CUSTOM CATEGORY
  // ============================================================

  Widget _customCategoryField() {
    return TextFormField(
      controller:
          _customCategoryController,

      textCapitalization:
          TextCapitalization
              .sentences,

      decoration:
          InputDecoration(
        labelText:
            'Custom Expense Category',

        hintText:
            'Example: RO Water Filter Service',

        prefixIcon:
            const Icon(
          Icons.edit_note_rounded,
        ),

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
                Color(0xFFDC2626),
            width: 1.5,
          ),
        ),
      ),

      validator: (value) {
        if (_selectedExpenseCategory ==
                ExpenseCategory.other &&
            (value == null ||
                value.trim().isEmpty)) {
          return 'Please enter custom category';
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

      child:
          InputDecorator(
        decoration:
            InputDecoration(
          labelText:
              'Expense Date',

          prefixIcon:
              const Icon(
            Icons.calendar_today_rounded,
          ),

          suffixIcon:
              const Icon(
            Icons.arrow_drop_down_rounded,
          ),

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
    final bool selected =
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

          border:
              Border.all(
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

              color:
                  color,

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

                fontWeight: selected
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

                color:
                    color,
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
          InputDecoration(
        hintText:
            'Example: Electricity bill for August',

        filled: true,

        fillColor:
            Colors.white,

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
                Color(0xFFDC2626),
            width: 1.5,
          ),
        ),
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

    return months[
        month - 1];
  }
}