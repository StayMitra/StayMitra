import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ============================================================
  // SETTINGS STATE
  // ============================================================

  bool rentReminderEnabled = true;
  bool ownerNotificationEnabled = true;
  bool tenantWhatsAppEnabled = true;
  bool tenantSmsEnabled = true;

  int reminderDays = 7;

  String currency = '₹ INR';

  String dateFormat = 'DD/MM/YYYY';

  String language = 'English';

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

        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
        ),

        title: const Text(
          'Settings',
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

              // ==================================================
              // PROPERTY
              // ==================================================

              _sectionTitle('Property'),

              const SizedBox(height: 12),

              _settingsCard(
                icon: Icons.apartment_rounded,
                iconColor: const Color(0xFF2563EB),
                title: 'PG / Property Details',
                subtitle:
                    'Manage your PG name, address and property information',
                onTap: () {
                  _showPropertyDetails();
                },
              ),

              const SizedBox(height: 12),

              _settingsCard(
                icon: Icons.person_rounded,
                iconColor: const Color(0xFF7C3AED),
                title: 'Owner Profile',
                subtitle:
                    'Manage owner name, mobile number and email',
                onTap: () {
                  _showOwnerProfile();
                },
              ),

              const SizedBox(height: 24),

              // ==================================================
              // NOTIFICATIONS
              // ==================================================

              _sectionTitle('Notifications'),

              const SizedBox(height: 12),

              _switchCard(
                icon: Icons.notifications_active_rounded,
                iconColor: const Color(0xFFF59E0B),
                title: 'Rent Reminders',
                subtitle:
                    'Enable automatic rent reminder notifications',
                value: rentReminderEnabled,
                onChanged: (value) {
                  setState(() {
                    rentReminderEnabled = value;
                  });
                },
              ),

              const SizedBox(height: 10),

              _switchCard(
                icon: Icons.person_outline_rounded,
                iconColor: const Color(0xFF2563EB),
                title: 'Owner Notifications',
                subtitle:
                    'Receive rent and important PG alerts',
                value: ownerNotificationEnabled,
                onChanged: (value) {
                  setState(() {
                    ownerNotificationEnabled = value;
                  });
                },
              ),

              const SizedBox(height: 10),

              _switchCard(
                icon: Icons.chat_rounded,
                iconColor: const Color(0xFF16A34A),
                title: 'Tenant WhatsApp',
                subtitle:
                    'Send rent reminders to tenants through WhatsApp',
                value: tenantWhatsAppEnabled,
                onChanged: (value) {
                  setState(() {
                    tenantWhatsAppEnabled = value;
                  });
                },
              ),

              const SizedBox(height: 10),

              _switchCard(
                icon: Icons.sms_rounded,
                iconColor: const Color(0xFF0891B2),
                title: 'Tenant SMS',
                subtitle:
                    'Send the same rent reminder through SMS',
                value: tenantSmsEnabled,
                onChanged: (value) {
                  setState(() {
                    tenantSmsEnabled = value;
                  });
                },
              ),

              const SizedBox(height: 12),

              _settingsCard(
                icon: Icons.calendar_month_rounded,
                iconColor: const Color(0xFFEA580C),
                title: 'Rent Reminder Timing',
                subtitle:
                    'Reminder currently set for $reminderDays days before due date',
                onTap: () {
                  _showReminderTiming();
                },
              ),

              const SizedBox(height: 24),

              // ==================================================
              // APP PREFERENCES
              // ==================================================

              _sectionTitle('App Preferences'),

              const SizedBox(height: 12),

              _settingsCard(
                icon: Icons.currency_rupee_rounded,
                iconColor: const Color(0xFF16A34A),
                title: 'Currency',
                subtitle: currency,
                onTap: () {
                  _showCurrency();
                },
              ),

              const SizedBox(height: 10),

              _settingsCard(
                icon: Icons.date_range_rounded,
                iconColor: const Color(0xFF6366F1),
                title: 'Date Format',
                subtitle: dateFormat,
                onTap: () {
                  _showDateFormat();
                },
              ),

              const SizedBox(height: 10),

              _settingsCard(
                icon: Icons.language_rounded,
                iconColor: const Color(0xFF0F766E),
                title: 'Language',
                subtitle: language,
                onTap: () {
                  _showLanguage();
                },
              ),

              const SizedBox(height: 24),

              // ==================================================
              // SECURITY
              // ==================================================

              _sectionTitle('Security'),

              const SizedBox(height: 12),

              _settingsCard(
                icon: Icons.lock_outline_rounded,
                iconColor: const Color(0xFF475569),
                title: 'Change Password / PIN',
                subtitle:
                    'Update your account security details',
                onTap: () {
                  _showComingSoon(
                    'Password / PIN change',
                  );
                },
              ),

              const SizedBox(height: 24),

              // ==================================================
              // ABOUT
              // ==================================================

              _sectionTitle('About'),

              const SizedBox(height: 12),

              _settingsCard(
                icon: Icons.privacy_tip_outlined,
                iconColor: const Color(0xFF2563EB),
                title: 'Privacy Policy',
                subtitle:
                    'View Stay Mitra privacy information',
                onTap: () {
                  _showComingSoon(
                    'Privacy Policy',
                  );
                },
              ),

              const SizedBox(height: 10),

              _settingsCard(
                icon: Icons.description_outlined,
                iconColor: const Color(0xFF7C3AED),
                title: 'Terms & Conditions',
                subtitle:
                    'View Stay Mitra terms and conditions',
                onTap: () {
                  _showComingSoon(
                    'Terms & Conditions',
                  );
                },
              ),

              const SizedBox(height: 10),

              _settingsCard(
                icon: Icons.info_outline_rounded,
                iconColor: const Color(0xFF0891B2),
                title: 'App Version',
                subtitle: 'Stay Mitra • Version 1.0.0',
                onTap: () {
                  _showAbout();
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
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF111827),
      ),
    );
  }

  // ============================================================
  // SETTINGS CARD
  // ============================================================

  Widget _settingsCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),

      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),

        child: Container(
          padding: const EdgeInsets.all(14),

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),

            border: Border.all(
              color: const Color(0xFFE5E7EB),
            ),
          ),

          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,

                decoration: BoxDecoration(
                  color: iconColor.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(14),
                ),

                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
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

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

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
  // SWITCH CARD
  // ============================================================

  Widget _switchCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
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
            width: 48,
            height: 48,

            decoration: BoxDecoration(
              color: iconColor.withValues(
                alpha: 0.10,
              ),
              borderRadius:
                  BorderRadius.circular(14),
            ),

            child: Icon(
              icon,
              color: iconColor,
              size: 24,
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
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor:
                const Color(0xFF2563EB),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROPERTY DETAILS
  // ============================================================

  void _showPropertyDetails() {
    final pgNameController =
        TextEditingController();

    final addressController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),

          title: const Text(
            'PG / Property Details',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: pgNameController,
                  decoration:
                      InputDecoration(
                    labelText: 'PG Name',
                    hintText:
                        'Enter PG name',
                    prefixIcon: const Icon(
                      Icons.apartment_rounded,
                    ),
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: addressController,
                  maxLines: 3,
                  decoration:
                      InputDecoration(
                    labelText: 'Address',
                    hintText:
                        'Enter property address',
                    prefixIcon: const Icon(
                      Icons.location_on_outlined,
                    ),
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),

            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );

                _showSavedMessage();
              },
              child: const Text(
                'Save',
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // OWNER PROFILE
  // ============================================================

  void _showOwnerProfile() {
    final nameController =
        TextEditingController();

    final mobileController =
        TextEditingController();

    final emailController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),

          title: const Text(
            'Owner Profile',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration:
                      InputDecoration(
                    labelText: 'Owner Name',
                    prefixIcon: const Icon(
                      Icons.person_outline_rounded,
                    ),
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller:
                      mobileController,
                  keyboardType:
                      TextInputType.phone,
                  decoration:
                      InputDecoration(
                    labelText: 'Mobile Number',
                    prefixIcon: const Icon(
                      Icons.phone_outlined,
                    ),
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller:
                      emailController,
                  keyboardType:
                      TextInputType.emailAddress,
                  decoration:
                      InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                    ),
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),

            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );

                _showSavedMessage();
              },
              child: const Text(
                'Save',
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // REMINDER TIMING
  // ============================================================

  void _showReminderTiming() {
    int temporaryDays = reminderDays;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder:
              (context, setDialogState) {
            return AlertDialog(
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  20,
                ),
              ),

              title: const Text(
                'Rent Reminder Timing',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              content: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  const Text(
                    'How many days before the rent due date should the reminder be sent?',
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          Color(0xFF64748B),
                    ),
                  ),

                  const SizedBox(height: 18),

                  RadioListTile<int>(
                    value: 7,
                    groupValue:
                        temporaryDays,
                    title: const Text(
                      '7 days before',
                    ),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setDialogState(() {
                        temporaryDays =
                            value;
                      });
                    },
                  ),

                  RadioListTile<int>(
                    value: 3,
                    groupValue:
                        temporaryDays,
                    title: const Text(
                      '3 days before',
                    ),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setDialogState(() {
                        temporaryDays =
                            value;
                      });
                    },
                  ),

                  RadioListTile<int>(
                    value: 1,
                    groupValue:
                        temporaryDays,
                    title: const Text(
                      '1 day before',
                    ),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setDialogState(() {
                        temporaryDays =
                            value;
                      });
                    },
                  ),
                ],
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  child: const Text(
                    'Cancel',
                  ),
                ),

                FilledButton(
                  onPressed: () {
                    setState(() {
                      reminderDays =
                          temporaryDays;
                    });

                    Navigator.pop(
                      dialogContext,
                    );

                    _showSavedMessage();
                  },
                  child: const Text(
                    'Save',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // CURRENCY
  // ============================================================

  void _showCurrency() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          title: const Text(
            'Select Currency',
          ),

          children: [
            SimpleDialogOption(
              onPressed: () {
                setState(() {
                  currency = '₹ INR';
                });

                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                '₹ INR',
              ),
            ),

            SimpleDialogOption(
              onPressed: () {
                setState(() {
                  currency = '\$ USD';
                });

                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                '\$ USD',
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  void _showDateFormat() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          title: const Text(
            'Select Date Format',
          ),

          children: [
            SimpleDialogOption(
              onPressed: () {
                setState(() {
                  dateFormat =
                      'DD/MM/YYYY';
                });

                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                'DD/MM/YYYY',
              ),
            ),

            SimpleDialogOption(
              onPressed: () {
                setState(() {
                  dateFormat =
                      'MM/DD/YYYY';
                });

                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                'MM/DD/YYYY',
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // LANGUAGE
  // ============================================================

  void _showLanguage() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          title: const Text(
            'Select Language',
          ),

          children: [
            SimpleDialogOption(
              onPressed: () {
                setState(() {
                  language = 'English';
                });

                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                'English',
              ),
            ),

            SimpleDialogOption(
              onPressed: () {
                setState(() {
                  language = 'Telugu';
                });

                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                'Telugu',
              ),
            ),

            SimpleDialogOption(
              onPressed: () {
                setState(() {
                  language = 'Kannada';
                });

                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                'Kannada',
              ),
            ),

            SimpleDialogOption(
              onPressed: () {
                setState(() {
                  language = 'Hindi';
                });

                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                'Hindi',
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // ABOUT
  // ============================================================

  void _showAbout() {
    showDialog(
      context: context,
      builder: (dialogContext) {
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

          content: const Text(
            'PG Management Made Simple\n\nVersion 1.0.0',
            style: TextStyle(
              height: 1.5,
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
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
  // COMING SOON
  // ============================================================

  void _showComingSoon(String feature) {
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

  // ============================================================
  // SAVED MESSAGE
  // ============================================================

  void _showSavedMessage() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Settings updated successfully.',
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  }
}