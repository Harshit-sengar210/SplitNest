import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/animations/custom_cursor.dart';
import '../widgets/animations/cursor_provider.dart';

class WebsiteFeaturesScreen extends StatefulWidget {
  const WebsiteFeaturesScreen({Key? key}) : super(key: key);

  @override
  State<WebsiteFeaturesScreen> createState() => _WebsiteFeaturesScreenState();
}

class _WebsiteFeaturesScreenState extends State<WebsiteFeaturesScreen> {
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
              _FeaturesHeroSection(isDesktop: isDesktop),
              const SizedBox(height: 100),
              _FeatureGridSection(isDesktop: isDesktop),
              const SizedBox(height: 160),
              _FeatureDeepDiveSections(isDesktop: isDesktop),
              const SizedBox(height: 160),
              _InteractiveDemoSection(isDesktop: isDesktop),
              const SizedBox(height: 160),
              _TrustSection(isDesktop: isDesktop),
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
class _FeaturesHeroSection extends StatelessWidget {
  final bool isDesktop;
  const _FeaturesHeroSection({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 100 : 24),
      child: isDesktop
          ? Row(
              children: [
                Expanded(flex: 3, child: _buildLeftAsset()),
                Expanded(flex: 6, child: _buildText(context)),
                Expanded(flex: 3, child: _buildRightAsset()),
              ],
            )
          : Column(
              children: [
                _buildText(context, isMobile: true),
                const SizedBox(height: 64),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(child: _buildLeftAsset(scale: 0.6)),
                    Expanded(child: _buildRightAsset(scale: 0.6)),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildText(BuildContext context, {bool isMobile = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: const Color(0xFF7B61FF).withOpacity(0.1), borderRadius: BorderRadius.circular(100)),
          child: Text('FEATURES', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF7B61FF), fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 1)),
        ),
        const SizedBox(height: 24),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 42 : 64,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              letterSpacing: -2,
              height: 1.1,
            ),
            children: [
              const TextSpan(text: 'Everything you need to\n'),
              WidgetSpan(
                child: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFF7B61FF), Color(0xFF4F46E5)]).createShader(bounds),
                  child: Text('split smart.', style: GoogleFonts.plusJakartaSans(fontSize: isMobile ? 42 : 64, fontWeight: FontWeight.w800, letterSpacing: -2, height: 1.1)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "Built with premium design and powerful functionality.",
          style: GoogleFonts.plusJakartaSans(fontSize: isMobile ? 18 : 20, color: const Color(0xFF475569)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLeftAsset({double scale = 1.0}) {
    return _FloatingAnimation(
      offset: 15,
      duration: 4,
      child: Image.asset(
        'assets/images/3d_premium_ledger.png',
        width: 300 * scale,
        errorBuilder: (c,e,s) => Icon(Icons.account_balance_wallet, size: 100 * scale, color: const Color(0xFF7B61FF)),
      ),
    );
  }

  Widget _buildRightAsset({double scale = 1.0}) {
    return _FloatingAnimation(
      offset: -15,
      duration: 5,
      child: Image.asset(
        'assets/images/3d_purple_phone_checkmark.png',
        width: 300 * scale,
        errorBuilder: (c,e,s) => Icon(Icons.phone_android, size: 100 * scale, color: const Color(0xFF7B61FF)),
      ),
    );
  }
}

class _FloatingAnimation extends StatefulWidget {
  final Widget child;
  final double offset;
  final int duration;
  const _FloatingAnimation({required this.child, required this.offset, required this.duration});
  @override
  State<_FloatingAnimation> createState() => _FloatingAnimationState();
}

class _FloatingAnimationState extends State<_FloatingAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(seconds: widget.duration))..repeat(reverse: true);
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
      builder: (context, child) => Transform.translate(offset: Offset(0, _controller.value * widget.offset * 2 - widget.offset), child: widget.child),
    );
  }
}

