import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/animations/custom_cursor.dart';
import '../widgets/animations/cursor_provider.dart';

class WebsiteHowItWorksScreen extends StatefulWidget {
  const WebsiteHowItWorksScreen({Key? key}) : super(key: key);

  @override
  State<WebsiteHowItWorksScreen> createState() => _WebsiteHowItWorksScreenState();
}

class _WebsiteHowItWorksScreenState extends State<WebsiteHowItWorksScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomCursorWrapper(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            children: [
              const SizedBox(height: 140), // Space for floating navbar
              _HeroSection(isDesktop: isDesktop),
              const SizedBox(height: 100),
              _FourStepJourneySection(isDesktop: isDesktop),
              const SizedBox(height: 100),
              _BenefitsStripSection(isDesktop: isDesktop),
              const SizedBox(height: 160),
              _PhoneShowcaseSection(isDesktop: isDesktop),
              const SizedBox(height: 160),
              _StatsAndFeaturesSection(isDesktop: isDesktop),
              const SizedBox(height: 160),
              _DashboardSection(isDesktop: isDesktop),
              const SizedBox(height: 160),
              _TestimonialSection(isDesktop: isDesktop),
              const SizedBox(height: 160),
              _FinalCtaSection(isDesktop: isDesktop),
              _FooterSection(isDesktop: isDesktop),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 1. HERO SECTION
// ============================================================================
class _HeroSection extends StatelessWidget {
  final bool isDesktop;
  const _HeroSection({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 100 : 24),
      child: isDesktop
          ? Row(
              children: [
                Expanded(flex: 5, child: _buildText(context)),
                Expanded(flex: 7, child: _build3DAsset(size)),
              ],
            )
          : Column(
              children: [
                _buildText(context, isMobile: true),
                const SizedBox(height: 64),
                _build3DAsset(size, isMobile: true),
              ],
            ),
    );
  }

  Widget _buildText(BuildContext context, {bool isMobile = false}) {
    return Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: const Color(0xFFE2E8F0).withOpacity(0.5), borderRadius: BorderRadius.circular(100)),
          child: Text('HOW IT WORKS', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 1)),
        ),
        const SizedBox(height: 24),
        RichText(
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          text: TextSpan(
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 48 : 72,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              letterSpacing: -2.5,
              height: 1.1,
            ),
            children: [
              const TextSpan(text: 'Four steps to\n'),
              WidgetSpan(
                child: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFF7B61FF), Color(0xFF4F46E5)]).createShader(bounds),
                  child: Text('financial peace.', style: GoogleFonts.plusJakartaSans(fontSize: isMobile ? 48 : 72, fontWeight: FontWeight.w800, letterSpacing: -2.5, height: 1.1)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "Split expenses. Track everything. Settle up easily.",
          style: GoogleFonts.plusJakartaSans(fontSize: isMobile ? 18 : 24, color: const Color(0xFF475569), height: 1.6),
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
        ),
      ],
    );
  }

  Widget _build3DAsset(Size size, {bool isMobile = false}) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: isMobile ? size.width * 0.8 : 600,
            height: isMobile ? size.width * 0.8 : 600,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [const Color(0xFF7B61FF).withOpacity(0.15), Colors.transparent]),
            ),
          ),
          _FloatingAnimation(
            child: Image.asset(
              'assets/images/3d_premium_nest_v2.png',
              width: isMobile ? size.width * 0.9 : 700,
              fit: BoxFit.contain,
              errorBuilder: (c,e,s) => const Icon(Icons.account_balance_wallet, size: 100, color: Color(0xFF7B61FF)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingAnimation extends StatefulWidget {
  final Widget child;
  const _FloatingAnimation({required this.child});
  @override
  State<_FloatingAnimation> createState() => _FloatingAnimationState();
}

class _FloatingAnimationState extends State<_FloatingAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.translate(offset: Offset(0, _controller.value * 20 - 10), child: widget.child),
    );
  }
}

