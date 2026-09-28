import 'package:flutter/material.dart';

import 'services/admin_dashboard_service.dart';
import 'services/admin_auth_service.dart';
import 'owners_screen.dart';
import 'support_requests_screen.dart';
import 'subscription_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({
    super.key,
    required this.profile,
  });

  final AdminProfile profile;

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState
    extends State<AdminDashboardScreen> {
  AdminDashboardStats? _stats;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final stats =
          await AdminDashboardService.instance
              .loadDashboardStats();

      if (!mounted) return;

      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Unable to load dashboard data.\n$e';
      });
    }
  }

  Future<void> _logout() async {
    try {
      await AdminAuthService.instance.signOut();

      if (!mounted) return;

      Navigator.of(context).popUntil(
        (route) => route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Logout failed: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        title: const Text(
          'STAY MITRA ADMIN',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
                _isLoading ? null : _loadDashboard,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: _buildBody(profile),
      ),
    );
  }

  Widget _buildBody(AdminProfile profile) {
    if (_isLoading && _stats == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null && _stats == null) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          const Icon(
            Icons.cloud_off_rounded,
            size: 60,
            color: Colors.grey,
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'Unable to load dashboard',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              onPressed: _loadDashboard,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text('Retry'),
            ),
          ),
        ],
      );
    }

    final stats = _stats!;

    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        32,
      ),
      children: [
        _buildWelcomeCard(profile),

        const SizedBox(height: 20),

        _buildSectionTitle(
          'Overview',
          Icons.dashboard_outlined,
        ),
        const SizedBox(height: 10),

        _buildOverviewGrid(stats),

        const SizedBox(height: 24),

        _buildSectionTitle(
          'Support Requests',
          Icons.support_agent_rounded,
        ),
        const SizedBox(height: 10),

        _buildSupportCard(stats),

        const SizedBox(height: 24),

        _buildSectionTitle(
          'Quick Actions',
          Icons.flash_on_outlined,
        ),
        const SizedBox(height: 10),

        _buildQuickActions(),
      ],
    );
  }

  Widget _buildWelcomeCard(AdminProfile profile) {
    final name = profile.email?.isNotEmpty == true
        ? profile.email!
        : 'Admin';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.08,
            ),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.12,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.admin_panel_settings_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome, Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(
                      alpha: 0.75,
                    ),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 7),
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: 0.12,
                    ),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Text(
                    profile.role,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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

  Widget _buildSectionTitle(
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 21,
          color: const Color(0xFF334155),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewGrid(
    AdminDashboardStats stats,
  ) {
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.15,
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      children: [
        _StatCard(
          icon: Icons.people_alt_outlined,
          title: 'Owners',
          value: stats.owners,
          iconColor: const Color(0xFF2563EB),
        ),
        _StatCard(
          icon: Icons.apartment_outlined,
          title: 'PGs',
          value: stats.properties,
          iconColor: const Color(0xFF7C3AED),
        ),
        _StatCard(
          icon: Icons.person_outline_rounded,
          title: 'Tenants',
          value: stats.tenants,
          iconColor: const Color(0xFF0891B2),
        ),
      ],
    );
  }

  Widget _buildSupportCard(
    AdminDashboardStats stats,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.confirmation_number_outlined,
                color: Color(0xFF475569),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Total Support Requests',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
              Text(
                '${stats.totalSupportRequests}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SupportPriority(
                  icon: Icons.circle,
                  label: 'Critical',
                  value:
                      stats.criticalSupportRequests,
                  iconColor:
                      const Color(0xFFDC2626),
                ),
              ),
              Expanded(
                child: _SupportPriority(
                  icon: Icons.circle,
                  label: 'High',
                  value:
                      stats.highSupportRequests,
                  iconColor:
                      const Color(0xFFEA580C),
                ),
              ),
              Expanded(
                child: _SupportPriority(
                  icon: Icons.circle,
                  label: 'Normal',
                  value:
                      stats.normalSupportRequests,
                  iconColor:
                      const Color(0xFFD97706),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.5,
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      children: [
        _QuickActionButton(
          icon: Icons.people_alt_outlined,
          title: 'Owners',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    const AdminOwnersScreen(),
              ),
            );
          },
        ),

        _QuickActionButton(
          icon: Icons.support_agent_outlined,
          title: 'Support',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    const AdminSupportRequestsScreen(),
              ),
            );
          },
        ),

        _QuickActionButton(
          icon: Icons.card_membership_outlined,
          title: 'Plans',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    const AdminSubscriptionManagementScreen(),
              ),
            );
          },
        ),

        _QuickActionButton(
          icon: Icons.campaign_outlined,
          title: 'Announcements',
          onTap: () {
            _showComingSoon(
              'Announcements',
            );
          },
        ),
      ],
    );
  }

  void _showComingSoon(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$title module will be added next.',
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.iconColor,
  });

  final IconData icon;
  final String title;
  final int value;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 25,
          ),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportPriority extends StatelessWidget {
  const _SupportPriority({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 12,
          color: iconColor,
        ),
        const SizedBox(height: 5),
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 23,
                color: const Color(0xFF334155),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
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
    );
  }
}