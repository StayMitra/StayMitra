import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  // ============================================================
  // SUPPORT CONTACT DETAILS
  // ============================================================

  static const String supportPhone = '+91 00000 00000';
  static const String supportWhatsApp = '+91 00000 00000';
  static const String supportEmail = 'support@staymitra.com';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),

        title: const Text(
          'Help & Support',
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
              // HEADER
              // ==================================================

              _supportHeader(),

              const SizedBox(height: 22),

              const Text(
                'Contact Us',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 12),

              // ==================================================
              // CALL SUPPORT
              // ==================================================

              _supportCard(
                icon: Icons.phone_in_talk_rounded,
                title: 'Call Support',
                subtitle:
                    'Talk to our support team for assistance',
                color: const Color(0xFF16A34A),
                onTap: () {
                  _showContactMessage(
                    context,
                    'Call Support',
                    supportPhone,
                  );
                },
              ),

              const SizedBox(height: 12),

              // ==================================================
              // WHATSAPP
              // ==================================================

              _supportCard(
                icon: Icons.chat_rounded,
                title: 'WhatsApp Support',
                subtitle:
                    'Chat with our support team on WhatsApp',
                color: const Color(0xFF22C55E),
                onTap: () {
                  _showContactMessage(
                    context,
                    'WhatsApp Support',
                    supportWhatsApp,
                  );
                },
              ),

              const SizedBox(height: 12),

              // ==================================================
              // EMAIL
              // ==================================================

              _supportCard(
                icon: Icons.email_rounded,
                title: 'Email Support',
                subtitle:
                    'Send us your issue or question by email',
                color: const Color(0xFF2563EB),
                onTap: () {
                  _showContactMessage(
                    context,
                    'Email Support',
                    supportEmail,
                  );
                },
              ),

              const SizedBox(height: 24),

              // ==================================================
              // FAQ
              // ==================================================

              const Text(
                'Frequently Asked Questions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 12),

              _faqCard(
                question:
                    'How can I add a new tenant?',
                answer:
                    'Go to Tenant Management from the dashboard and use the Add Tenant option to create a new tenant record.',
              ),

              _faqCard(
                question:
                    'How can I assign a room or bed?',
                answer:
                    'Open Rooms & Beds from the dashboard, select the required room and assign an available bed to the tenant.',
              ),

              _faqCard(
                question:
                    'How can I record a rent payment?',
                answer:
                    'Go to Accounts and select the appropriate tenant or payment option to record the rent payment.',
              ),

              _faqCard(
                question:
                    'How can I upload a document?',
                answer:
                    'Open More → Documents and tap Add Document. You can select a supported file and save it in Stay Mitra.',
              ),

              _faqCard(
                question:
                    'How does the subscription work?',
                answer:
                    'The first month is free. After the free period, the subscription plan and applicable offer will be displayed based on the plan configured by the Stay Mitra administrator.',
              ),

              _faqCard(
                question:
                    'What should I do if I face an issue?',
                answer:
                    'You can contact Stay Mitra Support by phone, WhatsApp or email. Please provide your PG details and a description of the issue so our support team can assist you.',
              ),

              const SizedBox(height: 24),

              // ==================================================
              // RAISE SUPPORT REQUEST
              // ==================================================

              const Text(
                'Need More Help?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 12),

              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    _showSupportRequestDialog(context);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E8FF),
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.support_agent_rounded,
                            color: Color(0xFF7C3AED),
                            size: 27,
                          ),
                        ),

                        const SizedBox(width: 14),

                        const Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Raise a Support Request',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight:
                                      FontWeight.w600,
                                  color:
                                      Color(0xFF111827),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Tell us about your issue and our team will help you.',
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
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

              const SizedBox(height: 24),

              // ==================================================
              // SUPPORT HOURS
              // ==================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFDBEAFE),
                  ),
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      color: Color(0xFF2563EB),
                      size: 25,
                    ),

                    const SizedBox(width: 12),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Support Hours',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  FontWeight.bold,
                              color:
                                  Color(0xFF111827),
                            ),
                          ),

                          SizedBox(height: 5),

                          Text(
                            'Monday – Saturday',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  FontWeight.w600,
                              color:
                                  Color(0xFF334155),
                            ),
                          ),

                          SizedBox(height: 2),

                          Text(
                            '9:00 AM – 7:00 PM',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  Color(0xFF64748B),
                            ),
                          ),

                          SizedBox(height: 5),

                          Text(
                            'Sunday: Limited support',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
                      'We are here to help you.',
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
  // SUPPORT HEADER
  // ============================================================

  Widget _supportHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2563EB),
            Color(0xFF1D4ED8),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.15,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),

          const SizedBox(width: 15),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'How can we help?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  'Our support team is here to help you with Stay Mitra.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Colors.white70,
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
  // SUPPORT CARD
  // ============================================================

  Widget _supportCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
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
                  size: 26,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),

                    const SizedBox(height: 4),

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

  // ============================================================
  // FAQ CARD
  // ============================================================

  Widget _faqCard({
    required String question,
    required String answer,
  }) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: Color(0xFFE5E7EB),
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 2,
        ),
        childrenPadding:
            const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        collapsedShape:
            RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        leading: const Icon(
          Icons.help_outline_rounded,
          color: Color(0xFF2563EB),
        ),
        title: Text(
          question,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              answer,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONTACT MESSAGE
  // ============================================================

  static void _showContactMessage(
    BuildContext context,
    String title,
    String contact,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Support contact:\n\n$contact\n\nYou can update this contact information later from the Admin settings.',
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF475569),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // SUPPORT REQUEST
  // ============================================================

  static void _showSupportRequestDialog(
    BuildContext context,
  ) {
    final subjectController =
        TextEditingController();

    final messageController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          title: const Text(
            'Raise Support Request',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: subjectController,
                  decoration: InputDecoration(
                    labelText: 'Subject',
                    hintText:
                        'Example: Payment issue',
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: messageController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Describe your issue',
                    hintText:
                        'Please explain the issue...',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                subjectController.dispose();
                messageController.dispose();
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),

            FilledButton(
              onPressed: () {
                final subject =
                    subjectController.text.trim();

                final message =
                    messageController.text.trim();

                if (subject.isEmpty ||
                    message.isEmpty) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter subject and issue details.',
                      ),
                      behavior:
                          SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                subjectController.dispose();
                messageController.dispose();

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Support request submitted successfully.',
                    ),
                    behavior:
                        SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text(
                'Submit',
              ),
            ),
          ],
        );
      },
    );
  }
}