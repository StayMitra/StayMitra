import 'package:flutter/material.dart';
import 'services/admin_subscription_service.dart';

class AdminSubscriptionManagementScreen extends StatefulWidget {
  const AdminSubscriptionManagementScreen({super.key});
  @override
  State<AdminSubscriptionManagementScreen> createState() => _AdminSubscriptionManagementScreenState();
}

class _AdminSubscriptionManagementScreenState extends State<AdminSubscriptionManagementScreen> {
  final _service = AdminSubscriptionService.instance;
  bool _loading = true;
  String? _error;
  List<AdminSubscriptionPlan> _plans = const [];
  List<AdminSubscriptionRequest> _requests = const [];
  String _filter = 'All';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final plans = _service.getPlans();
      final requests = await _service.getSubscriptionRequests();
      if (!mounted) return;
      setState(() { _plans = plans; _requests = requests; _loading = false; });
    } catch (e) {
      debugPrint('Admin subscription load error: $e');
      if (mounted) setState(() { _error = 'Unable to load subscription data.'; _loading = false; });
    }
  }

  List<AdminSubscriptionRequest> get _filtered => _filter == 'All'
      ? _requests
      : _requests.where((r) => _filter == 'Pending'
          ? r.status == 'payment_pending' || r.paymentStatus == 'pending'
          : _filter == 'Paid'
              ? r.paymentStatus == 'paid'
              : r.status == 'active').toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        elevation: 0, backgroundColor: Colors.white, foregroundColor: const Color(0xFF111827),
        title: const Text('Plans & Subscriptions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        actions: [IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _error != null ? _errorView() : RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 30), children: [
          _summary(), const SizedBox(height: 20),
          _title('Current Plans', 'Plans currently shown in the owner app.'), const SizedBox(height: 12),
          ..._plans.map(_planCard), const SizedBox(height: 18),
          _title('Subscription Requests', 'Requests saved by owners from the Subscription screen.'), const SizedBox(height: 12),
          _filters(), const SizedBox(height: 12),
          if (_filtered.isEmpty) _empty() else ..._filtered.map(_requestCard),
        ]),
      ),
    );
  }

  Widget _summary() {
    final pending = _requests.where((r) => r.status == 'payment_pending' || r.paymentStatus == 'pending').length;
    final paid = _requests.where((r) => r.paymentStatus == 'paid').length;
    final active = _requests.where((r) => r.status == 'active').length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)]), borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        _stat('Plans', _plans.length, Icons.card_membership_rounded),
        _stat('Requests', _requests.length, Icons.receipt_long_rounded),
        _stat('Pending', pending, Icons.hourglass_top_rounded),
        _stat('Paid', paid, Icons.payments_rounded),
        _stat('Active', active, Icons.check_circle_outline_rounded),
      ]),
    );
  }

  Widget _stat(String label, int value, IconData icon) => Expanded(child: Column(children: [Icon(icon, color: Colors.white70, size: 20), const SizedBox(height: 5), Text('$value', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(color: Colors.white70, fontSize: 9))]));

  Widget _title(String title, String subtitle) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF111827))), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))]);

  Widget _planCard(AdminSubscriptionPlan plan) => Container(
    margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: plan.popular ? const Color(0xFFBFDBFE) : const Color(0xFFE5E7EB))),
    child: Row(children: [
      Container(width: 46, height: 46, decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(13)), child: Icon(_icon(plan.id), color: const Color(0xFF2563EB))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Flexible(child: Text(plan.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))), if (plan.popular) ...[const SizedBox(width: 7), const Text('BEST VALUE', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF15803D)))] ]),
        const SizedBox(height: 4), Text(plan.description, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        const SizedBox(height: 7), Row(children: [Text('₹${plan.price}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(width: 5), Text('/ ${plan.duration}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))), if (plan.originalPrice != null) ...[const SizedBox(width: 9), Text('₹${plan.originalPrice}', style: const TextStyle(fontSize: 11, decoration: TextDecoration.lineThrough, color: Color(0xFF94A3B8)))]]),
        if (plan.saveText != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(plan.saveText!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF15803D)))),
      ])),
    ]),
  );

  Widget _filters() => SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ['All', 'Pending', 'Paid', 'Active'].map((f) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(f), selected: _filter == f, onSelected: (_) => setState(() => _filter = f)))).toList()));

  Widget _requestCard(AdminSubscriptionRequest r) => Card(
    margin: const EdgeInsets.only(bottom: 12), elevation: 0, color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xFFE5E7EB))),
    child: InkWell(borderRadius: BorderRadius.circular(18), onTap: () => _details(r), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text(r.planTitle.isEmpty ? 'Subscription Request' : r.planTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))), _badge(r)]),
      const SizedBox(height: 8), Text(r.ownerName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      if (r.ownerEmail.isNotEmpty) Text(r.ownerEmail, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
      const SizedBox(height: 9), Row(children: [const Icon(Icons.payments_outlined, size: 17, color: Color(0xFF64748B)), const SizedBox(width: 5), Text('₹${r.planPrice} • ${r.planDuration}', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))), const Spacer(), if (r.requestedAt != null) Text(_dateTime(r.requestedAt!), style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)))])
    ]))));

  Widget _badge(AdminSubscriptionRequest r) {
    final active = r.status == 'active'; final paid = r.paymentStatus == 'paid';
    final text = active ? 'ACTIVE' : paid ? 'PAID' : 'PENDING';
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: active ? const Color(0xFFDCFCE7) : paid ? const Color(0xFFDBEAFE) : const Color(0xFFFFEDD5), borderRadius: BorderRadius.circular(20)), child: Text(text, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: active ? const Color(0xFF15803D) : paid ? const Color(0xFF1D4ED8) : const Color(0xFF9A3412))));
  }

  Widget _empty() => const Padding(padding: EdgeInsets.all(30), child: Column(children: [Icon(Icons.receipt_long_outlined, size: 42, color: Color(0xFF94A3B8)), SizedBox(height: 10), Text('No subscription requests found.', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569)))]));

  Widget _errorView() => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFDC2626)), const SizedBox(height: 12), Text(_error ?? 'Something went wrong.', textAlign: TextAlign.center), const SizedBox(height: 14), FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh_rounded), label: const Text('Retry'))])));

