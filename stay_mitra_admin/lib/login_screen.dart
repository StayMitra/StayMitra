import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'services/admin_auth_service.dart';
import 'services/admin_dashboard_service.dart';
import 'owners_screen.dart';
import 'subscription_management_screen.dart';
import 'support_requests_screen.dart';
import 'announcements_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() =>
      _AdminLoginScreenState();
}

class _AdminLoginScreenState
    extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final profile =
          await AdminAuthService.instance.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AdminDashboardScreen(
            profile: profile,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          message = 'Invalid email or password.';
          break;

        case 'invalid-email':
          message =
              'Please enter a valid email address.';
          break;

        case 'user-disabled':
          message =
              'This account has been disabled.';
          break;

        case 'too-many-requests':
          message =
              'Too many attempts. Please try again later.';
          break;

        default:
          message = e.message ?? 'Login failed.';
      }

      _showMessage(message);
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showMessage(
        'Please enter your email address first.',
      );
      return;
    }

    try {
      await AdminAuthService.instance
          .sendPasswordResetEmail(email);

      if (!mounted) return;

      _showMessage(
        'Password reset email sent. Please check your inbox.',
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      _showMessage(
        e.message ??
            'Unable to send reset email.',
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F7FB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 430,
              ),
              child: Card(
                elevation: 2,
                child: Padding(
                  padding:
                      const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),

                        Container(
                          width: 76,
                          height: 76,
                          decoration:
                              BoxDecoration(
                            color:
                                theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons
                                .admin_panel_settings_rounded,
                            color: Colors.white,
                            size: 42,
                          ),
                        ),

                        const SizedBox(height: 20),

                        Text(
                          'Stay Mitra Admin',
                          textAlign:
                              TextAlign.center,
                          style: theme
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Admin Login',
                          textAlign:
                              TextAlign.center,
                          style: theme
                              .textTheme
                              .titleMedium,
                        ),

                        const SizedBox(height: 28),

                        TextFormField(
                          controller:
                              _emailController,
                          keyboardType:
                              TextInputType
                                  .emailAddress,
                          textInputAction:
                              TextInputAction.next,
                          decoration:
                              const InputDecoration(
                            labelText: 'Email',
                            hintText:
                                'Enter admin email',
                            prefixIcon: Icon(
                              Icons
                                  .email_outlined,
                            ),
                            border:
                                OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final email =
                                value?.trim() ??
                                    '';

                            if (email.isEmpty) {
                              return 'Please enter email';
                            }

                            if (!RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                            ).hasMatch(email)) {
                              return 'Enter a valid email';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller:
                              _passwordController,
                          obscureText:
                              _obscurePassword,
                          textInputAction:
                              TextInputAction.done,
                          onFieldSubmitted:
                              (_) => _login(),
                          decoration:
                              InputDecoration(
                            labelText: 'Password',
                            hintText:
                                'Enter password',
                            prefixIcon:
                                const Icon(
                              Icons.lock_outline,
                            ),
                            suffixIcon:
                                IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword =
                                      !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons
                                        .visibility_outlined
                                    : Icons
                                        .visibility_off_outlined,
                              ),
                            ),
                            border:
                                const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if ((value ?? '')
                                .isEmpty) {
                              return 'Please enter password';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 8),

                        Align(
                          alignment:
                              Alignment.centerRight,
                          child: TextButton(
                            onPressed:
                                _isLoading
                                    ? null
                                    : _forgotPassword,
                            child: const Text(
                              'Forgot Password?',
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        SizedBox(
                          height: 52,
                          child: FilledButton(
                            onPressed:
                                _isLoading
                                    ? null
                                    : _login,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2.5,
                                      color:
                                          Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'LOGIN',
                                    style:
                                        TextStyle(
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        Text(
                          'Authorized administrators only',
                          textAlign:
                              TextAlign.center,
                          style: theme
                              .textTheme
                              .bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ================================================================
// ADMIN DASHBOARD
// ================================================================

class AdminDashboardScreen
    extends StatefulWidget {
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
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
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
        _error = e.toString().replaceFirst(
              'Exception: ',
              '',
            );
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await AdminAuthService.instance.signOut();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
            const AdminLoginScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F8FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor:
            Colors.transparent,
        title: const Text(
          'STAY MITRA ADMIN',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading
                ? null
                : _loadDashboard,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(
              Icons.logout_rounded,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding:
              const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            32,
          ),
          children: [
            _buildWelcomeHeader(context),

            const SizedBox(height: 20),

            if (_isLoading)
              const Padding(
                padding:
                    EdgeInsets.symmetric(
                  vertical: 80,
                ),
                child: Center(
                  child:
                      CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              _ErrorCard(
                message: _error!,
                onRetry: _loadDashboard,
              )
            else if (stats != null) ...[
              _buildMainStats(
                context,
                stats,
              ),

              const SizedBox(height: 20),

              _buildSupportSection(
                context,
                stats,
              ),

              const SizedBox(height: 20),

              _buildSubscriptionSection(
                context,
                stats,
              ),

              const SizedBox(height: 20),

              _buildQuickActions(context),
            ],

            const SizedBox(height: 8),

            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // WELCOME HEADER
  // ==============================================================

  Widget _buildWelcomeHeader(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final name = widget.profile.name;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.secondary,
          ],
        ),
        borderRadius:
            BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary
                .withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white
                  .withValues(alpha: 0.18),
              borderRadius:
                  BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white
                    .withValues(alpha: 0.25),
              ),
            ),
            child: const Icon(
              Icons
                  .admin_panel_settings_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  name == null ||
                          name.trim().isEmpty
                      ? 'Welcome, Stay Mitra Admin'
                      : 'Welcome, ${name.trim()}',
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 7),

                Wrap(
                  crossAxisAlignment:
                      WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 5,
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration:
                          BoxDecoration(
                        color: Colors.white
                            .withValues(
                          alpha: 0.16,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),
                      ),
                      child: Text(
                        widget.profile.role,
                        style:
                            const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),

                    const Icon(
                      Icons.verified_rounded,
                      color: Colors.white,
                      size: 16,
                    ),

                    const Text(
                      'Authorized',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // MAIN STAT CARDS
  // ==============================================================

  Widget _buildMainStats(
    BuildContext context,
    AdminDashboardStats stats,
  ) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,

      // Slightly wider cards.
      // Prevents tight vertical constraints.
      childAspectRatio: 1.55,

      children: [
        _StatCard(
          icon: Icons.people_alt_rounded,
          title: 'Owners',
          value: stats.owners,
          iconColor: Colors.indigo,
        ),

        _StatCard(
          icon: Icons.apartment_rounded,
          title: 'PGs',
          value: stats.properties,
          iconColor: Colors.teal,
        ),

        _StatCard(
          icon: Icons.person_rounded,
          title: 'Tenants',
          value: stats.tenants,
          iconColor: Colors.orange,
        ),
      ],
    );
  }

  // ==============================================================
  // SUPPORT SECTION
  // ==============================================================

  Widget _buildSupportSection(
    BuildContext context,
    AdminDashboardStats stats,
  ) {
    return _DashboardSection(
      title: 'Support Requests',
      subtitle:
          'Monitor owner support requests',
      icon: Icons.support_agent_rounded,
      iconColor: Colors.deepPurple,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _PriorityCard(
                  label: 'Critical',
                  value:
                      stats.criticalSupportRequests,
                  icon: Icons.error_rounded,
                  iconColor: Colors.red,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _PriorityCard(
                  label: 'High',
                  value:
                      stats.highSupportRequests,
                  icon: Icons.warning_rounded,
                  iconColor:
                      Colors.orange,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _PriorityCard(
                  label: 'Normal',
                  value:
                      stats.normalSupportRequests,
                  icon: Icons.info_rounded,
                  iconColor: Colors.blue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color: Colors.deepPurple
                  .withValues(alpha: 0.06),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.inbox_rounded,
                  size: 19,
                  color: Colors.deepPurple,
                ),

                const SizedBox(width: 8),

                const Expanded(
                  child: Text(
                    'Total Support Requests',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),

                Text(
                  '${stats.totalSupportRequests}',
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 17,
                    color:
                        Colors.deepPurple,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // SUBSCRIPTION SECTION
  // ==============================================================

  Widget _buildSubscriptionSection(
    BuildContext context,
    AdminDashboardStats stats,
  ) {
    return _DashboardSection(
      title: 'Subscription Overview',
      subtitle:
          'Current owner subscription status',
      icon: Icons.payments_rounded,
      iconColor: Colors.green,
      child: Row(
        children: [
          Expanded(
            child: _SubscriptionStatusCard(
              title: 'Active',
              value:
                  stats.activeSubscriptions,
              icon:
                  Icons.check_circle_rounded,
              iconColor: Colors.green,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: _SubscriptionStatusCard(
              title: 'Trial',
              value:
                  stats.trialSubscriptions,
              icon:
                  Icons.card_giftcard_rounded,
              iconColor: Colors.blue,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: _SubscriptionStatusCard(
              title: 'Expired',
              value:
                  stats.expiredSubscriptions,
              icon: Icons.cancel_rounded,
              iconColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // QUICK ACTIONS
  // ==============================================================

  Widget _buildQuickActions(
    BuildContext context,
  ) {
    return _DashboardSection(
      title: 'Quick Actions',
      subtitle:
          'Manage Stay Mitra from one place',
      icon: Icons.flash_on_rounded,
      iconColor: Colors.amber.shade800,
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics:
            const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.25,
        children: [
          if (widget.profile.hasPermission(
            'owners',
          ))
            _QuickAction(
              icon:
                  Icons.people_alt_rounded,
              label: 'Owners',
              color: Colors.indigo,
              onTap: () {
                Navigator.of(context)
                    .push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const AdminOwnersScreen(),
                  ),
                );
              },
            ),

          if (widget.profile.hasPermission(
            'support',
          ))
            _QuickAction(
              icon:
                  Icons.support_agent_rounded,
              label: 'Support',
              color: Colors.deepPurple,
              onTap: () {
                Navigator.of(context)
                    .push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const AdminSupportRequestsScreen(),
                  ),
                );
              },
            ),

          if (widget.profile.hasPermission(
            'subscriptions',
          ))
            _QuickAction(
              icon: Icons.payments_rounded,
              label: 'Plans',
              color: Colors.green,
              onTap: () {
                Navigator.of(context)
                    .push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const AdminSubscriptionManagementScreen(),
                  ),
                );
              },
            ),

          if (widget.profile.hasPermission(
            'notifications',
          ))
            _QuickAction(
              icon: Icons.campaign_rounded,
              label: 'Announcements',
              color: Colors.orange,
              onTap: () {
                Navigator.of(context)
                    .push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const AdminAnnouncementsScreen(),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ==============================================================
  // FOOTER
  // ==============================================================

  Widget _buildFooter() {
    return const Padding(
      padding: EdgeInsets.only(
        top: 8,
        bottom: 4,
      ),
      child: Center(
        child: Text(
          'Stay Mitra Admin • Secure Management',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}

// ================================================================
// STAT CARD
// ================================================================

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
        color: iconColor.withValues(
          alpha: 0.08,
        ),
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: iconColor.withValues(
            alpha: 0.18,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.04,
            ),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(
                alpha: 0.13,
              ),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment:
                      Alignment.centerLeft,
                  child: Text(
                    value.toString(),
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight:
                          FontWeight.bold,
                      color: iconColor,
                      height: 1.0,
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  title,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// DASHBOARD SECTION
// ================================================================

class _DashboardSection
    extends StatelessWidget {
  const _DashboardSection({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.withValues(
            alpha: 0.12,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.045,
            ),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 23,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                          const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          child,
        ],
      ),
    );
  }
}

// ================================================================
// PRIORITY CARD
// ================================================================

class _PriorityCard
    extends StatelessWidget {
  const _PriorityCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 5,
      ),
      decoration: BoxDecoration(
        color: iconColor.withValues(
          alpha: 0.07,
        ),
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: iconColor.withValues(
            alpha: 0.18,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 24,
          ),

          const SizedBox(height: 6),

          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 21,
              fontWeight:
                  FontWeight.bold,
              color: iconColor,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            label,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// SUBSCRIPTION STATUS CARD
// ================================================================

class _SubscriptionStatusCard
    extends StatelessWidget {
  const _SubscriptionStatusCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final int value;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 15,
        horizontal: 6,
      ),
      decoration: BoxDecoration(
        color: iconColor.withValues(
          alpha: 0.08,
        ),
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: iconColor.withValues(
            alpha: 0.17,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 25,
          ),

          const SizedBox(height: 7),

          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 21,
              fontWeight:
                  FontWeight.bold,
              color: iconColor,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            title,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// QUICK ACTION
// ================================================================

class _QuickAction
    extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(
        alpha: 0.08,
      ),
      borderRadius:
          BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(14),
        child: Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 12,
          ),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(14),
            border: Border.all(
              color: color.withValues(
                alpha: 0.16,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration:
                    BoxDecoration(
                  color: color.withValues(
                    alpha: 0.13,
                  ),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),

              const SizedBox(width: 9),

              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight:
                        FontWeight.w700,
                    color: color,
                    fontSize: 13,
                  ),
                ),
              ),

              Icon(
                Icons
                    .arrow_forward_ios_rounded,
                size: 13,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// ERROR CARD
// ================================================================

class _ErrorCard
    extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withValues(
          alpha: 0.06,
        ),
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: Colors.red.withValues(
            alpha: 0.18,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.red.withValues(
                alpha: 0.10,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons
                  .error_outline_rounded,
              color: Colors.red,
              size: 28,
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            'Unable to load dashboard data.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight:
                  FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color:
                  Colors.grey.shade700,
            ),
          ),

          const SizedBox(height: 16),

          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            label: const Text(
              'Retry',
            ),
          ),
        ],
      ),
    );
  }
}