import 'package:flutter/material.dart';

import 'transaction_model.dart';
import 'transaction_service.dart';
import 'pg_manager_service.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends State<TransactionHistoryScreen> {
  int _selectedFilter = 0;

  List<TransactionModel> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  // ------------------------------------------------------------
  // LOAD TRANSACTIONS
  // ------------------------------------------------------------

Future<void> _loadTransactions() async {
  // ----------------------------------------------------------
  // GET CURRENT ACTIVE PG
  // ----------------------------------------------------------

  final activePgId =
      PgManagerService.activePgId;

  // ----------------------------------------------------------
  // NO ACTIVE PG
  // ----------------------------------------------------------

  if (activePgId == null ||
      activePgId.isEmpty) {
    if (!mounted) return;

    setState(() {
      _transactions = [];
    });

    return;
  }

  // ----------------------------------------------------------
  // GET ONLY CURRENT PG TRANSACTIONS
  // ----------------------------------------------------------

  final transactions =
      TransactionService.getTransactionsForBuilding(
    activePgId,
  );

  if (!mounted) {
    return;
  }

  setState(() {
    _transactions = transactions;
  });
}

  // ------------------------------------------------------------
  // FILTER
  // ------------------------------------------------------------

  List<TransactionModel> get _filteredTransactions {
    if (_selectedFilter == 1) {
      return _transactions
          .where(
            (transaction) =>
                transaction.type == TransactionType.income,
          )
          .toList();
    }

    if (_selectedFilter == 2) {
      return _transactions
          .where(
            (transaction) =>
                transaction.type == TransactionType.expense,
          )
          .toList();
    }

    return _transactions;
  }

  // ------------------------------------------------------------
  // TOTALS
  // ------------------------------------------------------------

  double get _totalIncome {
    return _transactions
        .where(
          (transaction) =>
              transaction.type == TransactionType.income,
        )
        .fold(
          0.0,
          (total, transaction) =>
              total + transaction.amount,
        );
  }

  double get _totalExpense {
    return _transactions
        .where(
          (transaction) =>
              transaction.type == TransactionType.expense,
        )
        .fold(
          0.0,
          (total, transaction) =>
              total + transaction.amount,
        );
  }

  // ------------------------------------------------------------
  // DELETE
  // ------------------------------------------------------------

  Future<void> _deleteTransaction(
    TransactionModel transaction,
  ) async {
    final confirmed = await showDialog<bool>(
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
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    TransactionService.deleteTransaction(
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
      backgroundColor: const Color(0xFFF7F8FC),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),

        title: const Text(
          'Transactions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            onPressed: _loadTransactions,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),

      body: RefreshIndicator(
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
              _summaryCard(),

              const SizedBox(height: 18),

              _filterSection(),

              const SizedBox(height: 18),

              if (_filteredTransactions.isEmpty)
                _emptyState()
              else
                _transactionList(),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // SUMMARY CARD
  // ------------------------------------------------------------

  Widget _summaryCard() {
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
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Text(
            'Account Summary',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _summaryItem(
                  'Income',
                  _totalIncome,
                  Icons.arrow_downward_rounded,
                  const Color(0xFF16A34A),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _summaryItem(
                  'Expense',
                  _totalExpense,
                  Icons.arrow_upward_rounded,
                  const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(
    String title,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),

        borderRadius:
            BorderRadius.circular(15),

        border: Border.all(
          color: color.withValues(alpha: 0.15),
        ),
      ),

      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,

            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius:
                  BorderRadius.circular(11),
            ),

            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),

                const SizedBox(height: 3),

                FittedBox(
                  alignment:
                      Alignment.centerLeft,

                  fit: BoxFit.scaleDown,

                  child: Text(
                    '₹ ${_money(amount)}',

                    style: TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                      color: color,
                    ),
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
  // FILTER
  // ------------------------------------------------------------

  Widget _filterSection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        const Text(
          'Transactions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),

        const SizedBox(height: 12),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,

          child: Row(
            children: [
              _filterChip(
                'All',
                0,
              ),

              const SizedBox(width: 8),

              _filterChip(
                'Income',
                1,
              ),

              const SizedBox(width: 8),

              _filterChip(
                'Expense',
                2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filterChip(
    String title,
    int index,
  ) {
    final selected =
        _selectedFilter == index;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = index;
        });
      },

      borderRadius:
          BorderRadius.circular(30),

      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),

        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF2563EB)
              : Colors.white,

          borderRadius:
              BorderRadius.circular(30),

          border: Border.all(
            color: selected
                ? const Color(0xFF2563EB)
                : const Color(0xFFE5E7EB),
          ),
        ),

        child: Text(
          title,

          style: TextStyle(
            fontSize: 13,
            fontWeight:
                selected
                    ? FontWeight.bold
                    : FontWeight.w500,

            color: selected
                ? Colors.white
                : const Color(0xFF374151),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // TRANSACTION LIST
  // ------------------------------------------------------------

  Widget _transactionList() {
    return Column(
      children: _filteredTransactions.map(
        (transaction) {
          return Padding(
            padding:
                const EdgeInsets.only(
              bottom: 12,
            ),

            child: _transactionCard(
              transaction,
            ),
          );
        },
      ).toList(),
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

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(18),

        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Container(
            width: 46,
            height: 46,

            decoration: BoxDecoration(
              color: color.withValues(
                alpha: 0.10,
              ),

              borderRadius:
                  BorderRadius.circular(14),
            ),

            child: Icon(
              isIncome
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,

              color: color,
              size: 23,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  isIncome
                      ? 'Payment'
                      : _expenseTitle(
                          transaction,
                        ),

                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Color(0xFF111827),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  transaction.description,

                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontSize: 12,
                    color:
                        Color(0xFF6B7280),
                  ),
                ),

                const SizedBox(height: 7),

                Wrap(
                  spacing: 6,
                  runSpacing: 5,

                  children: [
                    _smallTag(
                      _paymentMethodName(
                        transaction
                            .paymentMethod,
                      ),
                    ),

                    _smallTag(
                      _formatDate(
                        transaction.date,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Column(
            crossAxisAlignment:
                CrossAxisAlignment.end,

            children: [
              Text(
                '${isIncome ? '+' : '-'}₹ ${_money(transaction.amount)}',

                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                      FontWeight.bold,
                  color: color,
                ),
              ),

              const SizedBox(height: 7),

              InkWell(
                onTap: () {
                  _deleteTransaction(
                    transaction,
                  );
                },

                borderRadius:
                    BorderRadius.circular(20),

                child: const Padding(
                  padding:
                      EdgeInsets.all(4),

                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color:
                        Color(0xFF9CA3AF),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // EXPENSE TITLE
  // ------------------------------------------------------------

  String _expenseTitle(
    TransactionModel transaction,
  ) {
    if (transaction
            .expenseCategory ==
        ExpenseCategory.other) {
      if (transaction
              .customExpenseCategory !=
          null &&
          transaction
              .customExpenseCategory!
              .trim()
              .isNotEmpty) {
        return transaction
            .customExpenseCategory!;
      }

      return 'Other Expense';
    }

    if (transaction
            .expenseCategory !=
        null) {
      return _expenseCategoryName(
        transaction.expenseCategory!,
      );
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
  // PAYMENT METHOD NAME
  // ------------------------------------------------------------

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

  // ------------------------------------------------------------
  // SMALL TAG
  // ------------------------------------------------------------

  Widget _smallTag(String text) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),

      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),

        borderRadius:
            BorderRadius.circular(7),
      ),

      child: Text(
        text,

        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // EMPTY STATE
  // ------------------------------------------------------------

  Widget _emptyState() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(
        vertical: 50,
        horizontal: 20,
      ),

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
            width: 70,
            height: 70,

            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius:
                  BorderRadius.circular(22),
            ),

            child: const Icon(
              Icons.receipt_long_rounded,
              size: 34,
              color: Color(0xFF2563EB),
            ),
          ),

          const SizedBox(height: 15),

          const Text(
            'No transactions found',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Payments and expenses will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // DATE FORMAT
  // ------------------------------------------------------------

  String _formatDate(DateTime date) {
    return '${date.day} '
        '${_monthName(date.month)} '
        '${date.year}';
  }

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
}