import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'login_screen.dart';
import 'reports_screen.dart';
import 'documents_screen.dart';
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
import 'settings_screen.dart';
import 'create_bill_screen.dart' as create_bill_screen;
import 'upload_register_screen.dart';
import 'pg_switch_screen.dart';
import 'pg_manager_service.dart';
import 'pg_context.dart';
import 'package:sqflite/sqflite.dart';
import 'firestore_test_screen.dart';
import 'firebase_migration_screen.dart';
import 'services/firebase_dashboard_service.dart';
import 'check_in_screen.dart' as check_in;
import 'pin_lock_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
      home: const SplashScreen(),

routes: {
  '/login': (context) => const LoginScreen(),
  '/dashboard': (context) => const PinLockGate(
    child: DashboardPage(),
  ),
  '/firestore-test': (context) =>
    const FirestoreTestScreen(),
  '/firebase-migration': (context) =>
    const FirebaseMigrationScreen(
      ownerId: 'default_owner',
    ),  
},
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const String ownerId = 'default_owner';
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();
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
  double _todayCollection = 0;
  int _todayPaymentCount = 0;
  double _monthIncome = 0;
  double _monthExpense = 0;

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
    BuildingModel? activePg =
        PgManagerService.activePg;

    // ----------------------------------------------------------
    // IF NO ACTIVE PG, LOAD OWNER'S PGs
    // AND SELECT THE FIRST ONE
    // ----------------------------------------------------------

    if (activePg == null) {
      final pgs =
          await DatabaseHelper.instance.getBuildings(
        ownerId: ownerId,
      );

      if (pgs.isNotEmpty) {
        activePg = pgs.first;

        await PgManagerService.selectPg(
          activePg,
          ownerId: ownerId,
        );
      }
    }

    if (!mounted) return;

    setState(() {
      _building = activePg;
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

  Future<void> _showPropertySwitcher() async {
    // Always reload the list so newly created PGs appear immediately.
    try {
      final buildings =
          await DatabaseHelper.instance.getBuildings(
            ownerId: ownerId,
          );

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
                                const BuildingSetupScreen(
                                  ownerId: ownerId,
                                ),
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
    final activePg = PgManagerService.activePg;

    if (activePg == null) {
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
        _todayCollection = 0;
_todayPaymentCount = 0;
_monthIncome = 0;
_monthExpense = 0;
      });

      return;
    }

    final buildingId = activePg.id;

    final stats =
        await FirebaseDashboardService.instance
            .getPropertyStats(
      buildingId,
    );

    if (!mounted) return;

    setState(() {
      _totalRooms = stats.totalRooms;
      _totalBeds = stats.totalBeds;
      _occupiedBeds = stats.occupiedBeds;
      _availableBeds = stats.availableBeds;

      _activeTenants = stats.activeTenants;

      _pendingRent = stats.pendingRent;
      _pendingRentTenants =
          stats.pendingRentTenants;
      _todayCollection = stats.todayCollection;
      _todayPaymentCount = stats.todayPaymentCount;
      _monthIncome = stats.monthIncome;
      _monthExpense = stats.monthExpense;    

      _propertyStatsLoading = false;
    });
  } catch (e) {
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
      _todayCollection = 0;
_todayPaymentCount = 0;
_monthIncome = 0;
_monthExpense = 0;
    });
  }
}

  Future<void> _refreshDashboard() async {
    await TransactionService.initialize();

    await _loadDashboardData();
    await _loadPropertyStats();
    if (!mounted) return;

    setState(() {});
  }

  // ------------------------------------------------------------
  // TRANSACTION DATA
  // ------------------------------------------------------------

double get todayCollection =>
    _todayCollection;

double get todayExpense =>
    0;

double get monthIncome =>
    _monthIncome;

double get monthExpense =>
    _monthExpense;

double get cashBalance {
  final buildingId = _building?.id;

  if (buildingId == null) {
    return 0;
  }

  return TransactionService.getCashBalance(
    buildingId,
  );
}

double get bankBalance {
  final buildingId = _building?.id;

  if (buildingId == null) {
    return 0;
  }

  return TransactionService.getBankBalance(
    buildingId,
  );
}

double get upiBalance {
  final buildingId = _building?.id;

  if (buildingId == null) {
    return 0;
  }

  return TransactionService.getUpiBalance(
    buildingId,
  );
}

