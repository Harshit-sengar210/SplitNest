import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Onboarding State Service
// ─────────────────────────────────────────────────────────────────────────────
class OnboardingService {
  static const String _key = 'hasCompletedOnboarding';

  static Future<bool> hasCompleted() async {
    // Temporarily always return false so you can test the onboarding screen!
    return false;
  }

  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main OnboardingScreen Widget
// ─────────────────────────────────────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _goNext() {
    if (_currentPage == 0) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    await OnboardingService.markCompleted();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      body: Stack(
        children: [
          // Soft gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFDFBFF), Color(0xFFEFE9FF)],
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // PageView — takes remaining space
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) =>
                        setState(() => _currentPage = index),
                    children: const [_OnboardingPage1(), _OnboardingPage2()],
                  ),
                ),

                // Bottom bar (indicators + button)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Dot indicators
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(2, (index) {
                            final isActive = _currentPage == index;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 6,
                              width: isActive ? 28 : 6,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: isActive
                                    ? const Color(0xFF7B61FF)
                                    : const Color(
                                        0xFF7B61FF,
                                      ).withValues(alpha: 0.2),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 24),
                        // CTA Button
                        _AnimatedCTAButton(
                          label: _currentPage == 0 ? 'Continue' : 'Get Started',
                          onPressed: _goNext,
                        ),
                      ],
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Page 1 — Split Expenses. Stay Together.
// ─────────────────────────────────────────────────────────────────────────────
class _OnboardingPage1 extends StatefulWidget {
  const _OnboardingPage1();

  @override
  State<_OnboardingPage1> createState() => _OnboardingPage1State();
}

