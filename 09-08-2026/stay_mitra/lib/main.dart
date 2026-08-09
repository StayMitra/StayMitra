import 'package:flutter/material.dart';
import 'day_sheet_screen.dart';
import 'add_payment_screen.dart';
import 'add_expense_screen.dart';
import 'transaction_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await TransactionService.initialize();

  runApp(const StayMitraApp());
}

class StayMitraApp extends StatelessWidget {
  const StayMitraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stay Mitra',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),
        fontFamily: 'Arial',
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int selectedIndex = 0;

  // ------------------------------------------------------------
  // DYNAMIC TRANSACTION DATA
  // ------------------------------------------------------------

  double get todayCollection =>
      TransactionService.getTodayIncome();

  double get todayExpense =>
      TransactionService.getTodayExpense();

  double get monthIncome =>
      TransactionService.getCurrentMonthIncome();

  double get monthExpense =>
      TransactionService.getCurrentMonthExpense();

  double get cashBalance =>
      TransactionService.getCashBalance();

  double get bankBalance =>
      TransactionService.getBankBalance();

  double get upiBalance =>
      TransactionService.getUpiBalance();

  int get todayPaymentCount =>
      TransactionService.getTodayIncomeCount();

  double get totalBalance =>
      cashBalance + bankBalance + upiBalance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (MediaQuery.of(context).size.width >= 900)
              _buildSideNavigation(),

