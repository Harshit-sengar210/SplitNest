import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/animations/custom_cursor.dart';
import '../widgets/animations/cursor_provider.dart';

class WebsiteLedgerScreen extends StatefulWidget {
  const WebsiteLedgerScreen({Key? key}) : super(key: key);

  @override
  State<WebsiteLedgerScreen> createState() => _WebsiteLedgerScreenState();
}

class _WebsiteLedgerScreenState extends State<WebsiteLedgerScreen> {
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
              _LedgerHeroSection(isDesktop: isDesktop),
              const SizedBox(height: 140),
              _LedgerBenefitsSection(isDesktop: isDesktop),
              const SizedBox(height: 140),
              _NestsOverviewSection(isDesktop: isDesktop),
              const SizedBox(height: 140),
              _TransactionHistorySection(isDesktop: isDesktop),
              const SizedBox(height: 140),
              _AnalyticsSection(isDesktop: isDesktop),
              const SizedBox(height: 140),
              _InsightsSection(isDesktop: isDesktop),
              const SizedBox(height: 140),
              _SecuritySection(isDesktop: isDesktop),
              const SizedBox(height: 140),
              _HowItWorksSection(isDesktop: isDesktop),
              const SizedBox(height: 140),
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
// 1. HERO SECTION (Native 3D Dashboard)
// ============================================================================
class _LedgerHeroSection extends StatelessWidget {
  final bool isDesktop;
  const _LedgerHeroSection({required this.isDesktop});

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
                Expanded(flex: 7, child: _InteractiveDashboardShowcase(isDesktop: isDesktop)),
              ],
            )
          : Column(
              children: [
                _buildText(context, isMobile: true),
                const SizedBox(height: 64),
                _InteractiveDashboardShowcase(isDesktop: isDesktop),
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
            color: const Color(0xFFE2E8F0).withOpacity(0.5),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            'PERSONAL LEDGER',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
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
              const TextSpan(text: 'Your financial\nhealth '),
              WidgetSpan(
                child: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFF7B61FF), Color(0xFF00E5FF)]).createShader(bounds),
                  child: Text('at a glance.', style: GoogleFonts.plusJakartaSans(fontSize: isMobile ? 48 : 72, fontWeight: FontWeight.w800, letterSpacing: -2.5, height: 1.1)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "Get a bird's-eye view of your entire financial situation across all your Nests. Instantly see your total outstanding balance, who owes you money, and who you need to pay back.",
          style: GoogleFonts.plusJakartaSans(
            fontSize: isMobile ? 18 : 20,
            color: const Color(0xFF475569),
            height: 1.6,
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
              child: Text('Get Started', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
            ),
          ],
        )
      ],
    );
  }
}

class _InteractiveDashboardShowcase extends StatefulWidget {
  final bool isDesktop;
  const _InteractiveDashboardShowcase({required this.isDesktop});

  @override
  State<_InteractiveDashboardShowcase> createState() => _InteractiveDashboardShowcaseState();
}

