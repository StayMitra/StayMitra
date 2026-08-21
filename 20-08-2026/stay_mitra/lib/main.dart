import 'package:flutter/material.dart';

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
import 'upload_register_screen.dart';
import 'pg_switch_screen.dart';

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
  List<BuildingModel> _buildings = [];
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
        _buildings = buildings;
        _building =
            buildings.isNotEmpty ? buildings.first : null;
        _buildingLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _buildings = [];
        _building = null;
        _buildingLoading = false;
      });
    }
  }

  Future<void> _showPropertySwitcher() async {
    // Always reload the list so newly created PGs appear immediately.
    try {
      final buildings =
          await DatabaseHelper.instance.getBuildings();

      if (!mounted) return;

      setState(() {
        _buildings = buildings;
      });
    } catch (_) {
      if (!mounted) return;
    }

    if (!mounted) return;

    final selected = await showModalBottomSheet<BuildingModel>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight:
                  MediaQuery.of(sheetContext).size.height * 0.75,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                8,
                20,
                20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Property',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Switch between your PGs or apartments.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_buildings.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No properties found.',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _buildings.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final property = _buildings[index];
                          final isSelected =
                              _building?.id == property.id;

                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.pop(
                                sheetContext,
                                property,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFEFF6FF)
                                    : Colors.white,
                                borderRadius:
                                    BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF93C5FD)
                                      : const Color(0xFFE5E7EB),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius:
                                          BorderRadius.circular(13),
                                    ),
                                    child: const Icon(
                                      Icons.apartment_rounded,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          property.name,
                                          maxLines: 1,
                                          overflow:
                                              TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight:
                                                FontWeight.w600,
                                            color: Color(0xFF111827),
                                          ),
                                        ),
                                        if (property.address != null &&
                                            property.address!
                                                .trim()
                                                .isNotEmpty) ...[
                                          const SizedBox(height: 3),
                                          Text(
                                            property.address!,
                                            maxLines: 1,
                                            overflow:
                                                TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF6B7280),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    isSelected
                                        ? Icons.check_circle_rounded
                                        : Icons.chevron_right_rounded,
                                    color: isSelected
                                        ? const Color(0xFF2563EB)
                                        : const Color(0xFF9CA3AF),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(sheetContext);

                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const BuildingSetupScreen(),
                          ),
                        );

                        await _loadDashboardData();
                      },
                      icon: const Icon(
                        Icons.add_business_rounded,
                      ),
                      label: const Text(
                        'Add New PG / Apartment',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (selected == null || !mounted) return;

    setState(() {
      _building = selected;
      _propertyStatsLoading = true;
    });

    await _loadPropertyStats();

    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Switched to ${selected.name}.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _loadPropertyStats() async {
    try {
      final db =
          await DatabaseHelper.instance.database;

      final buildingId = _building?.id;

      if (buildingId == null) {
        if (!mounted) return;

        setState(() {
          _totalRooms = 0;
          _totalBeds = 0;
          _occupiedBeds = 0;
          _availableBeds = 0;
          _activeTenants = 0;
          _pendingRent = 0;
          _pendingRentTenants = 0;
          _propertyStatsLoading = false;
        });

        return;
      }

      // Rooms and beds are linked to a property through:
      // rooms -> floors -> buildings
      final roomResult = await db.rawQuery(
        '''
        SELECT COUNT(*) AS count
        FROM rooms r
        INNER JOIN floors f ON f.id = r.floor_id
        WHERE f.building_id = ?
        ''',
        [buildingId],
      );

      final bedResult = await db.rawQuery(
        '''
        SELECT COUNT(*) AS count
        FROM beds b
        INNER JOIN rooms r ON r.id = b.room_id
        INNER JOIN floors f ON f.id = r.floor_id
        WHERE f.building_id = ?
        ''',
        [buildingId],
      );

      final occupiedResult = await db.rawQuery(
        '''
        SELECT COUNT(*) AS count
        FROM beds b
        INNER JOIN rooms r ON r.id = b.room_id
        INNER JOIN floors f ON f.id = r.floor_id
        WHERE f.building_id = ?
          AND b.status = 'occupied'
        ''',
        [buildingId],
      );

      final availableResult = await db.rawQuery(
        '''
        SELECT COUNT(*) AS count
        FROM beds b
        INNER JOIN rooms r ON r.id = b.room_id
        INNER JOIN floors f ON f.id = r.floor_id
        WHERE f.building_id = ?
          AND b.status = 'available'
        ''',
        [buildingId],
      );

      final tenantResult = await db.rawQuery(
        '''
        SELECT COUNT(*) AS count
        FROM tenants t
        INNER JOIN beds b ON b.id = t.bed_id
        INNER JOIN rooms r ON r.id = b.room_id
        INNER JOIN floors f ON f.id = r.floor_id
        WHERE f.building_id = ?
          AND t.status = 'active'
        ''',
        [buildingId],
      );

      // ----------------------------------------------------------
      // PENDING RENT
      // ----------------------------------------------------------

      final activeTenants = await db.rawQuery(
        '''
        SELECT
          t.id,
          t.full_name,
          t.monthly_rent
        FROM tenants t
        INNER JOIN beds b ON b.id = t.bed_id
        INNER JOIN rooms r ON r.id = b.room_id
        INNER JOIN floors f ON f.id = r.floor_id
        WHERE f.building_id = ?
          AND t.status = 'active'
        ORDER BY t.created_at ASC
        ''',
        [buildingId],
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
                        onPressed: () async {
                          final changed = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const PgSwitchScreen(),
                            ),
                          );

                          if (changed == true && mounted) {
                            await _loadDashboardData();
                          }
                        },
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
                      onPressed: () async {
                          final changed = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const PgSwitchScreen(),
                            ),
                          );

                          if (changed == true && mounted) {
                            await _loadDashboardData();
                          }
                        },
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
          Icons.currency_rupee_rounded,
          _propertyStatsLoading
              ? 'Pending Rent'
              : 'Pending Rent: ₹ ${_money(_pendingRent)}',
          _propertyStatsLoading
              ? 'Loading rent information'
              : 'Based on active tenants monthly rent',
          const Color(0xFFDC2626),
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
  child: DropdownButtonFormField<String>(
    value: () {
      final selectedId =
          _selectedTenant?['id']?.toString();

      if (selectedId == null) {
        return null;
      }

      final exists = _tenants.any(
        (tenant) =>
            tenant['id']?.toString() == selectedId,
      );

      return exists ? selectedId : null;
    }(),

    isExpanded: true,

    decoration: _inputDecoration(
      'Select active tenant',
    ),

    items: () {
      final uniqueTenants =
          <String, Map<String, dynamic>>{};

      for (final tenant in _tenants) {
        final id =
            tenant['id']?.toString();

        if (id != null && id.isNotEmpty) {
          uniqueTenants[id] = tenant;
        }
      }

      return uniqueTenants.values.map((tenant) {
        final tenantId =
            tenant['id']!.toString();

        final monthlyRent =
            (tenant['monthly_rent'] as num?)
                    ?.toDouble() ??
                0;

        return DropdownMenuItem<String>(
          value: tenantId,
          child: Text(
            '${tenant['full_name']}  •  ₹${monthlyRent.toStringAsFixed(0)}',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList();
    }(),

    onChanged: (tenantId) {
      if (tenantId == null) {
        return;
      }

      final matchingTenants =
          _tenants.where(
        (tenant) =>
            tenant['id']?.toString() ==
            tenantId,
      );

      if (matchingTenants.isEmpty) {
        return;
      }

      _selectTenant(
        matchingTenants.first,
      );
    },
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
DropdownButtonFormField<String>(
  value: () {
    final selectedId =
        _selectedTenant?['id']?.toString();

    if (selectedId == null) {
      return null;
    }

    final exists = _tenants.any(
      (tenant) =>
          tenant['id']?.toString() == selectedId,
    );

    return exists ? selectedId : null;
  }(),

  isExpanded: true,

  decoration: _inputDecoration(
    'Select active tenant',
  ),

  items: () {
    final uniqueTenants =
        <String, Map<String, dynamic>>{};

    for (final tenant in _tenants) {
      final id = tenant['id']?.toString();

      if (id != null && id.isNotEmpty) {
        uniqueTenants[id] = tenant;
      }
    }

    return uniqueTenants.values.map((tenant) {
      final tenantId =
          tenant['id']!.toString();

      return DropdownMenuItem<String>(
        value: tenantId,
        child: Text(
          '${tenant['full_name']}',
          overflow: TextOverflow.ellipsis,
        ),
      );
    }).toList();
  }(),

onChanged: (tenantId) {
  if (tenantId == null) {
    return;
  }

  final matchingTenants = _tenants.where(
    (tenant) =>
        tenant['id']?.toString() == tenantId,
  );

  if (matchingTenants.isEmpty) {
    return;
  }

  setState(() {
    _selectedTenant =
        matchingTenants.first;
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
