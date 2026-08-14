import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/animations/custom_cursor.dart';
import '../widgets/animations/cursor_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class WebsiteAboutScreen extends StatefulWidget {
  const WebsiteAboutScreen({Key? key}) : super(key: key);

  @override
  State<WebsiteAboutScreen> createState() => _WebsiteAboutScreenState();
}

class _WebsiteAboutScreenState extends State<WebsiteAboutScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomCursorWrapper(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            children: [
              const SizedBox(height: 140), // Space for navbar
              _AboutHeroSection(isDesktop: isDesktop),
              const SizedBox(height: 140),
              _WhatIsSplitNestSection(isDesktop: isDesktop),
              const SizedBox(height: 140),
              _CapabilitiesSection(isDesktop: isDesktop),
              const SizedBox(height: 120),
              _StatsSection(isDesktop: isDesktop),
              const SizedBox(height: 160),
              _InteractivePhoneShowcase(isDesktop: isDesktop),
              const SizedBox(height: 160),
              _ValuesSection(isDesktop: isDesktop),
              const SizedBox(height: 160),
              _CyberlimSection(isDesktop: isDesktop),
              const SizedBox(height: 120),
              _ContactSection(isDesktop: isDesktop),
              const SizedBox(height: 120),
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
class _AboutHeroSection extends StatelessWidget {
  final bool isDesktop;
  const _AboutHeroSection({required this.isDesktop});

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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(color: const Color(0xFF7B61FF).withOpacity(0.1), blurRadius: 10),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.stars_rounded, color: Color(0xFF7B61FF), size: 18),
              const SizedBox(width: 8),
              Text(
                'ABOUT SPLITNEST',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF7B61FF),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Money should\nbe simple.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: isMobile ? 48 : 84,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
            letterSpacing: -2.5,
            height: 1.0,
          ),
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
        ),
        const SizedBox(height: 24),
        Text(
          'SplitNest makes shared expenses, personal ledgers and everyday money management feel effortless.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: isMobile ? 18 : 22,
            color: const Color(0xFF475569),
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
        ),
      ],
    );
  }

  Widget _build3DAsset(Size size, {bool isMobile = false}) {
    return Center(
      child: _FloatingAnimation(
        child: Image.asset(
          'assets/images/3d_s_logo_pedestal.png',
          width: isMobile ? size.width * 0.9 : 600,
          fit: BoxFit.contain,
          errorBuilder: (c,e,s) => const Icon(Icons.image_not_supported, size: 100),
        ),
      ),
    );
  }
}

// ============================================================================
// 2. WHAT IS SPLITNEST
// ============================================================================
class _WhatIsSplitNestSection extends StatelessWidget {
  final bool isDesktop;
  const _WhatIsSplitNestSection({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 100 : 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0).withOpacity(0.5),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              'OUR STORY',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'One place for all the money you share.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: isDesktop ? 48 : 32,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              letterSpacing: -1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 700,
            child: Text(
              'SplitNest brings shared expenses and personal money tracking together, so you can spend time with people instead of calculating who owes what.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: isDesktop ? 20 : 16,
                color: const Color(0xFF475569),
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 48),
          CursorRegion(
            cursorState: CursorState.explore,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF7B61FF),
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF7B61FF).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Our Journey',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

// ============================================================================
// 3. CORE CAPABILITIES (HOVER CARDS)
// ============================================================================
class _CapabilitiesSection extends StatelessWidget {
  final bool isDesktop;
  const _CapabilitiesSection({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 100 : 24),
      child: isDesktop 
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(child: _FeatureCard(title: 'Split Expenses', desc: 'Split bills quickly and keep every shared expense organized.', icon: Icons.receipt_long_rounded)),
                const SizedBox(width: 24),
                Expanded(child: _FeatureCard(title: 'Personal Ledger', desc: 'Track personal money without mixing it up with group expenses.', icon: Icons.account_balance_wallet_rounded)),
                const SizedBox(width: 24),
                Expanded(child: _FeatureCard(title: 'Group Nests', desc: 'Create a Nest for trips, roommates, events, families.', icon: Icons.group_work_rounded)),
                const SizedBox(width: 24),
                Expanded(child: _FeatureCard(title: 'Real-Time Balance', desc: 'Always know what you need to pay and what you will receive.', icon: Icons.pie_chart_rounded)),
              ],
            )
          : Column(
              children: [
                _FeatureCard(title: 'Split Expenses', desc: 'Split bills quickly and keep every shared expense organized.', icon: Icons.receipt_long_rounded),
                const SizedBox(height: 16),
                _FeatureCard(title: 'Personal Ledger', desc: 'Track personal money without mixing it up with group expenses.', icon: Icons.account_balance_wallet_rounded),
                const SizedBox(height: 16),
                _FeatureCard(title: 'Group Nests', desc: 'Create a Nest for trips, roommates, events, families.', icon: Icons.group_work_rounded),
                const SizedBox(height: 16),
                _FeatureCard(title: 'Real-Time Balance', desc: 'Always know what you need to pay and what you will receive.', icon: Icons.pie_chart_rounded),
              ],
            ),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  final String title;
  final String desc;
  final IconData icon;