// ============================================================================
// 2. FEATURE GRID SECTION
// ============================================================================
class _FeatureGridSection extends StatelessWidget {
  final bool isDesktop;
  const _FeatureGridSection({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 100 : 24),
      child: Wrap(
        spacing: 24,
        runSpacing: 24,
        alignment: WrapAlignment.center,
        children: [
          _buildFeatureCard(
            title: 'Group Expenses',
            desc: 'Create Nests for roommates, trips, or events and track shared costs seamlessly.',
            bullets: ['Create unlimited Nests', 'Add members in seconds', 'Share and track expenses', 'Split in multiple ways'],
            color: const Color(0xFF7B61FF),
            icon: Icons.groups_rounded,
          ),
          _buildFeatureCard(
            title: 'Personal Ledger',
            desc: 'A unified dashboard showing exactly who owes you and who you owe.',
            bullets: ['Net balance overview', 'Who owes you', 'Who you owe', 'Transaction history'],
            color: const Color(0xFFEF4444),
            icon: Icons.book_rounded,
          ),
          _buildFeatureCard(
            title: 'Smart Settlement',
            desc: 'Our algorithm minimizes the number of transactions needed to settle all debts.',
            bullets: ['Minimum cash flow', 'Optimal settlement suggestions', 'Settle up in one click', 'Multiple payment options'],
            color: const Color(0xFFF59E0B),
            icon: Icons.bolt_rounded,
          ),
          _buildFeatureCard(
            title: 'Real-time Sync',
            desc: 'Keep balances, expenses, members, and activity synchronized across your devices.',
            bullets: ['Instant updates', 'Offline support', 'Cloud backup', 'Never lose data'],
            color: const Color(0xFF10B981),
            icon: Icons.sync_rounded,
          ),
          _buildFeatureCard(
            title: 'Beautiful Analytics',
            desc: 'Understand your spending with clear visual insights and meaningful financial summaries.',
            bullets: ['Spending insights', 'Category-wise breakdown', 'Trends over time', 'Export and share reports'],
            color: const Color(0xFFEC4899),
            icon: Icons.pie_chart_rounded,
          ),
          _buildFeatureCard(
            title: 'Cross-Platform',
            desc: 'Access your SplitNest experience wherever you need it, with a consistent interface.',
            bullets: ['iOS, Android & Web', 'Seamless experience', 'Same data everywhere', 'Always in sync'],
            color: const Color(0xFF3B82F6),
            icon: Icons.devices_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({required String title, required String desc, required List<String> bullets, required Color color, required IconData icon}) {
    return _HoverScaleFeatureCard(
      color: color,
      child: Container(
        width: 380,
        height: 380,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildNative3DIcon(icon, color),
                const SizedBox(width: 24),
                Expanded(child: Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)))),
              ],
            ),
            const SizedBox(height: 24),
            Text(desc, style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF64748B), height: 1.5)),
            const SizedBox(height: 24),
            ...bullets.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: color, size: 16),
                      const SizedBox(width: 12),
                      Text(b, style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF475569))),
                    ],
                  ),
                )),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), shape: BoxShape.circle),
                child: Icon(Icons.arrow_forward_rounded, color: color, size: 16),
              ),
            )
          ],
        ),
      ),
    );
  }

  // Native Flutter approximation of a premium 3D icon
  Widget _buildNative3DIcon(IconData icon, Color color) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10)),
          BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 0, spreadRadius: 2, offset: const Offset(-2, -2)),
        ],
      ),
      child: Center(
        child: Icon(icon, color: color, size: 40, shadows: [Shadow(color: color.withOpacity(0.5), blurRadius: 10, offset: const Offset(2, 2))]),
      ),
    );
  }
}

class _HoverScaleFeatureCard extends StatefulWidget {
  final Widget child;
  final Color color;
  const _HoverScaleFeatureCard({required this.child, required this.color});
  @override
  State<_HoverScaleFeatureCard> createState() => _HoverScaleFeatureCardState();
}

class _HoverScaleFeatureCardState extends State<_HoverScaleFeatureCard> {
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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: _isHovered ? [BoxShadow(color: widget.color.withOpacity(0.15), blurRadius: 40, offset: const Offset(0, 20))] : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: widget.child,
      ),
    );
  }
}

