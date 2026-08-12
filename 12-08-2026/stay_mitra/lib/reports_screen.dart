import 'package:flutter/material.dart';

import 'transaction_model.dart';
import 'transaction_service.dart';
import 'database_helper.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _loading = true;

  List<TransactionModel> _transactions = [];

  int _totalRooms = 0;
  int _totalBeds = 0;
  int _occupiedBeds = 0;
  int _availableBeds = 0;
  int _activeTenants = 0;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  // ============================================================
  // LOAD REPORT DATA
  // ============================================================

  Future<void> _loadReports() async {
    try {
      await TransactionService.initialize();

      final transactions =
          TransactionService.getTransactions();

      final db =
          await DatabaseHelper.instance.database;

      final roomResult = await db.rawQuery(
        'SELECT COUNT(*) AS count FROM rooms',
      );

      final bedResult = await db.rawQuery(
        'SELECT COUNT(*) AS count FROM beds',
      );

      final occupiedResult = await db.rawQuery(
        "SELECT COUNT(*) AS count FROM beds WHERE status = 'occupied'",
      );

      final availableResult = await db.rawQuery(
        "SELECT COUNT(*) AS count FROM beds WHERE status = 'available'",
      );

      final tenantResult = await db.rawQuery(
        "SELECT COUNT(*) AS count FROM tenants WHERE status = 'active'",
      );

      int countFrom(
        List<Map<String, Object?>> rows,
      ) {
        if (rows.isEmpty) {
          return 0;
        }

        final value = rows.first['count'];

        if (value is num) {
          return value.toInt();
        }

        return 0;
      }

      if (!mounted) return;

      setState(() {
        _transactions = transactions;

        _totalRooms = countFrom(roomResult);
        _totalBeds = countFrom(bedResult);
        _occupiedBeds =
            countFrom(occupiedResult);
        _availableBeds =
            countFrom(availableResult);
        _activeTenants =
            countFrom(tenantResult);

        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  // ============================================================
  // CURRENT MONTH TRANSACTIONS
  // ============================================================

  List<TransactionModel>
      get _currentMonthTransactions {
    final now = DateTime.now();

    return _transactions.where((transaction) {
      return transaction.date.year == now.year &&
          transaction.date.month == now.month;
    }).toList();
  }

  // ============================================================
  // MONTHLY INCOME
  // ============================================================

  double get _monthlyIncome {
    return _currentMonthTransactions
        .where(
          (transaction) =>
              transaction.type ==
              TransactionType.income,
        )
        .fold(
          0.0,
          (total, transaction) =>
              total + transaction.amount,
        );
  }

  // ============================================================
  // MONTHLY EXPENSE
  // ============================================================

  double get _monthlyExpense {
    return _currentMonthTransactions
        .where(
          (transaction) =>
              transaction.type ==
              TransactionType.expense,
        )
        .fold(
          0.0,
          (total, transaction) =>
              total + transaction.amount,
        );
  }

  // ============================================================
  // NET
  // ============================================================

  double get _netAmount {
    return _monthlyIncome - _monthlyExpense;
  }

  // ============================================================
  // MONTHLY INCOME COUNT
  // ============================================================

  int get _monthlyIncomeCount {
    return _currentMonthTransactions
        .where(
          (transaction) =>
              transaction.type ==
              TransactionType.income,
        )
        .length;
  }

  // ============================================================
  // MONTHLY EXPENSE COUNT
  // ============================================================

  int get _monthlyExpenseCount {
    return _currentMonthTransactions
        .where(
          (transaction) =>
              transaction.type ==
              TransactionType.expense,
        )
        .length;
  }

  // ============================================================
  // PAYMENT METHOD - CURRENT MONTH
  // ============================================================

  double _paymentMethodAmount(
    PaymentMethod method,
  ) {
    return _currentMonthTransactions
        .where(
          (transaction) =>
              transaction.paymentMethod ==
              method,
        )
        .fold(
          0.0,
          (total, transaction) {
            if (transaction.type ==
                TransactionType.income) {
              return total + transaction.amount;
            }

            return total - transaction.amount;
          },
        );
  }

  // ============================================================
  // MONEY FORMAT
  // ============================================================

  String _money(double value) {
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
        );
  }

  // ============================================================
  // MONTH NAME
  // ============================================================

  String _monthName() {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final now = DateTime.now();

    return '${months[now.month - 1]} ${now.year}';
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDate(DateTime date) {
    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
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

        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
        ),

        title: const Text(
          'Reports',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            onPressed: _loadReports,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),

      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadReports,
              child: SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
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

                    // ==========================================
                    // PERIOD
                    // ==========================================

                    _periodCard(),

                    const SizedBox(height: 20),

                    // ==========================================
                    // FINANCIAL SUMMARY
                    // ==========================================

                    const Text(
                      'Financial Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Color(0xFF111827),
                      ),
                    ),

                    const SizedBox(height: 12),

                    _financialSummary(),

                    const SizedBox(height: 22),

                    // ==========================================
                    // OCCUPANCY
                    // ==========================================

                    const Text(
                      'Occupancy Overview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Color(0xFF111827),
                      ),
                    ),

                    const SizedBox(height: 12),

                    _occupancyCard(),

                    const SizedBox(height: 22),

                    // ==========================================
                    // PAYMENT METHODS
                    // ==========================================

                    const Text(
                      'Payment Methods',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Color(0xFF111827),
                      ),
                    ),

                    const SizedBox(height: 12),

                    _paymentMethodsCard(),

                    const SizedBox(height: 22),

                    // ==========================================
                    // TRANSACTION SUMMARY
                    // ==========================================

                    const Text(
                      'Transaction Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Color(0xFF111827),
                      ),
                    ),

                    const SizedBox(height: 12),

                    _transactionSummary(),

                    const SizedBox(height: 22),

                    // ==========================================
                    // RECENT TRANSACTIONS
                    // ==========================================

                    const Text(
                      'Recent Transactions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Color(0xFF111827),
                      ),
                    ),

                    const SizedBox(height: 12),

                    _recentTransactions(),
                  ],
                ),
              ),
            ),
    );
  }

  // ============================================================
  // PERIOD CARD
  // ============================================================

  Widget _periodCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFBFDBFE),
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
              Icons.calendar_month_rounded,
              color: Color(0xFF2563EB),
              size: 25,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Report Period',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        Color(0xFF64748B),
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  _monthName(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Color(0xFF1E3A8A),
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.analytics_rounded,
            color: Color(0xFF2563EB),
            size: 28,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FINANCIAL SUMMARY
  // ============================================================

  Widget _financialSummary() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                title: 'Income',
                amount:
                    '₹ ${_money(_monthlyIncome)}',
                subtitle:
                    'This month',
                icon:
                    Icons.arrow_downward_rounded,
                color:
                    const Color(0xFF16A34A),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _summaryCard(
                title: 'Expense',
                amount:
                    '₹ ${_money(_monthlyExpense)}',
                subtitle:
                    'This month',
                icon:
                    Icons.arrow_upward_rounded,
                color:
                    const Color(0xFFDC2626),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        _netCard(),
      ],
    );
  }

  Widget _summaryCard({
    required String title,
    required String amount,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),

        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,

            decoration: BoxDecoration(
              color: color.withValues(
                alpha: 0.10,
              ),
              borderRadius:
                  BorderRadius.circular(13),
            ),

            child: Icon(
              icon,
              color: color,
              size: 23,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color:
                  Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 3),

          FittedBox(
            fit: BoxFit.scaleDown,
            alignment:
                Alignment.centerLeft,
            child: Text(
              amount,
              style: TextStyle(
                fontSize: 21,
                fontWeight:
                    FontWeight.bold,
                color: color,
              ),
            ),
          ),

          const SizedBox(height: 2),

          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color:
                  Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NET CARD
  // ============================================================

  Widget _netCard() {
    final bool positive =
        _netAmount >= 0;

    final Color color = positive
        ? const Color(0xFF2563EB)
        : const Color(0xFFDC2626);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),

      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.06,
        ),
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(
            alpha: 0.18,
          ),
        ),
      ),

      child: Row(
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
              positive
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded,
              color: color,
              size: 25,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Net Amount',
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        Color(0xFF64748B),
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  '₹ ${_money(_netAmount.abs())}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight:
                        FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),

          Text(
            positive ? 'Profit' : 'Loss',
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // OCCUPANCY CARD
  // ============================================================

  Widget _occupancyCard() {
    final double percentage =
        _totalBeds == 0
            ? 0
            : _occupiedBeds /
                _totalBeds;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),

      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,

                decoration: BoxDecoration(
                  color:
                      const Color(0xFFDCFCE7),
                  borderRadius:
                      BorderRadius.circular(14),
                ),

                child: const Icon(
                  Icons.bed_rounded,
                  color:
                      Color(0xFF16A34A),
                  size: 25,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bed Occupancy',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      '$_occupiedBeds of $_totalBeds beds occupied',
                      style: const TextStyle(
                        fontSize: 12,
                        color:
                            Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                '${(percentage * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      Color(0xFF16A34A),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          ClipRRect(
            borderRadius:
                BorderRadius.circular(10),
            child:
                LinearProgressIndicator(
              minHeight: 10,
              value: percentage,
              backgroundColor:
                  const Color(0xFFE5E7EB),
              valueColor:
                  const AlwaysStoppedAnimation<
                      Color>(
                Color(0xFF16A34A),
              ),
            ),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _smallStat(
                  'Rooms',
                  '$_totalRooms',
                  Icons.meeting_room_rounded,
                  const Color(0xFF2563EB),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _smallStat(
                  'Available',
                  '$_availableBeds',
                  Icons.bed_outlined,
                  const Color(0xFFF97316),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _smallStat(
                  'Tenants',
                  '$_activeTenants',
                  Icons.people_alt_rounded,
                  const Color(0xFF7C3AED),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SMALL STAT
  // ============================================================

  Widget _smallStat(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 8,
      ),

      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.05,
        ),
        borderRadius:
            BorderRadius.circular(14),
      ),

      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),

          const SizedBox(height: 5),

          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight:
                  FontWeight.bold,
              color: color,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color:
                  Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAYMENT METHODS
  // ============================================================

  Widget _paymentMethodsCard() {
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

      child: Column(
        children: [
          _paymentMethodRow(
            icon: Icons.payments_rounded,
            title: 'Cash',
            amount:
                _paymentMethodAmount(
              PaymentMethod.cash,
            ),
            color:
                const Color(0xFF16A34A),
          ),

          const Divider(
            height: 22,
          ),

          _paymentMethodRow(
            icon: Icons.qr_code_rounded,
            title: 'UPI',
            amount:
                _paymentMethodAmount(
              PaymentMethod.upi,
            ),
            color:
                const Color(0xFF7C3AED),
          ),

          const Divider(
            height: 22,
          ),

          _paymentMethodRow(
            icon:
                Icons.account_balance_rounded,
            title: 'Bank',
            amount:
                _paymentMethodAmount(
              PaymentMethod.bank,
            ),
            color:
                const Color(0xFF2563EB),
          ),
        ],
      ),
    );
  }

  Widget _paymentMethodRow({
    required IconData icon,
    required String title,
    required double amount,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,

          decoration: BoxDecoration(
            color: color.withValues(
              alpha: 0.10,
            ),
            borderRadius:
                BorderRadius.circular(12),
          ),

          child: Icon(
            icon,
            color: color,
            size: 21,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),

        Text(
          '₹ ${_money(amount)}',
          style: TextStyle(
            fontSize: 15,
            fontWeight:
                FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TRANSACTION SUMMARY
  // ============================================================

  Widget _transactionSummary() {
    return Row(
      children: [
        Expanded(
          child: _summaryCountCard(
            title: 'Income',
            count:
                _monthlyIncomeCount,
            icon:
                Icons.arrow_downward_rounded,
            color:
                const Color(0xFF16A34A),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _summaryCountCard(
            title: 'Expense',
            count:
                _monthlyExpenseCount,
            icon:
                Icons.arrow_upward_rounded,
            color:
                const Color(0xFFDC2626),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _summaryCountCard(
            title: 'Total',
            count:
                _currentMonthTransactions
                    .length,
            icon:
                Icons.receipt_long_rounded,
            color:
                const Color(0xFF2563EB),
          ),
        ),
      ],
    );
  }

  Widget _summaryCountCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),

      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 22,
          ),

          const SizedBox(height: 8),

          Text(
            '$count',
            style: TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
              color: color,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color:
                  Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RECENT TRANSACTIONS
  // ============================================================

  Widget _recentTransactions() {
    final transactions =
        List<TransactionModel>.from(
      _currentMonthTransactions,
    );

    transactions.sort(
      (a, b) => b.date.compareTo(a.date),
    );

    final recent =
        transactions.take(5).toList();

    if (recent.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(25),

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
              Icons.receipt_long_outlined,
              size: 42,
              color: Color(0xFFCBD5E1),
            ),

            SizedBox(height: 10),

            Text(
              'No transactions this month',
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    FontWeight.w600,
                color:
                    Color(0xFF64748B),
              ),
            ),

            SizedBox(height: 4),

            Text(
              'Income and expenses will appear here.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color:
                    Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),

      child: Column(
        children: [
          for (int i = 0;
              i < recent.length;
              i++) ...[
            _transactionRow(
              recent[i],
            ),

            if (i != recent.length - 1)
              const Divider(
                height: 1,
              ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // TRANSACTION ROW
  // ============================================================

  Widget _transactionRow(
    TransactionModel transaction,
  ) {
    final bool income =
        transaction.type ==
            TransactionType.income;

    final Color color = income
        ? const Color(0xFF16A34A)
        : const Color(0xFFDC2626);

    final IconData icon = income
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;

    final String sign =
        income ? '+' : '-';

    return Padding(
      padding: const EdgeInsets.all(14),

      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,

            decoration: BoxDecoration(
              color: color.withValues(
                alpha: 0.10,
              ),
              borderRadius:
                  BorderRadius.circular(12),
            ),

            child: Icon(
              icon,
              color: color,
              size: 21,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        Color(0xFF111827),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  _formatDate(
                    transaction.date,
                  ),
                  style: const TextStyle(
                    fontSize: 11,
                    color:
                        Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Text(
            '$sign ₹ ${_money(transaction.amount)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}