  const _FeatureCard({required this.title, required this.desc, required this.icon});

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..translate(0.0, _isHovered ? -10.0 : 0.0, 0.0),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: _isHovered ? const Color(0xFF7B61FF).withOpacity(0.15) : Colors.black.withOpacity(0.05),
              blurRadius: _isHovered ? 40 : 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              transform: Matrix4.identity()..scale(_isHovered ? 1.1 : 1.0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Icon(widget.icon, color: const Color(0xFF7B61FF), size: 32),
            ),
            const SizedBox(height: 24),
            Text(
              widget.title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.desc,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 4. STATS SECTION
// ============================================================================
class _StatsSection extends StatelessWidget {
  final bool isDesktop;
  const _StatsSection({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 100 : 24),
      child: Wrap(
        spacing: 48,
        runSpacing: 48,
        alignment: WrapAlignment.center,
        children: [
          _buildStat('10K+', 'Happy Users'),
          _buildStat('2K+', 'Nests Created'),
          _buildStat('50K+', 'Expenses Split'),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.group_rounded, color: Color(0xFF7B61FF), size: 32),
              const SizedBox(width: 16),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 5. INTERACTIVE 3D PHONE SHOWCASE (NATIVE FLUTTER)
// ============================================================================
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
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
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
            final rotateX = _mousePosition == Offset.zero ? 0.1 : ((_mousePosition.dy - centerY) / centerY) * 0.2;
            final rotateY = _mousePosition == Offset.zero ? -0.2 : ((_mousePosition.dx - centerX) / centerX) * -0.2;

            return CursorRegion(
              cursorState: CursorState.custom,
              customText: 'Interact',
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  
                  // The Native Phone
                  Transform(
                    alignment: FractionalOffset.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0015)
                      ..rotateX(rotateX)
                      ..rotateY(rotateY)
                      ..translate(0.0, -idleOffset * 0.5, 0.0),
                    child: _buildNativePhoneMockup(),
                  ),

                  // Floating Foreground Elements
                  Positioned(
                    right: widget.isDesktop ? 50 : 0,
                    bottom: height * 0.15,
                    child: Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateX(rotateX * 1.5)
                        ..rotateY(rotateY * 1.5)
                        ..translate(rotateY * -60, rotateX * -60, 0.0),
                      child: Image.asset('assets/images/3d_coins.png', width: 120, errorBuilder: (c,e,s) => const SizedBox()),
                    ),
                  ),
                  Positioned(
                    left: widget.isDesktop ? 20 : 0,
                    top: height * 0.3,
                    child: Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateX(rotateX * 0.8)
                        ..rotateY(rotateY * 0.8)
                        ..translate(rotateY * 80, rotateX * 80, 0.0),
                      child: Image.asset('assets/images/3d_pie_chart.png', width: 150, errorBuilder: (c,e,s) => const SizedBox()),
                    ),
                  ),
                ],
              ),
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
          BoxShadow(color: const Color(0xFF7B61FF).withOpacity(0.1), blurRadius: 60, offset: const Offset(-20, -20)),
        ],
        border: Border.all(color: const Color(0xFF334155), width: 3),
      ),
      padding: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Container(
          color: const Color(0xFFF8FAFC),
          child: Column(
            children: [
              // Mock Status Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('10:37', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12)),
                    Row(
                      children: const [
                        Icon(Icons.signal_cellular_4_bar, size: 14),
                        SizedBox(width: 4),
                        Icon(Icons.wifi, size: 14),
                        SizedBox(width: 4),
                        Icon(Icons.battery_full, size: 14),
                      ],
                    )
                  ],
                ),
              ),
              // Mock App Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF7B61FF), Color(0xFF4F46E5)]),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Balance', style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('₹ 4,250', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              // Mock Splits
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('You will receive', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.grey)),
                            Text('₹ 2,500', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF10B981))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('You need to pay', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.grey)),
                            Text('₹ 850', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFFEF4444))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Recent Activity', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              // Mock List
              Expanded(
                child: ListView(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildMockItem('Dinner with friends', 'You paid', '₹ 480', Colors.purple),
                    _buildMockItem('Trip to Manali', 'You paid', '₹ 1,200', Colors.orange),
                    _buildMockItem('House Rent', 'You paid', '₹ 1,000', Colors.blue),
                    _buildMockItem('Grocery Shopping', 'Trip shared', '₹ 870', Colors.green),
                  ],
                ),
              ),
              // Mock Bottom Nav
              Container(
                height: 60,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    const Icon(Icons.home_rounded, color: Color(0xFF7B61FF)),
                    const Icon(Icons.group_work_rounded, color: Colors.grey),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Color(0xFF7B61FF), shape: BoxShape.circle),
                      child: const Icon(Icons.add, color: Colors.white, size: 20),
                    ),
                    const Icon(Icons.receipt_long_rounded, color: Colors.grey),
                    const Icon(Icons.person_rounded, color: Colors.grey),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMockItem(String title, String sub, String amt, Color c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: c.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.receipt_rounded, color: c, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(sub, style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          Text(amt, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF7B61FF))),
        ],
      ),
    );
  }
}