            Expanded(
              child: _buildMainContent(),
            ),
          ],
        ),
      ),

      bottomNavigationBar:
          MediaQuery.of(context).size.width < 900
              ? _buildBottomNavigation()
              : null,
    );
  }

  // ------------------------------------------------------------
  // MONEY FORMATTER
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
  // DESKTOP / WEB SIDE NAVIGATION
  // ------------------------------------------------------------

  Widget _buildSideNavigation() {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 25),

          // Logo
          Row(
            children: [
              const SizedBox(width: 22),

              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.home_work_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),

              const SizedBox(width: 12),

              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stay Mitra',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'PG Management',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 40),

          _sideItem(
            Icons.dashboard_rounded,
            'Dashboard',
            0,
          ),

          _sideItem(
            Icons.people_alt_rounded,
            'Tenants',
            1,
          ),

          _sideItem(
            Icons.bed_rounded,
            'Rooms & Beds',
            2,
          ),

          _sideItem(
            Icons.calendar_month_rounded,
            'Day Sheet',
            3,
          ),

          _sideItem(
            Icons.receipt_long_rounded,
            'Billing',
            4,
          ),

          _sideItem(
            Icons.account_balance_wallet_rounded,
            'Accounts',
            5,
          ),

          _sideItem(
            Icons.bar_chart_rounded,
            'Reports',
            6,
          ),

          const Spacer(),

          _sideItem(
            Icons.settings_rounded,
            'Settings',
            7,
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sideItem(
    IconData icon,
    String title,
    int index,
  ) {
    final bool selected = selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 4,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() {
            selectedIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFEFF6FF)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 21,
                color: selected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF6B7280),
              ),

              const SizedBox(width: 14),

              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: selected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF374151),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // MAIN CONTENT
  // ------------------------------------------------------------

  Widget _buildMainContent() {
    return Column(
      children: [
        _buildTopBar(),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: _buildDashboard(),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // TOP BAR
  // ------------------------------------------------------------

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
      ),
      child: Row(
        children: [
          if (MediaQuery.of(context).size.width < 900)
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.menu_rounded),
            ),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good Morning 👋',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Stay Mitra Dashboard',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none_rounded,
              size: 27,
            ),
          ),

          const SizedBox(width: 8),

          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Color(0xFF2563EB),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // DASHBOARD
  // ------------------------------------------------------------

  Widget _buildDashboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPropertyCard(),

        const SizedBox(height: 22),

        _buildSectionTitle('Property Overview'),

        const SizedBox(height: 12),

        _buildOverviewCards(),

        const SizedBox(height: 22),

        _buildFinancialCards(),

        const SizedBox(height: 22),

        _buildSectionTitle('Quick Actions'),

        const SizedBox(height: 12),

        _buildQuickActions(),

        const SizedBox(height: 22),

        _buildBottomDashboard(),

        const SizedBox(height: 30),
      ],
    );
  }

  // ------------------------------------------------------------
  // PROPERTY CARD
  // ------------------------------------------------------------

  Widget _buildPropertyCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 600;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
            ),
          ),
          child: isMobile
              ? Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.apartment_rounded,
                            color: Color(0xFF2563EB),
                            size: 28,
                          ),
                        ),

                        const SizedBox(width: 12),

                        const Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sri Sai PG',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      'Bangalore, Karnataka',
                                      overflow:
                                          TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.swap_horiz_rounded,
                          size: 18,
                        ),
                        label: const Text('Switch PG'),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius:
                            BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.apartment_rounded,
                        color: Color(0xFF2563EB),
                        size: 30,
                      ),
                    ),

                    const SizedBox(width: 15),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sri Sai PG',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 15,
                                color: Colors.grey,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Bangalore, Karnataka',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.swap_horiz_rounded,
                      ),
                      label: const Text('Switch PG'),
                    ),
                  ],
                ),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // OVERVIEW CARDS
  // ------------------------------------------------------------

  Widget _buildOverviewCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int count = 2;

        if (constraints.maxWidth >= 1100) {
          count = 4;
        }

        final double aspectRatio =
            constraints.maxWidth < 600 ? 1.0 : 1.35;

        return GridView.count(
          crossAxisCount: count,
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: aspectRatio,
          children: [
            _statCard(
              'Total Rooms',
              '20',
              Icons.meeting_room_rounded,
              const Color(0xFF2563EB),
              'All Rooms',
            ),
            _statCard(
              'Total Beds',
              '80',
              Icons.bed_rounded,
              const Color(0xFF16A34A),
              'All Beds',
            ),
            _statCard(
              'Occupied',
              '53',
              Icons.person_rounded,
              const Color(0xFF16A34A),
              '66.3%',
            ),
            _statCard(
              'Vacant',
              '27',
              Icons.bed_outlined,
              const Color(0xFFF97316),
              '33.7%',
            ),
          ],
        );
      },
    );
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color:
                      color.withValues(alpha: 0.10),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),

              const Spacer(),

              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: Colors.grey.shade400,
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),

          const SizedBox(height: 2),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),

          const SizedBox(height: 1),

          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // FINANCIAL CARDS
  // ------------------------------------------------------------

  Widget _buildFinancialCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile =
            constraints.maxWidth < 600;

        final int count =
            constraints.maxWidth >= 1000 ? 4 : 2;

        return GridView.builder(
          itemCount: 4,
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),

          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent:
                isMobile ? 155 : 145,
          ),

          itemBuilder: (context, index) {
            final cards = [
              [
                'Today Collection',
                '₹ ${_money(todayCollection)}',
                '$todayPaymentCount Payments',
                Icons.payments_rounded,
                const Color(0xFF16A34A),
              ],
              [
                'Pending Rent',
                '₹ 68,450',
                '18 Tenants',
                Icons.event_busy_rounded,
                const Color(0xFFDC2626),
              ],
              [
                'This Month Income',
                '₹ ${_money(monthIncome)}',
                'All Income',
                Icons.account_balance_wallet_rounded,
                const Color(0xFF2563EB),
              ],
              [
                'This Month Expense',
                '₹ ${_money(monthExpense)}',
                'All Expense',
                Icons.receipt_long_rounded,
                const Color(0xFFF97316),
              ],
            ];

            final card = cards[index];

            return _financialCard(
              card[0] as String,
              card[1] as String,
              card[2] as String,
              card[3] as IconData,
              card[4] as Color,
            );
          },
        );
      },
    );
  }

  Widget _financialCard(
    String title,
    String amount,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:
                  color.withValues(alpha: 0.10),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),

          const SizedBox(height: 2),

          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              maxLines: 1,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),

          const SizedBox(height: 2),

          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // QUICK ACTIONS
  // ------------------------------------------------------------

  Widget _buildQuickActions() {
    final actions = [
      [
        Icons.person_add_alt_1_rounded,
        'Add Tenant',
        const Color(0xFF2563EB),
      ],
      [
        Icons.currency_rupee_rounded,
        'Add Payment',
        const Color(0xFF16A34A),
      ],
      [
        Icons.remove_circle_outline_rounded,
        'Add Expense',
        const Color(0xFFDC2626),
      ],
      [
        Icons.description_outlined,
        'Create Bill',
        const Color(0xFF7C3AED),
      ],
      [
        Icons.calendar_today_rounded,
        'Check-in',
        const Color(0xFF0891B2),
      ],
      [
        Icons.table_chart_rounded,
        'Day Sheet',
        const Color(0xFFF97316),
      ],
      [
        Icons.upload_file_rounded,
        'Upload Register',
        const Color(0xFF2563EB),
      ],
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int count;

        if (constraints.maxWidth >= 1100) {
          count = 7;
        } else {
          count = 4;
        }

        final double aspectRatio =
            constraints.maxWidth < 600
                ? 0.78
                : 1.0;

        return GridView.count(
          crossAxisCount: count,
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: aspectRatio,
          children: actions.map((action) {
            return _quickAction(
              action[0] as IconData,
              action[1] as String,
              action[2] as Color,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _quickAction(
    IconData icon,
    String title,
    Color color,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius:
            BorderRadius.circular(18),
        onTap: () async {
          if (title == 'Add Payment') {
            final result =
                await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const AddPaymentScreen(),
              ),
            );

            if (result == true) {
              setState(() {});
            }

            return;
          }

          if (title == 'Add Expense') {
            final result =
                await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const AddExpenseScreen(),
              ),
            );

            if (result == true) {
              setState(() {});
            }

            return;
          }

          if (title == 'Day Sheet') {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const DaySheetScreen(),
              ),
            );

            return;
          }

          ScaffoldMessenger.of(context)
              .showSnackBar(
            SnackBar(
              content:
                  Text('$title selected'),
              behavior:
                  SnackBarBehavior.floating,
            ),
          );
        },
        child: Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(18),
            border: Border.all(
              color:
                  const Color(0xFFE5E7EB),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(alpha: 0.025),
                blurRadius: 8,
                offset:
                    const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color:
                      color.withValues(alpha: 0.10),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),

              const SizedBox(height: 8),

              Flexible(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  textAlign:
                      TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        Color(0xFF374151),
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // BOTTOM DASHBOARD
  // ------------------------------------------------------------

  Widget _buildBottomDashboard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          return Column(
            children: [
              _remindersCard(),
              const SizedBox(height: 16),
              _balanceCard(),
            ],
          );
        }

        return Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _remindersCard(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _balanceCard(),
            ),
          ],
        );
      },
    );
  }

  Widget _remindersCard() {
    return _dashboardPanel(
      title: 'Important Reminders',
      children: [
        _reminderItem(
          Icons.currency_rupee_rounded,
          '15 Rent Payments Due',
          'Total Amount: ₹ 68,450',
          const Color(0xFFDC2626),
        ),
        _reminderItem(
          Icons.calendar_month_rounded,
          '3 Check-outs This Week',
          'Tap to view details',
          const Color(0xFFF97316),
        ),
        _reminderItem(
          Icons.campaign_rounded,
          '2 Notices To Send',
          'Tap to view tenants',
          const Color(0xFF7C3AED),
        ),
      ],
    );
  }

  Widget _reminderItem(
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 10,
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color:
                  color.withValues(alpha: 0.10),
              borderRadius:
                  BorderRadius.circular(50),
            ),
            child: Icon(
              icon,
              color: color,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style:
                      const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.chevron_right_rounded,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _balanceCard() {
    return _dashboardPanel(
      title: 'Cash & Bank Balance',
      children: [
        _balanceItem(
          Icons.payments_rounded,
          'Cash in Hand',
          '₹ ${_money(cashBalance)}',
          const Color(0xFF16A34A),
        ),

        _balanceItem(
          Icons.account_balance_rounded,
          'Bank Balance',
          '₹ ${_money(bankBalance)}',
          const Color(0xFF2563EB),
        ),

        _balanceItem(
          Icons.qr_code_rounded,
          'UPI Balance',
          '₹ ${_money(upiBalance)}',
          const Color(0xFF7C3AED),
        ),

        const SizedBox(height: 8),

        Container(
          padding:
              const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color:
                const Color(0xFFEFF6FF),
            borderRadius:
                BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Text(
                'Total Balance',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                  color:
                      Color(0xFF1E3A8A),
                ),
              ),

              const Spacer(),

              Text(
                '₹ ${_money(totalBalance)}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      Color(0xFF1D4ED8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _balanceItem(
    IconData icon,
    String title,
    String amount,
    Color color,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 9,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:
                  color.withValues(alpha: 0.10),
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
              style:
                  const TextStyle(
                fontSize: 13,
              ),
            ),
          ),

          Text(
            amount,
            style: TextStyle(
              fontWeight:
                  FontWeight.bold,
              color: color,
            ),
          ),

          const SizedBox(width: 5),

          const Icon(
            Icons.chevron_right_rounded,
            size: 19,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _dashboardPanel({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color:
              const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          ...children,
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
  ) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight:
            FontWeight.bold,
      ),
    );
  }

  // ------------------------------------------------------------
  // MOBILE BOTTOM NAVIGATION
  // ------------------------------------------------------------

  Widget _buildBottomNavigation() {
    return NavigationBar(
      selectedIndex:
          selectedIndex > 4
              ? 0
              : selectedIndex,

      onDestinationSelected: (index) {
        setState(() {
          selectedIndex = index;
        });
      },

      destinations: const [
        NavigationDestination(
          icon: Icon(
            Icons.home_outlined,
          ),
          selectedIcon: Icon(
            Icons.home_rounded,
          ),
          label: 'Home',
        ),

        NavigationDestination(
          icon: Icon(
            Icons.people_outline_rounded,
          ),
          selectedIcon: Icon(
            Icons.people_rounded,
          ),
          label: 'Tenants',
        ),

        NavigationDestination(
          icon: Icon(
            Icons.bed_outlined,
          ),
          selectedIcon: Icon(
            Icons.bed_rounded,
          ),
          label: 'Rooms',
        ),

        NavigationDestination(
          icon: Icon(
            Icons.account_balance_wallet_outlined,
          ),
          selectedIcon: Icon(
            Icons.account_balance_wallet_rounded,
          ),
          label: 'Accounts',
        ),

        NavigationDestination(
          icon: Icon(
            Icons.more_horiz_rounded,
          ),
          selectedIcon: Icon(
            Icons.more_horiz_rounded,
          ),
          label: 'More',
        ),
      ],
    );
  }
}