// ============================================================================
// 2. FOUR STEP JOURNEY
// ============================================================================
class _FourStepJourneySection extends StatelessWidget {
  final bool isDesktop;
  const _FourStepJourneySection({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 100 : 24),
      child: isDesktop
          ? Stack(
              alignment: Alignment.center,
              children: [
                Positioned(top: 60, left: 100, right: 100, child: Container(height: 2, color: const Color(0xFFE2E8F0))),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildStep('01', Icons.home_rounded, 'Create a Nest', 'Start by creating a Nest for your household, a vacation, or a night out.', const Color(0xFF7B61FF))),
                    Expanded(child: _buildStep('02', Icons.group_add_rounded, 'Add Friends', 'Invite your friends to the Nest. They can join instantly via link.', const Color(0xFF10B981))),
                    Expanded(child: _buildStep('03', Icons.receipt_long_rounded, 'Log Expenses', 'Add expenses as they happen. Split equally, by exact amounts, or percentages.', const Color(0xFFF59E0B))),
                    Expanded(child: _buildStep('04', Icons.check_circle_rounded, 'Settle Up', 'We calculate the simplest way for everyone to pay each other back.', const Color(0xFF3B82F6))),
                  ],
                ),
              ],
            )
          : Column(
              children: [
                _buildStep('01', Icons.home_rounded, 'Create a Nest', 'Start by creating a Nest for your household, a vacation, or a night out.', const Color(0xFF7B61FF)),
                const SizedBox(height: 48),
                _buildStep('02', Icons.group_add_rounded, 'Add Friends', 'Invite your friends to the Nest. They can join instantly via link.', const Color(0xFF10B981)),
                const SizedBox(height: 48),
                _buildStep('03', Icons.receipt_long_rounded, 'Log Expenses', 'Add expenses as they happen. Split equally, by exact amounts, or percentages.', const Color(0xFFF59E0B)),
                const SizedBox(height: 48),
                _buildStep('04', Icons.check_circle_rounded, 'Settle Up', 'We calculate the simplest way for everyone to pay each other back.', const Color(0xFF3B82F6)),
              ],
            ),
    );
  }

  Widget _buildStep(String num, IconData icon, String title, String desc, Color color) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.topLeft,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: color.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 10))],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(width: 60, height: 60, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.1))),
                  Icon(icon, color: color, size: 32),
                ],
              ),
            ),
            Positioned(
              top: -5,
              left: -5,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Center(child: Text(num, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 10))),
              ),
            )
          ],
        ),
        const SizedBox(height: 32),
        Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)), textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(desc, style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF64748B), height: 1.5), textAlign: TextAlign.center),
        ),
      ],
    );
  }
}