// ============================================================================
// 6. VALUES SECTION
// ============================================================================
class _ValuesSection extends StatelessWidget {
  final bool isDesktop;
  const _ValuesSection({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 100 : 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0).withOpacity(0.5),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              'OUR VALUES',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Built around what matters.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: isDesktop ? 42 : 32,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              letterSpacing: -1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 64),
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _ValueCard(title: 'Trust & Security', desc: 'Your data and money should always feel safe.', icon: Icons.shield_rounded)),
                const SizedBox(width: 24),
                Expanded(child: _ValueCard(title: 'Simplicity', desc: 'Powerful features should still feel effortless.', icon: Icons.auto_awesome_rounded)),
                const SizedBox(width: 24),
                Expanded(child: _ValueCard(title: 'Transparency', desc: 'Clear transactions. Clear balances. Clear relationships.', icon: Icons.bolt_rounded)),
                const SizedBox(width: 24),
                Expanded(child: _ValueCard(title: 'Togetherness', desc: 'We\'re here to make managing money easier with the people who matter.', icon: Icons.favorite_rounded)),
              ],
            )
          else
            Column(
              children: [
                _ValueCard(title: 'Trust & Security', desc: 'Your data and money should always feel safe.', icon: Icons.shield_rounded),
                const SizedBox(height: 16),
                _ValueCard(title: 'Simplicity', desc: 'Powerful features should still feel effortless.', icon: Icons.auto_awesome_rounded),
                const SizedBox(height: 16),
                _ValueCard(title: 'Transparency', desc: 'Clear transactions. Clear balances. Clear relationships.', icon: Icons.bolt_rounded),
                const SizedBox(height: 16),
                _ValueCard(title: 'Togetherness', desc: 'We\'re here to make managing money easier with the people who matter.', icon: Icons.favorite_rounded),
              ],
            ),
        ],
      ),
    );
  }
}

class _ValueCard extends StatefulWidget {
  final String title;
  final String desc;
  final IconData icon;

  const _ValueCard({required this.title, required this.desc, required this.icon});

  @override
  State<_ValueCard> createState() => _ValueCardState();
}

class _ValueCardState extends State<_ValueCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..translate(0.0, _isHovered ? -10.0 : 0.0, 0.0),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: _isHovered ? const Color(0xFF7B61FF).withOpacity(0.15) : Colors.black.withOpacity(0.03),
              blurRadius: _isHovered ? 40 : 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Custom Native 3D Icon Construct
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              transform: Matrix4.identity()..scale(_isHovered ? 1.1 : 1.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7B61FF), Color(0xFF4F46E5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF7B61FF).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10)),
                      ],
                    ),
                  ),
                  Icon(widget.icon, color: Colors.white, size: 40),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              widget.title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              widget.desc,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 7. CYBERLIM SECTION