// ============================================================================
// 3. DEEP DIVE SECTIONS
// ============================================================================
class _FeatureDeepDiveSections extends StatelessWidget {
  final bool isDesktop;
  const _FeatureDeepDiveSections({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 100 : 24),
      child: Column(
        children: [
          _buildDeepDiveRow(
            title: 'Shared expenses without the spreadsheet.',
            desc: 'Create a Nest, add members, log expenses, and choose your split rules. We track all the balances automatically so you never have to ask "who owes what?" again.',
            bullets: ['Flexible splitting (Equal, %, Exact)', 'Instant synchronization', 'Detailed activity feed'],
            isReversed: false,
            visual: _buildNativeVisualMockup(Icons.people_alt_rounded, const Color(0xFF7B61FF)),
          ),
          const SizedBox(height: 160),
          _buildDeepDiveRow(
            title: 'Your money. One clear picture.',
            desc: 'The Personal Ledger aggregates every expense from every Nest you are part of. Instantly see the total amount you will receive and the total amount you need to pay.',
            bullets: ['Global net balance', 'Cross-nest aggregation', 'Searchable transaction history'],
            isReversed: true,
            visual: _buildNativeVisualMockup(Icons.account_balance_wallet_rounded, const Color(0xFFEF4444)),
          ),
          const SizedBox(height: 160),
          _buildDeepDiveRow(
            title: 'Less math. Fewer payments.',
            desc: 'Our Smart Settlement algorithm calculates the most efficient way for everyone to settle their debts. If A owes B ₹100, and B owes C ₹100, SplitNest simply tells A to pay C ₹100.',
            bullets: ['Minimizes total transactions', 'Saves time and confusion', 'Clear settlement instructions'],
            isReversed: false,
            visual: _buildSettlementVisual(),
          ),
        ],
      ),
    );
  }

  Widget _buildDeepDiveRow({required String title, required String desc, required List<String> bullets, required bool isReversed, required Widget visual}) {
    if (!isDesktop) {
      return Column(
        children: [
          _buildText(title, desc, bullets),
          const SizedBox(height: 48),
          visual,
        ],
      );
    }
    return Row(
      children: [
        if (!isReversed) Expanded(child: _buildText(title, desc, bullets)),
        if (!isReversed) Expanded(child: visual),
        if (isReversed) Expanded(child: visual),
        if (isReversed) Expanded(child: _buildText(title, desc, bullets)),
      ],
    );
  }

  Widget _buildText(String title, String desc, List<String> bullets) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 42, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), letterSpacing: -1.5, height: 1.1)),
          const SizedBox(height: 24),
          Text(desc, style: GoogleFonts.plusJakartaSans(fontSize: 18, color: const Color(0xFF475569), height: 1.6)),
          const SizedBox(height: 32),
          ...bullets.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                      child: const Icon(Icons.check, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 16),
                    Text(b, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildNativeVisualMockup(IconData icon, Color color) {
    return Center(
      child: Container(
        width: 400,
        height: 400,
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(width: 250, height: 250, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 40, offset: const Offset(0, 20))])),
            Container(width: 150, height: 150, decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle)),
            Icon(icon, color: color, size: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSettlementVisual() {
    return Center(
      child: SizedBox(
        width: 400,
        height: 400,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(top: 50, child: _buildPersonBubble('A', Colors.blue)),
            Positioned(bottom: 50, left: 50, child: _buildPersonBubble('B', Colors.purple)),
            Positioned(bottom: 50, right: 50, child: _buildPersonBubble('C', Colors.teal)),
            // Animated arrows could go here, for now static visual representation
            const Icon(Icons.sync_alt_rounded, size: 60, color: Color(0xFFF59E0B)),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonBubble(String letter, Color color) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Center(child: Text(letter, style: GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.bold, color: color))),
    );
  }
}

// ============================================================================
// 4. INTERACTIVE DEMO SECTION (Native 3D Dashboard)
// ============================================================================
class _InteractiveDemoSection extends StatelessWidget {
  final bool isDesktop;
  const _InteractiveDemoSection({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 100 : 24, vertical: 80),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E293B)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
      ),
      child: Column(
        children: [
          Text(
            'Everything works together.',
            style: GoogleFonts.plusJakartaSans(fontSize: isDesktop ? 48 : 36, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            'See SplitNest in action.',
            style: GoogleFonts.plusJakartaSans(fontSize: 18, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 80),
          _InteractiveDashboard(isDesktop: isDesktop),
        ],
      ),
    );
  }
}

class _InteractiveDashboard extends StatefulWidget {
  final bool isDesktop;
  const _InteractiveDashboard({required this.isDesktop});
  @override
  State<_InteractiveDashboard> createState() => _InteractiveDashboardState();
}

class _InteractiveDashboardState extends State<_InteractiveDashboard> with SingleTickerProviderStateMixin {
  Offset _mousePosition = Offset.zero;
  late AnimationController _idleController;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _idleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = widget.isDesktop ? 1000.0 : size.width * 0.9;
    final height = widget.isDesktop ? 600.0 : 800.0;