// ============================================================================
// 3. BENEFITS STRIP
// ============================================================================
class _BenefitsStripSection extends StatelessWidget {
  final bool isDesktop;
  const _BenefitsStripSection({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 100 : 24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)],
        ),
        child: isDesktop
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: _buildBenefit(Icons.verified_user_rounded, 'Simple & Transparent', 'Everyone sees everything. No hidden surprises.', const Color(0xFF7B61FF))),
                  Container(height: 60, width: 1, color: const Color(0xFFF1F5F9)),
                  Expanded(child: _buildBenefit(Icons.lock_rounded, 'Automatic Calculations', 'No manual math. We do it for you.', const Color(0xFF10B981))),
                  Container(height: 60, width: 1, color: const Color(0xFFF1F5F9)),
                  Expanded(child: _buildBenefit(Icons.notifications_active_rounded, 'Real-time Updates', 'Instant notifications for every activity.', const Color(0xFFF59E0B))),
                  Container(height: 60, width: 1, color: const Color(0xFFF1F5F9)),
                  Expanded(child: _buildBenefit(Icons.pie_chart_rounded, 'Smart Insights', 'Understand spending patterns across Nests.', const Color(0xFF3B82F6))),
                ],
              )
            : Column(
                children: [
                  _buildBenefit(Icons.verified_user_rounded, 'Simple & Transparent', 'Everyone sees everything. No hidden surprises.', const Color(0xFF7B61FF)),
                  const SizedBox(height: 24),
                  _buildBenefit(Icons.lock_rounded, 'Automatic Calculations', 'No manual math. We do it for you.', const Color(0xFF10B981)),
                  const SizedBox(height: 24),
                  _buildBenefit(Icons.notifications_active_rounded, 'Real-time Updates', 'Instant notifications for every activity.', const Color(0xFFF59E0B)),
                  const SizedBox(height: 24),
                  _buildBenefit(Icons.pie_chart_rounded, 'Smart Insights', 'Understand spending patterns across Nests.', const Color(0xFF3B82F6)),
                ],
              ),
      ),
    );
  }

  Widget _buildBenefit(IconData icon, String title, String subtitle, Color color) {
    return _HoverScaleCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: const Color(0xFF0F172A), fontSize: 14)),
                  Text(subtitle, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 12, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HoverScaleCard extends StatefulWidget {
  final Widget child;
  const _HoverScaleCard({required this.child});
  @override
  State<_HoverScaleCard> createState() => _HoverScaleCardState();
}

class _HoverScaleCardState extends State<_HoverScaleCard> {
  bool _isHovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..translate(0.0, _isHovered ? -5.0 : 0.0, 0.0),
        child: widget.child,
      ),
    );
  }
}