class _OnboardingPage1State extends State<_OnboardingPage1>
    with TickerProviderStateMixin {
  late AnimationController _bgCtrl;
  late AnimationController _illustCtrl;
  late AnimationController _textCtrl;
  late AnimationController _floatCtrl;

  late Animation<double> _bgFade;
  late Animation<double> _illustScale;
  late Animation<double> _illustFade;
  late Animation<double> _headlineFade;
  late Animation<Offset> _headlineSlide;
  late Animation<double> _descFade;
  late Animation<double> _float;

  @override
  void initState() {
    super.initState();

    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _illustCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _bgFade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _bgCtrl, curve: Curves.easeIn));

    _illustScale = Tween<double>(
      begin: 0.88,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _illustCtrl, curve: Curves.easeOutCubic));
    _illustFade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _illustCtrl, curve: Curves.easeIn));

    _headlineFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _textCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    _headlineSlide =
        Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _textCtrl,
            curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
          ),
        );
    _descFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _textCtrl,
        curve: const Interval(0.3, 0.75, curve: Curves.easeIn),
      ),
    );

    _float = Tween<double>(
      begin: -6,
      end: 6,
    ).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _runSequence();
  }

  Future<void> _runSequence() async {
    _bgCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    _illustCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 350));
    _textCtrl.forward();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _illustCtrl.dispose();
    _textCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final safeTop = MediaQuery.of(context).padding.top;

    return FadeTransition(
      opacity: _bgFade,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Hero image — fills upper portion edge-to-edge ──────────────
          Expanded(
            flex: 11,
            child: Padding(
              padding: EdgeInsets.only(top: safeTop + 12),
              child: AnimatedBuilder(
                animation: Listenable.merge([_illustCtrl, _floatCtrl]),
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _illustFade,
                    child: Transform.scale(
                      scale: _illustScale.value,
                      child: Transform.translate(
                        offset: Offset(0, _float.value),
                        child: child,
                      ),
                    ),
                  );
                },
                child: _buildIllustration1(size),
              ),
            ),
          ),

          // ── Text section ───────────────────────────────────────────────
          Expanded(
            flex: 9,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Headline
                  FadeTransition(
                    opacity: _headlineFade,
                    child: SlideTransition(
                      position: _headlineSlide,
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'Split Expenses.\n',
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                                height: 1.2,
                                letterSpacing: -0.5,
                              ),
                            ),
                            TextSpan(
                              text: 'Stay Together.',
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF7B61FF),
                                height: 1.2,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Description
                  FadeTransition(
                    opacity: _descFade,
                    child: const Text(
                      'Share expenses, split bills and keep everyone on the same page — without the awkward math.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF64748B),
                        height: 1.55,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIllustration1(Size size) {
    // Fill available width, let the image breathe naturally
    final imgW = size.width;
    final imgH = size.height * 0.52;
    return SizedBox(
      width: imgW,
      height: imgH,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft lavender atmospheric glow
          Container(
            width: imgW * 0.75,
            height: imgH * 0.75,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7B61FF).withValues(alpha: 0.20),
                  blurRadius: 80,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),
          // Hero image — edge-to-edge, no box frame
          Image.asset(
            'assets/images/onboarding_hero.jpg',
            width: imgW,
            height: imgH,
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page 2 — All your expenses. One clear view.
// ─────────────────────────────────────────────────────────────────────────────
class _OnboardingPage2 extends StatefulWidget {
  const _OnboardingPage2();

  @override
  State<_OnboardingPage2> createState() => _OnboardingPage2State();
}

class _OnboardingPage2State extends State<_OnboardingPage2>
    with TickerProviderStateMixin {
  late AnimationController _illustCtrl;
  late AnimationController _textCtrl;
  late AnimationController _featuresCtrl;
  late AnimationController _floatCtrl;

  late Animation<double> _illustFade;
  late Animation<double> _illustScale;
  late Animation<double> _headlineFade;
  late Animation<Offset> _headlineSlide;
  late Animation<double> _descFade;
  late Animation<double> _float;

  late Animation<double> _feature1Fade;
  late Animation<Offset> _feature1Slide;
  late Animation<double> _feature2Fade;
  late Animation<Offset> _feature2Slide;
  late Animation<double> _feature3Fade;
  late Animation<Offset> _feature3Slide;
  late Animation<double> _feature4Fade;
  late Animation<Offset> _feature4Slide;

  @override
  void initState() {
    super.initState();

    _illustCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _featuresCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _illustFade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _illustCtrl, curve: Curves.easeIn));
    _illustScale = Tween<double>(
      begin: 0.88,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _illustCtrl, curve: Curves.easeOutCubic));

    _headlineFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _textCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    _headlineSlide =
        Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _textCtrl,
            curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
          ),
        );
    _descFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _textCtrl,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    _feature1Fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _featuresCtrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );
    _feature1Slide =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _featuresCtrl,
            curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
          ),
        );
    _feature2Fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _featuresCtrl,
        curve: const Interval(0.2, 0.6, curve: Curves.easeIn),
      ),
    );
    _feature2Slide =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _featuresCtrl,
            curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),
          ),
        );
    _feature3Fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _featuresCtrl,
        curve: const Interval(0.4, 0.8, curve: Curves.easeIn),
      ),
    );
    _feature3Slide =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _featuresCtrl,
            curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
          ),
        );
    _feature4Fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _featuresCtrl,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );
    _feature4Slide =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _featuresCtrl,
            curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _float = Tween<double>(
      begin: -5,
      end: 5,
    ).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _runSequence();
  }

  Future<void> _runSequence() async {
    _illustCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _featuresCtrl.forward();
  }

  @override
  void dispose() {
    _illustCtrl.dispose();
    _textCtrl.dispose();
    _featuresCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Larger image + scrollable so feature rows never overflow
    final imageH = size.height * 0.35;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Hero image ──────────────────────────────────────────────────
          AnimatedBuilder(
            animation: Listenable.merge([_illustCtrl, _floatCtrl]),
            builder: (context, child) => FadeTransition(
              opacity: _illustFade,
              child: Transform.scale(
                scale: _illustScale.value,
                child: Transform.translate(
                  offset: Offset(0, _float.value),
                  child: child,
                ),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Lavender glow
                Container(
                  width: size.width * 0.75,
                  height: imageH,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7B61FF).withValues(alpha: 0.22),
                        blurRadius: 70,
                        spreadRadius: 12,
                      ),
                    ],
                  ),
                ),
                ShaderMask(
                  shaderCallback: (bounds) => const RadialGradient(
                    center: Alignment.center,
                    radius: 0.5,
                    colors: [Colors.black, Colors.transparent],
                    stops: [0.65, 1.0],
                  ).createShader(bounds),
                  blendMode: BlendMode.dstIn,
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                      Color(0xFFF8F5FF),
                      BlendMode.multiply,
                    ),
                    child: Image.asset(
                      'assets/images/onboarding_hero_2.jpg',
                      height: imageH,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Headline ────────────────────────────────────────────────────
          FadeTransition(
            opacity: _headlineFade,
            child: SlideTransition(
              position: _headlineSlide,
              child: Column(
                children: [
                  const Text(
                    'All your expenses.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      height: 1.15,
                      letterSpacing: -0.5,
                    ),
                  ),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF9B84FF), Color(0xFF7B61FF)],
                    ).createShader(bounds),
                    child: const Text(
                      'One clear view.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.15,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Description ─────────────────────────────────────────────────
          FadeTransition(
            opacity: _descFade,
            child: const Text(
              'Track, split and settle expenses effortlessly with friends, family or anyone you share with.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Feature rows ────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7B61FF).withValues(alpha: 0.07),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _AnimatedFeatureRow(
                      fade: _feature1Fade,
                      slide: _feature1Slide,
                      icon: Icons.group_work_rounded,
                      iconColor: const Color(0xFF7B61FF),
                      iconBg: const Color(0xFFEDE9FF),
                      title: 'Create Nests',
                      subtitle: 'Add members and start splitting instantly.',
                      showDivider: true,
                    ),
                    _AnimatedFeatureRow(
                      fade: _feature2Fade,
                      slide: _feature2Slide,
                      icon: Icons.add_circle_outline_rounded,
                      iconColor: const Color(0xFF10B981),
                      iconBg: const Color(0xFFD1FAE5),
                      title: 'Add Expenses',
                      subtitle: 'Add expenses on the go in just a few taps.',
                      showDivider: true,
                    ),
                    _AnimatedFeatureRow(
                      fade: _feature3Fade,
                      slide: _feature3Slide,
                      icon: Icons.account_balance_wallet_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      iconBg: const Color(0xFFFEF3C7),
                      title: 'Track Balances',
                      subtitle: 'See who owes, who pays and your net balance.',
                      showDivider: true,
                    ),
                    _AnimatedFeatureRow(
                      fade: _feature4Fade,
                      slide: _feature4Slide,
                      icon: Icons.check_circle_outline_rounded,
                      iconColor: const Color(0xFF3B82F6),
                      iconBg: const Color(0xFFDBEAFE),
                      title: 'Settle Up Easily',
                      subtitle: 'Smart suggestions to settle up in one click.',
                      showDivider: false,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated Feature Row
// ─────────────────────────────────────────────────────────────────────────────
class _AnimatedFeatureRow extends StatelessWidget {
  final Animation<double> fade;
  final Animation<Offset> slide;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final bool showDivider;

  const _AnimatedFeatureRow({
    required this.fade,
    required this.slide,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(icon, color: iconColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF94A3B8),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (showDivider)
              const Divider(
                height: 1,
                indent: 72,
                endIndent: 16,
                color: Color(0xFFF1F5F9),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated CTA Button
// ─────────────────────────────────────────────────────────────────────────────
class _AnimatedCTAButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;

  const _AnimatedCTAButton({required this.label, required this.onPressed});

  @override
  State<_AnimatedCTAButton> createState() => _AnimatedCTAButtonState();
}

class _AnimatedCTAButtonState extends State<_AnimatedCTAButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _pressScale = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) async {
        await _pressCtrl.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _pressCtrl,
        builder: (context, child) =>
            Transform.scale(scale: _pressScale.value, child: child),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF9B84FF), Color(0xFF7B61FF)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7B61FF).withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Row(
                key: ValueKey(widget.label),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  if (widget.label == 'Get Started') ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