class _InteractiveDashboardShowcaseState extends State<_InteractiveDashboardShowcase> with SingleTickerProviderStateMixin {
  Offset _mousePosition = Offset.zero;
  late AnimationController _idleController;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
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
    final height = 500.0;

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
            final rotateX = _mousePosition == Offset.zero ? 0.05 : ((_mousePosition.dy - centerY) / centerY) * 0.15;
            final rotateY = _mousePosition == Offset.zero ? -0.1 : ((_mousePosition.dx - centerX) / centerX) * -0.15;

            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Glowing Background
                Container(
                  width: width * 0.8,
                  height: height * 0.8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [const Color(0xFF7B61FF).withOpacity(0.3), Colors.transparent]),
                  ),
                ),
                
                // Native Dashboard Frame
                Transform(
                  alignment: FractionalOffset.center,
                  transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateX(rotateX)..rotateY(rotateY)..translate(0.0, -idleOffset, 0.0),
                  child: _buildNativeDashboard(),
                ),

                // Floating Foreground Card (You will receive)
                Positioned(
                  right: widget.isDesktop ? -20 : 10,
                  top: 80,
                  child: Transform(
                    transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateX(rotateX * 1.5)..rotateY(rotateY * 1.5)..translate(rotateY * -40, rotateX * -40, 0.0),
                    child: _buildFloatingCard('You will receive', '₹ 2,500.00', const Color(0xFF10B981), Icons.arrow_upward_rounded),
                  ),
                ),

                // Floating Foreground Card (You need to pay)
                Positioned(
                  right: widget.isDesktop ? -20 : 10,
                  bottom: 120,
                  child: Transform(
                    transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateX(rotateX * 1.2)..rotateY(rotateY * 1.2)..translate(rotateY * -60, rotateX * -60, 0.0),
                    child: _buildFloatingCard('You need to pay', '₹ 850.00', const Color(0xFFEF4444), Icons.arrow_downward_rounded),
                  ),
                ),

                // 3D Wallet & Coins
                Positioned(
                  left: -40,
                  bottom: 40,
                  child: Transform(
                    transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateX(rotateX)..rotateY(rotateY)..translate(rotateY * 80, rotateX * 80 + idleOffset, 0.0),
                    child: Image.asset('assets/images/3d_wallet_new.png', width: 250, errorBuilder: (c,e,s) => const SizedBox()),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNativeDashboard() {
    return Container(
      width: 550,
      height: 350,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(colors: [Color(0xFF1E1B4B), Color(0xFF312E81)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [
          BoxShadow(color: const Color(0xFF7B61FF).withOpacity(0.5), blurRadius: 60, offset: const Offset(0, 30)),
          BoxShadow(color: Colors.white.withOpacity(0.1), blurRadius: 0, spreadRadius: 2, offset: const Offset(0, 2)), // Inner glass border
        ],
        border: Border.all(color: const Color(0xFF4F46E5), width: 2),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Net Balance', style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text('₹ 4,250.00', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w800, letterSpacing: -1)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    Text('All Nests', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 12)),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 48),
          // Mock Graph
          Expanded(
            child: Stack(
              children: [
                Align(alignment: Alignment.bottomCenter, child: Container(height: 1, color: Colors.white12)),
                Align(alignment: const Alignment(0, 0.5), child: Container(height: 1, color: Colors.white12)),
                Align(alignment: Alignment.topCenter, child: Container(height: 1, color: Colors.white12)),
                // SVG / Custom Paint path for graph would go here, simulating with a curved container
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 120,
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [const Color(0xFF00E5FF).withOpacity(0.5), Colors.transparent],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ).createShader(bounds),
                    child: Container(color: Colors.white),
                  ),
                ),
                // Graph Line
                Positioned(
                  bottom: 50,
                  left: 0,
                  right: 0,
                  height: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF),
                      boxShadow: [BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.8), blurRadius: 10)],
                    ),
                  ),
                ),
                // Tooltip mock
                Positioned(
                  right: 100,
                  top: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        Text('₹ 4,250', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold)),
                        Text('Jun 2026', style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 10)),
                      ],
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFloatingCard(String title, String amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, 15))],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 12)),
              const SizedBox(height: 4),
              Text(amount, style: GoogleFonts.plusJakartaSans(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          )
        ],
      ),
    );
  }
}