// ============================================================================
// 4. PHONE SHOWCASE SECTION
// ============================================================================
class _PhoneShowcaseSection extends StatelessWidget {
  final bool isDesktop;
  const _PhoneShowcaseSection({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 100 : 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFF7B61FF).withOpacity(0.1), borderRadius: BorderRadius.circular(100)),
            child: Text('SEE IT IN ACTION', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF7B61FF), fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 1)),
          ),
          const SizedBox(height: 24),
          isDesktop
              ? Row(
                  children: [
                    Expanded(flex: 5, child: _buildText(context)),
                    Expanded(flex: 7, child: _InteractivePhoneShowcase(isDesktop: isDesktop)),
                  ],
                )
              : Column(
                  children: [
                    _buildText(context, isMobile: true),
                    const SizedBox(height: 64),
                    _InteractivePhoneShowcase(isDesktop: isDesktop),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildText(BuildContext context, {bool isMobile = false}) {
    return Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          'All your shared expenses, in one beautiful place.',
          style: GoogleFonts.plusJakartaSans(fontSize: isMobile ? 36 : 48, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), letterSpacing: -1.5, height: 1.1),
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
        ),
        const SizedBox(height: 24),
        Text(
          'Track balances, view transactions, and settle up without the awkward conversation.',
          style: GoogleFonts.plusJakartaSans(fontSize: 18, color: const Color(0xFF475569), height: 1.6),
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
        ),
        const SizedBox(height: 48),
        _buildBullet('Real-time balance updates'),
        const SizedBox(height: 16),
        _buildBullet('See who owes and who you owe'),
        const SizedBox(height: 16),
        _buildBullet('Detailed activity history'),
        const SizedBox(height: 16),
        _buildBullet('Secure & private'),
        const SizedBox(height: 48),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7B61FF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Explore the App', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, size: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBullet(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(color: Color(0xFF7B61FF), shape: BoxShape.circle),
          child: const Icon(Icons.check, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 16),
        Text(text, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _InteractivePhoneShowcase extends StatefulWidget {
  final bool isDesktop;
  const _InteractivePhoneShowcase({required this.isDesktop});

  @override
  State<_InteractivePhoneShowcase> createState() => _InteractivePhoneShowcaseState();
}

class _InteractivePhoneShowcaseState extends State<_InteractivePhoneShowcase> with SingleTickerProviderStateMixin {
  Offset _mousePosition = Offset.zero;
  late AnimationController _idleController;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _idleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = widget.isDesktop ? 700.0 : size.width * 0.9;
    final height = 650.0;

    return MouseRegion(
      onHover: (event) => setState(() => _mousePosition = event.localPosition),
      onExit: (_) => setState(() => _mousePosition = Offset.zero),
      child: SizedBox(
        width: width,
        height: height,
        child: AnimatedBuilder(
          animation: _idleController,
          builder: (context, child) {
            final idleOffset = _idleController.value * 20.0;
            final centerX = width / 2;
            final centerY = height / 2;
            final rotateX = _mousePosition == Offset.zero ? 0.05 : ((_mousePosition.dy - centerY) / centerY) * 0.15;
            final rotateY = _mousePosition == Offset.zero ? -0.1 : ((_mousePosition.dx - centerX) / centerX) * -0.15;

            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  child: ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container(width: 400, height: 400, decoration: BoxDecoration(color: const Color(0xFF7B61FF).withOpacity(0.1), shape: BoxShape.circle))),
                ),
                
                // Native Phone
                Transform(
                  alignment: FractionalOffset.center,
                  transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateX(rotateX)..rotateY(rotateY)..translate(0.0, -idleOffset * 0.5, 0.0),
                  child: _buildNativePhoneMockup(),
                ),

                // Floating Assets
                Positioned(
                  right: widget.isDesktop ? 0 : 20,
                  top: height * 0.2,
                  child: Transform(
                    transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateX(rotateX * 1.5)..rotateY(rotateY * 1.5)..translate(rotateY * -40, rotateX * -40, 0.0),
                    child: _buildAvatarStack(),
                  ),
                ),
                Positioned(
                  left: widget.isDesktop ? 50 : 20,
                  bottom: height * 0.3,
                  child: Transform(
                    transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateX(rotateX * 0.8)..rotateY(rotateY * 0.8)..translate(rotateY * 60, rotateX * 60, 0.0),
                    child: Image.asset('assets/images/3d_coins.png', width: 80, errorBuilder: (c,e,s) => const SizedBox()),
                  ),
                ),
                Positioned(
                  right: widget.isDesktop ? 50 : 20,
                  bottom: height * 0.1,
                  child: Transform(
                    transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateX(rotateX * 1.2)..rotateY(rotateY * 1.2)..translate(rotateY * -80, rotateX * -80, 0.0),
                    child: Image.asset('assets/images/3d_purple_camera.png', width: 120, errorBuilder: (c,e,s) => const SizedBox()),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAvatarStack() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(100), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAvatarMock(Colors.blue),
          const SizedBox(height: 8),
          _buildAvatarMock(Colors.purple),
          const SizedBox(height: 8),
          _buildAvatarMock(Colors.orange),
          const SizedBox(height: 8),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), shape: BoxShape.circle),
            child: Center(child: Text('+3', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold))),
          )
        ],
      ),
    );
  }

  Widget _buildAvatarMock(Color color) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
      child: Icon(Icons.person, color: color, size: 20),
    );
  }

  Widget _buildNativePhoneMockup() {
    return Container(
      width: 320,
      height: 600,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(48),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 40, offset: const Offset(20, 20)),
          BoxShadow(color: const Color(0xFF7B61FF).withOpacity(0.15), blurRadius: 60, offset: const Offset(-20, -20)),
        ],
        border: Border.all(color: const Color(0xFF334155), width: 3),
      ),
      padding: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Container(
          color: const Color(0xFF0F172A),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF1E293B)))),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Goa Trip 2026', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('7 members', style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(24)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Balance', style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('₹ 4,250.00', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3))),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('You will receive', style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text('₹ 2,500.00', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF10B981), fontSize: 24, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3))),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('You need to pay', style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text('₹ 850.00', style: GoogleFonts.plusJakartaSans(color: const Color(0xFFEF4444), fontSize: 24, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 5. STATS AND WHY SPLITNEST
// ============================================================================
class _StatsAndFeaturesSection extends StatelessWidget {
  final bool isDesktop;
  const _StatsAndFeaturesSection({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 100 : 24),
      child: Column(
        children: [
          // Stat Cards
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: [
              _buildStatCard('50,000+', 'Active Groups', Icons.group_rounded, const Color(0xFF10B981)),
              _buildStatCard('1.2M+', 'Expenses Added', Icons.receipt_long_rounded, const Color(0xFF7B61FF)),
              _buildStatCard('3.6M+', 'Transactions', Icons.pie_chart_rounded, const Color(0xFFF59E0B)),
              _buildStatCard('99.9%', 'Happy Users', Icons.trending_up_rounded, const Color(0xFF3B82F6)),
            ],
          ),
          const SizedBox(height: 160),
          
          // Why SplitNest
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFE2E8F0).withOpacity(0.5), borderRadius: BorderRadius.circular(100)),
            child: Text('WHY SPLITNEST?', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 1)),
          ),
          const SizedBox(height: 24),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.plusJakartaSans(fontSize: isDesktop ? 48 : 32, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), letterSpacing: -1.5, height: 1.1),
              children: [
                const TextSpan(text: 'Because sharing money\n'),
                WidgetSpan(
                  child: ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFF7B61FF), Color(0xFF4F46E5)]).createShader(bounds),
                    child: Text('should be easy.', style: GoogleFonts.plusJakartaSans(fontSize: isDesktop ? 48 : 32, fontWeight: FontWeight.w800, letterSpacing: -1.5, height: 1.1)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'We built SplitNest to remove the stress from shared expenses.',
            style: GoogleFonts.plusJakartaSans(fontSize: 18, color: const Color(0xFF475569)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 64),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: [
              _buildFeatureCard('Privacy First', 'Your data is yours. We keep it private and secure.', Icons.security_rounded, const Color(0xFF7B61FF)),
              _buildFeatureCard('Lightning Fast', 'Add expenses and see balances update in real time.', Icons.bolt_rounded, const Color(0xFF10B981)),
              _buildFeatureCard('Works Anywhere', 'Use SplitNest on all your devices, anytime, anywhere.', Icons.devices_rounded, const Color(0xFFF59E0B)),
              _buildFeatureCard('Made for Groups', 'Whether it\'s 3 people or 30, everyone stays on the same page.', Icons.groups_rounded, const Color(0xFF3B82F6)),
              _buildFeatureCard('Smart Reports', 'Understand spending patterns and make better decisions.', Icons.pie_chart_outline_rounded, const Color(0xFF10B981)),
              _buildFeatureCard('We\'re Here', 'Need help? Our support team is always ready.', Icons.headset_mic_rounded, const Color(0xFFF59E0B)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
              Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF64748B))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(String title, String desc, IconData icon, Color color) {
    return _HoverScaleCard(
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [color.withOpacity(0.8), color]),
                boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Center(child: Icon(icon, color: Colors.white, size: 36)),
            ),
            const SizedBox(height: 32),
            Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(desc, style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF64748B), height: 1.5), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 6. DASHBOARD SECTION (Categories & Recent Nests)
