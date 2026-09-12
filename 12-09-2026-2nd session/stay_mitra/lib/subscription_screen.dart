import 'package:flutter/material.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() =>
      _SubscriptionScreenState();
}

class _SubscriptionScreenState
    extends State<SubscriptionScreen> {
  // ============================================================
  // TEMPORARY SUBSCRIPTION DATA
  //
  // IMPORTANT:
  // These values are temporary UI data.
  // Later Admin Subscription Management will control these.
  // ============================================================

  final DateTime _trialStartDate =
      DateTime.now().subtract(
    const Duration(days: 7),
  );

  int _selectedPlanIndex = 3;

  final List<_SubscriptionPlan> _plans = [
    _SubscriptionPlan(
      title: 'Monthly',
      duration: '1 Month',
      price: 499,
      originalPrice: null,
      saveText: null,
      description:
          'Flexible monthly subscription',
      popular: false,
    ),
    _SubscriptionPlan(
      title: 'Quarterly',
      duration: '3 Months',
      price: 1299,
      originalPrice: 1497,
      saveText: 'Save ₹198',
      description:
          'Good for growing PGs',
      popular: false,
    ),
    _SubscriptionPlan(
      title: 'Half-Yearly',
      duration: '6 Months',
      price: 2399,
      originalPrice: 2994,
      saveText: 'Save ₹595',
      description:
          'Better value for PG owners',
      popular: false,
    ),
    _SubscriptionPlan(
      title: 'Yearly',
      duration: '12 Months',
      price: 3999,
      originalPrice: 5988,
      saveText: 'Save ₹1,989',
      description:
          'Best value for your PG',
      popular: true,
    ),
  ];

  // ============================================================
  // TRIAL
  // ============================================================

  DateTime get _trialEndDate =>
      _trialStartDate.add(
        const Duration(days: 30),
      );

  int get _remainingTrialDays {
    final now = DateTime.now();

    final difference =
        _trialEndDate.difference(now).inDays;

    if (difference < 0) {
      return 0;
    }

    return difference;
  }

  bool get _trialActive =>
      DateTime.now().isBefore(_trialEndDate);

  double get _trialProgress {
    const totalDays = 30;

    final usedDays =
        30 - _remainingTrialDays;

    final progress =
        usedDays / totalDays;

    if (progress < 0) return 0;

    if (progress > 1) return 1;

    return progress;
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

        title: const Text(
          'Subscription & Plan',
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
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _welcomeCard(),

              const SizedBox(height: 18),

              _trialCard(),

              const SizedBox(height: 26),

              const Text(
                'Choose Your Plan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Select the subscription that works best for your PG.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 16),

              _offerBanner(),

              const SizedBox(height: 18),

              ...List.generate(
                _plans.length,
                (index) {
                  return Padding(
                    padding:
                        const EdgeInsets.only(
                      bottom: 14,
                    ),
                    child: _planCard(
                      plan: _plans[index],
                      index: index,
                    ),
                  );
                },
              ),

              const SizedBox(height: 8),

              _featureSection(),

              const SizedBox(height: 24),

              _subscriptionNote(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // WELCOME CARD
  // ============================================================

  Widget _welcomeCard() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2563EB),
            Color(0xFF1D4ED8),
          ],
        ),
        borderRadius:
            BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color:
                const Color(0xFF2563EB)
                    .withValues(alpha: 0.20),
            blurRadius: 18,
            offset:
                const Offset(0, 8),
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
                  .withValues(alpha: 0.15),
              borderRadius:
                  BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to Stay Mitra',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight:
                        FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  'Manage your PG with simple and powerful tools.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    height: 1.4,
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
  // TRIAL CARD
  // ============================================================

  Widget _trialCard() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color:
              const Color(0xFFBBF7D0),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFF0FDF4),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  color:
                      Color(0xFF16A34A),
                  size: 26,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      _trialActive
                          ? 'Your First Month is FREE'
                          : 'Free Trial Completed',
                      style:
                          const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Color(0xFF111827),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      _trialActive
                          ? 'Enjoy Stay Mitra free for your first 30 days.'
                          : 'Choose a subscription plan to continue using Stay Mitra.',
                      style:
                          const TextStyle(
                        fontSize: 12,
                        color:
                            Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          if (_trialActive) ...[
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Trial period',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        Color(0xFF475569),
                  ),
                ),

                Text(
                  '${_remainingTrialDays} days remaining',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Color(0xFF16A34A),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 9),

            ClipRRect(
              borderRadius:
                  BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _trialProgress,
                minHeight: 8,
                backgroundColor:
                    const Color(0xFFDCFCE7),
                valueColor:
                    const AlwaysStoppedAnimation(
                  Color(0xFF16A34A),
                ),
              ),
            ),

            const SizedBox(height: 9),

            Text(
              'Trial ends on ${_formatDate(_trialEndDate)}',
              style: const TextStyle(
                fontSize: 11,
                color:
                    Color(0xFF94A3B8),
              ),
            ),
          ] else
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    const Color(0xFFFFF7ED),
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color:
                        Color(0xFFEA580C),
                  ),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Your free trial has ended. Please select a plan below.',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            Color(0xFF9A3412),
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

  // ============================================================
  // ADMIN OFFER BANNER
  // ============================================================

  Widget _offerBanner() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            const Color(0xFFFFF7ED),
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              const Color(0xFFFED7AA),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color:
                  const Color(0xFFFFEDD5),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_offer_rounded,
              color:
                  Color(0xFFEA580C),
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Special Offer',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Color(0xFF9A3412),
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  'Choose a plan that suits your PG. Offers and pricing are managed by Stay Mitra.',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        Color(0xFF9A3412),
                    height: 1.4,
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
  // PLAN CARD
  // ============================================================

  Widget _planCard({
    required _SubscriptionPlan plan,
    required int index,
  }) {
    final selected =
        _selectedPlanIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlanIndex = index;
        });
      },
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 200),
        width: double.infinity,
        padding:
            const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF2563EB)
                : const Color(0xFFE5E7EB),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color:
                        const Color(0xFF2563EB)
                            .withValues(
                      alpha: 0.08,
                    ),
                    blurRadius: 12,
                    offset:
                        const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(
                            0xFFEFF6FF)
                        : const Color(
                            0xFFF8FAFC),
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                  child: Icon(
                    _planIcon(index),
                    color: selected
                        ? const Color(
                            0xFF2563EB)
                        : const Color(
                            0xFF64748B),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Row(
                        children: [
                          Text(
                            plan.title,
                            style:
                                const TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold,
                              color:
                                  Color(
                                0xFF111827,
                              ),
                            ),
                          ),

                          if (plan.popular) ...[
                            const SizedBox(
                              width: 8,
                            ),
                            Container(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration:
                                  BoxDecoration(
                                color:
                                    const Color(
                                  0xFFDCFCE7,
                                ),
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  20,
                                ),
                              ),
                              child:
                                  const Text(
                                'BEST VALUE',
                                style:
                                    TextStyle(
                                  fontSize: 9,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                  color:
                                      Color(
                                    0xFF15803D,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 4),

                      Text(
                        plan.description,
                        style:
                            const TextStyle(
                          fontSize: 11,
                          color:
                              Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),

                Radio<bool>(
                  value: true,
                  groupValue:
                      selected ? true : null,
                  onChanged: (_) {
                    setState(() {
                      _selectedPlanIndex =
                          index;
                    });
                  },
                  activeColor:
                      const Color(0xFF2563EB),
                ),
              ],
            ),

            const SizedBox(height: 14),

            const Divider(
              height: 1,
              color:
                  Color(0xFFF1F5F9),
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Text(
                  '₹${plan.price}',
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Color(0xFF111827),
                  ),
                ),

                const SizedBox(width: 7),

                Text(
                  '/ ${plan.duration}',
                  style: const TextStyle(
                    fontSize: 11,
                    color:
                        Color(0xFF64748B),
                  ),
                ),

                const Spacer(),

                if (plan.originalPrice !=
                    null)
                  Text(
                    '₹${plan.originalPrice}',
                    style: const TextStyle(
                      fontSize: 12,
                      decoration:
                          TextDecoration
                              .lineThrough,
                      color:
                          Color(0xFF94A3B8),
                    ),
                  ),
              ],
            ),

            if (plan.saveText != null) ...[
              const SizedBox(height: 8),

              Align(
                alignment:
                    Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color:
                        const Color(
                      0xFFF0FDF4,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      8,
                    ),
                  ),
                  child: Text(
                    plan.saveText!,
                    style:
                        const TextStyle(
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w600,
                      color:
                          Color(0xFF15803D),
                    ),
                  ),
                ),
              ),
            ],

            if (selected) ...[
              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () {
                    _showSubscribeDialog(
                      plan,
                    );
                  },
                  style:
                      FilledButton.styleFrom(
                    backgroundColor:
                        const Color(
                      0xFF2563EB,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),
                  child: Text(
                    'Subscribe to ${plan.title}',
                    style:
                        const TextStyle(
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FEATURES
  // ============================================================

  Widget _featureSection() {
    final features = [
      'Tenant management',
      'Room & bed management',
      'Billing and payment tracking',
      'Daily operations',
      'Reports',
      'Document management',
      'Notifications and reminders',
    ];

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(18),
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
          const Text(
            'What you get with Stay Mitra',
            style: TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.bold,
              color:
                  Color(0xFF111827),
            ),
          ),

          const SizedBox(height: 14),

          ...features.map(
            (feature) {
              return Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 11,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 20,
                      color:
                          Color(0xFF16A34A),
                    ),
                    const SizedBox(
                      width: 9,
                    ),
                    Expanded(
                      child: Text(
                        feature,
                        style:
                            const TextStyle(
                          fontSize: 13,
                          color:
                              Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NOTE
  // ============================================================

  Widget _subscriptionNote() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color:
            const Color(0xFFF8FAFC),
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 19,
            color:
                Color(0xFF64748B),
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Subscription plans, pricing and special offers are controlled by Stay Mitra Admin and may change from time to time.',
              style: TextStyle(
                fontSize: 11,
                height: 1.5,
                color:
                    Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUBSCRIBE DIALOG
  // ============================================================

  void _showSubscribeDialog(
    _SubscriptionPlan plan,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          title: Text(
            '${plan.title} Plan',
            style: const TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          content: Text(
            'You selected the ${plan.title} plan for ₹${plan.price}.\n\nPayment integration will be connected after the Admin subscription system is completed.',
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color:
                  Color(0xFF475569),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child:
                  const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // PLAN ICON
  // ============================================================

  IconData _planIcon(int index) {
    switch (index) {
      case 0:
        return Icons.calendar_month_rounded;

      case 1:
        return Icons.date_range_rounded;

      case 2:
        return Icons.event_available_rounded;

      case 3:
        return Icons.workspace_premium_rounded;

      default:
        return Icons.credit_card_rounded;
    }
  }

  // ============================================================
  // DATE
  // ============================================================

  String _formatDate(DateTime date) {
    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }
}

// ============================================================
// SUBSCRIPTION PLAN MODEL
// ============================================================

class _SubscriptionPlan {
  final String title;
  final String duration;
  final int price;
  final int? originalPrice;
  final String? saveText;
  final String description;
  final bool popular;

  const _SubscriptionPlan({
    required this.title,
    required this.duration,
    required this.price,
    required this.originalPrice,
    required this.saveText,
    required this.description,
    required this.popular,
  });
}