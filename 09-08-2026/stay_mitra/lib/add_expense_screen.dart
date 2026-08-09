import 'package:flutter/material.dart';
import 'transaction_model.dart';
import 'transaction_service.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _amountController =
      TextEditingController();

  final TextEditingController _descriptionController =
      TextEditingController();

  final TextEditingController _customExpenseController =
      TextEditingController();

  PaymentMethod _paymentMethod = PaymentMethod.cash;

  DateTime _selectedDate = DateTime.now();

  ExpenseCategory? _selectedExpenseCategory;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _customExpenseController.dispose();
    super.dispose();
  }

  // ============================================================
  // SAVE EXPENSE
  // ============================================================

  void _saveExpense() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedExpenseCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an expense category'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedExpenseCategory == ExpenseCategory.other &&
        _customExpenseController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the custom expense name'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final amount = double.tryParse(
      _amountController.text.trim(),
    );

    if (amount == null || amount <= 0) {
      return;
    }

    final description = _descriptionController.text.trim();

    final transaction = TransactionModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: TransactionType.expense,
      paymentMethod: _paymentMethod,
      amount: amount,
      date: _selectedDate,
      description: description.isEmpty
          ? 'Expense'
          : description,
      expenseCategory: _selectedExpenseCategory,
      customExpenseCategory:
          _selectedExpenseCategory == ExpenseCategory.other
              ? _customExpenseController.text.trim()
              : null,
    );

    TransactionService.addTransaction(transaction);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Expense saved successfully'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context, true);
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
      helpText: 'Select Expense Date',
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // ============================================================
  // EXPENSE CATEGORY SELECTOR
  // ============================================================

  Future<void> _selectExpenseCategory() async {
    final selected = await showModalBottomSheet<ExpenseCategory>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return _ExpenseCategorySheet(
          selectedCategory: _selectedExpenseCategory,
        );
      },
    );

    if (selected != null) {
      setState(() {
        _selectedExpenseCategory = selected;

        if (selected != ExpenseCategory.other) {
          _customExpenseController.clear();
        }
      });
    }
  }

  // ============================================================
  // PAYMENT METHOD
  // ============================================================

  String _paymentMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash';

      case PaymentMethod.upi:
        return 'UPI';

      case PaymentMethod.bank:
        return 'Bank';
    }
  }

  IconData _paymentMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.payments_rounded;

      case PaymentMethod.upi:
        return Icons.qr_code_rounded;

      case PaymentMethod.bank:
        return Icons.account_balance_rounded;
    }
  }

  Color _paymentMethodColor(PaymentMethod method) {
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

  String _expenseCategoryName(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.rent:
        return 'Rent / Lease';

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
        return 'Electricity Bill';

      case ExpenseCategory.water:
        return 'Water Bill';

      case ExpenseCategory.gas:
        return 'Gas / LPG';

      case ExpenseCategory.internet:
        return 'Internet / Wi-Fi';

      case ExpenseCategory.dthCable:
        return 'DTH / Cable';

      case ExpenseCategory.garbage:
        return 'Garbage / Waste Collection';

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
        return 'Bonus / Incentive';

      case ExpenseCategory.phoneRecharge:
        return 'Phone / Mobile Recharge';

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
        return 'Referral / Commission';

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

      case ExpenseCategory.paymentGatewayCharges:
        return 'Payment Gateway Charges';

      case ExpenseCategory.other:
        return 'Other Expense';
    }
  }

  // ============================================================
  // CATEGORY ICON
  // ============================================================

  IconData _expenseCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.rent:
        return Icons.home_work_rounded;

      case ExpenseCategory.propertyMaintenance:
      case ExpenseCategory.buildingRepair:
      case ExpenseCategory.plumbing:
      case ExpenseCategory.electricalRepair:
        return Icons.build_rounded;

      case ExpenseCategory.painting:
        return Icons.format_paint_rounded;

      case ExpenseCategory.furniture:
        return Icons.chair_rounded;

      case ExpenseCategory.mattressBed:
        return Icons.bed_rounded;

      case ExpenseCategory.appliances:
        return Icons.kitchen_rounded;

      case ExpenseCategory.pestControl:
        return Icons.pest_control_rounded;

      case ExpenseCategory.electricity:
        return Icons.bolt_rounded;

      case ExpenseCategory.water:
        return Icons.water_drop_rounded;

      case ExpenseCategory.gas:
        return Icons.local_fire_department_rounded;

      case ExpenseCategory.internet:
        return Icons.wifi_rounded;

      case ExpenseCategory.dthCable:
        return Icons.tv_rounded;

      case ExpenseCategory.garbage:
        return Icons.delete_outline_rounded;

      case ExpenseCategory.groceries:
      case ExpenseCategory.vegetables:
      case ExpenseCategory.milk:
        return Icons.shopping_cart_rounded;

      case ExpenseCategory.kitchenSupplies:
        return Icons.restaurant_rounded;

      case ExpenseCategory.drinkingWater:
        return Icons.local_drink_rounded;

      case ExpenseCategory.cleaningSupplies:
        return Icons.cleaning_services_rounded;

      case ExpenseCategory.laundry:
        return Icons.local_laundry_service_rounded;

      case ExpenseCategory.housekeepingSalary:
      case ExpenseCategory.staffSalary:
      case ExpenseCategory.caretakerSalary:
      case ExpenseCategory.wardenSalary:
      case ExpenseCategory.securitySalary:
        return Icons.people_alt_rounded;

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
        return Icons.campaign_rounded;

      case ExpenseCategory.onlineListing:
        return Icons.language_rounded;

      case ExpenseCategory.referralCommission:
        return Icons.handshake_rounded;

      case ExpenseCategory.propertyTax:
      case ExpenseCategory.licenseFee:
      case ExpenseCategory.registrationFee:
        return Icons.description_rounded;

      case ExpenseCategory.legalProfessionalFee:
        return Icons.gavel_rounded;

      case ExpenseCategory.insurance:
        return Icons.security_rounded;

      case ExpenseCategory.loanEmi:
      case ExpenseCategory.loanInterest:
        return Icons.account_balance_wallet_rounded;

      case ExpenseCategory.paymentGatewayCharges:
        return Icons.payment_rounded;

      case ExpenseCategory.other:
        return Icons.add_circle_outline_rounded;
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
          'Add Expense',
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
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              30,
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _expenseInfoCard(),

                const SizedBox(height: 20),

                const Text(
                  'Expense Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),

                const SizedBox(height: 12),

                _amountField(),

                const SizedBox(height: 14),

                _dateField(),

                const SizedBox(height: 14),

                _expenseCategoryField(),

                if (_selectedExpenseCategory ==
                    ExpenseCategory.other) ...[
                  const SizedBox(height: 14),
                  _customExpenseField(),
                ],

                const SizedBox(height: 22),

                const Text(
                  'Paid From',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),

                const SizedBox(height: 12),

                _paymentMethodSelector(),

                const SizedBox(height: 22),

                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),

                const SizedBox(height: 12),

                _descriptionField(),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saveExpense,
                    icon: const Icon(
                      Icons.save_rounded,
                    ),
                    label: const Text(
                      'Save Expense',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      backgroundColor:
                          const Color(0xFFDC2626),
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
      width: double.infinity,
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFECACA),
        ),
      ),

      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Color(0xFFDC2626),
              size: 25,
            ),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Record an Expense',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF991B1B),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Record PG expenses such as electricity, maintenance or supplies.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7F1D1D),
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
  // AMOUNT
  // ============================================================

  Widget _amountField() {
    return TextFormField(
      controller: _amountController,

      keyboardType:
          const TextInputType.numberWithOptions(
        decimal: true,
      ),

      decoration: InputDecoration(
        labelText: 'Amount',
        hintText: 'Enter expense amount',

        prefixIcon: const Icon(
          Icons.currency_rupee_rounded,
        ),

        filled: true,
        fillColor: Colors.white,

        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFDC2626),
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
            double.tryParse(value.trim());

        if (amount == null || amount <= 0) {
          return 'Enter a valid amount';
        }

        return null;
      },
    );
  }

  // ============================================================
  // DATE
  // ============================================================

  Widget _dateField() {
    return InkWell(
      onTap: _selectDate,

      borderRadius:
          BorderRadius.circular(14),

      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Expense Date',

          prefixIcon: const Icon(
            Icons.calendar_today_rounded,
          ),

          suffixIcon: const Icon(
            Icons.arrow_drop_down_rounded,
          ),

          filled: true,
          fillColor: Colors.white,

          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFE5E7EB),
            ),
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFE5E7EB),
            ),
          ),
        ),

        child: Text(
          '${_selectedDate.day} '
          '${_monthName(_selectedDate.month)} '
          '${_selectedDate.year}',
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF111827),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EXPENSE CATEGORY FIELD
  // ============================================================

  Widget _expenseCategoryField() {
    final selected = _selectedExpenseCategory;

    return InkWell(
      onTap: _selectExpenseCategory,

      borderRadius:
          BorderRadius.circular(14),

      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Expense Category',

          prefixIcon: Icon(
            selected == null
                ? Icons.category_outlined
                : _expenseCategoryIcon(selected),
            color: selected == null
                ? const Color(0xFF6B7280)
                : const Color(0xFFDC2626),
          ),

          suffixIcon: const Icon(
            Icons.arrow_drop_down_rounded,
          ),

          filled: true,
          fillColor: Colors.white,

          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFE5E7EB),
            ),
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFE5E7EB),
            ),
          ),
        ),

        child: Text(
          selected == null
              ? 'Select expense category'
              : _expenseCategoryName(selected),
          style: TextStyle(
            fontSize: 15,
            color: selected == null
                ? const Color(0xFF9CA3AF)
                : const Color(0xFF111827),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CUSTOM EXPENSE
  // ============================================================

  Widget _customExpenseField() {
    return TextFormField(
      controller: _customExpenseController,

      textCapitalization:
          TextCapitalization.sentences,

      decoration: InputDecoration(
        labelText: 'Custom Expense Name',
        hintText: 'Example: Washing machine repair',

        prefixIcon: const Icon(
          Icons.edit_note_rounded,
        ),

        filled: true,
        fillColor: Colors.white,

        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFDC2626),
            width: 1.5,
          ),
        ),
      ),

      validator: (value) {
        if (_selectedExpenseCategory ==
                ExpenseCategory.other &&
            (value == null ||
                value.trim().isEmpty)) {
          return 'Please enter expense name';
        }

        return null;
      },
    );
  }

  // ============================================================
  // PAYMENT METHOD
  // ============================================================

  Widget _paymentMethodSelector() {
    return Row(
      children: [
        Expanded(
          child: _methodCard(
            PaymentMethod.cash,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _methodCard(
            PaymentMethod.upi,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _methodCard(
            PaymentMethod.bank,
          ),
        ),
      ],
    );
  }

  Widget _methodCard(
    PaymentMethod method,
  ) {
    final bool selected =
        _paymentMethod == method;

    final color =
        _paymentMethodColor(method);

    return InkWell(
      onTap: () {
        setState(() {
          _paymentMethod = method;
        });
      },

      borderRadius:
          BorderRadius.circular(14),

      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 6,
        ),

        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.08)
              : Colors.white,

          borderRadius:
              BorderRadius.circular(14),

          border: Border.all(
            color: selected
                ? color
                : const Color(0xFFE5E7EB),
            width: selected ? 1.5 : 1,
          ),
        ),

        child: Column(
          children: [
            Icon(
              _paymentMethodIcon(method),
              color: color,
              size: 25,
            ),

            const SizedBox(height: 7),

            Text(
              _paymentMethodName(method),
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected
                    ? FontWeight.bold
                    : FontWeight.w500,
                color: selected
                    ? color
                    : const Color(0xFF374151),
              ),
            ),

            if (selected) ...[
              const SizedBox(height: 5),

              Icon(
                Icons.check_circle_rounded,
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
          TextCapitalization.sentences,

      decoration: InputDecoration(
        hintText:
            'Example: Electricity bill for August',

        filled: true,
        fillColor: Colors.white,

        prefixIcon: const Padding(
          padding: EdgeInsets.only(
            bottom: 45,
          ),
          child: Icon(
            Icons.notes_rounded,
          ),
        ),

        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFDC2626),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _monthName(int month) {
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

// =================================================================
// EXPENSE CATEGORY BOTTOM SHEET
// =================================================================

class _ExpenseCategorySheet extends StatefulWidget {
  final ExpenseCategory? selectedCategory;

  const _ExpenseCategorySheet({
    required this.selectedCategory,
  });

  @override
  State<_ExpenseCategorySheet> createState() =>
      _ExpenseCategorySheetState();
}

class _ExpenseCategorySheetState
    extends State<_ExpenseCategorySheet> {
  final TextEditingController _searchController =
      TextEditingController();

  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // CATEGORY DATA
  // ============================================================

  final List<Map<String, dynamic>> _categories = [
    // Property
    {
      'group': 'Property / PG',
      'category': ExpenseCategory.rent,
      'icon': Icons.home_work_rounded,
    },
    {
      'group': 'Property / PG',
      'category': ExpenseCategory.propertyMaintenance,
      'icon': Icons.build_rounded,
    },
    {
      'group': 'Property / PG',
      'category': ExpenseCategory.buildingRepair,
      'icon': Icons.construction_rounded,
    },
    {
      'group': 'Property / PG',
      'category': ExpenseCategory.plumbing,
      'icon': Icons.plumbing_rounded,
    },
    {
      'group': 'Property / PG',
      'category': ExpenseCategory.electricalRepair,
      'icon': Icons.electrical_services_rounded,
    },
    {
      'group': 'Property / PG',
      'category': ExpenseCategory.painting,
      'icon': Icons.format_paint_rounded,
    },
    {
      'group': 'Property / PG',
      'category': ExpenseCategory.furniture,
      'icon': Icons.chair_rounded,
    },
    {
      'group': 'Property / PG',
      'category': ExpenseCategory.mattressBed,
      'icon': Icons.bed_rounded,
    },
    {
      'group': 'Property / PG',
      'category': ExpenseCategory.appliances,
      'icon': Icons.kitchen_rounded,
    },
    {
      'group': 'Property / PG',
      'category': ExpenseCategory.pestControl,
      'icon': Icons.pest_control_rounded,
    },

    // Utilities
    {
      'group': 'Utilities',
      'category': ExpenseCategory.electricity,
      'icon': Icons.bolt_rounded,
    },
    {
      'group': 'Utilities',
      'category': ExpenseCategory.water,
      'icon': Icons.water_drop_rounded,
    },
    {
      'group': 'Utilities',
      'category': ExpenseCategory.gas,
      'icon': Icons.local_fire_department_rounded,
    },
    {
      'group': 'Utilities',
      'category': ExpenseCategory.internet,
      'icon': Icons.wifi_rounded,
    },
    {
      'group': 'Utilities',
      'category': ExpenseCategory.dthCable,
      'icon': Icons.tv_rounded,
    },
    {
      'group': 'Utilities',
      'category': ExpenseCategory.garbage,
      'icon': Icons.delete_outline_rounded,
    },

    // Food
    {
      'group': 'Food & Kitchen',
      'category': ExpenseCategory.groceries,
      'icon': Icons.shopping_cart_rounded,
    },
    {
      'group': 'Food & Kitchen',
      'category': ExpenseCategory.vegetables,
      'icon': Icons.eco_rounded,
    },
    {
      'group': 'Food & Kitchen',
      'category': ExpenseCategory.milk,
      'icon': Icons.local_drink_rounded,
    },
    {
      'group': 'Food & Kitchen',
      'category': ExpenseCategory.kitchenSupplies,
      'icon': Icons.restaurant_rounded,
    },
    {
      'group': 'Food & Kitchen',
      'category': ExpenseCategory.drinkingWater,
      'icon': Icons.water_rounded,
    },

    // Housekeeping
    {
      'group': 'Housekeeping',
      'category': ExpenseCategory.cleaningSupplies,
      'icon': Icons.cleaning_services_rounded,
    },
    {
      'group': 'Housekeeping',
      'category': ExpenseCategory.laundry,
      'icon': Icons.local_laundry_service_rounded,
    },
    {
      'group': 'Housekeeping',
      'category': ExpenseCategory.housekeepingSalary,
      'icon': Icons.cleaning_services_rounded,
    },

    // Staff
    {
      'group': 'Staff & Salary',
      'category': ExpenseCategory.staffSalary,
      'icon': Icons.people_alt_rounded,
    },
    {
      'group': 'Staff & Salary',
      'category': ExpenseCategory.caretakerSalary,
      'icon': Icons.person_rounded,
    },
    {
      'group': 'Staff & Salary',
      'category': ExpenseCategory.wardenSalary,
      'icon': Icons.badge_rounded,
    },
    {
      'group': 'Staff & Salary',
      'category': ExpenseCategory.securitySalary,
      'icon': Icons.security_rounded,
    },
    {
      'group': 'Staff & Salary',
      'category': ExpenseCategory.bonus,
      'icon': Icons.card_giftcard_rounded,
    },

    // Operations
    {
      'group': 'Operations',
      'category': ExpenseCategory.phoneRecharge,
      'icon': Icons.phone_android_rounded,
    },
    {
      'group': 'Operations',
      'category': ExpenseCategory.printingStationery,
      'icon': Icons.print_rounded,
    },
    {
      'group': 'Operations',
      'category': ExpenseCategory.transportation,
      'icon': Icons.directions_car_rounded,
    },
    {
      'group': 'Operations',
      'category': ExpenseCategory.deliveryCourier,
      'icon': Icons.local_shipping_rounded,
    },
    {
      'group': 'Operations',
      'category': ExpenseCategory.bankCharges,
      'icon': Icons.account_balance_rounded,
    },

    // Marketing
    {
      'group': 'Marketing',
      'category': ExpenseCategory.advertising,
      'icon': Icons.campaign_rounded,
    },
    {
      'group': 'Marketing',
      'category': ExpenseCategory.onlineListing,
      'icon': Icons.language_rounded,
    },
    {
      'group': 'Marketing',
      'category': ExpenseCategory.referralCommission,
      'icon': Icons.handshake_rounded,
    },

    // Government
    {
      'group': 'Government / Compliance',
      'category': ExpenseCategory.propertyTax,
      'icon': Icons.receipt_long_rounded,
    },
    {
      'group': 'Government / Compliance',
      'category': ExpenseCategory.licenseFee,
      'icon': Icons.assignment_rounded,
    },
    {
      'group': 'Government / Compliance',
      'category': ExpenseCategory.registrationFee,
      'icon': Icons.app_registration_rounded,
    },
    {
      'group': 'Government / Compliance',
      'category': ExpenseCategory.legalProfessionalFee,
      'icon': Icons.gavel_rounded,
    },
    {
      'group': 'Government / Compliance',
      'category': ExpenseCategory.insurance,
      'icon': Icons.security_rounded,
    },

    // Finance
    {
      'group': 'Finance',
      'category': ExpenseCategory.loanEmi,
      'icon': Icons.account_balance_wallet_rounded,
    },
    {
      'group': 'Finance',
      'category': ExpenseCategory.loanInterest,
      'icon': Icons.percent_rounded,
    },
    {
      'group': 'Finance',
      'category': ExpenseCategory.paymentGatewayCharges,
      'icon': Icons.payment_rounded,
    },
    {
      'group': 'Finance',
      'category': ExpenseCategory.bankCharges,
      'icon': Icons.account_balance_rounded,
    },

    // Other
    {
      'group': 'Other',
      'category': ExpenseCategory.other,
      'icon': Icons.add_circle_outline_rounded,
    },
  ];

  String _categoryName(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.rent:
        return 'Rent / Lease';
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
        return 'Electricity Bill';
      case ExpenseCategory.water:
        return 'Water Bill';
      case ExpenseCategory.gas:
        return 'Gas / LPG';
      case ExpenseCategory.internet:
        return 'Internet / Wi-Fi';
      case ExpenseCategory.dthCable:
        return 'DTH / Cable';
      case ExpenseCategory.garbage:
        return 'Garbage / Waste Collection';

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
        return 'Bonus / Incentive';

      case ExpenseCategory.phoneRecharge:
        return 'Phone / Mobile Recharge';
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
        return 'Referral / Commission';

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
      case ExpenseCategory.paymentGatewayCharges:
        return 'Payment Gateway Charges';

      case ExpenseCategory.other:
        return 'Other Expense';
    }
  }

  // ============================================================
  // BUILD CATEGORY SHEET
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final filtered = _categories.where((item) {
      final category =
          item['category'] as ExpenseCategory;

      final name =
          _categoryName(category).toLowerCase();

      return name.contains(
        _searchText.toLowerCase(),
      );
    }).toList();

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.82,
        child: Column(
          children: [
            const Text(
              'Select Expense Category',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchText = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search expense...',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                  ),
                  suffixIcon:
                      _searchText.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchText = '';
                                });
                              },
                              icon: const Icon(
                                Icons.clear_rounded,
                              ),
                            )
                          : null,
                  filled: true,
                  fillColor:
                      const Color(0xFFF7F8FC),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  4,
                  20,
                  20,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final item = filtered[index];

                  final category =
                      item['category']
                          as ExpenseCategory;

                  final icon =
                      item['icon'] as IconData;

                  final selected =
                      widget.selectedCategory ==
                          category;

                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(
                      vertical: 2,
                    ),

                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFFEFF6FF,
                        ),
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: const Color(
                          0xFF2563EB,
                        ),
                        size: 22,
                      ),
                    ),

                    title: Text(
                      _categoryName(category),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    subtitle: Text(
                      item['group'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(
                          0xFF6B7280,
                        ),
                      ),
                    ),

                    trailing: selected
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: Color(
                              0xFF2563EB,
                            ),
                          )
                        : const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(
                              0xFF9CA3AF,
                            ),
                          ),

                    onTap: () {
                      Navigator.pop(
                        context,
                        category,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}