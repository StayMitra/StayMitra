import 'package:flutter/material.dart';

class AboutStayMitraScreen extends StatelessWidget {
  const AboutStayMitraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        title: const Text(
          'About Stay Mitra',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            16,
            18,
            16,
            30,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // BRAND HEADER
              // ==================================================

              _brandHeader(),

              const SizedBox(height: 24),

              // ==================================================
              // ABOUT
              // ==================================================

              const Text(
                'About Stay Mitra',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 12),

              _sectionCard(
                icon: Icons.home_work_rounded,
                color: const Color(0xFF2563EB),
                title: 'PG Management Made Simple',
                child: const Text(
                  'Stay Mitra is a PG management platform designed to help property owners manage their day-to-day operations from one place.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Color(0xFF475569),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // ==================================================
              // OUR PURPOSE
              // ==================================================

              const Text(
                'Our Purpose',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 12),

              _sectionCard(
                icon: Icons.track_changes_rounded,
                color: const Color(0xFF16A34A),
                title: 'Making PG Management Easier',
                child: const Text(
                  'Our goal is to reduce manual work for PG owners and provide a simple, organised way to manage tenants, rooms, beds, payments, documents and important day-to-day activities.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Color(0xFF475569),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // ==================================================
              // KEY FEATURES
              // ==================================================

              const Text(
                'What You Can Manage',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 12),

              _featureItem(
                icon: Icons.people_alt_rounded,
                title: 'Tenants',
                subtitle:
                    'Manage tenant information and occupancy.',
                color: const Color(0xFF2563EB),
              ),

              _featureItem(
                icon: Icons.meeting_room_rounded,
                title: 'Rooms & Beds',
                subtitle:
                    'Track rooms, beds and availability.',
                color: const Color(0xFF7C3AED),
              ),

              _featureItem(
                icon: Icons.account_balance_wallet_rounded,
                title: 'Accounts',
                subtitle:
                    'Manage rent payments and financial records.',
                color: const Color(0xFF16A34A),
              ),

              _featureItem(
                icon: Icons.description_rounded,
                title: 'Documents',
                subtitle:
                    'Store important PG and property documents.',
                color: const Color(0xFFEA580C),
              ),

              _featureItem(
                icon: Icons.notifications_active_rounded,
                title: 'Notifications',
                subtitle:
                    'Stay informed about important reminders and alerts.',
                color: const Color(0xFFF59E0B),
              ),

              _featureItem(
                icon: Icons.support_agent_rounded,
                title: 'Help & Support',
                subtitle:
                    'Get assistance whenever you need help.',
                color: const Color(0xFF0891B2),
              ),

              const SizedBox(height: 22),

              // ==================================================
              // OWNER BENEFITS
              // ==================================================

              const Text(
                'Benefits for PG Owners',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 12),

              _benefitCard(
                icon: Icons.dashboard_customize_rounded,
                title: 'Everything in One Place',
                description:
                    'Access your important PG information from a single dashboard.',
              ),

              _benefitCard(
                icon: Icons.speed_rounded,
                title: 'Save Time',
                description:
                    'Reduce repetitive manual work and manage daily operations faster.',
              ),

              _benefitCard(
                icon: Icons.visibility_rounded,
                title: 'Better Visibility',
                description:
                    'Get a clear view of tenants, rooms, beds and payments.',
              ),

              _benefitCard(
                icon: Icons.devices_rounded,
                title: 'Simple Experience',
                description:
                    'Designed to keep PG management simple and easy to understand.',
              ),

              const SizedBox(height: 22),

              // ==================================================
              // OUR VISION
              // ==================================================

              const Text(
                'Our Vision',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF2563EB),
                      Color(0xFF1D4ED8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_rounded,
                      color: Colors.white,
                      size: 30,
                    ),

                    SizedBox(height: 12),

                    Text(
                      'Simplifying the way PGs are managed.',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                        color: Colors.white,
                      ),
                    ),

                    SizedBox(height: 8),

                    Text(
                      'We want to help PG owners spend less time managing paperwork and more time growing their property.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // APP INFORMATION
              // ==================================================

              const Text(
                'Application Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 12),

              _infoCard(
                icon: Icons.apps_rounded,
                title: 'Application',
                value: 'Stay Mitra',
              ),

              _infoCard(
                icon: Icons.verified_rounded,
                title: 'Version',
                value: '1.0.0',
              ),

              _infoCard(
                icon: Icons.business_rounded,
                title: 'Platform',
                value: 'Stay Mitra PG Management',
              ),

              const SizedBox(height: 24),

              // ==================================================
              // PRIVACY & TERMS
              // ==================================================

              const Text(
                'Legal & Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 12),

              _actionCard(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                subtitle:
                    'Learn how Stay Mitra handles your information.',
                onTap: () {
                  _showComingSoon(
                    context,
                    'Privacy Policy',
                  );
                },
              ),

              _actionCard(
                icon: Icons.article_outlined,
                title: 'Terms & Conditions',
                subtitle:
                    'Review the terms for using Stay Mitra.',
                onTap: () {
                  _showComingSoon(
                    context,
                    'Terms & Conditions',
                  );
                },
              ),

              const SizedBox(height: 28),

              // ==================================================
              // FOOTER
              // ==================================================

              Center(
                child: Column(
                  children: const [
                    Text(
                      'Stay Mitra',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),

                    SizedBox(height: 5),

                    Text(
                      'PG Management Made Simple',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),

                    SizedBox(height: 8),

                    Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),

                    SizedBox(height: 5),

                    Text(
                      'Made for PG Owners',
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
  // BRAND HEADER
  // ============================================================

  Widget _brandHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.03,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius:
                  BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.home_work_rounded,
              size: 44,
              color: Color(0xFF2563EB),
            ),
          ),

          const SizedBox(height: 14),

          const Text(
            'Stay Mitra',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'PG Management Made Simple',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius:
                  BorderRadius.circular(30),
            ),
            child: const Text(
              'Built for PG Owners',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2563EB),
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
    required IconData icon,
    required Color color,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
                  BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),

                const SizedBox(height: 7),

                child,
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FEATURE ITEM
  // ============================================================

  Widget _featureItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
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
                  BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.3,
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
  // BENEFIT CARD
  // ============================================================

  Widget _benefitCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF16A34A),
            size: 23,
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
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
  // INFO CARD
  // ============================================================

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF2563EB),
            size: 23,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
          ),

          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTION CARD
  // ============================================================

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: const Color(0xFF475569),
                  size: 24,
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w600,
                          color:
                              Color(0xFF111827),
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color:
                              Color(0xFF64748B),
                        ),
                      ),
                    ],
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
        ),
      );
  }
}