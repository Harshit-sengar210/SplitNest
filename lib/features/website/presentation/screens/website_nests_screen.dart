import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/animations/custom_cursor.dart';
import '../widgets/animations/cursor_provider.dart';

class WebsiteNestsScreen extends StatefulWidget {
  const WebsiteNestsScreen({Key? key}) : super(key: key);

  @override
  State<WebsiteNestsScreen> createState() => _WebsiteNestsScreenState();
}

class _WebsiteNestsScreenState extends State<WebsiteNestsScreen> {
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
              _NestsHeroSection(isDesktop: isDesktop),
              const SizedBox(height: 140),
              _NestsStatsSection(isDesktop: isDesktop),
              const SizedBox(height: 160),
              _HowNestsWorkSection(isDesktop: isDesktop),
              const SizedBox(height: 160),
              _NestsPhoneShowcase(isDesktop: isDesktop),
              const SizedBox(height: 160),
              _NestsDashboardSection(isDesktop: isDesktop),
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
class _NestsHeroSection extends StatelessWidget {
  final bool isDesktop;
  const _NestsHeroSection({required this.isDesktop});

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
          child: Text('NESTS', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 1)),
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
              const TextSpan(text: 'Shared expenses,\n'),
              WidgetSpan(
                child: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFF7B61FF), Color(0xFF4F46E5)]).createShader(bounds),
                  child: Text('simplified.', style: GoogleFonts.plusJakartaSans(fontSize: isMobile ? 48 : 72, fontWeight: FontWeight.w800, letterSpacing: -2.5, height: 1.1)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "Whether it is an apartment with roommates, a weekend getaway with friends, or shared family expenses, Nests keep everyone on the same page. Add expenses on the go and let SplitNest handle the math automatically.",
          style: GoogleFonts.plusJakartaSans(fontSize: isMobile ? 16 : 18, color: const Color(0xFF475569), height: 1.6),
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
        ),
        const SizedBox(height: 48),
        _buildHighlightFeature(Icons.swap_calls_rounded, 'Flexible Split Rules (Equal, %, Exact)'),
        const SizedBox(height: 16),
        _buildHighlightFeature(Icons.history_rounded, 'Complete Activity History'),
        const SizedBox(height: 16),
        _buildHighlightFeature(Icons.pie_chart_rounded, 'Group Spending Insights'),
        const SizedBox(height: 48),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(100),
            boxShadow: [BoxShadow(color: const Color(0xFF7B61FF).withOpacity(0.1), blurRadius: 20)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 80,
                height: 32,
                child: Stack(
                  children: [
                    Positioned(left: 0, child: _buildAvatarMock(Colors.blue)),
                    Positioned(left: 20, child: _buildAvatarMock(Colors.purple)),
                    Positioned(left: 40, child: _buildAvatarMock(Colors.orange)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Used by 50,000+ groups', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12, color: const Color(0xFF0F172A))),
                  Text('and growing every day!', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12, color: const Color(0xFF10B981))),
                ],
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildHighlightFeature(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFF7B61FF).withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: const Color(0xFF7B61FF), size: 16),
        ),
        const SizedBox(width: 16),
        Text(text, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildAvatarMock(Color color) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Icon(Icons.person, color: color, size: 20),
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
              errorBuilder: (c,e,s) => const Icon(Icons.image_not_supported, size: 100),
            ),
          ),
        ],
      ),
    );
  }
}

