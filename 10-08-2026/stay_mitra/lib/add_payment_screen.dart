import 'package:flutter/material.dart';
import 'transaction_model.dart';
import 'transaction_service.dart';

class AddPaymentScreen extends StatefulWidget {
  const AddPaymentScreen({super.key});

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _amountController =
      TextEditingController();

  final TextEditingController _tenantController =
      TextEditingController();

  final TextEditingController _descriptionController =
      TextEditingController();

  PaymentMethod _paymentMethod = PaymentMethod.cash;

  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _tenantController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // SAVE PAYMENT
  // ------------------------------------------------------------

  void _savePayment() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.tryParse(
      _amountController.text.trim(),
    );

    if (amount == null || amount <= 0) {
      return;
    }

    final tenantName = _tenantController.text.trim();
    final description = _descriptionController.text.trim();

    final transaction = TransactionModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: TransactionType.income,
      paymentMethod: _paymentMethod,
      amount: amount,
      date: _selectedDate,
      description: description.isEmpty
          ? 'Payment - $tenantName'
          : '$tenantName - $description',
    );

    TransactionService.addTransaction(transaction);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment saved successfully'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context, true);
  }

  // ------------------------------------------------------------
  // DATE PICKER
  // ------------------------------------------------------------

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Select Payment Date',
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // ------------------------------------------------------------
  // PAYMENT METHOD
  // ------------------------------------------------------------

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
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              30,
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _paymentInfoCard(),

                const SizedBox(height: 20),

                const Text(
                  'Payment Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),

                const SizedBox(height: 12),

                _amountField(),

                const SizedBox(height: 14),

                _tenantField(),

                const SizedBox(height: 14),

                _dateField(),

                const SizedBox(height: 22),

                const Text(
                  'Payment Method',
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
                    onPressed: _savePayment,

                    icon: const Icon(
                      Icons.save_rounded,
                    ),

                    label: const Text(
                      'Save Payment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),

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
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // PAYMENT INFO CARD
  // ------------------------------------------------------------

  Widget _paymentInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFDBEAFE),
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
              Icons.currency_rupee_rounded,
              color: Color(0xFF2563EB),
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
                  'Record a Payment',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  'Add rent or other income received from a tenant.',
                  style: TextStyle(
                    fontSize: 12,
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

  // ------------------------------------------------------------
  // AMOUNT FIELD
  // ------------------------------------------------------------

  Widget _amountField() {
    return TextFormField(
      controller: _amountController,

      keyboardType:
          const TextInputType.numberWithOptions(
        decimal: true,
      ),

      decoration: InputDecoration(
        labelText: 'Amount',
        hintText: 'Enter amount',
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
            color: Color(0xFF2563EB),
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

  // ------------------------------------------------------------
  // TENANT FIELD
  // ------------------------------------------------------------

  Widget _tenantField() {
    return TextFormField(
      controller: _tenantController,

      textCapitalization:
          TextCapitalization.words,

      decoration: InputDecoration(
        labelText: 'Tenant Name',
        hintText: 'Enter tenant name',

        prefixIcon: const Icon(
          Icons.person_outline_rounded,
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
            color: Color(0xFF2563EB),
            width: 1.5,
          ),
        ),
      ),

      validator: (value) {
        if (value == null ||
            value.trim().isEmpty) {
          return 'Please enter tenant name';
        }

        return null;
      },
    );
  }

  // ------------------------------------------------------------
  // DATE FIELD
  // ------------------------------------------------------------

  Widget _dateField() {
    return InkWell(
      onTap: _selectDate,

      borderRadius:
          BorderRadius.circular(14),

      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Payment Date',

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

  // ------------------------------------------------------------
  // PAYMENT METHOD SELECTOR
  // ------------------------------------------------------------

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

  // ------------------------------------------------------------
  // DESCRIPTION
  // ------------------------------------------------------------

  Widget _descriptionField() {
    return TextFormField(
      controller:
          _descriptionController,

      maxLines: 3,

      textCapitalization:
          TextCapitalization.sentences,

      decoration: InputDecoration(
        hintText:
            'Example: August rent payment',

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
            color: Color(0xFF2563EB),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------

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