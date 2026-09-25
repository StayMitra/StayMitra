import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailMobileController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailMobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOGIN - FIREBASE AUTHENTICATION
  // ============================================================

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String email = _emailMobileController.text.trim();
    final String password = _passwordController.text;

    // ------------------------------------------------------------
    // Firebase Email/Password authentication కోసం
    //
    // ప్రస్తుతం Email login support చేస్తున్నాం.
    //
    // Mobile number login కోసం Firebase Phone Authentication
    // + OTP flow separate-ga implement చేయాలి.
    // ------------------------------------------------------------

    if (!email.contains('@')) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Please login using your registered email address.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // ----------------------------------------------------------
      // FIREBASE LOGIN
      // ----------------------------------------------------------

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // ----------------------------------------------------------
      // Firebase login successful
      // ----------------------------------------------------------

      Navigator.pushReplacementNamed(
        context,
        '/dashboard',
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      String message;

      switch (e.code) {
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;

        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          message = 'Invalid email or password.';
          break;

        case 'user-disabled':
          message = 'This account has been disabled.';
          break;

        case 'too-many-requests':
          message =
              'Too many login attempts. Please try again later.';
          break;

        case 'network-request-failed':
          message =
              'Network error. Please check your internet connection.';
          break;

        default:
          message =
              'Login failed. Please check your email and password.';
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Something went wrong. Please try again.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  // ============================================================
  // FORGOT PASSWORD - FIREBASE
  // ============================================================

  void _forgotPassword() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final TextEditingController controller =
            TextEditingController();

        bool isSending = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Forgot Password?',
              ),

              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Enter your registered email address '
                    'to receive a password reset link.',
                  ),

                  const SizedBox(height: 18),

                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.emailAddress,

                    decoration: InputDecoration(
                      hintText: 'Email Address',

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

              actions: [
                TextButton(
                  onPressed: isSending
                      ? null
                      : () {
                          Navigator.pop(dialogContext);
                        },
                  child: const Text(
                    'Cancel',
                  ),
                ),

                ElevatedButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          final String email =
                              controller.text.trim();

                          if (email.isEmpty ||
                              !email.contains('@')) {
                            ScaffoldMessenger.of(this.context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please enter a valid email address.',
                                  ),
                                  behavior:
                                      SnackBarBehavior.floating,
                                ),
                              );
                            return;
                          }

                          setDialogState(() {
                            isSending = true;
                          });

                          try {
                            await FirebaseAuth.instance
                                .sendPasswordResetEmail(
                              email: email,
                            );

                            if (!mounted) return;

                            Navigator.pop(dialogContext);

                            ScaffoldMessenger.of(this.context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Password reset link sent to your email.',
                                  ),
                                  behavior:
                                      SnackBarBehavior.floating,
                                ),
                              );
                          } on FirebaseAuthException catch (e) {
                            setDialogState(() {
                              isSending = false;
                            });

                            String message;

                            switch (e.code) {
                              case 'invalid-email':
                                message =
                                    'Please enter a valid email address.';
                                break;

                              case 'user-not-found':
                                message =
                                    'No account found for this email.';
                                break;

                              case 'network-request-failed':
                                message =
                                    'Network error. Please check your internet connection.';
                                break;

                              default:
                                message =
                                    'Unable to send password reset email.';
                            }

                            ScaffoldMessenger.of(this.context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text(message),
                                  behavior:
                                      SnackBarBehavior.floating,
                                ),
                              );
                          } catch (e) {
                            setDialogState(() {
                              isSending = false;
                            });

                            ScaffoldMessenger.of(this.context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Something went wrong. Please try again.',
                                  ),
                                  behavior:
                                      SnackBarBehavior.floating,
                                ),
                              );
                          }
                        },

                  child: isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Continue',
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
  // SIGN UP
  // ============================================================

  void _openSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SignUpScreen(),
      ),
    );
  }

  // ============================================================
  // BUILD LOGIN SCREEN
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 30,
            ),

            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 500,
              ),

              child: Form(
                key: _formKey,

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ==================================================
                    // LOGO
                    // ==================================================

                    Center(
                      child: SizedBox(
                        width: 190,
                        height: 145,
                        child: Image.asset(
                          'assets/images/StayMitra.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ==================================================
                    // WELCOME TEXT
                    // ==================================================

                    const Text(
                      'Welcome to Stay Mitra',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 29,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                        letterSpacing: -0.4,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Manage your PG with ease',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF8A919F),
                      ),
                    ),

                    const SizedBox(height: 42),

                    // ==================================================
                    // EMAIL / MOBILE
                    // ==================================================

                    TextFormField(
                      controller: _emailMobileController,
                      keyboardType: TextInputType.emailAddress,

                      decoration: InputDecoration(
                        hintText: 'Email / Mobile Number',
                        hintStyle: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 18,
                        ),

                        prefixIcon: const Icon(
                          Icons.person_outline_rounded,
                          color: Color(0xFF60646C),
                          size: 25,
                        ),

                        filled: true,
                        fillColor: Colors.white,

                        contentPadding:
                            const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 19,
                        ),

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFE1E4E8),
                          ),
                        ),

                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFE1E4E8),
                          ),
                        ),

                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFF2563EB),
                            width: 1.5,
                          ),
                        ),

                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Colors.redAccent,
                          ),
                        ),
                      ),

                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Please enter email or mobile number';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 18),

                    // ==================================================
                    // PASSWORD
                    // ==================================================

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,

                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 18,
                        ),

                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          color: Color(0xFF60646C),
                          size: 25,
                        ),

                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword =
                                  !_obscurePassword;
                            });
                          },

                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: const Color(0xFF60646C),
                          ),
                        ),

                        filled: true,
                        fillColor: Colors.white,

                        contentPadding:
                            const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 19,
                        ),

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFE1E4E8),
                          ),
                        ),

                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFE1E4E8),
                          ),
                        ),

                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFF2563EB),
                            width: 1.5,
                          ),
                        ),

                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Colors.redAccent,
                          ),
                        ),
                      ),

                      validator: (value) {
                        if (value == null ||
                            value.isEmpty) {
                          return 'Please enter password';
                        }

                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    // ==================================================
                    // FORGOT PASSWORD
                    // ==================================================

                    Align(
                      alignment: Alignment.centerRight,

                      child: TextButton(
                        onPressed: _forgotPassword,

                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                        ),

                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: Color(0xFF405A91),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ==================================================
                    // LOGIN BUTTON
                    // ==================================================

                    SizedBox(
                      height: 64,

                      child: ElevatedButton(
                        onPressed:
                            _isLoading ? null : _login,

                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF2563EB),

                          disabledBackgroundColor:
                              const Color(0xFF9DB9F5),

                          foregroundColor: Colors.white,

                          elevation: 0,

                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(16),
                          ),
                        ),

                        child: _isLoading
                            ? const SizedBox(
                                width: 25,
                                height: 25,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor:
                                      AlwaysStoppedAnimation<
                                          Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ==================================================
                    // SIGN UP DIVIDER
                    // ==================================================

                    Row(
                      children: [
                        const Expanded(
                          child: Divider(
                            color: Color(0xFFE0E3E8),
                          ),
                        ),

                        Padding(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 14,
                          ),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        const Expanded(
                          child: Divider(
                            color: Color(0xFFE0E3E8),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // ==================================================
                    // NEW USER / SIGN UP
                    // ==================================================

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,

                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            color: Color(0xFF737985),
                            fontSize: 15,
                          ),
                        ),

                        TextButton(
                          onPressed: _openSignUp,

                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),

                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Color(0xFF2563EB),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 35),

                    // ==================================================
                    // FOOTER
                    // ==================================================

                    const Text(
                      'Stay Mitra • PG Management',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFADB5C2),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==================================================================
// SIGN UP SCREEN
// ==================================================================

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _mobileController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  // ============================================================
  // CREATE ACCOUNT - FIREBASE AUTHENTICATION
  // ============================================================

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String name = _nameController.text.trim();
    final String mobile = _mobileController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;

    setState(() {
      _isLoading = true;
    });

    try {
      // ----------------------------------------------------------
      // CREATE FIREBASE USER
      // ----------------------------------------------------------

      final UserCredential userCredential =
          await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ----------------------------------------------------------
      // SAVE USER DISPLAY NAME
      // ----------------------------------------------------------

      final User? user = userCredential.user;

      if (user != null) {
        await user.updateDisplayName(name);

        // --------------------------------------------------------
        // SEND EMAIL VERIFICATION
        // --------------------------------------------------------

        await user.sendEmailVerification();
      }

      // ----------------------------------------------------------
      // MOBILE NUMBER
      //
      // Currently collected from registration form.
      //
      // Firebase Email/Password Authentication does not use
      // this number for login.
      //
      // Phone OTP authentication can be added separately later.
      // ----------------------------------------------------------

      debugPrint(
        'Registered mobile number: $mobile',
      );

      // ----------------------------------------------------------
      // SIGN OUT AFTER REGISTRATION
      //
      // User will login from Login screen.
      // ----------------------------------------------------------

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Account created successfully. Please check your email for verification.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );

      // ----------------------------------------------------------
      // RETURN TO LOGIN SCREEN
      // ----------------------------------------------------------

      await Future.delayed(
        const Duration(milliseconds: 1000),
      );

      if (!mounted) return;

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      String message;

      switch (e.code) {
        case 'weak-password':
          message =
              'Password is too weak. Please use a stronger password.';
          break;

        case 'email-already-in-use':
          message =
              'An account already exists with this email address.';
          break;

        case 'invalid-email':
          message =
              'Please enter a valid email address.';
          break;

        case 'operation-not-allowed':
          message =
              'Email/Password authentication is not enabled in Firebase.';
          break;

        case 'network-request-failed':
          message =
              'Network error. Please check your internet connection.';
          break;

        default:
          message =
              'Account creation failed. Please try again.';
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Something went wrong. Please try again.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  // ============================================================
  // BUILD SIGN UP SCREEN
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FC),
        elevation: 0,

        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },

          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF111827),
          ),
        ),

        title: const Text(
          'Create Account',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w700,
          ),
        ),

        centerTitle: true,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 20,
          ),

          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 500,
              ),

              child: Form(
                key: _formKey,

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,

                  children: [
                    // ==================================================
                    // SIGN UP ICON
                    // ==================================================

                    Center(
                      child: Container(
                        width: 82,
                        height: 82,

                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF1FF),
                          borderRadius:
                              BorderRadius.circular(24),
                        ),

                        child: const Icon(
                          Icons.person_add_alt_1_rounded,
                          size: 42,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Create your Stay Mitra account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Register to manage your PG easily',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF858C98),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ==================================================
                    // FULL NAME
                    // ==================================================

                    _buildTextField(
                      controller: _nameController,
                      hintText: 'Full Name',
                      icon: Icons.person_outline_rounded,
                      keyboardType: TextInputType.name,
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Please enter your full name';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // ==================================================
                    // MOBILE NUMBER
                    // ==================================================

                    _buildTextField(
                      controller: _mobileController,
                      hintText: 'Mobile Number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Please enter mobile number';
                        }

                        if (value.trim().length < 10) {
                          return 'Please enter a valid mobile number';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // ==================================================
                    // EMAIL
                    // ==================================================

                    _buildTextField(
                      controller: _emailController,
                      hintText: 'Email Address',
                      icon: Icons.email_outlined,
                      keyboardType:
                          TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Please enter email address';
                        }

                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // ==================================================
                    // PASSWORD
                    // ==================================================

                    _buildPasswordField(
                      controller: _passwordController,
                      hintText: 'Password',
                      obscureText: _obscurePassword,
                      onToggle: () {
                        setState(() {
                          _obscurePassword =
                              !_obscurePassword;
                        });
                      },
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty) {
                          return 'Please enter password';
                        }

                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // ==================================================
                    // CONFIRM PASSWORD
                    // ==================================================

                    _buildPasswordField(
                      controller:
                          _confirmPasswordController,
                      hintText: 'Confirm Password',
                      obscureText:
                          _obscureConfirmPassword,
                      onToggle: () {
                        setState(() {
                          _obscureConfirmPassword =
                              !_obscureConfirmPassword;
                        });
                      },
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty) {
                          return 'Please confirm password';
                        }

                        if (value !=
                            _passwordController.text) {
                          return 'Passwords do not match';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 28),

                    // ==================================================
                    // CREATE ACCOUNT BUTTON
                    // ==================================================

                    SizedBox(
                      height: 62,

                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : _createAccount,

                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF2563EB),

                          disabledBackgroundColor:
                              const Color(0xFF9DB9F5),

                          foregroundColor: Colors.white,

                          elevation: 0,

                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(16),
                          ),
                        ),

                        child: _isLoading
                            ? const SizedBox(
                                width: 25,
                                height: 25,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor:
                                      AlwaysStoppedAnimation<
                                          Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ==================================================
                    // EXISTING ACCOUNT
                    // ==================================================

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,

                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(
                            color: Color(0xFF737985),
                            fontSize: 14,
                          ),
                        ),

                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },

                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),

                          child: const Text(
                            'Login',
                            style: TextStyle(
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // COMMON TEXT FIELD
  // ============================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required TextInputType keyboardType,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,

      decoration: InputDecoration(
        hintText: hintText,

        hintStyle: const TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 16,
        ),

        prefixIcon: Icon(
          icon,
          color: const Color(0xFF60646C),
        ),

        filled: true,
        fillColor: Colors.white,

        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFE1E4E8),
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFE1E4E8),
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFF2563EB),
            width: 1.5,
          ),
        ),
      ),

      validator: validator,
    );
  }

  // ============================================================
  // PASSWORD FIELD
  // ============================================================

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,

      decoration: InputDecoration(
        hintText: hintText,

        hintStyle: const TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 16,
        ),

        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
          color: Color(0xFF60646C),
        ),

        suffixIcon: IconButton(
          onPressed: onToggle,

          icon: Icon(
            obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: const Color(0xFF60646C),
          ),
        ),

        filled: true,
        fillColor: Colors.white,

        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFE1E4E8),
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFE1E4E8),
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFF2563EB),
            width: 1.5,
          ),
        ),
      ),

      validator: validator,
    );
  }
}