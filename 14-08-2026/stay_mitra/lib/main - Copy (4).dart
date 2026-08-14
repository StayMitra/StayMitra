import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'day_sheet_screen.dart';
import 'add_payment_screen.dart';
import 'add_expense_screen.dart';
import 'add_tenant_screen.dart';
import 'transaction_service.dart';
import 'accounts_screen.dart';
import 'building_setup_screen.dart';
import 'building_model.dart';
import 'database_helper.dart';
import 'tenant_management_screen.dart';
import 'rooms_screen.dart';
import 'more_screen.dart';
import 'create_bill_screen.dart';
import 'tenant_model.dart';

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
  // PG / BUILDING DATA
  // ------------------------------------------------------------

  BuildingModel? _building;
  bool _buildingLoading = true;

  int _totalRooms = 0;
  int _totalBeds = 0;
  int _occupiedBeds = 0;
  int _availableBeds = 0;
  int _activeTenants = 0;
  double _pendingRent = 0;
  int _pendingRentTenants = 0;
  bool _propertyStatsLoading = true;

  // ------------------------------------------------------------
  // LOAD DATA
  // ------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    await _loadBuilding();
    await _loadPropertyStats();
  }

  Future<void> _loadBuilding() async {
    try {
      final buildings =
          await DatabaseHelper.instance.getBuildings();

      if (!mounted) return;

      setState(() {
        _building =
            buildings.isNotEmpty ? buildings.first : null;
        _buildingLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _building = null;
        _buildingLoading = false;
      });
    }
  }

  Future<void> _loadPropertyStats() async {
    try {
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

      // ----------------------------------------------------------
      // PENDING RENT
      // ----------------------------------------------------------

      final activeTenants = await db.query(
        'tenants',
        where: 'status = ?',
        whereArgs: ['active'],
        orderBy: 'created_at ASC',
      );

      final transactions =
          TransactionService.getTransactions();

      final now = DateTime.now();

      double totalPendingRent = 0;
      int pendingTenantCount = 0;

      for (final tenant in activeTenants) {
        final tenantId =
            tenant['id'] as String;

        final tenantName =
            (tenant['full_name'] as String)
                .trim()
                .toLowerCase();

        final monthlyRent =
            (tenant['monthly_rent'] as num?)
                    ?.toDouble() ??
                0.0;

        double paidThisMonth = 0;

        for (final transaction in transactions) {
          if (transaction.type.name != 'income') {
            continue;
          }

          if (transaction.date.year != now.year ||
              transaction.date.month != now.month) {
            continue;
          }

          final description =
              transaction.description
                  .trim()
                  .toLowerCase();

          final matchesTenant =
              tenantName.isNotEmpty &&
                  description.contains(
                    tenantName,
                  );

          final matchesTenantId =
              description.contains(
            tenantId.toLowerCase(),
          );

          if (matchesTenant ||
              matchesTenantId) {
            paidThisMonth +=
                transaction.amount;
          }
        }

        final pendingForTenant =
            (monthlyRent - paidThisMonth)
                .clamp(
                  0.0,
                  double.infinity,
                );

        totalPendingRent +=
            pendingForTenant;

        if (pendingForTenant > 0) {
          pendingTenantCount++;
        }
      }

      int countFrom(
        List<Map<String, Object?>> rows,
      ) {
        if (rows.isEmpty) return 0;

        final value = rows.first['count'];

        return value is num
            ? value.toInt()
            : 0;
      }

      if (!mounted) return;

      setState(() {
        _totalRooms =
            countFrom(roomResult);

        _totalBeds =
            countFrom(bedResult);

        _occupiedBeds =
            countFrom(occupiedResult);

        _availableBeds =
            countFrom(availableResult);

        _activeTenants =
            countFrom(tenantResult);

        _pendingRent =
            totalPendingRent;

        _pendingRentTenants =
            pendingTenantCount;

        _propertyStatsLoading =
            false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _propertyStatsLoading = false;
      });
    }
  }

  Future<void> _refreshDashboard() async {
    await TransactionService.initialize();

    await _loadDashboardData();

    if (!mounted) return;

    setState(() {});
  }

  // ------------------------------------------------------------
  // TRANSACTION DATA
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
      cashBalance +
      bankBalance +
      upiBalance;

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

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
          RegExp(
            r'\B(?=(\d{3})+(?!\d))',
          ),
          (match) => ',',
        );
  }

  // ============================================================
  // DESKTOP SIDE NAVIGATION
  // ============================================================

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

          // ------------------------------------------------------
          // LOGO
          // ------------------------------------------------------

          Row(
            children: [
              const SizedBox(width: 22),

              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFF2563EB),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.home_work_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),

              const SizedBox(width: 12),

              const Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stay Mitra',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
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

          // ------------------------------------------------------
          // MORE
          // ------------------------------------------------------

          _sideItem(
            Icons.more_horiz_rounded,
            'More',
            8,
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

  // ============================================================
  // DESKTOP SIDE ITEM
  // ============================================================

  Widget _sideItem(
    IconData icon,
    String title,
    int index,
  ) {
    final bool selected =
        selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 4,
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(14),

        onTap: () async {
          // ------------------------------------------------------
          // DASHBOARD
          // ------------------------------------------------------

          if (title == 'Dashboard') {
            setState(() {
              selectedIndex = 0;
            });
            return;
          }

          // ------------------------------------------------------
          // TENANTS
          // ------------------------------------------------------

          if (title == 'Tenants') {
            setState(() {
              selectedIndex = 1;
            });

            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const TenantManagementScreen(),
              ),
            );

            await _refreshDashboard();

            return;
          }

          // ------------------------------------------------------
          // ROOMS
          // ------------------------------------------------------

          if (title == 'Rooms & Beds') {
            setState(() {
              selectedIndex = 2;
            });

            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const RoomsScreen(),
              ),
            );

            await _refreshDashboard();

            return;
          }

          // ------------------------------------------------------
          // DAY SHEET
          // ------------------------------------------------------

          if (title == 'Day Sheet') {
            setState(() {
              selectedIndex = 3;
            });

            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const DaySheetScreen(),
              ),
            );

            await _refreshDashboard();

            return;
          }

          // ------------------------------------------------------
          // BILLING
          // ------------------------------------------------------

          if (title == 'Billing') {
            setState(() {
              selectedIndex = 4;
            });

            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(
                  content: Text(
                    'Billing module will be available soon.',
                  ),
                  behavior:
                      SnackBarBehavior.floating,
                ),
              );

            return;
          }

          // ------------------------------------------------------
          // ACCOUNTS
          // ------------------------------------------------------

          if (title == 'Accounts') {
            setState(() {
              selectedIndex = 5;
            });

            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const AccountsScreen(),
              ),
            );

            await _refreshDashboard();

            return;
          }

          // ------------------------------------------------------
          // REPORTS
          // ------------------------------------------------------

          if (title == 'Reports') {
            setState(() {
              selectedIndex = 6;
            });

            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(
                  content: Text(
                    'Reports module will be available soon.',
                  ),
                  behavior:
                      SnackBarBehavior.floating,
                ),
              );

            return;
          }

          // ------------------------------------------------------
          // SETTINGS
          // ------------------------------------------------------

          if (title == 'Settings') {
            setState(() {
              selectedIndex = 7;
            });

            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(
                  content: Text(
                    'Settings will be available soon.',
                  ),
                  behavior:
                      SnackBarBehavior.floating,
                ),
              );

            return;
          }

          // ------------------------------------------------------
          // MORE
          // ------------------------------------------------------

          if (title == 'More') {
            setState(() {
              selectedIndex = 8;
            });

            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const MoreScreen(),
              ),
            );

            await _refreshDashboard();

            if (!mounted) return;

            setState(() {
              selectedIndex = 0;
            });

            return;
          }

          setState(() {
            selectedIndex = index;
          });
        },

        child: Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 13,
          ),

          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFEFF6FF)
                : Colors.transparent,

            borderRadius:
                BorderRadius.circular(14),
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

  // ============================================================
  // MAIN CONTENT
  // ============================================================

  Widget _buildMainContent() {
    return Column(
      children: [
        _buildTopBar(),

        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshDashboard,

            child: SingleChildScrollView(
              physics:
                  const AlwaysScrollableScrollPhysics(),

              padding:
                  const EdgeInsets.all(22),

              child: _buildDashboard(),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
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
          if (MediaQuery.of(context)
                  .size
                  .width <
              900)
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.menu_rounded,
              ),
            ),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Good Morning 👋',
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        Color(0xFF6B7280),
                  ),
                ),

                SizedBox(height: 3),

                Text(
                  'Stay Mitra Dashboard',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
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
              color:
                  const Color(0xFFEFF6FF),
              borderRadius:
                  BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.person_rounded,
              color:
                  Color(0xFF2563EB),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DASHBOARD
  // ============================================================

  Widget _buildDashboard() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        _buildPropertyCard(),

        const SizedBox(height: 22),

        _buildSectionTitle(
          'Property Overview',
        ),

        const SizedBox(height: 12),

        _buildOverviewCards(),

        const SizedBox(height: 22),

        _buildFinancialCards(),

        const SizedBox(height: 22),

        _buildSectionTitle(
          'Quick Actions',
        ),

        const SizedBox(height: 12),

        _buildQuickActions(),

        const SizedBox(height: 22),

        _buildBottomDashboard(),

        const SizedBox(height: 30),
      ],
    );
  }

  // ============================================================
  // PROPERTY CARD
  // ============================================================

  Widget _buildPropertyCard() {
    if (_buildingLoading) {
      return Container(
        width: double.infinity,
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
        child: const Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    final building = _building;

    // ----------------------------------------------------------
    // NO PG
    // ----------------------------------------------------------

    if (building == null) {
      return Container(
        width: double.infinity,
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
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration:
                      BoxDecoration(
                    color:
                        const Color(0xFFEFF6FF),
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                  child: const Icon(
                    Icons.apartment_rounded,
                    color:
                        Color(0xFF2563EB),
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
                        'No PG configured',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 4),

                      Text(
                        'Set up your PG to get started',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              child:
                  FilledButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const BuildingSetupScreen(),
                    ),
                  );

                  await _loadBuilding();
                },

                icon: const Icon(
                  Icons.add_business_rounded,
                ),

                label: const Text(
                  'Set Up PG',
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ----------------------------------------------------------
    // EXISTING PG
    // ----------------------------------------------------------

    return LayoutBuilder(
      builder:
          (context, constraints) {
        final bool isMobile =
            constraints.maxWidth < 600;

        return Container(
          padding:
              const EdgeInsets.all(16),

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(20),
            border: Border.all(
              color:
                  const Color(0xFFE5E7EB),
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
                          decoration:
                              BoxDecoration(
                            color:
                                const Color(0xFFEFF6FF),
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                          ),
                          child:
                              const Icon(
                            Icons
                                .apartment_rounded,
                            color:
                                Color(0xFF2563EB),
                            size: 28,
                          ),
                        ),

                        const SizedBox(
                          width: 12,
                        ),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                building.name,
                                maxLines: 1,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style:
                                    const TextStyle(
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),

                              if (building
                                          .address !=
                                      null &&
                                  building
                                      .address!
                                      .trim()
                                      .isNotEmpty) ...[
                                const SizedBox(
                                  height: 4,
                                ),

                                Row(
                                  children: [
                                    const Icon(
                                      Icons
                                          .location_on_outlined,
                                      size: 14,
                                      color:
                                          Colors.grey,
                                    ),

                                    const SizedBox(
                                      width: 3,
                                    ),

                                    Expanded(
                                      child:
                                          Text(
                                        building
                                            .address!,
                                        maxLines:
                                            1,
                                        overflow:
                                            TextOverflow
                                                .ellipsis,
                                        style:
                                            const TextStyle(
                                          fontSize:
                                              12,
                                          color:
                                              Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    SizedBox(
                      width:
                          double.infinity,
                      child:
                          OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(
                          Icons
                              .swap_horiz_rounded,
                          size: 18,
                        ),
                        label:
                            const Text(
                          'Switch PG',
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Container(
                      width: 55,
                      height: 55,
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(0xFFEFF6FF),
                        borderRadius:
                            BorderRadius.circular(
                          15,
                        ),
                      ),
                      child:
                          const Icon(
                        Icons
                            .apartment_rounded,
                        color:
                            Color(0xFF2563EB),
                        size: 30,
                      ),
                    ),

                    const SizedBox(
                      width: 15,
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            building.name,
                            maxLines: 1,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                const TextStyle(
                              fontSize: 19,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          if (building
                                      .address !=
                                  null &&
                              building
                                  .address!
                                  .trim()
                                  .isNotEmpty) ...[
                            const SizedBox(
                              height: 5,
                            ),

                            Row(
                              children: [
                                const Icon(
                                  Icons
                                      .location_on_outlined,
                                  size: 15,
                                  color:
                                      Colors.grey,
                                ),

                                const SizedBox(
                                  width: 4,
                                ),

                                Text(
                                  building.address!,
                                  style:
                                      const TextStyle(
                                    fontSize:
                                        13,
                                    color:
                                        Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(
                        Icons
                            .swap_horiz_rounded,
                      ),
                      label:
                          const Text(
                        'Switch PG',
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  // ============================================================
  // OVERVIEW CARDS
  // ============================================================

  Widget _buildOverviewCards() {
    return LayoutBuilder(
      builder:
          (context, constraints) {
        int count = 2;

        if (constraints.maxWidth >=
            1100) {
          count = 4;
        }

        final double aspectRatio =
            constraints.maxWidth < 600
                ? 1.0
                : 1.35;

        return GridView.count(
          crossAxisCount: count,
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio:
              aspectRatio,
          children: [
            _statCard(
              'Total Rooms',
              _propertyStatsLoading
                  ? '...'
                  : '$_totalRooms',
              Icons.meeting_room_rounded,
              const Color(0xFF2563EB),
              'All Rooms',
            ),

            _statCard(
              'Total Beds',
              _propertyStatsLoading
                  ? '...'
                  : '$_totalBeds',
              Icons.bed_rounded,
              const Color(0xFF16A34A),
              'All Beds',
            ),

            _statCard(
              'Occupied',
              _propertyStatsLoading
                  ? '...'
                  : '$_occupiedBeds',
              Icons.person_rounded,
              const Color(0xFF16A34A),
              _occupancyPercentage(),
            ),

            _statCard(
              'Vacant',
              _propertyStatsLoading
                  ? '...'
                  : '$_availableBeds',
              Icons.bed_outlined,
              const Color(0xFFF97316),
              _availabilityPercentage(),
            ),
          ],
        );
      },
    );
  }

  String _occupancyPercentage() {
    if (_totalBeds == 0) {
      return '0.0%';
    }

    return '${(_occupiedBeds / _totalBeds * 100).toStringAsFixed(1)}%';
  }

  String _availabilityPercentage() {
    if (_totalBeds == 0) {
      return '0.0%';
    }

    return '${(_availableBeds / _totalBeds * 100).toStringAsFixed(1)}%';
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(16),

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
                .withValues(
              alpha: 0.025,
            ),
            blurRadius: 8,
            offset:
                const Offset(0, 2),
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
                decoration:
                    BoxDecoration(
                  color:
                      color.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),

              const Spacer(),

              Icon(
                Icons
                    .arrow_forward_ios_rounded,
                size: 13,
                color:
                    Colors.grey.shade400,
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            title,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color:
                  Color(0xFF6B7280),
            ),
          ),

          const SizedBox(height: 2),

          Text(
            value,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 25,
              fontWeight:
                  FontWeight.bold,
              color:
                  Color(0xFF111827),
            ),
          ),

          const SizedBox(height: 1),

          Text(
            subtitle,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FINANCIAL CARDS
  // ============================================================

  Widget _buildFinancialCards() {
    return LayoutBuilder(
      builder:
          (context, constraints) {
        final bool isMobile =
            constraints.maxWidth < 600;

        final int count =
            constraints.maxWidth >= 1000
                ? 4
                : 2;

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

          itemBuilder:
              (context, index) {
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
                _propertyStatsLoading
                    ? '₹ ...'
                    : '₹ ${_money(_pendingRent)}',
                _propertyStatsLoading
                    ? 'Loading'
                    : '$_pendingRentTenants Active Tenants',
                Icons.event_busy_rounded,
                const Color(0xFFDC2626),
              ],

              [
                'This Month Income',
                '₹ ${_money(monthIncome)}',
                'All Income',
                Icons
                    .account_balance_wallet_rounded,
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

            final card =
                cards[index];

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
      padding:
          const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color:
            color.withValues(alpha: 0.04),
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              color.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: 0.02),
            blurRadius: 8,
            offset:
                const Offset(0, 2),
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
            decoration:
                BoxDecoration(
              color:
                  color.withValues(
                alpha: 0.10,
              ),
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
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
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color:
                  Color(0xFF6B7280),
            ),
          ),

          const SizedBox(height: 2),

          FittedBox(
            fit: BoxFit.scaleDown,
            alignment:
                Alignment.centerLeft,
            child: Text(
              amount,
              maxLines: 1,
              style: TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
                color: color,
              ),
            ),
          ),

          const SizedBox(height: 2),

          Text(
            subtitle,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color:
                  Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUICK ACTIONS
  // ============================================================

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
      [
        Icons.apartment_rounded,
        'PG/Apartment Structure',
        const Color(0xFF0891B2),
      ],
    ];

    return LayoutBuilder(
      builder:
          (context, constraints) {
        int count;

        if (constraints.maxWidth >=
            1100) {
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
          childAspectRatio:
              aspectRatio,
          children:
              actions.map((action) {
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
          // ADD TENANT
          if (title == 'Add Tenant') {
            final result =
                await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const AddTenantScreen(),
              ),
            );

            if (result == true) {
              await _refreshDashboard();
            }

            return;
          }

          // ADD PAYMENT
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
              await _refreshDashboard();
            }

            return;
          }

          // ADD EXPENSE
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

          // DAY SHEET
          if (title == 'Day Sheet') {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const DaySheetScreen(),
              ),
            );

            await _refreshDashboard();

            return;
          }

          // PG STRUCTURE
          if (title ==
              'PG/Apartment Structure') {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const BuildingSetupScreen(),
              ),
            );

            await _refreshDashboard();

            return;
          }

          // CREATE BILL
          if (title == 'Create Bill') {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const CreateBillScreen(),
              ),
            );

            if (result == true) {
              await _refreshDashboard();
            }

            return;
          }

          // CHECK-IN
          if (title == 'Check-in') {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const CheckInScreen(),
              ),
            );

            if (result == true) {
              await _refreshDashboard();
            }

            return;
          }

          // UPLOAD REGISTER
          if (title == 'Upload Register') {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const UploadRegisterScreen(),
              ),
            );

            if (result == true) {
              await _refreshDashboard();
            }

            return;
          }

          // OTHER QUICK ACTIONS
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
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
                    .withValues(
                  alpha: 0.025,
                ),
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
                decoration:
                    BoxDecoration(
                  color:
                      color.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
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
                  style:
                      const TextStyle(
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

  // ============================================================
  // BOTTOM DASHBOARD
  // ============================================================

  Widget _buildBottomDashboard() {
    return LayoutBuilder(
      builder:
          (context, constraints) {
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
              child:
                  _remindersCard(),
            ),

            const SizedBox(width: 16),

            Expanded(
              child:
                  _balanceCard(),
            ),
          ],
        );
      },
    );
  }

  Widget _remindersCard() {
    return _dashboardPanel(
      title:
          'Important Reminders',

      children: [
        _reminderItem(
          Icons.people_alt_rounded,
          _propertyStatsLoading
              ? 'Active Tenants'
              : '$_activeTenants Active Tenants',
          _propertyStatsLoading
              ? 'Loading tenant count'
              : 'Current active occupancy',
          const Color(0xFF2563EB),
        ),

        _reminderItem(
          Icons.currency_rupee_rounded,
          _propertyStatsLoading
              ? 'Pending Rent'
              : 'Pending Rent: ₹ ${_money(_pendingRent)}',
          _propertyStatsLoading
              ? 'Loading rent information'
              : 'Based on active tenants monthly rent',
          const Color(0xFFDC2626),
        ),

        _reminderItem(
          Icons.support_agent_rounded,
          'Complaints',
          'Complaint module can be added later',
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
            decoration:
                BoxDecoration(
              color:
                  color.withValues(
                alpha: 0.10,
              ),
              borderRadius:
                  BorderRadius.circular(
                50,
              ),
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
      title:
          'Cash & Bank Balance',

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
                BorderRadius.circular(
              14,
            ),
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
                style:
                    const TextStyle(
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
            decoration:
                BoxDecoration(
              color:
                  color.withValues(
                alpha: 0.10,
              ),
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
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

  // ============================================================
  // MOBILE BOTTOM NAVIGATION
  // ============================================================

  Widget _buildBottomNavigation() {
    return NavigationBar(
      selectedIndex: selectedIndex > 4
          ? 0
          : selectedIndex,

      onDestinationSelected:
          (index) async {

        // ------------------------------------------------------
        // HOME
        // ------------------------------------------------------

        if (index == 0) {
          setState(() {
            selectedIndex = 0;
          });

          return;
        }

        // ------------------------------------------------------
        // TENANTS
        // ------------------------------------------------------

        if (index == 1) {
          setState(() {
            selectedIndex = 1;
          });

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const TenantManagementScreen(),
            ),
          );

          if (!mounted) return;

          await _refreshDashboard();

          if (!mounted) return;

          setState(() {
            selectedIndex = 0;
          });

          return;
        }

        // ------------------------------------------------------
        // ROOMS
        // ------------------------------------------------------

        if (index == 2) {
          setState(() {
            selectedIndex = 2;
          });

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const RoomsScreen(),
            ),
          );

          if (!mounted) return;

          await _refreshDashboard();

          if (!mounted) return;

          setState(() {
            selectedIndex = 0;
          });

          return;
        }

        // ------------------------------------------------------
        // ACCOUNTS
        // ------------------------------------------------------

        if (index == 3) {
          setState(() {
            selectedIndex = 3;
          });

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const AccountsScreen(),
            ),
          );

          if (!mounted) return;

          await _refreshDashboard();

          if (!mounted) return;

          setState(() {
            selectedIndex = 0;
          });

          return;
        }

        // ------------------------------------------------------
        // MORE
        // ------------------------------------------------------

        if (index == 4) {
          setState(() {
            selectedIndex = 4;
          });

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const MoreScreen(),
            ),
          );

          if (!mounted) return;

          await _refreshDashboard();

          if (!mounted) return;

          setState(() {
            selectedIndex = 0;
          });

          return;
        }
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
            Icons
                .account_balance_wallet_outlined,
          ),
          selectedIcon: Icon(
            Icons
                .account_balance_wallet_rounded,
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

// ============================================================
// CREATE BILL SCREEN
// ============================================================

class CreateBillScreen extends StatefulWidget {
  const CreateBillScreen({super.key});

  @override
  State<CreateBillScreen> createState() =>
      _CreateBillScreenState();
}

class _CreateBillScreenState extends State<CreateBillScreen> {
  bool _loading = true;
  bool _saving = false;
  List<Map<String, dynamic>> _tenants = [];
  Map<String, dynamic>? _selectedTenant;
  String _billType = 'Monthly Rent';
  DateTime _dueDate = DateTime.now();
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _noteController = TextEditingController();
    _loadTenants();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadTenants() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query(
        'tenants',
        columns: ['id', 'full_name', 'monthly_rent'],
        where: 'status = ?',
        whereArgs: ['active'],
        orderBy: 'full_name ASC',
      );

      if (!mounted) return;
      setState(() {
        _tenants = rows;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      _showMessage('Unable to load active tenants.', true);
    }
  }

  void _selectTenant(Map<String, dynamic>? tenant) {
    setState(() {
      _selectedTenant = tenant;
      if (tenant != null) {
        final rent = (tenant['monthly_rent'] as num?)?.toDouble() ?? 0;
        _amountController.text = rent.toStringAsFixed(0);
      }
    });
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (picked == null || !mounted) return;
    setState(() {
      _dueDate = picked;
    });
  }

  Future<void> _saveBill() async {
    if (_selectedTenant == null) {
      _showMessage('Please select a tenant.', true);
      return;
    }

    final amount = double.tryParse(
      _amountController.text.trim().replaceAll(',', ''),
    );

    if (amount == null || amount <= 0) {
      _showMessage('Please enter a valid bill amount.', true);
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;

      await db.execute('''
        CREATE TABLE IF NOT EXISTS bills (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          tenant_id TEXT NOT NULL,
          tenant_name TEXT NOT NULL,
          bill_type TEXT NOT NULL,
          amount REAL NOT NULL,
          due_date TEXT NOT NULL,
          note TEXT,
          status TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');

      await db.insert('bills', {
        'tenant_id': _selectedTenant!['id'].toString(),
        'tenant_name': _selectedTenant!['full_name'].toString(),
        'bill_type': _billType,
        'amount': amount,
        'due_date': _dueDate.toIso8601String(),
        'note': _noteController.text.trim(),
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bill created successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Unable to create bill.', true);
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  void _showMessage(String message, bool error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? const Color(0xFFDC2626) : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        title: const Text(
          'Create Bill',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _formCard(
                        icon: Icons.person_rounded,
                        title: 'Tenant',
                        child: DropdownButtonFormField<Map<String, dynamic>>(
                          value: _selectedTenant,
                          isExpanded: true,
                          decoration: _inputDecoration('Select active tenant'),
                          items: _tenants.map((tenant) {
                            return DropdownMenuItem<Map<String, dynamic>>(
                              value: tenant,
                              child: Text(
                                '${tenant['full_name']}  •  ₹${((tenant['monthly_rent'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: _selectTenant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _formCard(
                        icon: Icons.receipt_long_rounded,
                        title: 'Bill Details',
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              value: _billType,
                              decoration: _inputDecoration('Bill Type'),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Monthly Rent',
                                  child: Text('Monthly Rent'),
                                ),
                                DropdownMenuItem(
                                  value: 'Security Deposit',
                                  child: Text('Security Deposit'),
                                ),
                                DropdownMenuItem(
                                  value: 'Other Charges',
                                  child: Text('Other Charges'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  _billType = value;
                                });
                              },
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _amountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: _inputDecoration('Amount').copyWith(
                                prefixText: '₹ ',
                              ),
                            ),
                            const SizedBox(height: 14),
                            InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: _pickDueDate,
                              child: InputDecorator(
                                decoration: _inputDecoration('Due Date'),
                                child: Row(
                                  children: [
                                    Text(_formatDate(_dueDate)),
                                    const Spacer(),
                                    const Icon(Icons.calendar_month_rounded),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _noteController,
                              maxLines: 3,
                              decoration: _inputDecoration('Note (optional)'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _saveBill,
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.receipt_long_rounded),
                          label: Text(_saving ? 'Saving...' : 'Create Bill'),
                        ),
                      ),
                      if (_tenants.isEmpty) ...[
                        const SizedBox(height: 16),
                        const Center(
                          child: Text(
                            'No active tenants found. Add a tenant first.',
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
    );
  }

  Widget _formCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF2563EB)),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

// ============================================================
// CHECK-IN SCREEN
// ============================================================

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  bool _loading = true;
  bool _saving = false;
  List<Map<String, dynamic>> _tenants = [];
  Map<String, dynamic>? _selectedTenant;
  DateTime _date = DateTime.now();
  String _status = 'Checked In';
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    _loadTenants();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadTenants() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query(
        'tenants',
        columns: ['id', 'full_name'],
        where: 'status = ?',
        whereArgs: ['active'],
        orderBy: 'full_name ASC',
      );
      if (!mounted) return;
      setState(() {
        _tenants = rows;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      _message('Unable to load active tenants.', true);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _date = picked;
    });
  }

  Future<void> _saveCheckIn() async {
    if (_selectedTenant == null) {
      _message('Please select a tenant.', true);
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;
      await db.execute('''
        CREATE TABLE IF NOT EXISTS check_ins (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          tenant_id TEXT NOT NULL,
          tenant_name TEXT NOT NULL,
          check_in_date TEXT NOT NULL,
          status TEXT NOT NULL,
          note TEXT,
          created_at TEXT NOT NULL
        )
      ''');

      await db.insert('check_ins', {
        'tenant_id': _selectedTenant!['id'].toString(),
        'tenant_name': _selectedTenant!['full_name'].toString(),
        'check_in_date': _date.toIso8601String(),
        'status': _status,
        'note': _noteController.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Check-in saved successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      _message('Unable to save check-in.', true);
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  void _message(String message, bool error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? const Color(0xFFDC2626) : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        title: const Text(
          'Check-in',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tenant Check-in',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 18),
                        DropdownButtonFormField<Map<String, dynamic>>(
                          value: _selectedTenant,
                          isExpanded: true,
                          decoration: _inputDecoration('Tenant'),
                          items: _tenants.map((tenant) {
                            return DropdownMenuItem<Map<String, dynamic>>(
                              value: tenant,
                              child: Text(tenant['full_name'].toString()),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedTenant = value;
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(14),
                          child: InputDecorator(
                            decoration: _inputDecoration('Check-in Date'),
                            child: Row(
                              children: [
                                Text(_formatDate(_date)),
                                const Spacer(),
                                const Icon(Icons.calendar_month_rounded),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          value: _status,
                          decoration: _inputDecoration('Status'),
                          items: const [
                            DropdownMenuItem(
                              value: 'Checked In',
                              child: Text('Checked In'),
                            ),
                            DropdownMenuItem(
                              value: 'Expected',
                              child: Text('Expected'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _status = value;
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _noteController,
                          maxLines: 3,
                          decoration: _inputDecoration('Note (optional)'),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: _saving ? null : _saveCheckIn,
                            icon: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.login_rounded),
                            label: Text(_saving ? 'Saving...' : 'Save Check-in'),
                          ),
                        ),
                        if (_tenants.isEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'No active tenants found. Add a tenant first.',
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

// ============================================================
// OCR TENANT DRAFT
// ============================================================

class _OcrTenantDraft {
  String name;
  String phone;
  double monthlyRent;
  String roomNumber;
  String bedNumber;

  _OcrTenantDraft({
    required this.name,
    required this.phone,
    required this.monthlyRent,
    required this.roomNumber,
    required this.bedNumber,
  });
}

// ============================================================
// UPLOAD REGISTER SCREEN
// ============================================================

class UploadRegisterScreen extends StatefulWidget {
  const UploadRegisterScreen({super.key});

  @override
  State<UploadRegisterScreen> createState() =>
      _UploadRegisterScreenState();
}

class _UploadRegisterScreenState extends State<UploadRegisterScreen> {
  PlatformFile? _selectedFile;
  bool _saving = false;
  late final TextEditingController _nameController;
  final ImagePicker _imagePicker = ImagePicker();
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  bool _ocrRunning = false;
  List<_OcrTenantDraft> _ocrTenants = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf', 'xls', 'xlsx', 'csv', 'jpg', 'jpeg', 'png', 'doc', 'docx',
      ],
    );

    if (result == null || result.files.isEmpty || !mounted) return;

    final file = result.files.first;
    setState(() {
      _selectedFile = file;
      if (_nameController.text.trim().isEmpty) {
        _nameController.text = file.name;
      }
    });

    final extension = (file.extension ?? '').toLowerCase();
    if (file.path != null &&
        ['jpg', 'jpeg', 'png'].contains(extension)) {
      await _runRegisterOcr(file.path!);
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        maxWidth: 2400,
        maxHeight: 2400,
      );

      if (photo == null || !mounted) return;

      final photoFile = File(photo.path);
      final fileSize = await photoFile.length();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final cameraFile = PlatformFile(
        name: 'register_photo_$timestamp.jpg',
        size: fileSize,
        path: photo.path,
      );

      setState(() {
        _selectedFile = cameraFile;
        if (_nameController.text.trim().isEmpty) {
          _nameController.text = 'Tenant Register Photo';
        }
      });

      await _runRegisterOcr(photo.path);
    } catch (_) {
      if (!mounted) return;
      _message('Unable to open the camera.', true);
    }
  }


  // ============================================================
  // REGISTER OCR
  // ============================================================

  Future<void> _runRegisterOcr(String imagePath) async {
    if (_ocrRunning) return;

    setState(() => _ocrRunning = true);

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText =
          await _textRecognizer.processImage(inputImage);
      final drafts = _parseOcrTenants(recognizedText.text);

      if (!mounted) return;

      setState(() => _ocrTenants = drafts);

      if (drafts.isEmpty) {
        _message(
          'No tenant details could be detected. You can still upload the register.',
          true,
        );
        return;
      }

      await _showOcrReviewDialog();
    } catch (_) {
      if (!mounted) return;
      _message(
        'OCR could not read this register photo. You can still upload it manually.',
        true,
      );
    } finally {
      if (mounted) setState(() => _ocrRunning = false);
    }
  }

  List<_OcrTenantDraft> _parseOcrTenants(String text) {
    final lines = text
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final drafts = <_OcrTenantDraft>[];
    final ignored = RegExp(
      r'^(name|tenant|tenants|phone|mobile|contact|rent|room|bed|amount|sno|sl|no|register|date|signature)$',
      caseSensitive: false,
    );

    for (final rawLine in lines) {
      var line = rawLine.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (line.length < 3 || ignored.hasMatch(line)) continue;

      final phoneMatch = RegExp(
        r'(?<!\d)([6-9]\d{9})(?!\d)',
      ).firstMatch(line);
      final phone = phoneMatch?.group(1) ?? '';
      if (phoneMatch != null) {
        line = line.replaceFirst(phoneMatch.group(0)!, ' ');
      }

      String rentText = '';
      final amountMatches = RegExp(
        r'(?:₹|rs\.?|rent\s*)?\s*([0-9]{3,7}(?:\.[0-9]{1,2})?)',
        caseSensitive: false,
      ).allMatches(line).toList();
      if (amountMatches.isNotEmpty) {
        final match = amountMatches.last;
        rentText = match.group(1) ?? '';
        line = line.replaceRange(match.start, match.end, ' ');
      }

      String roomNumber = '';
      String bedNumber = '';

      // Many handwritten registers use a simple row such as:
      // 101 Venu 6000. If there is no explicit "Room" label,
      // treat a leading 1-4 digit token as the room number.
      final leadingRoomMatch = RegExp(
        r'^\s*([0-9]{1,4})\s+',
      ).firstMatch(line);
      if (leadingRoomMatch != null) {
        roomNumber = leadingRoomMatch.group(1) ?? '';
        line = line.replaceFirst(leadingRoomMatch.group(0)!, '');
      }

      final roomMatch = RegExp(
        r'(?:room\s*[:#-]?\s*)([A-Za-z0-9-]+)',
        caseSensitive: false,
      ).firstMatch(line);
      if (roomMatch != null) {
        roomNumber = roomMatch.group(1) ?? '';
        line = line.replaceFirst(roomMatch.group(0)!, ' ');
      }

      final bedMatch = RegExp(
        r'(?:bed\s*[:#-]?\s*)([A-Za-z0-9-]+)',
        caseSensitive: false,
      ).firstMatch(line);
      if (bedMatch != null) {
        bedNumber = bedMatch.group(1) ?? '';
        line = line.replaceFirst(bedMatch.group(0)!, ' ');
      }

      line = line
          .replaceAll(RegExp(r'^\s*[0-9]+[.)-]\s*'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      if (line.isEmpty || ignored.hasMatch(line)) continue;
      if (RegExp(r'^(tenant|tenant list|name|details|monthly rent|rent details)$', caseSensitive: false).hasMatch(line)) continue;

      drafts.add(
        _OcrTenantDraft(
          name: line,
          phone: phone,
          monthlyRent: double.tryParse(rentText) ?? 0,
          roomNumber: roomNumber,
          bedNumber: bedNumber,
        ),
      );
    }

    final seen = <String>{};
    return drafts.where((draft) {
      final key = '${draft.name.toLowerCase()}|${draft.phone}|${draft.monthlyRent}';
      if (!seen.add(key)) return false;
      return true;
    }).toList();
  }

  Future<List<Map<String, Object?>>> _getAvailableBedsForOcr() async {
    final db = await DatabaseHelper.instance.database;
    return db.rawQuery('''
      SELECT
        beds.id AS bed_id,
        beds.bed_number AS bed_number,
        rooms.room_number AS room_number,
        floors.name AS floor_name,
        buildings.name AS building_name
      FROM beds
      INNER JOIN rooms ON rooms.id = beds.room_id
      INNER JOIN floors ON floors.id = rooms.floor_id
      INNER JOIN buildings ON buildings.id = floors.building_id
      WHERE beds.status = 'available'
      ORDER BY floors.floor_order, rooms.room_number, beds.bed_number
    ''');
  }

  Future<void> _showOcrReviewDialog() async {
    final availableBeds = await _getAvailableBedsForOcr();
    if (!mounted) return;

    if (availableBeds.isEmpty) {
      _message(
        'OCR found tenant details, but there are no available beds. Add beds first, then import the tenants.',
        true,
      );
      return;
    }

    final nameControllers = _ocrTenants
        .map((draft) => TextEditingController(text: draft.name))
        .toList();
    final phoneControllers = _ocrTenants
        .map((draft) => TextEditingController(text: draft.phone))
        .toList();
    final rentControllers = _ocrTenants
        .map((draft) => TextEditingController(
              text: draft.monthlyRent > 0
                  ? draft.monthlyRent.toStringAsFixed(0)
                  : '',
            ))
        .toList();

    final selectedBeds = <String, Map<String, Object?>>{};
    for (var i = 0; i < _ocrTenants.length; i++) {
      final draft = _ocrTenants[i];
      Map<String, Object?>? matched;
      for (final bed in availableBeds) {
        final room = '${bed['room_number'] ?? ''}'.toLowerCase();
        final bedNo = '${bed['bed_number'] ?? ''}'.toLowerCase();
        if (draft.roomNumber.isNotEmpty &&
            room == draft.roomNumber.toLowerCase() &&
            (draft.bedNumber.isEmpty ||
                bedNo == draft.bedNumber.toLowerCase())) {
          matched = bed;
          break;
        }
      }
      matched ??= availableBeds[i < availableBeds.length ? i : availableBeds.length - 1];
      selectedBeds['$i'] = matched;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Review OCR Tenants'),
              content: SizedBox(
                width: 650,
                height: MediaQuery.of(context).size.height * 0.68,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'OCR extracted the details below. Verify the name, phone, rent and room/bed before importing.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'OCR can make mistakes with handwriting. Always verify the extracted details before importing.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        itemCount: _ocrTenants.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final selected = selectedBeds['$index']!;
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Tenant ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: nameControllers[index],
                                  decoration: const InputDecoration(
                                    labelText: 'Name',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: phoneControllers[index],
                                        keyboardType: TextInputType.phone,
                                        decoration: const InputDecoration(
                                          labelText: 'Phone',
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: rentControllers[index],
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Monthly Rent',
                                          prefixText: '₹ ',
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  initialValue: selected['bed_id'] as String?,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Room / Bed',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  items: availableBeds.map((bed) {
                                    final id = bed['bed_id'] as String;
                                    final label = '${bed['building_name'] ?? ''} • ${bed['floor_name'] ?? ''} • Room ${bed['room_number'] ?? ''} • Bed ${bed['bed_number'] ?? ''}';
                                    return DropdownMenuItem<String>(
                                      value: id,
                                      child: Text(label, overflow: TextOverflow.ellipsis),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value == null) return;
                                    final bed = availableBeds.firstWhere((item) => item['bed_id'] == value);
                                    setDialogState(() => selectedBeds['$index'] = bed);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    for (var i = 0; i < _ocrTenants.length; i++) {
                      _ocrTenants[i]
                        ..name = nameControllers[i].text.trim()
                        ..phone = phoneControllers[i].text.trim()
                        ..monthlyRent = double.tryParse(
                              rentControllers[i].text.trim().replaceAll(',', ''),
                            ) ??
                            0;
                    }
                    Navigator.pop(dialogContext, true);
                  },
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Import Tenants'),
                ),
              ],
            );
          },
        );
      },
    );

    for (final controller in nameControllers) {
      controller.dispose();
    }
    for (final controller in phoneControllers) {
      controller.dispose();
    }
    for (final controller in rentControllers) {
      controller.dispose();
    }

    if (confirmed != true || !mounted) return;
    await _importOcrTenants(selectedBeds);
  }

  Future<void> _importOcrTenants(
    Map<String, Map<String, Object?>> selectedBeds,
  ) async {
    var imported = 0;
    var skipped = 0;

    for (var i = 0; i < _ocrTenants.length; i++) {
      final draft = _ocrTenants[i];
      final bed = selectedBeds['$i'];
      if (bed == null || draft.name.trim().isEmpty) {
        skipped++;
        continue;
      }

      final bedId = bed['bed_id'] as String;

      try {
        final existing = await DatabaseHelper.instance.database.then(
          (db) => db.query(
            'tenants',
            columns: ['id'],
            where: 'bed_id = ? AND status = ?',
            whereArgs: [bedId, 'active'],
            limit: 1,
          ),
        );

        if (existing.isNotEmpty) {
          skipped++;
          continue;
        }

        final tenant = TenantModel(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          bedId: bedId,
          fullName: draft.name.trim(),
          phone: draft.phone.trim(),
          alternatePhone: null,
          email: null,
          idProofType: null,
          idProofNumber: null,
          joiningDate: DateTime.now(),
          monthlyRent: draft.monthlyRent,
          securityDeposit: 0,
          status: 'active',
          createdAt: DateTime.now(),
        );

        await DatabaseHelper.instance.insertTenant(tenant);
        imported++;
      } catch (_) {
        skipped++;
      }
    }

    if (!mounted) return;
    setState(() => _ocrTenants = []);
    _message(
      skipped == 0
          ? '$imported tenant(s) imported successfully.'
          : '$imported tenant(s) imported. $skipped row(s) skipped.',
      false,
    );
  }

  Future<void> _showFileSourceOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Select Register Source',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF2563EB)),
                  ),
                  title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Take a photo of your handwritten register'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _takePhoto();
                  },
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.folder_rounded, color: Color(0xFF2563EB)),
                  ),
                  title: const Text('Choose from Device', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Select PDF, Excel, CSV, Word or image files'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _pickFile();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveRegister() async {
    if (_selectedFile == null) {
      _message('Please select a register file or take a photo.', true);
      return;
    }

    if (_selectedFile!.path == null) {
      _message('Unable to access the selected file.', true);
      return;
    }

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _message('Please enter a register name.', true);
      return;
    }

    setState(() => _saving = true);

    try {
      final appDirectory = await getApplicationDocumentsDirectory();
      final registerDirectory = Directory(
        '${appDirectory.path}/stay_mitra_registers',
      );

      if (!await registerDirectory.exists()) {
        await registerDirectory.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeFileName = '${timestamp}_${_selectedFile!.name}';
      final destination = '${registerDirectory.path}/$safeFileName';

      await File(_selectedFile!.path!).copy(destination);

      final db = await DatabaseHelper.instance.database;
      await db.execute('''
        CREATE TABLE IF NOT EXISTS registers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          file_name TEXT NOT NULL,
          file_path TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');

      await db.insert('registers', {
        'name': name,
        'file_name': _selectedFile!.name,
        'file_path': destination,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Register uploaded successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      _message('Unable to upload register.', true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String message, bool error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? const Color(0xFFDC2626) : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final hasFile = _selectedFile != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        title: const Text(
          'Upload Register',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Upload Register File',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Store tenant, payment or other property registers inside Stay Mitra.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Register Name',
                      hintText: 'Example: Tenant Register - Block A',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: _showFileSourceOptions,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              hasFile ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hasFile ? _selectedFile!.name : 'Choose Register File or Take Photo',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  hasFile
                                      ? 'Tap to change file or take another photo'
                                      : 'PDF, Excel, CSV, Word, image or camera photo',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _saving ? null : _takePhoto,
                          icon: const Icon(Icons.camera_alt_rounded),
                          label: const Text('Take Photo'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _saving ? null : _pickFile,
                          icon: const Icon(Icons.folder_open_rounded),
                          label: const Text('Choose File'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _saveRegister,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud_upload_rounded),
                      label: Text(_saving ? 'Uploading...' : 'Upload Register'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