// Utility for simple up/down floating
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
// 2. STATISTICS & FEATURES
// ============================================================================
class _NestsStatsSection extends StatelessWidget {
  final bool isDesktop;
  const _NestsStatsSection({required this.isDesktop});

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
          const SizedBox(height: 64),
          // Mini Feature Strip
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 48),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: const Color(0xFFF1F5F9)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)],
            ),
            child: isDesktop
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiniFeature(Icons.group_work_rounded, 'Everyone on one page', 'All members, all expenses.'),
                      Container(height: 40, width: 1, color: const Color(0xFFF1F5F9)),
                      _buildMiniFeature(Icons.add_circle_rounded, 'Add expenses instantly', 'Add on the go easily.'),
                      Container(height: 40, width: 1, color: const Color(0xFFF1F5F9)),
                      _buildMiniFeature(Icons.calculate_rounded, 'Automatic calculations', 'No more manual math.'),
                      Container(height: 40, width: 1, color: const Color(0xFFF1F5F9)),
                      _buildMiniFeature(Icons.notifications_active_rounded, 'Never miss a settlement', 'Get reminders and alerts.'),
                    ],
                  )
                : Column(
                    children: [
                      _buildMiniFeature(Icons.group_work_rounded, 'Everyone on one page', 'All members, all expenses.'),
                      const SizedBox(height: 24),
                      _buildMiniFeature(Icons.add_circle_rounded, 'Add expenses instantly', 'Add on the go easily.'),
                      const SizedBox(height: 24),
                      _buildMiniFeature(Icons.calculate_rounded, 'Automatic calculations', 'No more manual math.'),
                      const SizedBox(height: 24),
                      _buildMiniFeature(Icons.notifications_active_rounded, 'Never miss a settlement', 'Get reminders and alerts.'),
                    ],
                  ),
          )
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

  Widget _buildMiniFeature(IconData icon, String title, String subtitle) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF10B981), size: 24), // Using mint green
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: const Color(0xFF0F172A), fontSize: 14)),
            Text(subtitle, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 12)),
          ],
        ),
      ],
    );
  }
}

// ============================================================================
// 3. HOW NESTS WORK
// ============================================================================
class _HowNestsWorkSection extends StatelessWidget {
  final bool isDesktop;
  const _HowNestsWorkSection({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 100 : 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFE2E8F0).withOpacity(0.5), borderRadius: BorderRadius.circular(100)),
            child: Text('HOW NESTS WORK', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 1)),
          ),
          const SizedBox(height: 24),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.plusJakartaSans(fontSize: isDesktop ? 48 : 32, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), letterSpacing: -1.5, height: 1.1),
              children: [
                const TextSpan(text: 'Simple steps for\n'),
                WidgetSpan(
                  child: ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFF7B61FF), Color(0xFF4F46E5)]).createShader(bounds),
                    child: Text('stress-free ', style: GoogleFonts.plusJakartaSans(fontSize: isDesktop ? 48 : 32, fontWeight: FontWeight.w800, letterSpacing: -1.5, height: 1.1)),
                  ),
                ),
                const TextSpan(text: 'sharing.'),
              ],
            ),
          ),
          const SizedBox(height: 80),
          if (isDesktop)
            Stack(
              alignment: Alignment.center,
              children: [
                // Connecting line
                Positioned(top: 80, left: 100, right: 100, child: Container(height: 2, color: const Color(0xFFE2E8F0))),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildWorkflowStep('01', Icons.group_add_rounded, 'Create a Nest', 'Add members and set the purpose.', true)),
                    Expanded(child: _buildWorkflowStep('02', Icons.receipt_long_rounded, 'Add Expenses', 'Add expenses as they happen.', false)),
                    Expanded(child: _buildWorkflowStep('03', Icons.pie_chart_rounded, 'We Calculate', 'SplitNest calculates everything instantly.', false)),
                    Expanded(child: _buildWorkflowStep('04', Icons.notifications_active_rounded, 'Settle Up', 'Everyone knows what they owe.', false)),
                  ],
                ),
              ],
            )
          else
            Column(
              children: [
                _buildWorkflowStep('01', Icons.group_add_rounded, 'Create a Nest', 'Add members and set the purpose.', true),
                const SizedBox(height: 48),
                _buildWorkflowStep('02', Icons.receipt_long_rounded, 'Add Expenses', 'Add expenses as they happen.', false),
                const SizedBox(height: 48),
                _buildWorkflowStep('03', Icons.pie_chart_rounded, 'We Calculate', 'SplitNest calculates everything instantly.', false),
                const SizedBox(height: 48),
                _buildWorkflowStep('04', Icons.notifications_active_rounded, 'Settle Up', 'Everyone knows what they owe.', false),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildWorkflowStep(String num, IconData icon, String title, String desc, bool isFirst) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: const Color(0xFFE2E8F0), shape: BoxShape.circle),
          child: Center(child: Text(num, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: const Color(0xFF64748B), fontSize: 12))),
        ),
        const SizedBox(height: 24),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: const Color(0xFF7B61FF).withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 10))],
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [Color(0xFF7B61FF), Color(0xFF4F46E5)])),
              ),
              Icon(icon, color: Colors.white, size: 40),
              if (isFirst)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                    child: const Icon(Icons.add, color: Colors.white, size: 16),
                  ),
                )
            ],
          ),
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
// 4. PHONE SHOWCASE
// ============================================================================
class _NestsPhoneShowcase extends StatefulWidget {
  final bool isDesktop;
  const _NestsPhoneShowcase({required this.isDesktop});