// ============================================================================
// 2. QUICK BENEFITS SECTION
// ============================================================================
class _LedgerBenefitsSection extends StatelessWidget {
  final bool isDesktop;
  const _LedgerBenefitsSection({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 100 : 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFE2E8F0).withOpacity(0.5), borderRadius: BorderRadius.circular(100)),
            child: Text('EVERYTHING ORGANIZED', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 1)),
          ),
          const SizedBox(height: 24),
          Text(
            'Your money. Perfectly organized.',
            style: GoogleFonts.plusJakartaSans(fontSize: isDesktop ? 48 : 32, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), letterSpacing: -1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'SplitNest Ledger keeps every rupee accounted for.',
            style: GoogleFonts.plusJakartaSans(fontSize: isDesktop ? 20 : 16, color: const Color(0xFF475569)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 64),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: [
              _buildBenefitCard('Total Overview', 'Track your total net balance across all Nests in one unified view.', Icons.pie_chart_rounded, const Color(0xFF4F46E5)),
              _buildBenefitCard('Who Owes You', 'See who owes you money and how much they need to pay.', Icons.group_add_rounded, const Color(0xFF10B981)),
              _buildBenefitCard('Who You Owe', 'Keep track of your dues so you never miss a settlement.', Icons.group_remove_rounded, const Color(0xFFEF4444)),
              _buildBenefitCard('Transaction History', 'See payments, splits and settlements in one detailed history.', Icons.receipt_long_rounded, const Color(0xFF7B61FF)),
              _buildBenefitCard('Smart Reminders', 'Get notified about upcoming and pending settlements.', Icons.notifications_active_rounded, const Color(0xFF3B82F6)),
              _buildBenefitCard('Secure & Private', 'Your financial data is protected with privacy-focused security.', Icons.lock_rounded, const Color(0xFFF59E0B)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitCard(String title, String desc, IconData icon, Color color) {
    return _HoverBenefitCard(title: title, desc: desc, icon: icon, color: color);
  }
}

class _HoverBenefitCard extends StatefulWidget {
  final String title;
  final String desc;
  final IconData icon;
  final Color color;
  
  const _HoverBenefitCard({required this.title, required this.desc, required this.icon, required this.color});

  @override
  State<_HoverBenefitCard> createState() => _HoverBenefitCardState();
}

class _HoverBenefitCardState extends State<_HoverBenefitCard> {
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
        width: 350,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: _isHovered ? widget.color.withOpacity(0.4) : const Color(0xFFF1F5F9),
            width: _isHovered ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered ? widget.color.withOpacity(0.15) : Colors.black.withOpacity(0.02),
              blurRadius: _isHovered ? 30 : 20,
              offset: const Offset(0, 10),
              spreadRadius: _isHovered ? 5 : 0,
            )
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withOpacity(0.1),
                boxShadow: [BoxShadow(color: widget.color.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Icon(widget.icon, color: widget.color, size: 40),
            ),
            const SizedBox(height: 24),
            Text(widget.title, style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(widget.desc, style: GoogleFonts.plusJakartaSans(fontSize: 15, color: const Color(0xFF64748B), height: 1.5), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// Hover utility for cards
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
        transform: Matrix4.identity()..translate(0.0, _isHovered ? -10.0 : 0.0, 0.0),
        child: widget.child,
      ),
    );
  }
}

// ============================================================================
// 3. NESTS OVERVIEW SECTION
// ============================================================================
class _NestsOverviewSection extends StatelessWidget {
  final bool isDesktop;
  const _NestsOverviewSection({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 100 : 24),
      child: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 4, child: _buildText()),
                Expanded(flex: 5, child: _buildNestsList()),
                const SizedBox(width: 48),
                Expanded(flex: 3, child: _buildBalanceChart()),
              ],
            )
          : Column(
              children: [
                _buildText(isMobile: true),
                const SizedBox(height: 48),
                _buildNestsList(),
                const SizedBox(height: 48),
                _buildBalanceChart(),
              ],
            ),
    );
  }

  Widget _buildText({bool isMobile = false}) {
    return Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: const Color(0xFFE2E8F0).withOpacity(0.5), borderRadius: BorderRadius.circular(100)),
          child: Text('NESTS OVERVIEW', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 1)),
        ),
        const SizedBox(height: 24),
        Text(
          'All your Nests.\nOne place.',
          style: GoogleFonts.plusJakartaSans(fontSize: isMobile ? 42 : 56, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), letterSpacing: -2, height: 1.1),
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
        ),
        const SizedBox(height: 24),
        Text(
          'Manage every group and personal ledger seamlessly.',
          style: GoogleFonts.plusJakartaSans(fontSize: 18, color: const Color(0xFF475569)),
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
        ),
        const SizedBox(height: 48),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7B61FF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          ),
          child: const Text('View all Nests →', style: TextStyle(fontWeight: FontWeight.bold)),
        )
      ],
    );
  }

  Widget _buildNestsList() {
    return Column(
      children: [
        _NestRowMock(title: 'Trip to Manali', members: 5, amount: '₹ 1,250', isReceive: true, icon: Icons.landscape_rounded, color: Colors.blue),
        _NestRowMock(title: 'Roommates', members: 3, amount: '₹ 650', isReceive: false, icon: Icons.home_rounded, color: Colors.orange),
        _NestRowMock(title: 'Office Team Lunch', members: 8, amount: '₹ 780', isReceive: true, icon: Icons.work_rounded, color: Colors.brown),
        _NestRowMock(title: 'Family Expenses', members: 6, amount: '₹ 1,200', isReceive: false, icon: Icons.family_restroom_rounded, color: Colors.red),
        _NestRowMock(title: 'Weekend Getaway', members: 4, amount: '₹ 420', isReceive: true, icon: Icons.directions_car_rounded, color: Colors.purple),
      ],
    );
  }

  Widget _buildBalanceChart() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Balance Summary', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 32),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CircularProgressIndicator(value: 0.7, strokeWidth: 16, backgroundColor: const Color(0xFFF1F5F9), valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981))),
                ),
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CircularProgressIndicator(value: 0.3, strokeWidth: 16, backgroundColor: Colors.transparent, valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEF4444))),
                ),
                Column(
                  children: [
                    Text('Net Balance', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.grey)),
                    Text('₹ 4,250', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 24, color: const Color(0xFF0F172A))),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildChartLegend(const Color(0xFF10B981), 'You will receive', '₹ 2,500'),
          const SizedBox(height: 12),
          _buildChartLegend(const Color(0xFFEF4444), 'You need to pay', '₹ 850'),
          const SizedBox(height: 12),
          _buildChartLegend(const Color(0xFF7B61FF), 'Settled', '₹ 1,900'),
        ],
      ),
    );
  }

  Widget _buildChartLegend(Color color, String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF475569))),
          ],
        ),
        Text(amount, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}

