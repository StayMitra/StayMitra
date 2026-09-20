import 'package:flutter/material.dart';
import 'building_setup_screen.dart';
import 'reports_screen.dart';
import 'documents_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import 'subscription_screen.dart';
import 'help_support_screen.dart';
import 'about_stay_mitra_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),

      // ==========================================================
      // APP BAR
      // ==========================================================

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),

        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
        ),

        title: const Text(
          'More',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
IconButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const NotificationsScreen(),
      ),
    );
  },
  icon: const Icon(
    Icons.notifications_none_rounded,
  ),
),
          const SizedBox(width: 4),
        ],
      ),

      // ==========================================================
      // BODY
      // ==========================================================

      body: SafeArea(
        child: SingleChildScrollView(
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

              // ==================================================
              // PROFILE
              // ==================================================

              _profileCard(context),

              const SizedBox(height: 24),

              // ==================================================
              // PROPERTY
              // ==================================================

              const Text(
                'Property',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 12),

              // --------------------------------------------------
              // PG / PROPERTY SETTINGS
              // --------------------------------------------------

              _menuCard(
                context: context,
                icon: Icons.apartment_rounded,
                title: 'PG / Property Settings',
                subtitle:
                    'Manage property and PG details',
                color: const Color(0xFF2563EB),

                // IMPORTANT:
                // This screen already exists in the project.
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const BuildingSetupScreen(
  ownerId: 'default_owner',
),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // --------------------------------------------------
              // REPORTS
              // --------------------------------------------------

              _menuCard(
                context: context,
                icon: Icons.bar_chart_rounded,
                title: 'Reports',
                subtitle:
                    'View income, expense and occupancy reports',
                color: const Color(0xFF16A34A),
onTap: () async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) =>
          const ReportsScreen(),
    ),
  );
},
              ),

              const SizedBox(height: 24),

              // ==================================================
              // MANAGEMENT
              // ==================================================

              const Text(
                'Management',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 12),

              // --------------------------------------------------
              // DOCUMENTS
              // --------------------------------------------------

              _menuCard(
                context: context,
                icon: Icons.description_rounded,
                title: 'Documents',
                subtitle:
                    'Store and manage PG documents',
                color: const Color(0xFF7C3AED),
onTap: () async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) =>
          const DocumentsScreen(),
    ),
  );
},
              ),

              const SizedBox(height: 12),

              // --------------------------------------------------
              // NOTIFICATIONS
              // --------------------------------------------------

              _menuCard(
                context: context,
                icon:
                    Icons.notifications_active_rounded,
                title: 'Notifications',
                subtitle:
                    'Rent reminders and important alerts',
                color: const Color(0xFFF59E0B),
                onTap: () {
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) =>
        const NotificationsScreen(),
  ),
);
                },
              ),

              const SizedBox(height: 24),

              // ==================================================
              // ACCOUNT
              // ==================================================

              const Text(
                'Account',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 12),

              // --------------------------------------------------
              // SETTINGS
              // --------------------------------------------------

_menuCard(
  context: context,
  icon: Icons.settings_rounded,
  title: 'Settings',
  subtitle:
      'App preferences and configuration',
  color: const Color(0xFF475569),
  onTap: () async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const SettingsScreen(),
      ),
    );
  },
),

              const SizedBox(height: 12),

              // --------------------------------------------------
              // SUBSCRIPTION
              // --------------------------------------------------

_menuCard(
  context: context,
  icon: Icons.workspace_premium_rounded,
  title: 'Subscription & Plan',
  subtitle: 'Manage your Stay Mitra plan',
  color: const Color(0xFFEA580C),
  onTap: () async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const SubscriptionScreen(),
      ),
    );
  },
),

              const SizedBox(height: 24),

              // ==================================================
              // SUPPORT
              // ==================================================

              const Text(
                'Support',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 12),

              // --------------------------------------------------
              // HELP & SUPPORT
              // --------------------------------------------------

_menuCard(
  context: context,
  icon: Icons.support_agent_rounded,
  title: 'Help & Support',
  subtitle: 'Get help with Stay Mitra',
  color: const Color(0xFF0891B2),
  onTap: () async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const HelpSupportScreen(),
      ),
    );
  },
),

              const SizedBox(height: 12),

              // --------------------------------------------------
              // ABOUT
              // --------------------------------------------------

