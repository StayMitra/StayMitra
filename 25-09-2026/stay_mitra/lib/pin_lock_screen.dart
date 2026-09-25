import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Protects the authenticated app with the 4-digit PIN saved in:
/// owners/{uid}/settings/app
///
/// Behaviour:
/// - If no PIN is configured, the child screen opens normally.
/// - If a PIN is configured, the PIN screen is shown before the child.
/// - When the app goes to the background, it locks again.
/// - The PIN itself is never stored locally or in plain text.
class PinLockGate extends StatefulWidget {
  final Widget child;

  const PinLockGate({
    super.key,
    required this.child,
  });

  @override
  State<PinLockGate> createState() => _PinLockGateState();
}

class _PinLockGateState extends State<PinLockGate>
    with WidgetsBindingObserver {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _loading = true;
  bool _hasPin = false;
  bool _locked = true;
  String? _errorMessage;

  DocumentReference<Map<String, dynamic>>? get _settingsRef {
    final user = _auth.currentUser;

    if (user == null) return null;

    return _firestore
        .collection('owners')
        .doc(user.uid)
        .collection('settings')
        .doc('app');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPinState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // The PIN may have been created or changed while the dashboard was open.
      // Re-check it when the app comes back so the lock state stays current.
      if (_hasPin && mounted) {
        setState(() {
          _locked = true;
        });
      }
      return;
    }

    if (state == AppLifecycleState.resumed) {
      // This also detects a PIN that was set from Settings while the app was
      // already open. If a PIN exists, the app remains locked until verified.
      _loadPinState();
    }
  }

  Future<void> _loadPinState() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final user = _auth.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _hasPin = false;
        _locked = false;
      });
      return;
    }

    try {
      final ref = _settingsRef;

      if (ref == null) {
        throw Exception('User is not logged in.');
      }

      final snapshot = await ref.get();
      final data = snapshot.data();

      final hash = data?['pin_hash']?.toString().trim();
      final salt = data?['pin_salt']?.toString().trim();

      final hasValidPin =
          snapshot.exists &&
          hash != null &&
          hash.isNotEmpty &&
          salt != null &&
          salt.isNotEmpty;

      if (!mounted) return;

      setState(() {
        _hasPin = hasValidPin;
        _locked = hasValidPin;
        _loading = false;
      });
    } catch (e) {
      debugPrint('PIN LOCK LOAD ERROR: $e');

      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorMessage =
            'Unable to verify app PIN. Please check your internet connection and try again.';
        _locked = true;
      });
    }
  }

  void _unlock() {
    if (!mounted) return;

    setState(() {
      _locked = false;
      _errorMessage = null;
    });
  }

  Future<void> _signOut() async {
    await _auth.signOut();

    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const _PinLoadingScreen();
    }

    if (_errorMessage != null) {
      return _PinErrorScreen(
        message: _errorMessage!,
        onRetry: _loadPinState,
        onSignOut: _signOut,
      );
    }

    if (!_hasPin || !_locked) {
      return widget.child;
    }

    return _PinUnlockScreen(
      onUnlocked: _unlock,
      onSignOut: _signOut,
    );
  }
}

class _PinUnlockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  final Future<void> Function() onSignOut;

  const _PinUnlockScreen({
    required this.onUnlocked,
    required this.onSignOut,
  });

  @override
  State<_PinUnlockScreen> createState() => _PinUnlockScreenState();
}

class _PinUnlockScreenState extends State<_PinUnlockScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();

  bool _checking = false;
  bool _obscurePin = true;
  String? _error;

  DocumentReference<Map<String, dynamic>>? get _settingsRef {
    final user = _auth.currentUser;

    if (user == null) return null;

    return _firestore
        .collection('owners')
        .doc(user.uid)
        .collection('settings')
        .doc('app');
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _pinFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  String _hashPin(String pin, String salt) {
    return sha256
        .convert(
          utf8.encode('$salt:$pin'),
        )
        .toString();
  }

  Future<void> _verifyPin() async {
    final pin = _pinController.text.trim();

    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      setState(() {
        _error = 'Please enter your 4-digit PIN.';
      });
      return;
    }

    if (_checking) return;

    setState(() {
      _checking = true;
      _error = null;
    });

    try {
      final ref = _settingsRef;

      if (ref == null) {
        throw Exception('User is not logged in.');
      }

      final snapshot = await ref.get();
      final data = snapshot.data();

      final storedHash = data?['pin_hash']?.toString();
      final salt = data?['pin_salt']?.toString();

      if (!snapshot.exists ||
          storedHash == null ||
          storedHash.isEmpty ||
          salt == null ||
          salt.isEmpty) {
        throw Exception('PIN is not configured.');
      }

      final enteredHash = _hashPin(pin, salt);

      if (enteredHash != storedHash) {
        if (!mounted) return;

        setState(() {
          _checking = false;
          _error = 'Incorrect PIN. Please try again.';
        });

        _pinController.clear();
        _pinFocusNode.requestFocus();
        return;
      }

      if (!mounted) return;

      setState(() {
        _checking = false;
      });

      widget.onUnlocked();
    } catch (e) {
      debugPrint('PIN VERIFY ERROR: $e');

      if (!mounted) return;

      setState(() {
        _checking = false;
        _error =
            'Unable to verify PIN. Please check your internet connection and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: const BorderSide(
                    color: Color(0xFFE5E7EB),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          size: 34,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Stay Mitra Locked',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Enter your 4-digit PIN to continue',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _pinController,
                        focusNode: _pinFocusNode,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        obscureText: _obscurePin,
                        maxLength: 4,
                        enabled: !_checking,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 10,
                        ),
                        onSubmitted: (_) => _verifyPin(),
                        decoration: InputDecoration(
                          labelText: '4-Digit PIN',
                          counterText: '',
                          prefixIcon: const Icon(
                            Icons.pin_rounded,
                          ),
                          suffixIcon: IconButton(
                            onPressed: _checking
                                ? null
                                : () {
                                    setState(() {
                                      _obscurePin = !_obscurePin;
                                    });
                                  },
                            icon: Icon(
                              _obscurePin
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFF2563EB),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: _error == null
                            ? const SizedBox(
                                key: ValueKey('no_error'),
                                height: 20,
                              )
                            : Text(
                                _error!,
                                key: const ValueKey('error'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: _checking ? null : _verifyPin,
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _checking
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Unlock',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _checking ? null : widget.onSignOut,
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Logout / Use Password Login'),
                      ),
                    ],
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

class _PinLoadingScreen extends StatelessWidget {
  const _PinLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF7F9FC),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Checking app security...',
              style: TextStyle(
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinErrorScreen extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  final Future<void> Function() onSignOut;

  const _PinErrorScreen({
    required this.message,
    required this.onRetry,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_off_rounded,
                        size: 52,
                        color: Color(0xFFDC2626),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Security Check Failed',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: onRetry,
                          child: const Text('Retry'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: onSignOut,
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Logout / Use Password Login'),
                      ),
                    ],
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