class _NestRowMock extends StatefulWidget {
  final String title;
  final int members;
  final String amount;
  final bool isReceive;
  final IconData icon;
  final Color color;

  const _NestRowMock({required this.title, required this.members, required this.amount, required this.isReceive, required this.icon, required this.color});

  @override
  State<_NestRowMock> createState() => _NestRowMockState();
}

class _NestRowMockState extends State<_NestRowMock> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    Future.delayed(Duration(milliseconds: widget.title.length * 100), () {
      if (mounted) _controller.repeat(reverse: true);
    });
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
        offset: Offset(0, _controller.value * 8 - 4),
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isHovered ? const Color(0xFF7B61FF).withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _isHovered ? const Color(0xFF7B61FF).withOpacity(0.2) : const Color(0xFFF1F5F9)),
              boxShadow: _isHovered ? [BoxShadow(color: const Color(0xFF7B61FF).withOpacity(0.05), blurRadius: 10)] : [],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: widget.color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                  child: Icon(widget.icon, color: widget.color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${widget.members} members', style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(widget.isReceive ? 'You will receive' : 'You need to pay', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.grey)),
                    _AnimatedAmount(text: widget.amount, color: widget.isReceive ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                  ],
                ),
                const SizedBox(width: 16),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  transform: Matrix4.identity()..translate(_isHovered ? 5.0 : 0.0, 0.0),
                  child: const Icon(Icons.chevron_right, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedAmount extends StatefulWidget {
  final String text;
  final Color color;
  const _AnimatedAmount({required this.text, required this.color});
  @override
  State<_AnimatedAmount> createState() => _AnimatedAmountState();
}

class _AnimatedAmountState extends State<_AnimatedAmount> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double targetAmount = 0;
  String prefix = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    
    String numStr = widget.text.replaceAll(RegExp(r'[^0-9.]'), '');
    if (numStr.isNotEmpty) {
      targetAmount = double.tryParse(numStr) ?? 0;
    }
    prefix = widget.text.replaceAll(RegExp(r'[0-9.,]'), '');
    
    _animation = Tween<double>(begin: 0, end: targetAmount).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        String formatted = _animation.value.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
        return Text('$prefix$formatted', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: widget.color));
      }
    );
  }
}