void _details(AdminSubscriptionRequest r) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (c) {
      return Container(
        constraints: const BoxConstraints(
          maxHeight: 620,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                const Text(
                  'Subscription Request',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 18),

                _row('Owner', r.ownerName),
                _row(
                  'Email',
                  r.ownerEmail.isEmpty
                      ? 'Not available'
                      : r.ownerEmail,
                ),
                _row('Owner ID', r.ownerId),
                _row('Plan', r.planTitle),
                _row('Duration', r.planDuration),
                _row('Price', '₹${r.planPrice}'),
                _row(
                  'Original Price',
                  r.planOriginalPrice == null
                      ? '—'
                      : '₹${r.planOriginalPrice}',
                ),
                _row('Payment', r.paymentStatus),
                _row('Status', r.status),
                _row(
                  'Requested',
                  r.requestedAt == null
                      ? 'Not available'
                      : _dateTime(r.requestedAt!),
                ),

                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 19,
                        color: Color(0xFFEA580C),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Payment verification and activation are not implemented yet. This screen only reads the subscription data currently stored by the owner app.',
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.45,
                            color: Color(0xFF9A3412),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(c),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

  Widget _row(String label, String value) => Padding(padding: const EdgeInsets.only(bottom: 11), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 105, child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)))), Expanded(child: Text(value, style: const TextStyle(fontSize: 12, color: Color(0xFF111827))))]));

  IconData _icon(String id) => switch (id) { 'monthly' => Icons.calendar_month_rounded, 'quarterly' => Icons.date_range_rounded, 'half_yearly' => Icons.event_available_rounded, 'yearly' => Icons.workspace_premium_rounded, _ => Icons.credit_card_rounded };

  String _dateTime(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