_menuCard(
  context: context,
  icon: Icons.info_outline_rounded,
  title: 'About Stay Mitra',
  subtitle: 'Version and application information',
  color: const Color(0xFF6366F1),
  onTap: () async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const AboutStayMitraScreen(),
      ),
    );
  },
),

              const SizedBox(height: 28),

              // ==================================================
              // LOGOUT
              // ==================================================

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showLogoutDialog(context);
                  },

                  icon: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFDC2626),
                  ),

                  label: const Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFDC2626),
                    ),
                  ),

                  style:
                      OutlinedButton.styleFrom(
                    minimumSize:
                        const Size.fromHeight(52),

                    side: const BorderSide(
                      color: Color(0xFFFECACA),
                    ),

                    backgroundColor:
                        const Color(0xFFFEF2F2),

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // ==================================================
              // APP FOOTER
              // ==================================================

              Center(
                child: Column(
                  children: const [
                    Text(
                      'Stay Mitra',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),

                    SizedBox(height: 4),

                    Text(
                      'PG Management Made Simple',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),

                    SizedBox(height: 4),

                    Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFCBD5E1),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PROFILE CARD
  // ============================================================

  Widget _profileCard(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),

        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.03,
            ),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Row(
        children: [
          // ------------------------------------------------------
          // PROFILE ICON
          // ------------------------------------------------------

          Container(
            width: 58,
            height: 58,

            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius:
                  BorderRadius.circular(18),
            ),

            child: const Icon(
              Icons.person_rounded,
              size: 32,
              color: Color(0xFF2563EB),
            ),
          ),

          const SizedBox(width: 14),

          // ------------------------------------------------------
          // PROFILE TEXT
          // ------------------------------------------------------

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'PG Owner',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  'Manage your profile',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          // ------------------------------------------------------
          // PROFILE ARROW
          // ------------------------------------------------------

          IconButton(
            onPressed: () {
              _showComingSoon(
                context,
                'My Profile',
              );
            },

            icon: const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MENU CARD
  // ============================================================

  Widget _menuCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,

      borderRadius:
          BorderRadius.circular(16),

      child: InkWell(
        onTap: onTap,

        borderRadius:
            BorderRadius.circular(16),

        child: Container(
          padding: const EdgeInsets.all(14),

          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(16),

            border: Border.all(
              color: const Color(0xFFE5E7EB),
            ),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: 0.015,
                ),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),

          child: Row(
            children: [
              // ------------------------------------------------
              // ICON
              // ------------------------------------------------

              Container(
                width: 48,
                height: 48,

                decoration: BoxDecoration(
                  color: color.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(14),
                ),

                child: Icon(
                  icon,
                  color: color,
                  size: 25,
                ),
              ),

              const SizedBox(width: 14),

              // ------------------------------------------------
              // TITLE + SUBTITLE
              // ------------------------------------------------

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w600,
                        color:
                            Color(0xFF111827),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color:
                            Color(0xFF64748B),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ------------------------------------------------
              // ARROW
              // ------------------------------------------------

              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF94A3B8),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // COMING SOON
  // ============================================================

  static void _showComingSoon(
    BuildContext context,
    String feature,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '$feature will be available soon.',
          ),
          behavior:
              SnackBarBehavior.floating,

          duration:
              const Duration(seconds: 2),
        ),
      );
  }

  // ============================================================
  // ABOUT DIALOG
  // ============================================================

  static void _showAboutDialog(
    BuildContext context,
  ) {
    showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),

          title: const Text(
            'Stay Mitra',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'PG Management Made Simple',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),

              SizedBox(height: 16),

              Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              SizedBox(height: 10),

              Text(
                'Stay Mitra helps PG owners manage tenants, rooms, beds, payments and daily operations from one place.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text(
                'Close',
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // LOGOUT DIALOG
  // ============================================================

  static void _showLogoutDialog(
    BuildContext context,
  ) {
    showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),

          title: const Text(
            'Logout?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          content: const Text(
            'Are you sure you want to logout from Stay Mitra?',
          ),

          actions: [
            // ----------------------------------------------------
            // CANCEL
            // ----------------------------------------------------

            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text(
                'Cancel',
              ),
            ),

            // ----------------------------------------------------
            // LOGOUT
            // ----------------------------------------------------

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Logout functionality will be connected later.',
                    ),
                    behavior:
                        SnackBarBehavior.floating,
                  ),
                );
              },

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFFDC2626),
                foregroundColor:
                    Colors.white,
              ),

              child: const Text(
                'Logout',
              ),
            ),
          ],
        );
      },
    );
  }
}