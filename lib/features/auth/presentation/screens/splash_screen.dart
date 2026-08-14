import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import 'onboarding_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // ── Background fade-in ───────────────────────────────────────────────────
  late AnimationController _bgCtrl;
  late Animation<double> _bgFade;

  // ── Logo entrance ────────────────────────────────────────────────────────
  late AnimationController _logoEntryCtrl;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;

  // ── Heartbeat (lub-dub) ──────────────────────────────────────────────────
  late AnimationController _heartbeatCtrl;
  late Animation<double> _heartScale;

  // ── Ripple rings ─────────────────────────────────────────────────────────
  late AnimationController _ripple1Ctrl;
  late Animation<double> _ripple1Scale;
  late Animation<double> _ripple1Opacity;

  late AnimationController _ripple2Ctrl;
  late Animation<double> _ripple2Scale;
  late Animation<double> _ripple2Opacity;

  // ── Text reveal ──────────────────────────────────────────────────────────
  late AnimationController _textCtrl;
  late Animation<double> _nameOpacity;
  late Animation<Offset> _nameSlide;
  late Animation<double> _taglineOpacity;

  // ── Subtle idle float ────────────────────────────────────────────────────
  late AnimationController _floatCtrl;
  late Animation<double> _float;

  bool _isNavigating = false;
  bool _animationComplete = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _runSequence();
  }

  void _setupAnimations() {
    // Background
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _bgFade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _bgCtrl, curve: Curves.easeIn));

    // Logo entry
    _logoEntryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _logoFade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _logoEntryCtrl, curve: Curves.easeOut));
    _logoScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _logoEntryCtrl, curve: Curves.easeOutBack),
    );

    // Heartbeat: lub (big) → dub (smaller) using TweenSequence
    _heartbeatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _heartScale = TweenSequence<double>([
      // Lub — quick expand
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.12,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      // Return
      TweenSequenceItem(
        tween: Tween(
          begin: 1.12,
          end: 0.97,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15,
      ),
      // Dub — smaller expand
      TweenSequenceItem(
        tween: Tween(
          begin: 0.97,
          end: 1.06,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      // Settle back
      TweenSequenceItem(
        tween: Tween(
          begin: 1.06,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 45,
      ),
    ]).animate(_heartbeatCtrl);

    // Ripple 1 — triggered on lub
    _ripple1Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _ripple1Scale = Tween<double>(
      begin: 0.6,
      end: 2.2,
    ).animate(CurvedAnimation(parent: _ripple1Ctrl, curve: Curves.easeOut));
    _ripple1Opacity = Tween<double>(
      begin: 0.55,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _ripple1Ctrl, curve: Curves.easeOut));

    // Ripple 2 — slightly delayed, triggered on dub
    _ripple2Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _ripple2Scale = Tween<double>(
      begin: 0.6,
      end: 1.8,
    ).animate(CurvedAnimation(parent: _ripple2Ctrl, curve: Curves.easeOut));
    _ripple2Opacity = Tween<double>(
      begin: 0.40,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _ripple2Ctrl, curve: Curves.easeOut));

    // Text reveal: name + tagline staggered
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _nameOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _textCtrl,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
      ),
    );
    _nameSlide = Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _textCtrl,
            curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
          ),
        );
    _taglineOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _textCtrl,
        curve: const Interval(0.45, 1.0, curve: Curves.easeIn),
      ),
    );

    // Idle float after everything settles
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _float = Tween<double>(
      begin: -15,
      end: 15,
    ).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
  }

  Future<void> _runSequence() async {
    // 0.00s — background appears
    _bgCtrl.forward();

    // 0.15s — logo fades/scales in
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    _logoEntryCtrl.forward();

    // 0.40s — first heartbeat (lub)
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    _heartbeatCtrl.forward();
    _ripple1Ctrl.forward(); // ripple fires with lub

    // 0.65s — second ripple fires with dub
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    _ripple2Ctrl.forward();

    // 1.35s — "SplitNest" begins appearing
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    _textCtrl.forward();

    // 1.8s — hold completed splash, then navigate
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    setState(() => _animationComplete = true);
    _checkNavigation();
  }

  void _checkNavigation() async {
    if (!mounted || _isNavigating || !_animationComplete) return;

    final authState = ref.read(authNotifierProvider);
    if (authState.isLoading) return;

    _isNavigating = true;

    // Graceful hold before navigating
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    final user = authState.user;
    if (user != null) {
      // Already logged in → go to home
      if (user.activeNestId == null) {
        context.go('/welcome');
      } else {
        context.go('/dashboard');
      }
    } else {
      final hasSeenOnboarding = await OnboardingService.hasCompleted();
      if (!mounted) return;
      if (hasSeenOnboarding) {
        context.go('/login');
      } else {
        context.go('/onboarding');
      }
    }
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _logoEntryCtrl.dispose();
    _heartbeatCtrl.dispose();
    _ripple1Ctrl.dispose();
    _ripple2Ctrl.dispose();
    _textCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // React to auth state changes
    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      if (!next.isLoading) _checkNavigation();
    });

    final size = MediaQuery.of(context).size;
    final logoSize = size.width * 0.60;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      body: FadeTransition(
        opacity: _bgFade,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: [
                Color(0xFFFEFCFF), // Near-white center
                Color(0xFFF0E9FF), // Soft lavender edge
              ],
              stops: [0.0, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Logo + Ripple Stack ─────────────────────────────────────
                AnimatedBuilder(
                  animation: _floatCtrl,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, _float.value),
                    child: child,
                  ),
                  child: SizedBox(
                    width: logoSize + 80,
                    height: logoSize + 80,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // ── Ripple 1 (outer, triggered with lub) ───────────
                        AnimatedBuilder(
                          animation: _ripple1Ctrl,
                          builder: (context, _) => Opacity(
                            opacity: _ripple1Opacity.value,
                            child: Transform.scale(
                              scale: _ripple1Scale.value,
                              child: Container(
                                width: logoSize,
                                height: logoSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF7B61FF),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // ── Ripple 2 (inner, triggered with dub) ───────────
                        AnimatedBuilder(
                          animation: _ripple2Ctrl,
                          builder: (context, _) => Opacity(
                            opacity: _ripple2Opacity.value,
                            child: Transform.scale(
                              scale: _ripple2Scale.value,
                              child: Container(
                                width: logoSize * 0.8,
                                height: logoSize * 0.8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(
                                    0xFF7B61FF,
                                  ).withValues(alpha: 0.08),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // ── Ambient glow (always visible, soft) ────────────
                        Container(
                          width: logoSize * 0.85,
                          height: logoSize * 0.85,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF7B61FF,
                                ).withValues(alpha: 0.14),
                                blurRadius: 60,
                                spreadRadius: 12,
                              ),
                            ],
                          ),
                        ),

                        // ── S Logo (heartbeat scale, on top) ───────────────
                        AnimatedBuilder(
                          animation: Listenable.merge([
                            _logoEntryCtrl,
                            _heartbeatCtrl,
                          ]),
                          builder: (context, child) {
                            final entryScale = _logoScale.value;
                            final hbScale = _heartbeatCtrl.isAnimating
                                ? _heartScale.value
                                : 1.0;
                            return FadeTransition(
                              opacity: _logoFade,
                              child: Transform.scale(
                                scale: entryScale * hbScale,
                                child: child,
                              ),
                            );
                          },
                          child: Image.asset(
                            'assets/images/app_icon.png',
                            width: logoSize,
                            height: logoSize,
                            fit: BoxFit.contain,
                            // PNG is transparent — no color/filter applied
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Brand Name & Tagline ────────────────────────────────────
                FadeTransition(
                  opacity: _nameOpacity,
                  child: SlideTransition(
                    position: _nameSlide,
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Split',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          TextSpan(
                            text: 'Nest',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF7B61FF),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                FadeTransition(
                  opacity: _taglineOpacity,
                  child: const Text(
                    'Split Smart, Live Easy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