// ============================================================================
class _CyberlimSection extends StatelessWidget {
  final bool isDesktop;
  const _CyberlimSection({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: isDesktop ? 64 : 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(color: const Color(0xFF7B61FF).withOpacity(0.3), blurRadius: 40, offset: const Offset(0, 20)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/cyberlim_city_banner.png',
                fit: BoxFit.cover,
                errorBuilder: (c,e,s) => Container(color: const Color(0xFF6246EA)),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF2E1065).withOpacity(0.9),
                      Colors.transparent,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(isDesktop ? 80 : 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Crafted with passion by',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cyberlim',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isDesktop ? 64 : 42,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -2,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: isDesktop ? 400 : double.infinity,
                    child: Text(
                      'Cyberlim is a product studio focused on building meaningful digital experiences that simplify everyday life.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  CursorRegion(
                    cursorState: CursorState.explore,
                    child: ElevatedButton(
                      onPressed: () async {
                        final url = Uri.parse('https://cyberlim.com');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF7B61FF),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      ),
                      child: Text(
                        'Learn more about Cyberlim →',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 100 : 24),
      child: isDesktop
          ? Row(
              children: [
                Expanded(child: _buildText(context)),
                Expanded(
                  child: _FloatingAnimation(
                    child: Image.asset('assets/images/3d_purple_phone_checkmark.png', height: 500, fit: BoxFit.contain, errorBuilder: (c,e,s) => const SizedBox()),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                _buildText(context, isMobile: true),
                const SizedBox(height: 48),
                _FloatingAnimation(
                  child: Image.asset('assets/images/3d_purple_phone_checkmark.png', height: 350, fit: BoxFit.contain, errorBuilder: (c,e,s) => const SizedBox()),
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
          'Ready to simplify\nyour finances?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: isMobile ? 42 : 56,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
            letterSpacing: -2,
            height: 1.1,
          ),
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
        ),
        const SizedBox(height: 24),
        Text(
          'Split expenses. Track your money. Stay organized.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            color: const Color(0xFF64748B),
          ),
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
        ),
        const SizedBox(height: 48),
        Row(
          mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: () => context.go('/download'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B61FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                elevation: 10,
                shadowColor: const Color(0xFF7B61FF).withOpacity(0.5),
              ),
              child: Text('Download SplitNest', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 16),
            OutlinedButton(
              onPressed: () => context.go('/'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF7B61FF),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                side: const BorderSide(color: Color(0xFF7B61FF), width: 2),
              ),
              child: Text('Explore SplitNest', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
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
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
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
                      Row(
                        children: [
                          Image.asset('assets/images/splitnest_logo_final.png', height: 40, errorBuilder: (c,e,s) => const Icon(Icons.account_balance_wallet, color: Color(0xFF7B61FF))),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Split expenses, manage ledgers, and live stress-free.',
                        style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 14),
                      ),
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
                Image.asset('assets/images/splitnest_logo_final.png', height: 40, errorBuilder: (c,e,s) => const Icon(Icons.account_balance_wallet, color: Color(0xFF7B61FF))),
                const SizedBox(height: 24),
                Text(
                  'Split expenses, manage ledgers, and live stress-free.',
                  style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 14),
                ),
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
          const Divider(color: Color(0xFFF1F5F9)),
          const SizedBox(height: 32),
          Text(
            '© 2026 SplitNest by Cyberlim. All rights reserved.',
            style: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterCol(String title, List<String> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
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

// ============================================================================
// 9. CONTACT SECTION
// ============================================================================
class _ContactSection extends StatelessWidget {
  final bool isDesktop;
  const _ContactSection({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 100 : 24, vertical: 80),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
      ),
      child: Column(
        children: [
          Text(
            'Get in Touch',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: isDesktop ? 48 : 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Have questions or want to partner with us? We'd love to hear from you.",
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white70,
              fontSize: isDesktop ? 18 : 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Wrap(
            spacing: 32,
            runSpacing: 32,
            alignment: WrapAlignment.center,
            children: [
              _buildContactItem(Icons.email_outlined, 'Email Us', 'splitnest0@gmail.com'),
              _buildContactItem(Icons.phone_outlined, 'Call Us', '+91-9599676325'),
              GestureDetector(
                onTap: () async {
                  final url = Uri.parse('https://cyberlim.com');
                  if (await canLaunchUrl(url)) await launchUrl(url);
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: _buildContactItem(Icons.language_rounded, 'Website', 'cyberlim.com', isLink: true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String title, String value, {bool isLink = false}) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF7B61FF), size: 32),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: isLink ? const Color(0xFF7B61FF) : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              decoration: isLink ? TextDecoration.underline : TextDecoration.none,
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
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _controller.value * 20 - 10),
        child: widget.child,
      ),
    );
  }
}