// ============================================================================
class _DashboardSection extends StatelessWidget {
  final bool isDesktop;
  const _DashboardSection({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 100 : 24),
      child: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildCategories()),
                const SizedBox(width: 48),
                Expanded(flex: 4, child: _buildRecentNests()),
                const SizedBox(width: 48),
                Expanded(flex: 4, child: _buildTopSpending()),
              ],
            )
          : Column(
              children: [
                _buildCategories(),
                const SizedBox(height: 64),
                _buildRecentNests(),
                const SizedBox(height: 64),
                _buildTopSpending(),
              ],
            ),
    );
  }

  // Categories
  Widget _buildCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Popular Nest Categories', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        Text('Pick a category and get started in seconds.', style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 32),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildCategoryCard('Trips & Travel', Icons.flight_takeoff_rounded, Colors.blue),
            _buildCategoryCard('Roommates', Icons.home_rounded, Colors.purple),
            _buildCategoryCard('Family', Icons.family_restroom_rounded, Colors.teal),
            _buildCategoryCard('Events', Icons.cake_rounded, Colors.pink),
            _buildCategoryCard('Couples', Icons.favorite_rounded, Colors.red),
            _buildCategoryCard('Friends', Icons.group_rounded, Colors.indigo),
          ],
        ),
        const SizedBox(height: 32),
        TextButton(onPressed: (){}, child: const Text('Explore all categories →', style: TextStyle(color: Color(0xFF7B61FF)))),
      ],
    );
  }

  Widget _buildCategoryCard(String title, IconData icon, Color color) {
    return _HoverScaleCard(
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF1F5F9))),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  // Recent Nests
  Widget _buildRecentNests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recent Nests', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                Text('Your latest groups and their status.', style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 14)),
              ],
            ),
            TextButton(onPressed: (){}, child: const Text('View all', style: TextStyle(color: Color(0xFF7B61FF)))),
          ],
        ),
        const SizedBox(height: 32),
        _buildNestRow('Goa Trip 2026', 7, '₹ 1,850', true, Icons.landscape_rounded, Colors.blue),
        _buildNestRow('Flatmates', 4, '₹ 920', false, Icons.home_rounded, Colors.orange),
        _buildNestRow('Birthday Bash', 10, '₹ 1,200', true, Icons.cake_rounded, Colors.pink),
        _buildNestRow('Family Grocery', 5, '₹ 470', false, Icons.shopping_cart_rounded, Colors.teal),
      ],
    );
  }

  Widget _buildNestRow(String title, int members, String amount, bool isReceive, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('$members members', style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(isReceive ? 'You will receive' : 'You need to pay', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.grey)),
              Text(amount, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14, color: isReceive ? const Color(0xFF10B981) : const Color(0xFFEF4444))),
            ],
          ),
        ],
      ),
    );
  }

  // Top Spending
  Widget _buildTopSpending() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Top Spending Groups', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(border: Border.all(color: const Color(0xFFF1F5F9)), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Text('This month', style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                  const Icon(Icons.keyboard_arrow_down, size: 16),
                ],
              ),
            )
          ],
        ),
        const SizedBox(height: 48),
        _buildSpendingRow('Trip to Manali', '₹ 12,450', 0.8, Icons.flight, Colors.purple),
        const SizedBox(height: 24),
        _buildSpendingRow('Office Team Lunch', '₹ 8,760', 0.6, Icons.work, Colors.blue),
        const SizedBox(height: 24),
        _buildSpendingRow('Goa Getaway', '₹ 6,840', 0.45, Icons.beach_access, Colors.orange),
        const SizedBox(height: 24),
        _buildSpendingRow('Family Expenses', '₹ 5,230', 0.3, Icons.family_restroom, Colors.teal),
        const SizedBox(height: 24),
        _buildSpendingRow('Weekend Getaway', '₹ 4,120', 0.2, Icons.directions_car, Colors.pink),
      ],
    );
  }

  Widget _buildSpendingRow(String title, String amount, double percent, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 12),
                Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: const Color(0xFF0F172A), fontSize: 14)),
              ],
            ),
            Text(amount, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: const Color(0xFF64748B), fontSize: 14)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 8,
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
          child: Align(
            alignment: Alignment.centerLeft,
            child: _AnimatedProgressBar(percent: percent),
          ),
        )
      ],
    );
  }
}

