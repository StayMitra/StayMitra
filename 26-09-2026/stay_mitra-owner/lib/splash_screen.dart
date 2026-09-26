import 'dart:async';

import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _positionAnimation;

  // ============================================================
  // STAY MITRA LETTER ANIMATIONS
  // ============================================================

  final List<Offset> _letterStartPositions = [
    const Offset(-2.0, 0.8), // S
    const Offset(-1.2, -1.5), // t
    const Offset(0.0, 1.8), // a
    const Offset(1.5, -1.4), // y
    const Offset(2.0, 0.8), // M
    const Offset(1.2, 1.6), // i
    const Offset(2.0, -1.2), // t
    const Offset(-1.4, 1.4), // r
    const Offset(-2.0, -0.8), // a
  ];

  late List<Animation<Offset>> _letterPositionAnimations;
  late List<Animation<double>> _letterOpacityAnimations;
  late List<Animation<double>> _letterScaleAnimations;

  @override
  void initState() {
    super.initState();

    // ============================================================
    // COMPLETE SPLASH ANIMATION
    //
    // Total duration = 6 seconds
    //
    // Existing logo animation is preserved.
    // ============================================================

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );

    // ============================================================
    // SCALE ANIMATION
    // ============================================================

    _scaleAnimation = TweenSequence<double>(
      [
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 0.70,
            end: 1.08,
          ).chain(
            CurveTween(
              curve: Curves.easeOutCubic,
            ),
          ),
          weight: 30,
        ),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 1.08,
            end: 0.96,
          ).chain(
            CurveTween(
              curve: Curves.easeInOut,
            ),
          ),
          weight: 40,
        ),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 0.96,
            end: 1.0,
          ).chain(
            CurveTween(
              curve: Curves.easeOutCubic,
            ),
          ),
          weight: 30,
        ),
      ],
    ).animate(_controller);

    // ============================================================
    // VERY SMALL ROTATION
    // ============================================================

    _rotationAnimation = TweenSequence<double>(
      [
        TweenSequenceItem(
          tween: Tween<double>(
            begin: -0.025,
            end: 0.020,
          ).chain(
            CurveTween(
              curve: Curves.easeInOut,
            ),
          ),
          weight: 35,
        ),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 0.020,
            end: -0.012,
          ).chain(
            CurveTween(
              curve: Curves.easeInOut,
            ),
          ),
          weight: 35,
        ),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: -0.012,
            end: 0.0,
          ).chain(
            CurveTween(
              curve: Curves.easeOutCubic,
            ),
          ),
          weight: 30,
        ),
      ],
    ).animate(_controller);

    // ============================================================
    // FADE ANIMATION
    // ============================================================

    _fadeAnimation = TweenSequence<double>(
      [
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).chain(
            CurveTween(
              curve: Curves.easeOut,
            ),
          ),
          weight: 18,
        ),
        TweenSequenceItem(
          tween: ConstantTween<double>(1.0),
          weight: 82,
        ),
      ],
    ).animate(_controller);

    // ============================================================
    // COMPLETE LOGO POSITION ANIMATION
    // ============================================================

    _positionAnimation = TweenSequence<Offset>(
      [
        TweenSequenceItem(
          tween: Tween<Offset>(
            begin: const Offset(-0.90, 0.10),
            end: const Offset(0.35, -0.06),
          ).chain(
            CurveTween(
              curve: Curves.easeOutCubic,
            ),
          ),
          weight: 25,
        ),
        TweenSequenceItem(
          tween: Tween<Offset>(
            begin: const Offset(0.35, -0.06),
            end: const Offset(-0.28, 0.08),
          ).chain(
            CurveTween(
              curve: Curves.easeInOut,
            ),
          ),
          weight: 25,
        ),
        TweenSequenceItem(
          tween: Tween<Offset>(
            begin: const Offset(-0.28, 0.08),
            end: const Offset(0.10, -0.025),
          ).chain(
            CurveTween(
              curve: Curves.easeInOut,
            ),
          ),
          weight: 20,
        ),
        TweenSequenceItem(
          tween: Tween<Offset>(
            begin: const Offset(0.10, -0.025),
            end: Offset.zero,
          ).chain(
            CurveTween(
              curve: Curves.easeOutCubic,
            ),
          ),
          weight: 30,
        ),
      ],
    ).animate(_controller);

    // ============================================================
    // INDIVIDUAL LETTER ANIMATIONS
    //
    // Each letter starts from a different location.
    // Letters enter one after another.
    // ============================================================

    _letterPositionAnimations = [];

    _letterOpacityAnimations = [];

    _letterScaleAnimations = [];

    for (int i = 0; i < 9; i++) {
      // ----------------------------------------------------------
      // Each letter starts slightly later than previous letter.
      // ----------------------------------------------------------

      final double start = 0.20 + (i * 0.035);

      final double end = start + 0.28;

      // ----------------------------------------------------------
      // POSITION
      // ----------------------------------------------------------

      _letterPositionAnimations.add(
        Tween<Offset>(
          begin: _letterStartPositions[i],
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(
              start,
              end.clamp(0.0, 1.0),
              curve: Curves.easeOutBack,
            ),
          ),
        ),
      );

      // ----------------------------------------------------------
      // OPACITY
      // ----------------------------------------------------------

      _letterOpacityAnimations.add(
        Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(
              start,
              end.clamp(0.0, 1.0),
              curve: Curves.easeOut,
            ),
          ),
        ),
      );

      // ----------------------------------------------------------
      // SCALE
      //
      // Letter slightly grows while entering.
      // ----------------------------------------------------------

      _letterScaleAnimations.add(
        TweenSequence<double>(
          [
            TweenSequenceItem(
              tween: Tween<double>(
                begin: 0.55,
                end: 1.12,
              ).chain(
                CurveTween(
                  curve: Curves.easeOutBack,
                ),
              ),
              weight: 75,
            ),
            TweenSequenceItem(
              tween: Tween<double>(
                begin: 1.12,
                end: 1.0,
              ).chain(
                CurveTween(
                  curve: Curves.easeOut,
                ),
              ),
              weight: 25,
            ),
          ],
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(
              start,
              end.clamp(0.0, 1.0),
            ),
          ),
        ),
      );
    }

    // ============================================================
    // START ANIMATION
    // ============================================================

    _controller.forward();

    // ============================================================
    // AFTER EXACTLY 6 SECONDS
    // GO TO LOGIN
    // ============================================================

    Timer(
      const Duration(seconds: 6),
      () {
        if (!mounted) return;

        Navigator.pushReplacementNamed(
          context,
          '/login',
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD STAY MITRA LETTERS
  // ============================================================

  Widget _buildAnimatedName(double imageSize) {
    const String firstWord = 'Stay';
    const String secondWord = 'Mitra';

    final List<String> letters = [
      ...firstWord.split(''),
      ...secondWord.split(''),
    ];

    final double fontSize = imageSize * 0.118;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(
        letters.length,
        (index) {
          final bool isMitra = index >= 4;

          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FractionalTranslation(
                translation: _letterPositionAnimations[index].value,
                child: Opacity(
                  opacity: _letterOpacityAnimations[index].value,
                  child: Transform.scale(
                    scale: _letterScaleAnimations[index].value,
                    child: Text(
                      letters[index],
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w700,
                        height: 0.95,
                        letterSpacing: -1.2,
                        color: isMitra
                            ? const Color(0xFF6630B5)
                            : const Color(0xFF0B2850),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF4),

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // ----------------------------------------------------
            // Keep image almost exactly as your existing design.
            // ----------------------------------------------------

            final double imageSize =
                (constraints.maxWidth * 0.90).clamp(
              0.0,
              constraints.maxHeight * 0.80,
            );

            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Center(
                  child: FractionalTranslation(
                    translation: _positionAnimation.value,
                    child: Transform.rotate(
                      angle: _rotationAnimation.value,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: SizedBox(
                            width: imageSize,
                            height: imageSize,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // ==================================================
                                // ORIGINAL STAY MITRA IMAGE
                                //
                                // Logo
                                // Tagline
                                // Bottom feature icons
                                // Everything remains from your original PNG.
                                // ==================================================

                                Image.asset(
                                  'assets/images/StayMitra.png',
                                  fit: BoxFit.contain,
                                  width: imageSize,
                                  height: imageSize,
                                ),

                                // ==================================================
                                // HIDE ONLY ORIGINAL "Stay Mitra" TEXT
                                //
                                // The original text in PNG is covered so that
                                // our individual animated letters can appear.
                                // Tagline and bottom icons remain untouched.
                                // ==================================================

                                Positioned(
                                  left: imageSize * 0.08,
                                  right: imageSize * 0.08,
                                  top: imageSize * 0.555,
                                  height: imageSize * 0.155,
                                  child: Container(
                                    color: const Color(0xFFFFFAF4),
                                  ),
                                ),

                                // ==================================================
                                // INDIVIDUAL LETTER ANIMATION
                                // ==================================================

                                Positioned(
                                  left: imageSize * 0.06,
                                  right: imageSize * 0.06,
                                  top: imageSize * 0.565,
                                  height: imageSize * 0.145,
                                  child: _buildAnimatedName(
                                    imageSize,
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
              },
            );
          },
        ),
      ),
    );
  }
}