int get todayPaymentCount =>
    _todayPaymentCount;

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
      key: _scaffoldKey,
      drawer: _buildNavigationDrawer(),
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

  // ============================================================
  // NAVIGATION DRAWER
  // ============================================================

  Widget _buildNavigationDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
              decoration: const BoxDecoration(
                color: Color(0xFF2563EB),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.home_work_rounded,
                          color: Color(0xFF2563EB),
                          size: 27,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Stay Mitra',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'PG Management',
                              style: TextStyle(
                                color: Color(0xFFDCEAFE),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _building?.name ?? 'PG / Property',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Current property',
                    style: TextStyle(
                      color: Color(0xFFDBEAFE),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  _drawerItem(
                    Icons.dashboard_rounded,
                    'Dashboard',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => selectedIndex = 0);
                    },
                  ),
//                  _drawerItem(
//                    Icons.apartment_rounded,
//                    'Switch PG / Apartment',
//                    onTap: () async {
//                      Navigator.pop(context);
//                      await _showPropertySwitcher();
//                      if (mounted) await _refreshDashboard();
//                    },
//                  ),
                  _drawerItem(
                    Icons.people_alt_rounded,
                    'Tenants',
                    onTap: () async {
                      Navigator.pop(context);
                      setState(() => selectedIndex = 1);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const TenantManagementScreen(),
                        ),
                      );
                      await _refreshDashboard();
                    },
                  ),
                  _drawerItem(
                    Icons.bed_rounded,
                    'Rooms',
                    onTap: () async {
                      Navigator.pop(context);
                      setState(() => selectedIndex = 2);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RoomsScreen(),
                        ),
                      );
                      await _refreshDashboard();
                    },
                  ),
                  _drawerItem(
                    Icons.account_balance_wallet_rounded,
                    'Accounts',
                    onTap: () async {
                      Navigator.pop(context);
                      setState(() => selectedIndex = 5);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AccountsScreen(),
                        ),
                      );
                      await _refreshDashboard();
                    },
                  ),