class _AnimatedProgressBar extends StatefulWidget {
  final double percent;
  const _AnimatedProgressBar({required this.percent});

  @override
  State<_AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<_AnimatedProgressBar> {
  double _width = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _width = 400 * widget.percent);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(seconds: 1),
      curve: Curves.easeOutQuart,
      width: _width,
      decoration: BoxDecoration(color: const Color(0xFF7B61FF), borderRadius: BorderRadius.circular(10)),
    );
  }
}

// ============================================================================
// 7. TESTIMONIAL SECTION
// ============================================================================
class _TestimonialSection extends StatelessWidget {
  final bool isDesktop;
  const _TestimonialSection({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 100 : 24),
      child: isDesktop
          ? Row(
              children: [
                Expanded(child: _buildTestimonialCard()),
                Expanded(child: _buildTestimonialText()),
              ],
            )
          : Column(
              children: [
                _buildTestimonialCard(isMobile: true),
                const SizedBox(height: 48),
                _buildTestimonialText(isMobile: true),
              ],
            ),
    );
  }

  Widget _buildTestimonialCard({bool isMobile = false}) {
    return Container(
      height: 350,
      decoration: BoxDecoration(
        color: const Color(0xFFE0E7FF),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            bottom: 0,
            child: Image.asset(
              'assets/images/3d_avatar_group_testimonial.png',
              width: 350,
              errorBuilder: (c,e,s) => const Icon(Icons.groups, size: 100, color: Color(0xFF7B61FF)),
            ),
          ),
          Positioned(
            top: 32,
            right: 32,
            child: Container(
              padding: const EdgeInsets.all(24),
              width: 280,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.format_quote_rounded, color: Color(0xFF7B61FF), size: 32),
                  const SizedBox(height: 8),
                  Text('SplitNest has made managing group expenses so much easier. No more Excel sheets or confusion!', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold, height: 1.4)),
                  const SizedBox(height: 16),
                  Text('— Ankit, Goa Trip 2025', style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(children: List.generate(5, (index) => const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16))),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTestimonialText({bool isMobile = false}) {
    return Padding(
      padding: EdgeInsets.only(left: isMobile ? 0 : 80),
      child: Column(
        crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFE2E8F0).withOpacity(0.5), borderRadius: BorderRadius.circular(100)),
            child: Text('TRUSTED BY THOUSANDS', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 1)),
          ),
          const SizedBox(height: 24),
          Text(
            'Loved by groups everywhere.',
            style: GoogleFonts.plusJakartaSans(fontSize: isMobile ? 36 : 48, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), letterSpacing: -1.5, height: 1.1),
            textAlign: isMobile ? TextAlign.center : TextAlign.left,
          ),
          const SizedBox(height: 24),
          Text(
            'Real people. Real stories. Real peace of mind.',
            style: GoogleFonts.plusJakartaSans(fontSize: 18, color: const Color(0xFF475569)),
            textAlign: isMobile ? TextAlign.center : TextAlign.left,
          ),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              _buildTrustScore('50,000+', 'Groups'),
              const SizedBox(width: 48),
              _buildTrustScore('4.9/5', 'App Store & Play Store'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTrustScore(String score, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(score, style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
        Text(label, style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 14)),
      ],
    );
  }
}