// ============================================================================
// 4. DETAILED LEDGER (TRANSACTIONS)
// ============================================================================
class _TransactionHistorySection extends StatelessWidget {
  final bool isDesktop;
  const _TransactionHistorySection({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 100 : 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFE2E8F0).withOpacity(0.5), borderRadius: BorderRadius.circular(100)),
            child: Text('DETAILED LEDGER', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 1)),
          ),
          const SizedBox(height: 24),
          Text(
            'Complete transparency in every transaction.',
            style: GoogleFonts.plusJakartaSans(fontSize: isDesktop ? 48 : 32, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), letterSpacing: -1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Deep dive into your transaction history and financial flow.',
            style: GoogleFonts.plusJakartaSans(fontSize: 18, color: const Color(0xFF475569)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 64),
          
          // Transaction Table Card
          Container(
            padding: EdgeInsets.all(isDesktop ? 40 : 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: const Color(0xFFF1F5F9)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 40, offset: const Offset(0, 20))],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Latest Transactions', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 20)),
                    TextButton(onPressed: (){}, child: const Text('View all')),
                  ],
                ),
                const SizedBox(height: 24),
                if (isDesktop) _buildDesktopTable() else _buildMobileCards(),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDesktopTable() {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(3),
        2: FlexColumnWidth(3),
        3: FlexColumnWidth(2),
        4: FlexColumnWidth(2),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
          children: ['Date', 'Description', 'Nest', 'Amount', 'Status']
              .map((e) => Padding(padding: const EdgeInsets.all(16), child: Text(e, style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12))))
              .toList(),
        ),
        _buildTableRow('12 Jun 2026', 'Dinner with friends', 'Trip to Manali', '+₹480', 'Owed to you', true),
        _buildTableRow('10 Jun 2026', 'House Rent', 'Roommates', '-₹1,000', 'You owe', false),
        _buildTableRow('08 Jun 2026', 'Grocery Shopping', 'Family Expenses', '+₹870', 'Owed to you', true),
        _buildTableRow('05 Jun 2026', 'Petrol', 'Weekend Getaway', '-₹350', 'You owe', false),
        _buildTableRow('02 Jun 2026', 'Lunch', 'Office Team Lunch', '+₹250', 'Owed to you', true),
      ],
    );
  }

  TableRow _buildTableRow(String date, String desc, String nest, String amount, String status, bool isPositive) {
    return TableRow(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF8FAFC)))),
      children: [
        Padding(padding: const EdgeInsets.all(16), child: Text(date, style: GoogleFonts.plusJakartaSans(fontSize: 14))),
        Padding(padding: const EdgeInsets.all(16), child: Text(desc, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold))),
        Padding(padding: const EdgeInsets.all(16), child: Text(nest, style: GoogleFonts.plusJakartaSans(fontSize: 14))),
        Padding(
          padding: const EdgeInsets.all(16), 
          child: _AnimatedAmount(text: amount, color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: (isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.1),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(status, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444))),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileCards() {
    return Column(
      children: [
        _buildMobileCard('Dinner with friends', 'Trip to Manali', '+₹480', 'Owed to you', true),
        _buildMobileCard('House Rent', 'Roommates', '-₹1,000', 'You owe', false),
        _buildMobileCard('Grocery Shopping', 'Family Expenses', '+₹870', 'Owed to you', true),
      ],
    );
  }

  Widget _buildMobileCard(String desc, String nest, String amount, String status, bool isPositive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFF1F5F9)), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(desc, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
              _AnimatedAmount(text: amount, color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(nest, style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
              Text(status, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444))),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 5. SPENDING ANALYTICS
// ============================================================================
class _AnalyticsSection extends StatelessWidget {
  final bool isDesktop;
  const _AnalyticsSection({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 100 : 24),
      child: Column(
        children: [
          Text(
            'Understand where your money goes.',
            style: GoogleFonts.plusJakartaSans(fontSize: isDesktop ? 48 : 32, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), letterSpacing: -1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 64),
          isDesktop
              ? Row(
                  children: [
                    Expanded(child: _buildBarChart()),
                    const SizedBox(width: 48),
                    Expanded(child: _buildCategoryBreakdown()),
                  ],
                )
              : Column(
                  children: [
                    _buildBarChart(),
                    const SizedBox(height: 48),
                    _buildCategoryBreakdown(),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Spending Analytics', style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
          const SizedBox(height: 8),
          Text('₹ 8,450', style: GoogleFonts.plusJakartaSans(fontSize: 42, fontWeight: FontWeight.w800)),
          Text('Total Spending', style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
          const SizedBox(height: 48),
          SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _AnimatedBar(height: 120, label: '10 Jun'),
                _AnimatedBar(height: 80, label: '12 Jun'),
                _AnimatedBar(height: 160, label: '14 Jun'),
                _AnimatedBar(height: 100, label: '16 Jun'),
                _AnimatedBar(height: 190, label: '18 Jun'),
                _AnimatedBar(height: 140, label: '20 Jun'),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top Categories', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 32),
          _buildCategoryRow('Food & Dining', '₹ 3,250', 0.4),
          const SizedBox(height: 24),
          _buildCategoryRow('Shopping', '₹ 2,100', 0.25),
          const SizedBox(height: 24),
          _buildCategoryRow('Transport', '₹ 1,450', 0.15),
          const SizedBox(height: 24),
          _buildCategoryRow('Entertainment', '₹ 900', 0.1),
          const SizedBox(height: 24),
          _buildCategoryRow('Others', '₹ 750', 0.1),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(String title, String amount, double percent) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
            Text(amount, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: const Color(0xFF7B61FF))),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 8,
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 400 * percent, // Mock width calculation
              decoration: BoxDecoration(color: const Color(0xFF7B61FF), borderRadius: BorderRadius.circular(10)),
            ),
          ),
        )
      ],
    );
  }
}

