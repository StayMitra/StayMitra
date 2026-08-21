import 'package:flutter/material.dart';

import 'database_helper.dart';
import 'transaction_model.dart';
import 'transaction_history_screen.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  List<TransactionModel> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  // ------------------------------------------------------------
  // LOAD TRANSACTIONS FROM SQLITE
  // ------------------------------------------------------------

  Future<void> _loadTransactions() async {
    final transactions =
        await DatabaseHelper.instance.getTransactions();

    if (!mounted) {
      return;
    }

    setState(() {
      _transactions = transactions;
      _isLoading = false;
    });
  }

  // ------------------------------------------------------------
  // BALANCES
  // ------------------------------------------------------------

  double _balanceForMethod(PaymentMethod method) {
    double balance = 0;

    for (final transaction in _transactions) {
      if (transaction.paymentMethod != method) {
        continue;
      }

      if (transaction.type == TransactionType.income) {
        balance += transaction.amount;
      } else {
        balance -= transaction.amount;
      }
    }

    return balance;
  }

  double get _cashBalance =>
      _balanceForMethod(PaymentMethod.cash);

  double get _upiBalance =>
      _balanceForMethod(PaymentMethod.upi);

  double get _bankBalance =>
      _balanceForMethod(PaymentMethod.bank);

  double get _totalBalance =>
      _cashBalance + _upiBalance + _bankBalance;

  // ------------------------------------------------------------
  // MONEY FORMAT
  // ------------------------------------------------------------

  String _money(double value) {
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
        );
  }

  // ------------------------------------------------------------
  // PAYMENT METHOD NAME
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

  // ------------------------------------------------------------
  // PAYMENT METHOD ICON
  // ------------------------------------------------------------

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

  // ------------------------------------------------------------
  // PAYMENT METHOD COLOR
  // ------------------------------------------------------------

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
  // TRANSACTION TITLE
  // ------------------------------------------------------------

  String _transactionTitle(
    TransactionModel transaction,
  ) {
    // ----------------------------------------------------------
    // INCOME
    // ----------------------------------------------------------

    if (transaction.type == TransactionType.income) {
      final description =
          transaction.description.trim();

      if (description.isNotEmpty) {
        return description;
      }

      return 'Payment';
    }

    // ----------------------------------------------------------
    // EXPENSE - OTHER WITH CUSTOM CATEGORY
    // ----------------------------------------------------------

    if (transaction.expenseCategory ==
        ExpenseCategory.other) {
      final customCategory =
          transaction.customExpenseCategory?.trim();

      if (customCategory != null &&
          customCategory.isNotEmpty) {
        return customCategory;
      }

      final description =
          transaction.description.trim();

      if (description.isNotEmpty &&
          description.toLowerCase() != 'expense') {
        return description;
      }

      return 'Other Expense';
    }

    // ----------------------------------------------------------
    // EXPENSE - CATEGORY AVAILABLE
    // ----------------------------------------------------------

    if (transaction.expenseCategory != null) {
      return _expenseCategoryName(
        transaction.expenseCategory!,
      );
    }

    // ----------------------------------------------------------
    // OLD TRANSACTIONS WITHOUT CATEGORY
    // ----------------------------------------------------------

    final description =
        transaction.description.trim();

    if (description.isNotEmpty) {
      return description;
    }

    return 'Expense';
  }

  // ------------------------------------------------------------
  // EXPENSE CATEGORY NAME
  // ------------------------------------------------------------

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

      case ExpenseCategory.paymentGatewayCharges:
        return 'Payment Gateway Charges';

      case ExpenseCategory.other:
        return 'Other';
    }
  }

  // ------------------------------------------------------------
  // TRANSACTION DATE
  // ------------------------------------------------------------

  String _formatDate(DateTime date) {
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

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // ------------------------------------------------------------
  // DELETE TRANSACTION
  // ------------------------------------------------------------

  Future<void> _deleteTransaction(
    TransactionModel transaction,
  ) async {
    await DatabaseHelper.instance.deleteTransaction(
      transaction.id,
    );

    await _loadTransactions();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Transaction deleted successfully',
        ),
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
      backgroundColor: const Color(0xFFF7F9FC),

      // ----------------------------------------------------------
      // APP BAR
      // ----------------------------------------------------------

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),

        title: const Text(
          'Accounts',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            onPressed: _loadTransactions,
            tooltip: 'Refresh',
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),

      // ----------------------------------------------------------
      // BODY
      // ----------------------------------------------------------

      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadTransactions,

              child: SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),

                padding: const EdgeInsets.fromLTRB(
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
                    // BALANCE SUMMARY
                    // ------------------------------------------------

                    _balanceSummary(),

                    const SizedBox(height: 22),

                    // ------------------------------------------------
                    // RECENT TRANSACTIONS HEADER
                    // ------------------------------------------------

                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Recent Transactions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                              color:
                                  Color(0xFF111827),
                            ),
                          ),
                        ),

                        // View All appears only when
                        // more than 3 transactions exist.
                        if (_transactions.isNotEmpty)
                          TextButton.icon(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const TransactionHistoryScreen(),
                                ),
                              );

                              await _loadTransactions();
                            },
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                            ),
                            label: const Text(
                              'View All',
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ------------------------------------------------
                    // TRANSACTIONS
                    // ------------------------------------------------

                    _transactionsList(),
                  ],
                ),
              ),
            ),
    );
  }

  // ------------------------------------------------------------
  // BALANCE SUMMARY
  // ------------------------------------------------------------

  Widget _balanceSummary() {
    return Column(
      children: [
        // ----------------------------------------------------------
        // TOTAL BALANCE
        // ----------------------------------------------------------

        Container(
          width: double.infinity,

          padding: const EdgeInsets.all(20),

          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),

            borderRadius:
                BorderRadius.circular(20),

            border: Border.all(
              color: const Color(0xFFBFDBFE),
            ),
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              const Text(
                'Total Balance',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1E3A8A),
                ),
              ),

              const SizedBox(height: 6),

              Text(
                '₹ ${_money(_totalBalance)}',

                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D4ED8),
                ),
              ),

              const SizedBox(height: 4),

              Text(
                '${_transactions.length} Transactions',

                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ----------------------------------------------------------
        // CASH / UPI / BANK
        // ----------------------------------------------------------

        Row(
          children: [
            Expanded(
              child: _balanceItem(
                PaymentMethod.cash,
                _cashBalance,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _balanceItem(
                PaymentMethod.upi,
                _upiBalance,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _balanceItem(
                PaymentMethod.bank,
                _bankBalance,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // BALANCE ITEM
  // ------------------------------------------------------------

  Widget _balanceItem(
    PaymentMethod method,
    double balance,
  ) {
    final color =
        _paymentMethodColor(method);

    return Container(
      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(16),

        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Container(
            width: 38,
            height: 38,

            decoration: BoxDecoration(
              color:
                  color.withValues(alpha: 0.10),

              borderRadius:
                  BorderRadius.circular(11),
            ),

            child: Icon(
              _paymentMethodIcon(method),
              color: color,
              size: 20,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            _paymentMethodName(method),

            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),

          const SizedBox(height: 3),

          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,

            child: Text(
              '₹ ${_money(balance)}',

              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // TRANSACTIONS LIST
  // ------------------------------------------------------------

  Widget _transactionsList() {
    if (_transactions.isEmpty) {
      return Container(
        width: double.infinity,

        padding: const EdgeInsets.all(30),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius:
              BorderRadius.circular(18),

          border: Border.all(
            color: const Color(0xFFE5E7EB),
          ),
        ),

        child: const Column(
          children: [
            Icon(
              Icons.receipt_long_rounded,
              size: 45,
              color: Color(0xFF9CA3AF),
            ),

            SizedBox(height: 12),

            Text(
              'No transactions yet',

              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),

            SizedBox(height: 5),

            Text(
              'Add a payment or expense to see it here.',

              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      );
    }

    // ----------------------------------------------------------
    // SHOW ONLY LATEST 3 TRANSACTIONS
    // ----------------------------------------------------------

    final recentTransactions =
        _transactions.take(3).toList();

    return Column(
      children:
          recentTransactions.map((transaction) {
        return _transactionCard(transaction);
      }).toList(),
    );
  }

  // ------------------------------------------------------------
  // TRANSACTION CARD
  // ------------------------------------------------------------

  Widget _transactionCard(
    TransactionModel transaction,
  ) {
    final bool isIncome =
        transaction.type ==
            TransactionType.income;

    final Color color = isIncome
        ? const Color(0xFF16A34A)
        : const Color(0xFFDC2626);

    final IconData icon = isIncome
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;

    return Dismissible(
      key: ValueKey(transaction.id),

      direction:
          DismissDirection.endToStart,

      // ----------------------------------------------------------
      // DELETE CONFIRMATION
      // ----------------------------------------------------------

      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,

          builder: (context) {
            return AlertDialog(
              title: const Text(
                'Delete Transaction?',
              ),

              content: const Text(
                'This transaction will be permanently deleted.',
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      false,
                    );
                  },

                  child: const Text(
                    'Cancel',
                  ),
                ),

                FilledButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      true,
                    );
                  },

                  style:
                      FilledButton.styleFrom(
                    backgroundColor:
                        const Color(
                      0xFFDC2626,
                    ),
                    foregroundColor:
                        Colors.white,
                  ),

                  child: const Text(
                    'Delete',
                  ),
                ),
              ],
            );
          },
        );
      },

      // ----------------------------------------------------------
      // DELETE
      // ----------------------------------------------------------

      onDismissed: (_) {
        _deleteTransaction(
          transaction,
        );
      },

      // ----------------------------------------------------------
      // SWIPE BACKGROUND
      // ----------------------------------------------------------

      background: Container(
        margin:
            const EdgeInsets.only(
          bottom: 10,
        ),

        alignment:
            Alignment.centerRight,

        padding:
            const EdgeInsets.only(
          right: 20,
        ),

        decoration: BoxDecoration(
          color:
              const Color(0xFFFEE2E2),

          borderRadius:
              BorderRadius.circular(16),
        ),

        child: const Icon(
          Icons.delete_rounded,
          color: Color(0xFFDC2626),
        ),
      ),

      // ----------------------------------------------------------
      // TRANSACTION CONTENT
      // ----------------------------------------------------------

      child: Container(
        margin:
            const EdgeInsets.only(
          bottom: 10,
        ),

        padding:
            const EdgeInsets.all(14),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius:
              BorderRadius.circular(16),

          border: Border.all(
            color:
                const Color(0xFFE5E7EB),
          ),
        ),

        child: Row(
          children: [
            // ----------------------------------------------------
            // TRANSACTION ICON
            // ----------------------------------------------------

            Container(
              width: 45,
              height: 45,

              decoration: BoxDecoration(
                color:
                    color.withValues(
                  alpha: 0.10,
                ),

                borderRadius:
                    BorderRadius.circular(
                  13,
                ),
              ),

              child: Icon(
                icon,
                color: color,
                size: 23,
              ),
            ),

            const SizedBox(width: 12),

            // ----------------------------------------------------
            // TITLE + DETAILS
            // ----------------------------------------------------

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Text(
                    _transactionTitle(
                      transaction,
                    ),

                    maxLines: 1,

                    overflow:
                        TextOverflow.ellipsis,

                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w600,
                      color:
                          Color(0xFF111827),
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    '${_paymentMethodName(transaction.paymentMethod)} • '
                    '${_formatDate(transaction.date)}',

                    maxLines: 1,

                    overflow:
                        TextOverflow.ellipsis,

                    style: const TextStyle(
                      fontSize: 11,
                      color:
                          Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // ----------------------------------------------------
            // AMOUNT
            // ----------------------------------------------------

            Text(
              '${isIncome ? '+' : '-'} ₹ ${_money(transaction.amount)}',

              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}