// ============================================================================
// 8. FINAL CTA & FOOTER
// ============================================================================
class _FinalCtaSection extends StatelessWidget {
  final bool isDesktop;
  const _FinalCtaSection({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: isDesktop ? 100 : 24),
      padding: EdgeInsets.all(isDesktop ? 80 : 32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF7B61FF), Color(0xFF4F46E5)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(48),
        boxShadow: [BoxShadow(color: const Color(0xFF7B61FF).withOpacity(0.4), blurRadius: 40, offset: const Offset(0, 20))],
      ),
      child: isDesktop
          ? Row(
              children: [
                Expanded(child: _buildText(context)),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset('assets/images/3d_premium_nest_v2.png', width: 400, errorBuilder: (c,e,s) => const SizedBox()),
                      Positioned(right: 0, top: 0, child: Image.asset('assets/images/3d_coins.png', width: 100, errorBuilder: (c,e,s) => const SizedBox())),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              children: [
                _buildText(context, isMobile: true),
                const SizedBox(height: 64),
                Image.asset('assets/images/3d_premium_nest_v2.png', width: 300, errorBuilder: (c,e,s) => const SizedBox()),
              ],
            ),
    );
  }

  Widget _buildText(BuildContext context, {bool isMobile = false}) {
    return Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          'Ready to make sharing\nexpenses effortless?',
          style: GoogleFonts.plusJakartaSans(fontSize: isMobile ? 42 : 56, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -2, height: 1.1),
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
        ),
        const SizedBox(height: 24),
        Text(
          'Create your first Nest in less than a minute.',
          style: GoogleFonts.plusJakartaSans(fontSize: 18, color: Colors.white70),
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
        ),
        const SizedBox(height: 48),
        Row(
          mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF7B61FF),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Create a Nest', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  const Icon(Icons.add, size: 20),
                ],
              ),
            ),
            const SizedBox(width: 16),
            TextButton(
              onPressed: () {},
              child: Row(
                children: [
                  Text('Explore Features', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FooterSection extends StatelessWidget {
  final bool isDesktop;
  const _FooterSection({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 80),
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 100 : 24, vertical: 64),
      decoration: const BoxDecoration(color: Color(0xFF0F172A)),
      child: Column(
        children: [
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset('assets/images/splitnest_logo_final.png', height: 40, color: Colors.white, errorBuilder: (c,e,s) => const Icon(Icons.account_balance_wallet, color: Colors.white)),
                      const SizedBox(height: 24),
                      Text('Split expenses, manage ledgers, and live stress-free.', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 14)),
                      const SizedBox(height: 24),
                      Row(
                        children: const [
                          Icon(Icons.camera_alt, color: Colors.white70, size: 20),
                          SizedBox(width: 16),
                          Icon(Icons.link, color: Colors.white70, size: 20),
                          SizedBox(width: 16),
                          Icon(Icons.language, color: Colors.white70, size: 20),
                        ],
                      )
                    ],
                  ),
                ),
                Expanded(child: _buildFooterCol('Product', ['Features', 'How it Works', 'Nests', 'Ledger'])),
                Expanded(child: _buildFooterCol('Company', ['About SplitNest', 'About Cyberlim', 'Careers', 'Blog'])),
                Expanded(child: _buildFooterCol('Support', ['Help Center', 'Contact Us', 'Privacy Policy', 'Terms of Use'])),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset('assets/images/splitnest_logo_final.png', height: 40, color: Colors.white, errorBuilder: (c,e,s) => const Icon(Icons.account_balance_wallet, color: Colors.white)),
                const SizedBox(height: 24),
                Text('Split expenses, manage ledgers, and live stress-free.', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 14)),
                const SizedBox(height: 48),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildFooterCol('Product', ['Features', 'How it Works', 'Nests', 'Ledger'])),
                    Expanded(child: _buildFooterCol('Company', ['About SplitNest', 'About Cyberlim', 'Careers', 'Blog'])),
                  ],
                ),
                const SizedBox(height: 32),
                _buildFooterCol('Support', ['Help Center', 'Contact Us', 'Privacy Policy', 'Terms of Use']),
              ],
            ),
          const SizedBox(height: 64),
          const Divider(color: Color(0xFF1E293B)),
          const SizedBox(height: 32),
          Text('© 2026 SplitNest by Cyberlim. All rights reserved.', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildFooterCol(String title, List<String> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 24),
        ...links.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: CursorRegion(
            cursorState: CursorState.custom,
            customText: e,
            child: Text(e, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 14)),
          ),
        )),
      ],
    );
  }
}