class _AnimatedBar extends StatefulWidget {
  final double height;
  final String label;
  const _AnimatedBar({required this.height, required this.label});

  @override
  State<_AnimatedBar> createState() => _AnimatedBarState();
}

class _AnimatedBarState extends State<_AnimatedBar> {
  double _currentHeight = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _currentHeight = widget.height);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AnimatedContainer(
          duration: const Duration(seconds: 1),
          curve: Curves.easeOutQuart,
          height: _currentHeight,
          width: 30,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF7B61FF), Color(0xFF00E5FF)], begin: Alignment.bottomCenter, end: Alignment.topCenter),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 16),
        Text(widget.label, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

// ============================================================================
// 6. INSIGHTS SECTION
// ============================================================================
class _InsightsSection extends StatelessWidget {
  final bool isDesktop;
  const _InsightsSection({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 100 : 24),
      child: Column(
        children: [
          Text(
            'Turn transactions into insights.',
            style: GoogleFonts.plusJakartaSans(fontSize: isDesktop ? 42 : 32, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), letterSpacing: -1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 64),
          isDesktop
              ? Row(
                  children: [
                    Expanded(child: _buildInsightCard('You\'re receiving more than you\'re paying this month.', Icons.trending_up_rounded, const Color(0xFF10B981))),
                    const SizedBox(width: 24),
                    Expanded(child: _buildInsightCard('Your spending is highest on weekends.', Icons.calendar_month_rounded, const Color(0xFFF59E0B))),
                    const SizedBox(width: 24),
                    Expanded(child: _buildInsightCard('Most shared expenses come from your \'Roommates\' Nest.', Icons.home_rounded, const Color(0xFF7B61FF))),
                  ],
                )
              : Column(
                  children: [
                    _buildInsightCard('You\'re receiving more than you\'re paying this month.', Icons.trending_up_rounded, const Color(0xFF10B981)),
                    const SizedBox(height: 16),
                    _buildInsightCard('Your spending is highest on weekends.', Icons.calendar_month_rounded, const Color(0xFFF59E0B)),
                    const SizedBox(height: 16),
                    _buildInsightCard('Most shared expenses come from your \'Roommates\' Nest.', Icons.home_rounded, const Color(0xFF7B61FF)),
                  ],
                )
        ],
      ),
    );
  }

  Widget _buildInsightCard(String text, IconData icon, Color color) {
    return _HoverScaleCard(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Colors.white, Color(0xFFF8FAFC)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 24),
            Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, height: 1.4)),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 7. SECURITY SECTION
