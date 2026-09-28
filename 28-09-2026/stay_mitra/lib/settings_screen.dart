import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'language_service.dart';
import 'pg_manager_service.dart';

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

  // App lock with optional 4-digit PIN.
  // The owner can enable/disable this without removing the PIN implementation.
  bool appLockEnabled = false;

  int reminderDays = 7;

  String currency = '₹ INR';

  String dateFormat = 'DD/MM/YYYY';

  // ============================================================
  // LANGUAGE
  // ============================================================

  String get language =>
      LanguageService.instance.language;

  String _t(String key, [String? fallback]) {
    final value = LanguageService.instance.get(key);
    if (value == key && fallback != null) return fallback;
    return value;
  }

  @override
  void initState() {
    super.initState();

    LanguageService.instance.addListener(
      _onLanguageChanged,
    );

    _loadFirebaseSettings();
  }

  @override
  void dispose() {
    LanguageService.instance.removeListener(
      _onLanguageChanged,
    );

    super.dispose();
  }

  void _onLanguageChanged() {
    if (!mounted) return;

    setState(() {});
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

        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
        ),

        title: Text(
          _t('settings', 'Settings'),
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

              _sectionTitle(_t('property', 'Property')),

              const SizedBox(height: 12),

              _settingsCard(
                icon: Icons.apartment_rounded,
                iconColor: const Color(0xFF2563EB),
                title: _t('pg_property_details', 'PG / Property Details'),
                subtitle:
                    _t('property_details_subtitle', 'Manage your PG name, address and property information'),
                onTap: () {
                  _showPropertyDetails();
                },
              ),

              const SizedBox(height: 12),

              _settingsCard(
                icon: Icons.person_rounded,
                iconColor: const Color(0xFF7C3AED),
                title: _t('owner_profile', 'Owner Profile'),
                subtitle:
                    _t('owner_profile_subtitle', 'Manage owner name, mobile number and email'),
                onTap: () {
                  _showOwnerProfile();
                },
              ),

              const SizedBox(height: 24),

              // ==================================================
              // NOTIFICATIONS
              // ==================================================

              _sectionTitle(_t('notifications', 'Notifications')),

              const SizedBox(height: 12),

              _switchCard(
                icon: Icons.notifications_active_rounded,
                iconColor: const Color(0xFFF59E0B),
                title: _t('rent_reminders', 'Rent Reminders'),
                subtitle:
                    _t('rent_reminders_subtitle', 'Enable automatic rent reminder notifications'),
                value: rentReminderEnabled,
                onChanged: (value) {
                  setState(() {
                    rentReminderEnabled = value;
                  });
                  _saveAppSettings({
                    'rent_reminder_enabled': value,
                  });
                },
              ),

              const SizedBox(height: 10),

              _switchCard(
                icon: Icons.person_outline_rounded,
                iconColor: const Color(0xFF2563EB),
                title: _t('owner_notifications', 'Owner Notifications'),
                subtitle:
                    _t('owner_notifications_subtitle', 'Receive rent and important PG alerts'),
                value: ownerNotificationEnabled,
                onChanged: (value) {
                  setState(() {
                    ownerNotificationEnabled = value;
                  });
                  _saveAppSettings({
                    'owner_notification_enabled': value,
                  });
                },
              ),

              const SizedBox(height: 10),

              _switchCard(
                icon: Icons.chat_rounded,
                iconColor: const Color(0xFF16A34A),
                title: _t('tenant_whatsapp', 'Tenant WhatsApp'),
                subtitle:
                    _t('tenant_whatsapp_subtitle', 'Send rent reminders to tenants through WhatsApp'),
                value: tenantWhatsAppEnabled,
                onChanged: (value) {
                  setState(() {
                    tenantWhatsAppEnabled = value;
                  });
                  _saveAppSettings({
                    'tenant_whatsapp_enabled': value,
                  });
                },
              ),

              const SizedBox(height: 10),

              _switchCard(
                icon: Icons.sms_rounded,
                iconColor: const Color(0xFF0891B2),
                title: _t('tenant_sms', 'Tenant SMS'),
                subtitle:
                    _t('tenant_sms_subtitle', 'Send the same rent reminder through SMS'),
                value: tenantSmsEnabled,
                onChanged: (value) {
                  setState(() {
                    tenantSmsEnabled = value;
                  });
                  _saveAppSettings({
                    'tenant_sms_enabled': value,
                  });
                },
              ),

              const SizedBox(height: 12),

              _settingsCard(
                icon: Icons.calendar_month_rounded,
                iconColor: const Color(0xFFEA580C),
                title: _t('rent_reminder_timing', 'Rent Reminder Timing'),
                subtitle:
                    _t('reminder_currently_set', 'Reminder currently set for {days} days before due date').replaceAll('{days}', '$reminderDays'),
                onTap: () {
                  _showReminderTiming();
                },
              ),

              const SizedBox(height: 24),

              // ==================================================
              // APP PREFERENCES
              // ==================================================

              _sectionTitle(_t('app_preferences', 'App Preferences')),

              const SizedBox(height: 12),

              _settingsCard(
                icon: Icons.currency_rupee_rounded,
                iconColor: const Color(0xFF16A34A),
                title: _t('currency', 'Currency'),
                subtitle: currency,
                onTap: () {
                  _showCurrency();
                },
              ),

              const SizedBox(height: 10),

              _settingsCard(
                icon: Icons.date_range_rounded,
                iconColor: const Color(0xFF6366F1),
                title: _t('date_format', 'Date Format'),
                subtitle: dateFormat,
                onTap: () {
                  _showDateFormat();
                },
              ),

              const SizedBox(height: 10),

              _settingsCard(
                icon: Icons.language_rounded,
                iconColor: const Color(0xFF0F766E),
                title: _t('language', 'Language'),
                subtitle: language,
                onTap: () {
                  _showLanguage();
                },
              ),

              const SizedBox(height: 24),

              // ==================================================
              // SECURITY
              // ==================================================

              _sectionTitle(_t('security', 'Security')),

              const SizedBox(height: 12),

              _switchCard(
                icon: Icons.phonelink_lock_rounded,
                iconColor: const Color(0xFF2563EB),
                title: _t('app_lock', '4-Digit App Lock'),
                subtitle: appLockEnabled
                    ? _t('app_lock_enabled_subtitle', 'App lock is enabled. A 4-digit PIN will be required.')
                    : _t('app_lock_disabled_subtitle', 'App lock is disabled. The 4-digit PIN will not be asked.'),
                value: appLockEnabled,
                onChanged: _onAppLockChanged,
              ),

              const SizedBox(height: 10),

              _settingsCard(
                icon: Icons.lock_outline_rounded,
                iconColor: const Color(0xFF475569),
                title: _t('change_password_pin', 'Change Password / PIN'),
                subtitle:
                    _t('security_details_subtitle', 'Update your account security details'),
                onTap: () {
                  _showSecurityOptions();
                },
              ),

              const SizedBox(height: 24),

              // ==================================================
              // ABOUT
              // ==================================================

              _sectionTitle(_t('about', 'About')),

              const SizedBox(height: 12),

              _settingsCard(
                icon: Icons.privacy_tip_outlined,
                iconColor: const Color(0xFF2563EB),
                title: _t('privacy_policy', 'Privacy Policy'),
                subtitle:
                    _t('privacy_policy_subtitle', 'View Stay Mitra privacy information'),
                onTap: () {
                  _showPrivacyPolicy();
                },
              ),

              const SizedBox(height: 10),

              _settingsCard(
                icon: Icons.description_outlined,
                iconColor: const Color(0xFF7C3AED),
                title: _t('terms_conditions', 'Terms & Conditions'),
                subtitle:
                    _t('terms_conditions_subtitle', 'View Stay Mitra terms and conditions'),
                onTap: () {
                  _showTermsAndConditions();
                },
              ),

              const SizedBox(height: 10),

              _settingsCard(
                icon: Icons.info_outline_rounded,
                iconColor: const Color(0xFF0891B2),
                title: _t('app_version', 'App Version'),
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
                  children: [
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
                      _t('pg_management_simple', 'PG Management Made Simple'),
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

  void _showPropertyDetails() async {
    final pgNameController = TextEditingController();
    final addressController = TextEditingController();

    try {
      final ref = _propertyRef;
      if (ref != null) {
        final snapshot = await ref.get();
        final data = snapshot.data() ?? {};

        pgNameController.text =
            (data['name'] ?? data['pg_name'] ?? '').toString();
        addressController.text =
            (data['address'] ?? data['location'] ?? '').toString();
      }
    } catch (e) {
      debugPrint('PROPERTY LOAD ERROR: $e');
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool saving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                _t('pg_property_details', 'PG / Property Details'),
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
                      enabled: !saving,
                      decoration: InputDecoration(
                        labelText: _t('pg_name', 'PG Name'),
                        hintText: _t('enter_pg_name', 'Enter PG name'),
                        prefixIcon: const Icon(
                          Icons.apartment_rounded,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: addressController,
                      enabled: !saving,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: _t('address', 'Address'),
                        hintText: _t('enter_property_address', 'Enter property address'),
                        prefixIcon: const Icon(
                          Icons.location_on_outlined,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () {
                          Navigator.pop(dialogContext);
                        },
                  child: Text(_t('cancel', 'Cancel')),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final ref = _propertyRef;
                          if (ref == null) {
                            _showSecuritySnackBar(
                              _t('select_active_property_error', 'Please select an active property.'),
                            );
                            return;
                          }

                          setDialogState(() {
                            saving = true;
                          });

                          try {
                            await ref.set(
                              {
                                'name':
                                    pgNameController.text.trim(),
                                'pg_name':
                                    pgNameController.text.trim(),
                                'address':
                                    addressController.text.trim(),
                                'updated_at':
                                    FieldValue.serverTimestamp(),
                              },
                              SetOptions(merge: true),
                            );

                            if (!mounted) return;
                            Navigator.pop(dialogContext);
                            _showSavedMessage();
                          } catch (e) {
                            if (!context.mounted) return;

                            setDialogState(() {
                              saving = false;
                            });

                            _showSecuritySnackBar(
                              _t('unable_save_property', 'Unable to save property details: {error}').replaceAll('{error}', '$e'),
                            );
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Text('Save'),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      pgNameController.dispose();
      addressController.dispose();
    });
  }

  // ============================================================
  // OWNER PROFILE
  // ============================================================

  void _showOwnerProfile() async {
    final nameController = TextEditingController();
    final mobileController = TextEditingController();
    final emailController = TextEditingController();

    try {
      final user = FirebaseAuth.instance.currentUser;
      final ref = _ownerRef;

      if (ref != null) {
        final snapshot = await ref.get();
        final data = snapshot.data() ?? {};

        nameController.text =
            (data['name'] ?? data['owner_name'] ?? '').toString();
        mobileController.text =
            (data['mobile'] ??
                    data['phone'] ??
                    data['mobile_number'] ??
                    '')
                .toString();
        emailController.text =
            (data['email'] ?? user?.email ?? '').toString();
      } else {
        emailController.text =
            FirebaseAuth.instance.currentUser?.email ?? '';
      }
    } catch (e) {
      debugPrint('OWNER PROFILE LOAD ERROR: $e');
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool saving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                _t('owner_profile', 'Owner Profile'),
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
                      enabled: !saving,
                      decoration: InputDecoration(
                        labelText: _t('owner_name', 'Owner Name'),
                        prefixIcon: const Icon(
                          Icons.person_outline_rounded,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: mobileController,
                      enabled: !saving,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: _t('mobile_number', 'Mobile Number'),
                        prefixIcon: const Icon(
                          Icons.phone_outlined,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: emailController,
                      enabled: !saving,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: _t('email', 'Email'),
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () {
                          Navigator.pop(dialogContext);
                        },
                  child: Text(_t('cancel', 'Cancel')),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final user =
                              FirebaseAuth.instance.currentUser;
                          final ref = _ownerRef;

                          if (user == null || ref == null) {
                            _showSecuritySnackBar(
                              _t('please_login_again', 'Please login again.'),
                            );
                            return;
                          }

                          final newEmail =
                              emailController.text.trim();

                          if (newEmail.isEmpty) {
                            _showSecuritySnackBar(
                              _t('email_required', 'Email is required.'),
                            );
                            return;
                          }

                          setDialogState(() {
                            saving = true;
                          });

                          try {
                            if (newEmail != (user.email ?? '')) {
                              await user.verifyBeforeUpdateEmail(
                                newEmail,
                              );
                            }

                            await ref.set(
                              {
                                'name':
                                    nameController.text.trim(),
                                'owner_name':
                                    nameController.text.trim(),
                                'mobile':
                                    mobileController.text.trim(),
                                'phone':
                                    mobileController.text.trim(),
                                'email': newEmail,
                                'updated_at':
                                    FieldValue.serverTimestamp(),
                              },
                              SetOptions(merge: true),
                            );

                            if (!mounted) return;
                            Navigator.pop(dialogContext);
                            _showSavedMessage();
                          } on FirebaseAuthException catch (e) {
                            if (!context.mounted) return;

                            setDialogState(() {
                              saving = false;
                            });

                            _showSecuritySnackBar(
                              e.message ??
                                  _t('unable_update_owner', 'Unable to update owner profile.'),
                            );
                          } catch (e) {
                            if (!context.mounted) return;

                            setDialogState(() {
                              saving = false;
                            });

                            _showSecuritySnackBar(
                              _t('unable_save_owner', 'Unable to save owner profile: {error}').replaceAll('{error}', '$e'),
                            );
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Text('Save'),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      nameController.dispose();
      mobileController.dispose();
      emailController.dispose();
    });
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

              title: Text(
                _t('rent_reminder_timing', 'Rent Reminder Timing'),
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              content: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Text(
                    _t('reminder_question', 'How many days before the rent due date should the reminder be sent?'),
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
                    title: Text(
                      _t('days_7_before', '7 days before'),
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
                    title: Text(
                      _t('days_3_before', '3 days before'),
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
                    title: Text(
                      _t('day_1_before', '1 day before'),
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
                  child: Text(
                    'Cancel',
                  ),
                ),

                FilledButton(
                  onPressed: () {
                    setState(() {
                      reminderDays =
                          temporaryDays;
                    });

                    _saveAppSettings({
                      'reminder_days': temporaryDays,
                    });

                    Navigator.pop(
                      dialogContext,
                    );

                    _showSavedMessage();
                  },
                  child: Text(
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
          title: Text(
            _t('select_currency', 'Select Currency'),
          ),

          children: [
            SimpleDialogOption(
              onPressed: () {
                setState(() {
                  currency = '₹ INR';
                });

                _saveAppSettings({
                  'currency': '₹ INR',
                });

                Navigator.pop(
                  dialogContext,
                );
              },
              child: Text(
                '₹ INR',
              ),
            ),

            SimpleDialogOption(
              onPressed: () {
                setState(() {
                  currency = '\$ USD';
                });

                _saveAppSettings({
                  'currency': '\$ USD',
                });

                Navigator.pop(
                  dialogContext,
                );
              },
              child: Text(
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
          title: Text(
            _t('select_date_format', 'Select Date Format'),
          ),

          children: [
            SimpleDialogOption(
              onPressed: () {
                setState(() {
                  dateFormat =
                      'DD/MM/YYYY';
                });

                _saveAppSettings({
                  'date_format': 'DD/MM/YYYY',
                });

                Navigator.pop(
                  dialogContext,
                );
              },
              child: Text(
                'DD/MM/YYYY',
              ),
            ),

            SimpleDialogOption(
              onPressed: () {
                setState(() {
                  dateFormat =
                      'MM/DD/YYYY';
                });

                _saveAppSettings({
                  'date_format': 'MM/DD/YYYY',
                });

                Navigator.pop(
                  dialogContext,
                );
              },
              child: Text(
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
        return AlertDialog(
          title: Text(
            LanguageService.instance.get('select_language'),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 8,
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount:
                  LanguageService.supportedLanguages.length,
              itemBuilder: (context, index) {
                final selectedLanguage =
                    LanguageService.supportedLanguages[index];

                final selected =
                    LanguageService.instance.language ==
                        selectedLanguage;

                return ListTile(
                  title: Text(selectedLanguage),
                  trailing: selected
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF2563EB),
                        )
                      : null,
                  onTap: () {
                    LanguageService.instance
                        .setLanguage(selectedLanguage);

                    Navigator.pop(dialogContext);
                  },
                );
              },
            ),
          ),
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

          title: Text(
            'Stay Mitra',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          content: Text(
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
              child: Text(
                _t('close', 'Close'),
              ),
            ),
          ],
        );
      },
    );
  }


  // ============================================================
  // FIREBASE SETTINGS REFERENCES
  // ============================================================

  DocumentReference<Map<String, dynamic>>? get _settingsRef {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    return FirebaseFirestore.instance
        .collection('owners')
        .doc(user.uid)
        .collection('settings')
        .doc('app');
  }

  DocumentReference<Map<String, dynamic>>? get _ownerRef {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    return FirebaseFirestore.instance
        .collection('owners')
        .doc(user.uid);
  }

  DocumentReference<Map<String, dynamic>>? get _propertyRef {
    final user = FirebaseAuth.instance.currentUser;
    final pgId = PgManagerService.activePgId;

    if (user == null || pgId == null || pgId.isEmpty) {
      return null;
    }

    return FirebaseFirestore.instance
        .collection('owners')
        .doc(user.uid)
        .collection('properties')
        .doc(pgId);
  }

  Future<void> _loadFirebaseSettings() async {
    try {
      final ref = _settingsRef;
      if (ref == null) return;

      final snapshot = await ref.get();
      final data = snapshot.data();

      if (!snapshot.exists || data == null || !mounted) {
        return;
      }

      setState(() {
        rentReminderEnabled =
            data['rent_reminder_enabled'] is bool
                ? data['rent_reminder_enabled'] as bool
                : rentReminderEnabled;

        ownerNotificationEnabled =
            data['owner_notification_enabled'] is bool
                ? data['owner_notification_enabled'] as bool
                : ownerNotificationEnabled;

        tenantWhatsAppEnabled =
            data['tenant_whatsapp_enabled'] is bool
                ? data['tenant_whatsapp_enabled'] as bool
                : tenantWhatsAppEnabled;

        tenantSmsEnabled =
            data['tenant_sms_enabled'] is bool
                ? data['tenant_sms_enabled'] as bool
                : tenantSmsEnabled;

        appLockEnabled =
            data['pin_lock_enabled'] is bool
                ? data['pin_lock_enabled'] as bool
                : appLockEnabled;

        reminderDays =
            data['reminder_days'] is num
                ? (data['reminder_days'] as num).toInt()
                : reminderDays;

        currency =
            (data['currency'] ?? currency).toString();

        dateFormat =
            (data['date_format'] ?? dateFormat).toString();
      });
    } catch (e) {
      debugPrint('SETTINGS LOAD ERROR: $e');
    }
  }

  Future<void> _saveAppSettings(
    Map<String, dynamic> values,
  ) async {
    try {
      final ref = _settingsRef;
      if (ref == null) return;

      await ref.set(
        {
          ...values,
          'updated_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('SETTINGS SAVE ERROR: $e');
    }
  }

  // ============================================================
  // 4-DIGIT APP LOCK ENABLE / DISABLE
  // ============================================================

  Future<void> _onAppLockChanged(bool enabled) async {
    if (!enabled) {
      // Disabling the switch must immediately stop the PIN lock.
      // Keep the saved PIN so the owner can enable the lock again later
      // without creating a new PIN.
      if (mounted) {
        setState(() {
          appLockEnabled = false;
        });
      }

      await _saveAppSettings({
        'pin_lock_enabled': false,
      });
      return;
    }

    // If a PIN already exists, simply enable the lock.
    final existingPin = await _readPinData();

    if (existingPin != null) {
      if (mounted) {
        setState(() {
          appLockEnabled = true;
        });
      }

      await _saveAppSettings({
        'pin_lock_enabled': true,
      });
      return;
    }

    // No PIN exists yet. Enable only after the owner creates one.
    if (mounted) {
      setState(() {
        appLockEnabled = true;
      });
    }

    await _saveAppSettings({
      'pin_lock_enabled': true,
    });

    if (!mounted) return;

    _showPinDialog(
      enablingAppLock: true,
    );
  }

  // ============================================================
  // SECURITY OPTIONS
  // ============================================================

  void _showSecurityOptions() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              18,
              12,
              18,
              20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  _t('security', 'Security'),
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _t('choose_security_option', 'Choose what you want to change.'),
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEFF6FF),
                    child: Icon(
                      Icons.lock_outline_rounded,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  title: Text(
                    _t('change_password', 'Change Password'),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    _t('change_password_subtitle', 'Change your Firebase account password'),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showChangePasswordDialog();
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFF0FDF4),
                    child: Icon(
                      Icons.pin_rounded,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                  title: Text(
                    _t('change_pin', 'Change 4-Digit PIN'),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    _t('change_pin_subtitle', 'Set or change your app security PIN'),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showPinDialog();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // CHANGE PASSWORD
  // ============================================================

  void _showChangePasswordDialog() {
    final newPasswordController =
        TextEditingController();

    final confirmPasswordController =
        TextEditingController();

    bool obscureNew = true;
    bool obscureConfirm = true;
    bool saving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                _t('change_password', 'Change Password'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: newPasswordController,
                    obscureText: obscureNew,
                    enabled: !saving,
                    decoration: InputDecoration(
                      labelText: _t('new_password', 'New Password'),
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setDialogState(() {
                            obscureNew = !obscureNew;
                          });
                        },
                        icon: Icon(
                          obscureNew
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: obscureConfirm,
                    enabled: !saving,
                    decoration: InputDecoration(
                      labelText: _t('confirm_password', 'Confirm Password'),
                      prefixIcon: const Icon(
                        Icons.lock_reset_rounded,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setDialogState(() {
                            obscureConfirm = !obscureConfirm;
                          });
                        },
                        icon: Icon(
                          obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _t('password_min', 'Password must contain at least 6 characters.'),
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () {
                          Navigator.pop(dialogContext);
                        },
                  child: Text(_t('cancel', 'Cancel')),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final password =
                              newPasswordController.text.trim();

                          final confirm =
                              confirmPasswordController.text.trim();

                          if (password.length < 6) {
                            _showSecuritySnackBar(
                              _t('password_min', 'Password must contain at least 6 characters.'),
                            );
                            return;
                          }

                          if (password != confirm) {
                            _showSecuritySnackBar(
                              _t('passwords_no_match', 'Passwords do not match.'),
                            );
                            return;
                          }

                          final user =
                              FirebaseAuth.instance.currentUser;

                          if (user == null) {
                            _showSecuritySnackBar(
                              _t('please_login_again', 'Please login again.'),
                            );
                            return;
                          }

                          setDialogState(() {
                            saving = true;
                          });

                          try {
                            await user.updatePassword(password);

                            if (!mounted) return;

                            Navigator.pop(dialogContext);

                            _showSecuritySnackBar(
                              _t('password_changed', 'Password changed successfully.'),
                            );
                          } on FirebaseAuthException catch (e) {
                            if (!context.mounted) return;

                            setDialogState(() {
                              saving = false;
                            });

                            if (e.code ==
                                'requires-recent-login') {
                              _showSecuritySnackBar(
                                'For security, please login again and then change the password.',
                              );
                            } else if (e.code ==
                                'weak-password') {
                              _showSecuritySnackBar(
                                _t('weak_password', 'The password is too weak.'),
                              );
                            } else {
                              _showSecuritySnackBar(
                                e.message ??
                                    _t('unable_change_password', 'Unable to change password.'),
                              );
                            }
                          } catch (e) {
                            if (!context.mounted) return;

                            setDialogState(() {
                              saving = false;
                            });

                            _showSecuritySnackBar(
                              _t('unable_change_password_error', 'Unable to change password: {error}').replaceAll('{error}', '$e'),
                            );
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Text(_t('change_password', 'Change Password')),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      newPasswordController.dispose();
      confirmPasswordController.dispose();
    });
  }

  // ============================================================
  // SECURE PIN HASHING
  // ============================================================

  String _createPinSalt() {
    final random = Random.secure();

    final bytes = List<int>.generate(
      16,
      (_) => random.nextInt(256),
    );

    return base64UrlEncode(bytes);
  }

  String _hashPin(
    String pin,
    String salt,
  ) {
    return sha256
        .convert(
          utf8.encode('$salt:$pin'),
        )
        .toString();
  }

  Future<Map<String, dynamic>?> _readPinData() async {
    try {
      final ref = _settingsRef;

      if (ref == null) return null;

      final snapshot = await ref.get();
      final data = snapshot.data();

      if (!snapshot.exists || data == null) {
        return null;
      }

      final hash = data['pin_hash'];
      final salt = data['pin_salt'];

      if (hash == null || salt == null) {
        return null;
      }

      return {
        'pin_hash': hash.toString(),
        'pin_salt': salt.toString(),
      };
    } catch (e) {
      debugPrint('PIN READ ERROR: $e');
      return null;
    }
  }

  // ============================================================
  // SET / CHANGE 4-DIGIT PIN
  // ============================================================

  void _showPinDialog({
    bool enablingAppLock = false,
  }) {
    final currentPinController =
        TextEditingController();

    final newPinController =
        TextEditingController();

    final confirmPinController =
        TextEditingController();

    bool? hasExistingPin;
    bool saving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (hasExistingPin == null) {
              _readPinData().then((data) {
                if (!context.mounted) return;

                setDialogState(() {
                  hasExistingPin = data != null;
                });
              });
            }

            if (hasExistingPin == null) {
              return AlertDialog(
                content: SizedBox(
                  height: 70,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              );
            }

            final existing = hasExistingPin!;

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                enablingAppLock
                    ? _t('set_pin', 'Set 4-Digit PIN')
                    : (existing
                        ? _t('change_pin', 'Change 4-Digit PIN')
                        : _t('set_pin', 'Set 4-Digit PIN')),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (existing) ...[
                    TextField(
                      controller: currentPinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      enabled: !saving,
                      decoration: InputDecoration(
                        labelText: _t('current_pin', 'Current PIN'),
                        counterText: '',
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  TextField(
                    controller: newPinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    enabled: !saving,
                    decoration: InputDecoration(
                      labelText: _t('new_pin', 'New 4-Digit PIN'),
                      counterText: '',
                      prefixIcon: const Icon(
                        Icons.pin_rounded,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: confirmPinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    enabled: !saving,
                    decoration: InputDecoration(
                      labelText: _t('confirm_pin', 'Confirm PIN'),
                      counterText: '',
                      prefixIcon: const Icon(
                        Icons.pin_end_rounded,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _t('pin_security_note', 'Exactly 4 digits. Only a salted SHA-256 hash and salt are stored in Firebase.'),
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () async {
                          Navigator.pop(dialogContext);

                          if (enablingAppLock) {
                            if (mounted) {
                              setState(() {
                                appLockEnabled = false;
                              });
                            }

                            await _saveAppSettings({
                              'pin_lock_enabled': false,
                            });
                          }
                        },
                  child: Text(_t('cancel', 'Cancel')),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final currentPin =
                              currentPinController.text.trim();

                          final newPin =
                              newPinController.text.trim();

                          final confirmPin =
                              confirmPinController.text.trim();

                          final pattern =
                              RegExp(r'^\d{4}$');

                          if (existing &&
                              !pattern.hasMatch(currentPin)) {
                            _showSecuritySnackBar(
                              _t('enter_current_pin', 'Enter your current 4-digit PIN.'),
                            );
                            return;
                          }

                          if (!pattern.hasMatch(newPin)) {
                            _showSecuritySnackBar(
                              _t('new_pin_4_digits', 'New PIN must contain exactly 4 digits.'),
                            );
                            return;
                          }

                          if (newPin != confirmPin) {
                            _showSecuritySnackBar(
                              _t('pins_no_match', 'PINs do not match.'),
                            );
                            return;
                          }

                          setDialogState(() {
                            saving = true;
                          });

                          try {
                            final oldData =
                                await _readPinData();

                            if (existing &&
                                oldData != null) {
                              final oldHash = _hashPin(
                                currentPin,
                                oldData['pin_salt'].toString(),
                              );

                              if (oldHash !=
                                  oldData['pin_hash']) {
                                if (!context.mounted) return;

                                setDialogState(() {
                                  saving = false;
                                });

                                _showSecuritySnackBar(
                                  _t('current_pin_incorrect', 'Current PIN is incorrect.'),
                                );
                                return;
                              }
                            }

                            final salt =
                                _createPinSalt();

                            final hash =
                                _hashPin(
                              newPin,
                              salt,
                            );

                            final ref = _settingsRef;

                            if (ref == null) {
                              throw Exception(
                                'User is not logged in.',
                              );
                            }

                            await ref.set(
                              {
                                'pin_hash': hash,
                                'pin_salt': salt,
                                'pin_updated_at':
                                    FieldValue.serverTimestamp(),
                                'updated_at':
                                    FieldValue.serverTimestamp(),
                              },
                              SetOptions(merge: true),
                            );

                            if (!mounted) return;

                            Navigator.pop(dialogContext);

                            _showSecuritySnackBar(
                              existing
                                  ? _t('pin_changed', 'PIN changed successfully.')
                                  : _t('pin_set', 'PIN set successfully.'),
                            );
                          } catch (e) {
                            if (!context.mounted) return;

                            setDialogState(() {
                              saving = false;
                            });

                            _showSecuritySnackBar(
                              _t('unable_save_pin', 'Unable to save PIN: {error}').replaceAll('{error}', '$e'),
                            );
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          existing
                              ? _t('change_pin', 'Change PIN')
                              : _t('set_pin_short', 'Set PIN'),
                        ),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      currentPinController.dispose();
      newPinController.dispose();
      confirmPinController.dispose();
    });
  }

  void _showSecuritySnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // PRIVACY POLICY
  // ============================================================

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Privacy Policy',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const SingleChildScrollView(
            child: Text(
              'Stay Mitra stores PG, tenant, payment and property information to provide PG management features. '
              'Tenant ID proof images are stored in Firebase Storage and related metadata is stored in Firebase Firestore. '
              'Access is intended for authenticated users according to the application security rules.\n\n'
              'Please do not upload information that is not required for PG management.',
              style: TextStyle(
                height: 1.5,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(_t('close', 'Close')),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // TERMS & CONDITIONS
  // ============================================================

  void _showTermsAndConditions() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Terms & Conditions',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const SingleChildScrollView(
            child: Text(
              'Stay Mitra is provided as a PG management tool. '
              'The owner is responsible for entering accurate property, tenant, payment and document information. '
              'The owner is also responsible for maintaining the confidentiality of their account credentials and for using tenant information appropriately.\n\n'
              'The application should not be used to store information that is unnecessary for PG management.',
              style: TextStyle(
                height: 1.5,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(_t('close', 'Close')),
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
        SnackBar(
          content: Text(
            _t('settings_updated', 'Settings updated successfully.'),
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  }
}