_drawerItem(
  Icons.bar_chart_rounded,
  'Reports',
  onTap: () async {
    Navigator.pop(context);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ReportsScreen(),
      ),
    );

    if (mounted) {
      await _refreshDashboard();
    }
  },
),
_drawerItem(
  Icons.description_outlined,
  'Documents',
  onTap: () async {
    Navigator.pop(context);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DocumentsScreen(),
      ),
    );

    if (result == true) {
      await _refreshDashboard();
    }
  },
),
                  _drawerItem(
                    Icons.notifications_none_rounded,
                    'Notifications',
                    onTap: () async {
                      Navigator.pop(context);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const DashboardNotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  _drawerItem(
                    Icons.settings_rounded,
                    'Settings',
                    onTap: () async {
                      Navigator.pop(context);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            _drawerItem(
              Icons.logout_rounded,
              'Logout',
              color: const Color(0xFFDC2626),
              onTap: () {
                Navigator.pop(context);
                _showLogoutConfirmation();
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    IconData icon,
    String title, {
    required VoidCallback onTap,
    Color color = const Color(0xFF334155),
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFF94A3B8),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }

  void _showLogoutConfirmation() {
    showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text(
            'Are you sure you want to logout?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
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
              tooltip: 'Menu',
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
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
                  'Welcome 👋',
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
            tooltip: 'Notifications',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const DashboardNotificationsScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.notifications_none_rounded,
              size: 27,
            ),
          ),

          const SizedBox(width: 8),

          InkWell(
            borderRadius: BorderRadius.circular(50),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const DashboardOwnerProfileScreen(),
                ),
              );
            },
            child: Container(
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
                          const BuildingSetupScreen(
                            ownerId: ownerId,
                          ),
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
                                  const PgSwitchScreen(
                                    ownerId: ownerId,
                                  ),
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
                                  const PgSwitchScreen(
                                    ownerId: ownerId,
                                  ),
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
        'Check-in/Out',
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
// ADD EXPENSE
if (title == 'Add Expense') {
  final currentBuilding = _building;

  if (currentBuilding == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Please add/select a PG first',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AddExpenseScreen(
        buildingId: currentBuilding.id,
      ),
    ),
  );

  if (result == true) {
    await _refreshDashboard();
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
                    const BuildingSetupScreen(
                      ownerId: ownerId,
                    ),
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
    create_bill_screen.CreateBillScreen(
      buildingId: _building?.id,
      buildingName: _building?.name,
    ),
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
                    const check_in.CheckInScreen(),
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
// ============================================================
// CHECK-IN SCREEN
// ============================================================

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  static const String ownerId = 'default_owner';

  bool _loading = true;
  bool _saving = false;
  bool _checkingOut = false;
  bool _switchingPg = false;

  List<Map<String, dynamic>> _buildings = [];
  List<Map<String, dynamic>> _tenants = [];
  List<Map<String, dynamic>> _recentCheckIns = [];

  String? _selectedBuildingId;
  String? _selectedTenantId;

  DateTime _checkInDate = DateTime.now();
  String _status = 'Checked In';

  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    _initializeCheckIns();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // ============================================================
  // SELECTED PG
  // ============================================================

  Map<String, dynamic>? get _selectedBuilding {
    final id = _selectedBuildingId;
    if (id == null) return null;

    for (final building in _buildings) {
      if (building['id']?.toString() == id) {
        return building;
      }
    }

    return null;
  }

  String get _selectedBuildingName {
    return _selectedBuilding?['name']?.toString() ?? 'No PG selected';
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> _initializeCheckIns() async {
    try {
      final db = await DatabaseHelper.instance.database;

      await _ensureCheckInsTable(db);
      await _loadBuildings();
      await _loadTenants();
      await _loadRecentCheckIns();

      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showMessage(
        'Unable to load check-in information. $e',
        isError: true,
      );
    }
  }

  // ============================================================
  // CHECK-IN TABLE
  // ============================================================

  Future<void> _ensureCheckInsTable(dynamic db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS check_ins (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tenant_id TEXT NOT NULL,
        tenant_name TEXT NOT NULL,
        building_id TEXT,
        check_in_date TEXT NOT NULL,
        status TEXT NOT NULL,
        note TEXT,
        checkout_date TEXT,
        checkout_note TEXT,
        check_out_date TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await _addColumnIfNotExists(db, 'check_ins', 'building_id', 'TEXT');
    await _addColumnIfNotExists(db, 'check_ins', 'checkout_date', 'TEXT');
    await _addColumnIfNotExists(db, 'check_ins', 'checkout_note', 'TEXT');

    // Older versions used check_out_date. Keep old data and copy it to
    // the new checkout_date column instead of deleting anything.
    await _addColumnIfNotExists(db, 'check_ins', 'check_out_date', 'TEXT');

    try {
      await db.execute('''
        UPDATE check_ins
        SET checkout_date = check_out_date
        WHERE (checkout_date IS NULL OR checkout_date = '')
          AND check_out_date IS NOT NULL
          AND check_out_date != ''
      ''');
    } catch (_) {
      // Keep the app usable even if the legacy column is unavailable.
    }
  }

  Future<void> _addColumnIfNotExists(
    dynamic db,
    String table,
    String column,
    String definition,
  ) async {
    final result = await db.rawQuery('PRAGMA table_info($table)');

    final exists = result.any(
      (row) => row['name']?.toString() == column,
    );

    if (!exists) {
      await db.execute(
        'ALTER TABLE $table ADD COLUMN $column $definition',
      );
    }
  }

  // ============================================================
  // LOAD PGs
  // ============================================================

  Future<void> _loadBuildings() async {
    final db = await DatabaseHelper.instance.database;

    final rows = await db.query(
      'buildings',
      columns: [
        'id',
        'name',
        'address',
        'owner_id',
        'created_at',
      ],
      where: 'owner_id = ?',
      whereArgs: [ownerId],
      orderBy: 'name COLLATE NOCASE ASC',
    );

    if (!mounted) return;

    setState(() {
      _buildings = rows;
    });

    // First preference: the PG already selected in the app.
    final activePg = PgManagerService.activePg;

    if (activePg != null &&
        rows.any((row) => row['id']?.toString() == activePg.id.toString())) {
      _selectedBuildingId = activePg.id.toString();
      return;
    }

    // If no PG is active, automatically select the first PG.
    if (rows.isNotEmpty) {
      final firstId = rows.first['id']?.toString();

      if (firstId != null && firstId.isNotEmpty) {
        _selectedBuildingId = firstId;

        final firstPg = rows.first;

        try {
          await PgManagerService.selectPg(
            _buildingFromRow(firstPg),
            ownerId: ownerId,
          );
        } catch (_) {
          // The screen can still use the selected building ID.
        }
      }
    } else {
      _selectedBuildingId = null;
    }
  }

  BuildingModel _buildingFromRow(Map<String, dynamic> row) {
    return BuildingModel(
      id: row['id']?.toString() ?? '',
      name: row['name']?.toString() ?? 'PG',
      address: row['address']?.toString(),
      ownerId: row['owner_id']?.toString() ?? ownerId,
      createdAt: DateTime.tryParse(
            row['created_at']?.toString() ?? '',
          ) ??
          DateTime.now(),
    );
  }

  // ============================================================
  // LOAD ACTIVE TENANTS - SELECTED PG ONLY
  // ============================================================

  Future<void> _loadTenants() async {
    try {
      final buildingId = _selectedBuildingId;

      if (buildingId == null || buildingId.isEmpty) {
        if (!mounted) return;

        setState(() {
          _tenants = [];
          _selectedTenantId = null;
        });
        return;
      }

      final db = await DatabaseHelper.instance.database;

      // IMPORTANT:
      // Tenant does not store building_id directly.
      // The correct PG is resolved through:
      // Tenant -> Bed -> Room -> Floor -> Building.
      final rows = await db.rawQuery(
        '''
        SELECT
          t.id AS id,
          t.full_name AS full_name,
          t.phone AS phone,
          t.monthly_rent AS monthly_rent,
          t.bed_id AS bed_id,
          t.joining_date AS joining_date,
          t.status AS status,
          b.bed_number AS bed_number,
          r.room_number AS room_number,
          f.name AS floor_name,
          bl.id AS building_id,
          bl.name AS building_name
        FROM tenants t
        INNER JOIN beds b
          ON b.id = t.bed_id
        INNER JOIN rooms r
          ON r.id = b.room_id
        INNER JOIN floors f
          ON f.id = r.floor_id
        INNER JOIN buildings bl
          ON bl.id = f.building_id
        WHERE t.status = ?
          AND f.building_id = ?
        ORDER BY t.full_name COLLATE NOCASE ASC
        ''',
        ['active', buildingId],
      );

      if (!mounted) return;

      setState(() {
        _tenants = rows;

        if (_selectedTenantId != null &&
            !_tenants.any(
              (tenant) => tenant['id']?.toString() == _selectedTenantId,
            )) {
          _selectedTenantId = null;
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _tenants = [];
        _selectedTenantId = null;
      });

      _showMessage(
        'Unable to load active tenants. $e',
        isError: true,
      );
    }
  }

  // ============================================================
  // SELECT TENANT
  // ============================================================

  Map<String, dynamic>? get _selectedTenant {
    final id = _selectedTenantId;
    if (id == null) return null;

    for (final tenant in _tenants) {
      if (tenant['id']?.toString() == id) {
        return tenant;
      }
    }

    return null;
  }

  // ============================================================
  // SWITCH PG
  // ============================================================

  Future<void> _selectBuilding(String? value) async {
    if (value == null || value.isEmpty || _switchingPg) return;

    if (!_buildings.any((building) => building['id']?.toString() == value)) {
      return;
    }

    setState(() {
      _switchingPg = true;
      _selectedBuildingId = value;
      _selectedTenantId = null;
      _tenants = [];
      _recentCheckIns = [];
    });

    try {
      final row = _buildings.firstWhere(
        (building) => building['id']?.toString() == value,
      );

      await PgManagerService.selectPg(
        _buildingFromRow(row),
        ownerId: ownerId,
      );

      await _loadTenants();
      await _loadRecentCheckIns();
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to switch PG. $e',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _switchingPg = false;
        });
      }
    }
  }

  // ============================================================
  // DATE
  // ============================================================

  Future<void> _pickCheckInDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkInDate,
      firstDate: DateTime.now().subtract(
        const Duration(days: 3650),
      ),
      lastDate: DateTime.now().add(
        const Duration(days: 3650),
      ),
    );

    if (picked == null || !mounted) return;

    setState(() {
      _checkInDate = picked;
    });
  }

  // ============================================================
  // OPEN CHECK-IN
  // ============================================================

  Future<bool> _hasOpenCheckIn(String tenantId) async {
    final buildingId = _selectedBuildingId;
    if (buildingId == null || buildingId.isEmpty) return false;

    final db = await DatabaseHelper.instance.database;

    final rows = await db.rawQuery(
      '''
      SELECT ci.id
      FROM check_ins ci
      WHERE ci.tenant_id = ?
        AND ci.building_id = ?
        AND ci.status = 'Checked In'
        AND (
          ci.checkout_date IS NULL
          OR ci.checkout_date = ''
        )
      ORDER BY ci.id DESC
      LIMIT 1
      ''',
      [tenantId, buildingId],
    );

    return rows.isNotEmpty;
  }

  // ============================================================
  // SAVE CHECK-IN
  // ============================================================

  Future<void> _saveCheckIn() async {
    final tenant = _selectedTenant;
    final buildingId = _selectedBuildingId;

    if (buildingId == null || buildingId.isEmpty) {
      _showMessage(
        'Please select a PG first.',
        isError: true,
      );
      return;
    }

    if (tenant == null) {
      _showMessage(
        'Please select a tenant.',
        isError: true,
      );
      return;
    }

    // Final safety check. A tenant from another PG can never be saved.
    if (tenant['building_id']?.toString() != buildingId) {
      _showMessage(
        'Selected tenant does not belong to $_selectedBuildingName.',
        isError: true,
      );
      return;
    }

    if (_status == 'Cancelled') {
      _showMessage(
        'Cancelled check-ins are not saved as a check-in record.',
        isError: true,
      );
      return;
    }

    if (_saving || _checkingOut) return;

    setState(() {
      _saving = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;
      await _ensureCheckInsTable(db);

      final tenantId = tenant['id']?.toString() ?? '';

      if (tenantId.isEmpty) {
        throw Exception('Invalid tenant ID.');
      }

      final alreadyCheckedIn = await _hasOpenCheckIn(tenantId);

      if (alreadyCheckedIn) {
        if (!mounted) return;

        _showMessage(
          '${tenant['full_name'] ?? 'This tenant'} is already checked in. '
          'Please check out first.',
          isError: true,
        );
        return;
      }

      await db.insert(
        'check_ins',
        {
          'tenant_id': tenantId,
          'tenant_name': tenant['full_name']?.toString() ?? 'Tenant',
          'building_id': buildingId,
          'check_in_date': _checkInDate.toIso8601String(),
          'status': 'Checked In',
          'note': _noteController.text.trim(),
          'checkout_date': null,
          'checkout_note': null,
          'created_at': DateTime.now().toIso8601String(),
        },
      );

      await _loadRecentCheckIns();

      if (!mounted) return;

      _noteController.clear();

      setState(() {
        _selectedTenantId = null;
        _status = 'Checked In';
        _checkInDate = DateTime.now();
      });

      _showMessage(
        '${tenant['full_name'] ?? 'Tenant'} checked in successfully in $_selectedBuildingName.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to save check-in. $e',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // ============================================================
  // CHECK-OUT
  // ============================================================

  Future<void> _checkoutRecord(
    Map<String, dynamic> record,
  ) async {
    if (_checkingOut || _saving) return;

    final tenantId = record['tenant_id']?.toString();
    final checkInId = record['id'];
    final tenantName = record['tenant_name']?.toString() ?? 'Tenant';
    final recordBuildingId = record['building_id']?.toString() ?? '';

    if (tenantId == null || tenantId.isEmpty || checkInId == null) {
      _showMessage(
        'Invalid check-in record.',
        isError: true,
      );
      return;
    }

    if (_selectedBuildingId == null ||
        recordBuildingId != _selectedBuildingId) {
      _showMessage(
        'This check-in does not belong to the selected PG.',
        isError: true,
      );
      return;
    }

    final noteController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Check-out'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to check out $tenantName?',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Checkout note',
                  hintText: 'Optional',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Check-out'),
            ),
          ],
        );
      },
    );

    final checkoutNote = noteController.text.trim();
    noteController.dispose();

    if (confirmed != true || !mounted) return;

    setState(() {
      _checkingOut = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;
      await _ensureCheckInsTable(db);

      final checkoutDate = DateTime.now().toIso8601String();

      final updated = await db.update(
        'check_ins',
        {
          'status': 'Checked Out',
          'checkout_date': checkoutDate,
          'checkout_note': checkoutNote,
          'check_out_date': checkoutDate,
        },
        where: 'id = ? AND building_id = ? AND status = ?',
        whereArgs: [
          checkInId,
          _selectedBuildingId,
          'Checked In',
        ],
      );

      if (updated != 1) {
        throw Exception(
          'Check-in record is already checked out or does not exist.',
        );
      }

      await _loadRecentCheckIns();

      if (!mounted) return;

      _showMessage(
        '$tenantName checked out successfully. History has been retained.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to check out $tenantName. $e',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _checkingOut = false;
        });
      }
    }
  }

  // ============================================================
  // LOAD HISTORY - SELECTED PG ONLY
  // ============================================================

  Future<void> _loadRecentCheckIns() async {
    try {
      final buildingId = _selectedBuildingId;

      if (buildingId == null || buildingId.isEmpty) {
        if (!mounted) return;

        setState(() {
          _recentCheckIns = [];
        });
        return;
      }

      final db = await DatabaseHelper.instance.database;
      await _ensureCheckInsTable(db);

      // The PG is filtered using the building_id saved at check-in time.
      // This is important because a tenant may later be moved/vacated.
      // Therefore old history cannot accidentally move to another PG.
      final rows = await db.rawQuery(
        '''
        SELECT
          ci.id AS id,
          ci.tenant_id AS tenant_id,
          ci.tenant_name AS tenant_name,
          ci.building_id AS building_id,
          ci.check_in_date AS check_in_date,
          ci.status AS status,
          ci.note AS note,
          ci.checkout_date AS checkout_date,
          ci.checkout_note AS checkout_note,
          ci.created_at AS created_at,
          bl.name AS building_name,
          b.bed_number AS bed_number,
          r.room_number AS room_number,
          f.name AS floor_name
        FROM check_ins ci
        LEFT JOIN buildings bl
          ON bl.id = ci.building_id
        LEFT JOIN tenants t
          ON t.id = ci.tenant_id
        LEFT JOIN beds b
          ON b.id = t.bed_id
        LEFT JOIN rooms r
          ON r.id = b.room_id
        LEFT JOIN floors f
          ON f.id = r.floor_id
        WHERE ci.building_id = ?
           OR (ci.building_id IS NULL AND f.building_id = ?)
        ORDER BY ci.check_in_date DESC, ci.id DESC
        LIMIT 100
        ''',
        [buildingId, buildingId],
      );

      if (!mounted) return;

      setState(() {
        _recentCheckIns = rows;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _recentCheckIns = [];
      });

      _showMessage(
        'Unable to load check-in history. $e',
        isError: true,
      );
    }
  }

  // ============================================================
  // ADD TENANT
  // ============================================================

  Future<void> _openAddTenant() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddTenantScreen(),
      ),
    );

    if (result == true) {
      await _loadBuildings();
      await _loadTenants();
      await _loadRecentCheckIns();
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError
              ? const Color(0xFFDC2626)
              : null,
        ),
      );
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
          'Check-in',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : RefreshIndicator(
                onRefresh: _refresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    18,
                    16,
                    30,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 760,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _headerCard(),
                          const SizedBox(height: 18),
                          _checkInFormCard(),
                          const SizedBox(height: 24),
                          _recentCheckInsSection(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _headerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFDBEAFE),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.login_rounded,
              color: Color(0xFF2563EB),
              size: 29,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Record Tenant Check-in',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_selectedBuildingName • Only tenants from this PG are shown. '
                  'Check-in, check-out and history stay within this PG.',
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.45,
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

  // ============================================================
  // FORM
  // ============================================================

  Widget _checkInFormCard() {
    return _sectionCard(
      title: 'Check-in Details',
      icon: Icons.fact_check_rounded,
      iconColor: const Color(0xFF2563EB),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PG / Building',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          if (_buildings.isEmpty)
            _noPgBox()
          else
            DropdownButtonFormField<String>(
              value: _selectedBuildingId,
              isExpanded: true,
              decoration: _inputDecoration(
                hintText: 'Select PG',
                icon: Icons.apartment_rounded,
              ),
              items: _buildings.map((building) {
                final id = building['id']?.toString() ?? '';
                final name = building['name']?.toString() ?? 'PG';

                return DropdownMenuItem<String>(
                  value: id,
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: _switchingPg ? null : _selectBuilding,
            ),

          if (_selectedBuilding != null) ...[
            const SizedBox(height: 12),
            _buildingSummary(_selectedBuilding!),
          ],

          const SizedBox(height: 18),

          const Text(
            'Tenant',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          if (_selectedBuildingId == null)
            _selectPgFirstBox()
          else if (_tenants.isEmpty)
            _noTenantBox()
          else
            DropdownButtonFormField<String>(
              value: _tenants.any(
                (tenant) => tenant['id']?.toString() == _selectedTenantId,
              )
                  ? _selectedTenantId
                  : null,
              isExpanded: true,
              decoration: _inputDecoration(
                hintText: 'Select tenant from $_selectedBuildingName',
                icon: Icons.person_outline_rounded,
              ),
              items: _tenants.map((tenant) {
                final id = tenant['id']?.toString() ?? '';
                final name = tenant['full_name']?.toString() ?? 'Tenant';
                final phone = tenant['phone']?.toString() ?? '';
                final room = tenant['room_number']?.toString() ?? '';
                final bed = tenant['bed_number']?.toString() ?? '';

                final details = <String>[
                  if (phone.isNotEmpty) phone,
                  if (room.isNotEmpty) 'Room $room',
                  if (bed.isNotEmpty) 'Bed $bed',
                ].join(' • ');

                return DropdownMenuItem<String>(
                  value: id,
                  child: Text(
                    details.isEmpty ? name : '$name • $details',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (_saving || _checkingOut)
                  ? null
                  : (value) {
                      setState(() {
                        _selectedTenantId = value;
                      });
                    },
            ),

          if (_selectedTenant != null) ...[
            const SizedBox(height: 12),
            _tenantSummary(_selectedTenant!),
          ],

          const SizedBox(height: 18),

          const Text(
            'Check-in Date',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: (_saving || _checkingOut) ? null : _pickCheckInDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 15,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    color: Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _formatDate(_checkInDate),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'Status',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _status,
            decoration: _inputDecoration(
              hintText: 'Status',
              icon: Icons.verified_rounded,
            ),
            items: const [
              DropdownMenuItem(
                value: 'Checked In',
                child: Text('Checked In'),
              ),
              DropdownMenuItem(
                value: 'Cancelled',
                child: Text('Cancelled'),
              ),
            ],
            onChanged: (_saving || _checkingOut)
                ? null
                : (value) {
                    if (value == null) return;
                    setState(() {
                      _status = value;
                    });
                  },
          ),

          const SizedBox(height: 18),

          const Text(
            'Notes',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            maxLines: 3,
            enabled: !_saving && !_checkingOut,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Optional check-in notes',
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 42),
                child: Icon(Icons.notes_rounded),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFFE5E7EB),
                ),
              ),
            ),
          ),

          const SizedBox(height: 22),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saving || _checkingOut
                      ? null
                      : _openAddTenant,
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Add Tenant'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _saving || _checkingOut
                      ? null
                      : _saveCheckIn,
                  icon: _saving
                      ? const SizedBox(
                          width: 19,
                          height: 19,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.login_rounded),
                  label: Text(
                    _saving ? 'Saving...' : 'Confirm Check-in',
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (_switchingPg) ...[
            const SizedBox(height: 12),
            const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Loading PG data...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // BUILDING SUMMARY
  // ============================================================

  Widget _buildingSummary(Map<String, dynamic> building) {
    final name = building['name']?.toString() ?? 'PG';
    final address = building['address']?.toString() ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.apartment_rounded,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TENANT SUMMARY
  // ============================================================

  Widget _tenantSummary(Map<String, dynamic> tenant) {
    final rent = tenant['monthly_rent'];
    final phone = tenant['phone']?.toString() ?? '';
    final room = tenant['room_number']?.toString() ?? '';
    final bed = tenant['bed_number']?.toString() ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tenant['full_name']?.toString() ?? 'Tenant',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    phone,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
                if (room.isNotEmpty || bed.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    [
                      if (room.isNotEmpty) 'Room $room',
                      if (bed.isNotEmpty) 'Bed $bed',
                    ].join(' • '),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (rent is num)
            Text(
              '₹${rent.toStringAsFixed(0)}/month',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF16A34A),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // HISTORY
  // ============================================================

  Widget _recentCheckInsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Check-in / Check-out History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            if (_selectedBuilding != null)
              Container(
                constraints: const BoxConstraints(maxWidth: 140),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _selectedBuildingName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_recentCheckIns.isEmpty)
          _emptyHistory()
        else
          Column(
            children: _recentCheckIns.map(_checkInCard).toList(),
          ),
      ],
    );
  }

  Widget _emptyHistory() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.history_rounded,
            size: 40,
            color: Color(0xFF94A3B8),
          ),
          SizedBox(height: 10),
          Text(
            'No check-in / check-out records found for this PG',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkInCard(Map<String, dynamic> record) {
    final name = record['tenant_name']?.toString() ?? 'Tenant';
    final status = record['status']?.toString() ?? 'Checked In';

    final checkInDate = DateTime.tryParse(
          record['check_in_date']?.toString() ?? '',
        ) ??
        DateTime.now();

    final checkoutDate = DateTime.tryParse(
      record['checkout_date']?.toString() ?? '',
    );

    final note = record['note']?.toString() ?? '';
    final checkoutNote = record['checkout_note']?.toString() ?? '';
    final room = record['room_number']?.toString() ?? '';
    final bed = record['bed_number']?.toString() ?? '';

    final isCheckedIn = status == 'Checked In' && checkoutDate == null;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isCheckedIn
                      ? const Color(0xFFF0FDF4)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  isCheckedIn
                      ? Icons.login_rounded
                      : Icons.logout_rounded,
                  color: isCheckedIn
                      ? const Color(0xFF16A34A)
                      : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Check-in: ${_formatDateTime(checkInDate)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    if (room.isNotEmpty || bed.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        [
                          if (room.isNotEmpty) 'Room $room',
                          if (bed.isNotEmpty) 'Bed $bed',
                        ].join(' • '),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                    if (note.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Note: $note',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                    if (checkoutDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Check-out: ${_formatDateTime(checkoutDate)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                    if (checkoutNote.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        'Checkout note: $checkoutNote',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _statusChip(status),
            ],
          ),
          if (isCheckedIn) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _checkingOut || _saving
                    ? null
                    : () => _checkoutRecord(record),
                icon: _checkingOut
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.logout_rounded),
                label: Text(
                  _checkingOut
                      ? 'Checking out...'
                      : 'Check-out $name',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(
                    color: Color(0xFFFCA5A5),
                  ),
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final checkedIn = status == 'Checked In';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: checkedIn
            ? const Color(0xFFF0FDF4)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: checkedIn
              ? const Color(0xFF16A34A)
              : const Color(0xFF64748B),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATES
  // ============================================================

  Widget _noPgBox() {
    return _infoBox(
      icon: Icons.info_outline_rounded,
      color: const Color(0xFFD97706),
      background: const Color(0xFFFFFBEB),
      borderColor: const Color(0xFFFDE68A),
      text: 'No PG found. Add a PG first.',
    );
  }

  Widget _selectPgFirstBox() {
    return _infoBox(
      icon: Icons.arrow_upward_rounded,
      color: const Color(0xFF2563EB),
      background: const Color(0xFFEFF6FF),
      borderColor: const Color(0xFFBFDBFE),
      text: 'Please select the PG first. Only tenants from that PG will be shown.',
    );
  }

  Widget _noTenantBox() {
    return _infoBox(
      icon: Icons.info_outline_rounded,
      color: const Color(0xFFD97706),
      background: const Color(0xFFFFFBEB),
      borderColor: const Color(0xFFFDE68A),
      text: 'No active tenants found in this PG. Add a tenant first.',
    );
  }

  Widget _infoBox({
    required IconData icon,
    required Color color,
    required Color background,
    required Color borderColor,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: color == const Color(0xFF2563EB)
                    ? const Color(0xFF1D4ED8)
                    : const Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
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
                  color: iconColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 11),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE5E7EB),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF2563EB),
          width: 1.4,
        ),
      ),
    );
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refresh() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      await _loadBuildings();
      await _loadTenants();
      await _loadRecentCheckIns();
    } catch (e) {
      if (mounted) {
        _showMessage(
          'Unable to refresh check-in data. $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    final dateText = _formatDate(date);

    final hour12 = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;

    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$dateText $hour12:$minute $period';
  }
}


// ============================================================
// DASHBOARD NOTIFICATIONS SCREEN
// ============================================================

class DashboardNotificationsScreen extends StatelessWidget {
  const DashboardNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    size: 38,
                    color: Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'No new notifications',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Rent reminders and important PG alerts will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// DASHBOARD OWNER PROFILE SCREEN
// ============================================================

class DashboardOwnerProfileScreen extends StatefulWidget {
  const DashboardOwnerProfileScreen({super.key});

  @override
  State<DashboardOwnerProfileScreen> createState() =>
      _DashboardOwnerProfileScreenState();
}

class _DashboardOwnerProfileScreenState
    extends State<DashboardOwnerProfileScreen> {
  final TextEditingController _nameController =
      TextEditingController();
  final TextEditingController _mobileController =
      TextEditingController();
  final TextEditingController _emailController =
      TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Owner profile updated successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        title: const Text(
          'Owner Profile',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Owner Name',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saveProfile,
                        icon: const Icon(Icons.save_rounded),
                        label: const Text('Save Profile'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