// ============================================================================
class _SecuritySection extends StatelessWidget {
  final bool isDesktop;
  const _SecuritySection({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: isDesktop ? 100 : 24),
      padding: EdgeInsets.all(isDesktop ? 80 : 32),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(48),
        boxShadow: [BoxShadow(color: const Color(0xFF7B61FF).withOpacity(0.3), blurRadius: 60, offset: const Offset(0, 20))],
      ),
      child: isDesktop
          ? Row(
              children: [
                Expanded(child: _buildText()),
                Expanded(child: _buildShield()),
              ],
            )
          : Column(
              children: [
                _buildText(),
                const SizedBox(height: 64),
                _buildShield(),
              ],
            ),
    );
  }

  Widget _buildText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your financial data\ndeserves protection.',
          style: GoogleFonts.plusJakartaSans(fontSize: 48, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1.5, height: 1.1),
        ),
        const SizedBox(height: 24),
        Text(
          'SplitNest is built with privacy-first architecture and robust security to ensure your data stays yours.',
          style: GoogleFonts.plusJakartaSans(fontSize: 18, color: Colors.white70, height: 1.6),
        ),
        const SizedBox(height: 48),
        _buildSecurityFeature(Icons.lock_rounded, 'Bank-level security & encryption'),
        const SizedBox(height: 16),
        _buildSecurityFeature(Icons.verified_user_rounded, 'Secure OAuth Authentication'),
        const SizedBox(height: 16),
        _buildSecurityFeature(Icons.visibility_off_rounded, 'Private financial records'),
      ],
    );
  }

  Widget _buildSecurityFeature(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF00E5FF), size: 24),
        const SizedBox(width: 16),
        Text(text, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildShield() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [const Color(0xFF7B61FF).withOpacity(0.4), Colors.transparent])),
          ),
          Image.asset('assets/images/3d_shield_security.png', width: 400, errorBuilder: (c,e,s) => const Icon(Icons.shield, color: Color(0xFF7B61FF), size: 100)),
        ],
      ),
    );
  }
}

// ============================================================================
// 8. HOW IT WORKS
// ============================================================================
class _HowItWorksSection extends StatelessWidget {
  final bool isDesktop;
  const _HowItWorksSection({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 100 : 24),
      child: Column(
        children: [
          Text(
            'Your money, without the mental math.',
            style: GoogleFonts.plusJakartaSans(fontSize: isDesktop ? 42 : 32, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), letterSpacing: -1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 80),
          isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildStep('01', 'Add your expense')),
                    Expanded(child: _buildStep('02', 'Split or record it')),
                    Expanded(child: _buildStep('03', 'Track your balance')),
                    Expanded(child: _buildStep('04', 'Settle when ready')),
                  ],
                )
              : Column(
                  children: [
                    _buildStep('01', 'Add your expense'),
                    const SizedBox(height: 48),
                    _buildStep('02', 'Split or record it'),
                    const SizedBox(height: 48),
                    _buildStep('03', 'Track your balance'),
                    const SizedBox(height: 48),
                    _buildStep('04', 'Settle when ready'),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildStep(String num, String text) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF7B61FF), width: 2), boxShadow: [BoxShadow(color: const Color(0xFF7B61FF).withOpacity(0.2), blurRadius: 20)]),
          child: Center(child: Text(num, style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w900, color: const Color(0xFF7B61FF)))),
        ),
        const SizedBox(height: 24),
        Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)), textAlign: TextAlign.center),
      ],
    );
  }
}

// ============================================================================
// 9. FINAL CTA
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
                      Image.asset('assets/images/3d_wallet_new.png', width: 400, errorBuilder: (c,e,s) => const SizedBox()),
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
                Image.asset('assets/images/3d_wallet_new.png', width: 300, errorBuilder: (c,e,s) => const SizedBox()),
              ],
            ),
    );
  }

  Widget _buildText(BuildContext context, {bool isMobile = false}) {
    return Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          'Take control of your finances today.',
          style: GoogleFonts.plusJakartaSans(fontSize: isMobile ? 42 : 56, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -2, height: 1.1),
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
        ),
        const SizedBox(height: 24),
        Text(
          'Join thousands who trust SplitNest to manage shared expenses and personal money effortlessly.',
          style: GoogleFonts.plusJakartaSans(fontSize: 18, color: Colors.white70),
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
        ),
        const SizedBox(height: 48),
        Row(
          mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: () => context.go('/download'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF7B61FF),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              ),
              child: Text('Download SplitNest', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================================
// 10. FOOTER
// ============================================================================
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
                      Image.asset('assets/images/splitnest_logo_final.png', height: 40, errorBuilder: (c,e,s) => const Icon(Icons.account_balance_wallet, color: Color(0xFF7B61FF))),
                      const SizedBox(height: 24),
                      Text('Split expenses, manage ledgers, and live stress-free.', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 14)),
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