    return MouseRegion(
      onHover: (event) => setState(() => _mousePosition = event.localPosition),
      onExit: (_) => setState(() => _mousePosition = Offset.zero),
      child: SizedBox(
        width: width,
        height: height,
        child: AnimatedBuilder(
          animation: _idleController,
          builder: (context, child) {
            final idleOffset = _idleController.value * 15.0;
            final centerX = width / 2;
            final centerY = height / 2;
            final rotateX = _mousePosition == Offset.zero ? 0.05 : ((_mousePosition.dy - centerY) / centerY) * 0.1;
            final rotateY = _mousePosition == Offset.zero ? -0.1 : ((_mousePosition.dx - centerX) / centerX) * -0.1;

            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  child: ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100), child: Container(width: 600, height: 600, decoration: BoxDecoration(color: const Color(0xFF7B61FF).withOpacity(0.15), shape: BoxShape.circle))),
                ),
                
                // The Native Dashboard
                Transform(
                  alignment: FractionalOffset.center,
                  transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateX(rotateX)..rotateY(rotateY)..translate(0.0, -idleOffset, 0.0),
                  child: _buildDashboardContent(),
                ),

                // Floating Labels
                if (widget.isDesktop) ...[
                  Positioned(
                    left: 20,
                    top: 100,
                    child: Transform(
                      transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateX(rotateX * 1.5)..rotateY(rotateY * 1.5)..translate(rotateY * -40, rotateX * -40, 0.0),
                      child: _buildFloatingLabel('Live balance', const Color(0xFF10B981)),
                    ),
                  ),
                  Positioned(
                    right: 20,
                    top: 200,
                    child: Transform(
                      transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateX(rotateX * 0.8)..rotateY(rotateY * 0.8)..translate(rotateY * 60, rotateX * 60, 0.0),
                      child: _buildFloatingLabel('Shared expenses', const Color(0xFF7B61FF)),
                    ),
                  ),
                  Positioned(
                    left: 80,
                    bottom: 100,
                    child: Transform(
                      transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateX(rotateX * 1.2)..rotateY(rotateY * 1.2)..translate(rotateY * -80, rotateX * -80, 0.0),
                      child: _buildFloatingLabel('Smart settlement', const Color(0xFFF59E0B)),
                    ),
                  ),
                ]
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFloatingLabel(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(100), boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 30, offset: const Offset(0, 15))]),
      child: Text(text, style: GoogleFonts.plusJakartaSans(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  Widget _buildDashboardContent() {
    return Container(
      width: widget.isDesktop ? 800 : double.infinity,
      height: widget.isDesktop ? 500 : 700,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 60, offset: const Offset(0, 30)),
        ],
        border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.3), width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Column(
          children: [
            // Top Nav Mock
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('SplitNest', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF7B61FF), fontWeight: FontWeight.bold, fontSize: 20)),
                  Row(
                    children: [
                      Container(width: 32, height: 32, decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle), child: const Icon(Icons.notifications, size: 16)),
                      const SizedBox(width: 16),
                      Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.2), shape: BoxShape.circle), child: const Icon(Icons.person, size: 16, color: Color(0xFF10B981))),
                    ],
                  )
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: widget.isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildMockNav('Dashboard', Icons.dashboard, true),
                                _buildMockNav('Nests', Icons.home, false),
                                _buildMockNav('Activity', Icons.history, false),
                                _buildMockNav('Settings', Icons.settings, false),
                              ],
                            ),
                          ),
                          const SizedBox(width: 48),
                          Expanded(
                            flex: 3,
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                Text('Total Balance', style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
                                Text('₹ 4,250.00', style: GoogleFonts.plusJakartaSans(fontSize: 48, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 32),
                                Row(
                                  children: [
                                    Expanded(child: _buildMockBalanceCard('You will receive', '₹ 2,500.00', const Color(0xFF10B981))),
                                    const SizedBox(width: 24),
                                    Expanded(child: _buildMockBalanceCard('You need to pay', '₹ 850.00', const Color(0xFFEF4444))),
                                  ],
                                ),
                                const SizedBox(height: 32),
                                Text('Recent Nests', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 16),
                                _buildMockNestRow('Goa Trip', '₹ 1,850'),
                                _buildMockNestRow('Roommates', '-₹ 420'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                        child: Column(
                          children: [
                             Text('Total Balance', style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
                              Text('₹ 4,250.00', style: GoogleFonts.plusJakartaSans(fontSize: 48, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 32),
                              _buildMockBalanceCard('You will receive', '₹ 2,500.00', const Color(0xFF10B981)),
                              const SizedBox(height: 16),
                              _buildMockBalanceCard('You need to pay', '₹ 850.00', const Color(0xFFEF4444)),
                              const SizedBox(height: 32),
                              _buildMockNestRow('Goa Trip', '₹ 1,850'),
                          ],
                        ),
                      ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMockNav(String text, IconData icon, bool isActive) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: isActive ? const Color(0xFF7B61FF) : Colors.grey, size: 20),
          const SizedBox(width: 16),
          Text(text, style: GoogleFonts.plusJakartaSans(color: isActive ? const Color(0xFF0F172A) : Colors.grey, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildMockBalanceCard(String title, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          Text(amount, style: GoogleFonts.plusJakartaSans(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMockNestRow(String title, String amount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          Text(amount, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ============================================================================
// 5. TRUST / FINAL CTA
// ============================================================================
class _TrustSection extends StatelessWidget {
  final bool isDesktop;
  const _TrustSection({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: isDesktop ? 100 : 24),
      padding: EdgeInsets.all(isDesktop ? 64 : 32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF7B61FF), Color(0xFF4F46E5)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(48),
        boxShadow: [BoxShadow(color: const Color(0xFF7B61FF).withOpacity(0.4), blurRadius: 40, offset: const Offset(0, 20))],
      ),
      child: isDesktop
          ? Row(
              children: [
                Expanded(flex: 3, child: _buildLeftAsset(context)),
                Expanded(flex: 6, child: _buildText(context)),
                Expanded(flex: 3, child: _buildRightAsset(context)),
              ],
            )
          : Column(
              children: [
                _buildText(context, isMobile: true),
                const SizedBox(height: 64),
                _buildLeftAsset(context, scale: 0.8),
              ],
            ),
    );
  }

  Widget _buildText(BuildContext context, {bool isMobile = false}) {
    return Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          'Made for real life.\nBuilt for everyone.',
          style: GoogleFonts.plusJakartaSans(fontSize: isMobile ? 36 : 48, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1.5, height: 1.1),
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
        ),
        const SizedBox(height: 24),
        Text(
          'Whether it\'s a trip, a dinner, a home, or a big event — SplitNest makes sharing expenses effortless.',
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
                  Text('Explore How It Works', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
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

  Widget _buildLeftAsset(BuildContext context, {double scale = 1.0}) {
    return Center(
      child: Container(
        width: 150 * scale,
        height: 150 * scale,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.3), width: 4)),
        child: Center(child: Icon(Icons.verified_user_rounded, color: Colors.white, size: 80 * scale)),
      ),
    );
  }

  Widget _buildRightAsset(BuildContext context, {double scale = 1.0}) {
    return Center(
      child: Image.asset('assets/images/3d_premium_ledger.png', width: 250 * scale, errorBuilder: (c,e,s) => const SizedBox()),
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
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFF1F5F9)))),
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
                      Image.asset('assets/images/splitnest_logo_final.png', height: 40, errorBuilder: (c,e,s) => const Icon(Icons.account_balance_wallet, color: Color(0xFF7B61FF))),
                      const SizedBox(height: 24),
                      Text('Split Smart, Live Easy.', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      Row(
                        children: const [
                          Icon(Icons.camera_alt, color: Color(0xFF64748B), size: 20),
                          SizedBox(width: 16),
                          Icon(Icons.link, color: Color(0xFF64748B), size: 20),
                          SizedBox(width: 16),
                          Icon(Icons.language, color: Color(0xFF64748B), size: 20),
                        ],
                      )
                    ],
                  ),
                ),
                Expanded(child: _buildFooterCol('Product', ['Features', 'How it Works', 'Nests', 'Ledger'])),
                Expanded(child: _buildFooterCol('Company', ['About', 'Contact'])),
                Expanded(child: _buildFooterCol('Account', ['Log in', 'Sign up', 'Download'])),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset('assets/images/splitnest_logo_final.png', height: 40, errorBuilder: (c,e,s) => const Icon(Icons.account_balance_wallet, color: Color(0xFF7B61FF))),
                const SizedBox(height: 24),
                Text('Split Smart, Live Easy.', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 48),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildFooterCol('Product', ['Features', 'How it Works', 'Nests', 'Ledger'])),
                    Expanded(child: _buildFooterCol('Company', ['About', 'Contact'])),
                  ],
                ),
                const SizedBox(height: 32),
                _buildFooterCol('Account', ['Log in', 'Sign up', 'Download']),
              ],
            ),
          const SizedBox(height: 64),
          const Divider(color: Color(0xFFF1F5F9)),
          const SizedBox(height: 32),
          Text('© 2026 SplitNest by Cyberlim. All rights reserved.', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 12)),
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