  @override
  State<_NestsPhoneShowcase> createState() => _NestsPhoneShowcaseState();
}

class _NestsPhoneShowcaseState extends State<_NestsPhoneShowcase> with SingleTickerProviderStateMixin {
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
    final width = widget.isDesktop ? 800.0 : size.width * 0.9;
    final height = widget.isDesktop ? 700.0 : 600.0;

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
            final rotateX = _mousePosition == Offset.zero ? 0.05 : ((_mousePosition.dy - centerY) / centerY) * 0.2;
            final rotateY = _mousePosition == Offset.zero ? -0.1 : ((_mousePosition.dx - centerX) / centerX) * -0.2;

            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Abstract Background Orbs
                Positioned(
                  child: ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container(width: 400, height: 400, decoration: BoxDecoration(color: const Color(0xFF7B61FF).withOpacity(0.1), shape: BoxShape.circle))),
                ),
                
                // The Native Phone
                Transform(
                  alignment: FractionalOffset.center,
                  transform: Matrix4.identity()..setEntry(3, 2, 0.0015)..rotateX(rotateX)..rotateY(rotateY)..translate(0.0, -idleOffset * 0.5, 0.0),
                  child: _buildNativePhoneMockup(),
                ),

                // Floating Assets
                Positioned(
                  right: widget.isDesktop ? -20 : 0,
                  bottom: height * 0.1,
                  child: Transform(
                    transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateX(rotateX * 1.5)..rotateY(rotateY * 1.5)..translate(rotateY * -60, rotateX * -60, 0.0),
                    child: Image.asset('assets/images/3d_purple_camera.png', width: 200, errorBuilder: (c,e,s) => const SizedBox()),
                  ),
                ),
                Positioned(
                  left: widget.isDesktop ? -50 : 0,
                  top: height * 0.2,
                  child: Transform(
                    transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateX(rotateX * 0.8)..rotateY(rotateY * 0.8)..translate(rotateY * 80, rotateX * 80, 0.0),
                    child: Image.asset('assets/images/3d_coins.png', width: 120, errorBuilder: (c,e,s) => const SizedBox()),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNativePhoneMockup() {
    return Container(
      width: 320,
      height: 650,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Phone bezels
        borderRadius: BorderRadius.circular(48),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 40, offset: const Offset(20, 20)),
          BoxShadow(color: const Color(0xFF7B61FF).withOpacity(0.2), blurRadius: 60, offset: const Offset(-20, -20)),
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
              // Header
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
                        Text('Trip to Manali', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('5 members', style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Balance Cards
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
// 5. DASHBOARD LAYOUT (Categories, Recent, Analytics)
// ============================================================================
class _NestsDashboardSection extends StatelessWidget {
  final bool isDesktop;
  const _NestsDashboardSection({required this.isDesktop});

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
        Text('Explore how people use Nests.', style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 14)),
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
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis)),
        ],
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
                Text('See what your groups are up to.', style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 14)),
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

  // Analytics
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
      width: _width, // Approximation since we are inside an Align, in reality we'd use LayoutBuilder for accurate percentage
      decoration: BoxDecoration(color: const Color(0xFF7B61FF), borderRadius: BorderRadius.circular(10)),
    );
  }
}

// ============================================================================
// 6. FINAL CTA & FOOTER
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
                      Image.asset('assets/images/3d_premium_ledger.png', width: 400, errorBuilder: (c,e,s) => const SizedBox()),
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
                Image.asset('assets/images/3d_premium_ledger.png', width: 300, errorBuilder: (c,e,s) => const SizedBox()),
              ],
            ),
    );
  }

  Widget _buildText(BuildContext context, {bool isMobile = false}) {
    return Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          'Stay on top of every\nshared expense.',
          style: GoogleFonts.plusJakartaSans(fontSize: isMobile ? 42 : 56, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -2, height: 1.1),
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
        ),
        const SizedBox(height: 24),
        Text(
          'Bring clarity, transparency and peace of mind to every group you are part of.',
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
