import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../widgets/animations/custom_cursor.dart';
import '../widgets/animations/cursor_provider.dart';

class WebsiteHomeScreen extends StatefulWidget {
  const WebsiteHomeScreen({super.key});

  @override
  State<WebsiteHomeScreen> createState() => _WebsiteHomeScreenState();
}

class _WebsiteHomeScreenState extends State<WebsiteHomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Light background
      body: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildHeroSection(size, isDesktop),
            _buildSocialProof(isDesktop),
            
            // Feature Sections
            const SizedBox(height: 100),
            _buildFeatureSection(
              size: size,
              isDesktop: isDesktop,
              isReversed: false,
              title: 'Money gets complicated.',
              subtitle: 'Trips, dinners, and rent add up quickly. Keeping track of who owes who is a nightmare.',
              color: const Color(0xFFEF4444),
              widget: _buildExpenseWidget(),
            ),
            
            const SizedBox(height: 100),
            _buildFeatureSection(
              size: size,
              isDesktop: isDesktop,
              isReversed: true,
              title: 'One place for everyone.',
              subtitle: 'Create a Nest for your apartment or trip. Add expenses, and SplitNest automatically organizes the debts.',
              color: const Color(0xFF14B8A6),
              widget: _buildNestWidget(),
            ),
            
            const SizedBox(height: 100),
            _buildFeatureSection(
              size: size,
              isDesktop: isDesktop,
              isReversed: false,
              title: 'Your Personal Ledger.',
              subtitle: 'Keep track of all your personal finances, one-off debts, and total balances across all groups.',
              color: const Color(0xFF0F172A),
              widget: _buildLedgerWidget(),
            ),

            const SizedBox(height: 150),
            _buildSecuritySection(isDesktop),
            
            const SizedBox(height: 150),
            _buildTestimonials(isDesktop),
            
            const SizedBox(height: 150),
            _buildCallToAction(isDesktop),
            _buildFooter(isDesktop),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // HERO SECTION
  // =========================================================================
  Widget _buildHeroSection(Size size, bool isDesktop) {
    return Container(
      width: double.infinity,
      height: size.height,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 100 : 24),
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.5,
          colors: [
            Color(0xFFE8E0FF),
            Color(0xFFF8FAFC),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
             child: CustomPaint(painter: _GridBackgroundPainter()),
          ),
          if (isDesktop) 
            Row(
              children: [
                Expanded(flex: 5, child: _buildHeroText()),
                const Expanded(flex: 7, child: _Hero3DScene()),
              ],
            )
          else 
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 100),
                _buildHeroText(isMobile: true),
                const SizedBox(height: 48),
                const Expanded(child: _Hero3DScene(isMobile: true)),
              ],
            ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: _ScrollIndicator(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroText({bool isMobile = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7B61FF).withOpacity(0.1),
                blurRadius: 10,
              ),
            ],
          ),
          child: Text(
            'The new standard for shared expenses ✨',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF7B61FF),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Split smart.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: isMobile ? 48 : 84,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
            letterSpacing: -2.5,
            height: 1.0,
          ),
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
        ),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF7B61FF), Color(0xFF4F46E5)],
          ).createShader(bounds),
          child: Text(
            'Live easy.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 48 : 84,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -2.5,
              height: 1.0,
            ),
            textAlign: isMobile ? TextAlign.center : TextAlign.left,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Split expenses, manage your personal ledger,\nand keep every Nest perfectly organized.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: isMobile ? 18 : 22,
            color: const Color(0xFF475569),
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
        ),
        const SizedBox(height: 48),
        Row(
          mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            CursorRegion(
              cursorState: CursorState.download,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => context.go('/download'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7B61FF), Color(0xFF6246EA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7B61FF).withOpacity(0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Get SplitNest Now',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (!isMobile) const SizedBox(width: 24),
            if (!isMobile)
              CursorRegion(
                cursorState: CursorState.explore,
                child: TextButton(
                  onPressed: () {
                     _scrollController.animateTo(
                       MediaQuery.of(context).size.height,
                       duration: const Duration(milliseconds: 800),
                       curve: Curves.easeOutCubic,
                     );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  ),
                  child: Text(
                    'See how it works →',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // =========================================================================
  // SOCIAL PROOF SECTION
  // =========================================================================
  Widget _buildSocialProof(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 64),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border.symmetric(horizontal: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Column(
        children: [
          Text(
            'TRUSTED BY OVER 1,000,000 FRIENDS & ROOMMATES',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogo('Forbes'),
                _buildLogo('TechCrunch'),
                _buildLogo('Bloomberg'),
                _buildLogo('The Verge'),
                _buildLogo('Wired'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Text(
        name,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          color: const Color(0xFFCBD5E1),
        ),
      ),
    );
  }

  // =========================================================================
  // FEATURE SECTIONS
  // =========================================================================
  Widget _buildFeatureSection({
    required Size size,
    required bool isDesktop,
    required bool isReversed,
    required String title,
    required String subtitle,
    required Color color,
    required Widget widget,
  }) {
    final textContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: isDesktop ? 48 : 36,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
            letterSpacing: -1,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          subtitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            color: const Color(0xFF475569),
            height: 1.5,
          ),
        ),
      ],
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 100 : 24, vertical: 64),
      width: double.infinity,
      child: isDesktop
          ? Row(
              children: [
                if (!isReversed) Expanded(child: textContent),
                if (!isReversed) const SizedBox(width: 80),
                Expanded(child: Center(child: widget)),
                if (isReversed) const SizedBox(width: 80),
                if (isReversed) Expanded(child: textContent),
              ],
            )
          : Column(
              children: [
                textContent,
                const SizedBox(height: 64),
                widget,
              ],
            ),
    );
  }

  Widget _buildExpenseWidget() {
    return Container(
      width: 400,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: const Color(0xFFEF4444).withOpacity(0.1), blurRadius: 40, offset: const Offset(0, 20))
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFEF4444).withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.flight, color: Color(0xFFEF4444)),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Flights to Bali', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('You paid \$850', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFF59E0B).withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.home, color: Color(0xFFF59E0B)),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Airbnb', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Alex paid \$1,200', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNestWidget() {
    return Container(
      width: 400,
      height: 380,
      decoration: BoxDecoration(
        color: const Color(0xFF14B8A6),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: const Color(0xFF14B8A6).withOpacity(0.3), blurRadius: 40, offset: const Offset(0, 20))
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.group_work, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Text('Bali Trip Nest', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 32),
          _buildNestMemberRow('You', 'Owe Alex', '\$400', Colors.redAccent),
          const SizedBox(height: 16),
          _buildNestMemberRow('Sarah', 'Owes You', '\$150', Colors.greenAccent),
          const SizedBox(height: 16),
          _buildNestMemberRow('Mike', 'Settled up', '\$0', Colors.white54),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Center(
              child: Text('Settle Up', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF14B8A6), fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNestMemberRow(String name, String status, String amount, Color amountColor) {
    return Row(
      children: [
        CircleAvatar(backgroundColor: Colors.white24, child: Text(name[0], style: const TextStyle(color: Colors.white))),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
            Text(status, style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 12)),
          ],
        ),
        const Spacer(),
        Text(amount, style: GoogleFonts.plusJakartaSans(color: amountColor, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildLedgerWidget() {
    return Container(
      width: 450,
      height: 250,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.3), blurRadius: 40, offset: const Offset(0, 20))
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Total Owed', style: GoogleFonts.plusJakartaSans(color: Colors.white54)),
                Text('\$1,250', style: GoogleFonts.plusJakartaSans(color: Colors.redAccent, fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),
                Text('Total Owed to You', style: GoogleFonts.plusJakartaSans(color: Colors.white54)),
                Text('\$3,400', style: GoogleFonts.plusJakartaSans(color: Colors.greenAccent, fontSize: 32, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(child: Icon(Icons.bar_chart, color: Colors.white38, size: 100)),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // SECURITY SECTION
  // =========================================================================
  Widget _buildSecuritySection(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 100 : 24, vertical: 100),
      color: const Color(0xFF0F172A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.security, color: Color(0xFF7B61FF), size: 64),
          const SizedBox(height: 24),
          Text(
            'Bank-Level Security',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Your financial data is protected with 256-bit encryption. We never sell your data.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TESTIMONIALS SECTION
  // =========================================================================
  Widget _buildTestimonials(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 100 : 24),
      child: Column(
        children: [
          Text(
            'Loved by thousands.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 64),
          isDesktop 
              ? Row(
                  children: [
                    Expanded(child: _buildTestimonialCard('SplitNest saved my roommate relationship. No more awkward math at the end of the month.', 'Sarah Jenkins')),
                    const SizedBox(width: 24),
                    Expanded(child: _buildTestimonialCard('Used this for our bachelor party trip to Vegas. Incredible how easy it makes splitting hotel and drinks.', 'Mike Chen')),
                    const SizedBox(width: 24),
                    Expanded(child: _buildTestimonialCard('The personal ledger feature is a gamechanger. I can finally see my total debt across all my friend groups.', 'Elena Rodriguez')),
                  ],
                )
              : Column(
                  children: [
                    _buildTestimonialCard('SplitNest saved my roommate relationship. No more awkward math at the end of the month.', 'Sarah Jenkins'),
                    const SizedBox(height: 24),
                    _buildTestimonialCard('Used this for our bachelor party trip to Vegas. Incredible how easy it makes splitting hotel and drinks.', 'Mike Chen'),
                    const SizedBox(height: 24),
                    _buildTestimonialCard('The personal ledger feature is a gamechanger. I can finally see my total debt across all my friend groups.', 'Elena Rodriguez'),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildTestimonialCard(String quote, String author) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.format_quote, color: Color(0xFF7B61FF), size: 32),
          const SizedBox(height: 16),
          Text(
            '"$quote"',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              color: const Color(0xFF1E293B),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '- $author',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // CALL TO ACTION
  // =========================================================================
  Widget _buildCallToAction(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 100 : 24, vertical: 100),
      child: Container(
        padding: EdgeInsets.all(isDesktop ? 64 : 32),
        decoration: BoxDecoration(
          color: const Color(0xFF7B61FF),
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7B61FF).withOpacity(0.3),
              blurRadius: 60,
              offset: const Offset(0, 20),
            )
          ],
        ),
        child: Column(
          children: [
            Text(
              'Ready to split smartly?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: isDesktop ? 48 : 32,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              'Join over a million users organizing their shared finances.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            CursorRegion(
              cursorState: CursorState.explore,
              child: ElevatedButton(
                onPressed: () => context.go('/register'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF7B61FF),
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                ),
                child: Text(
                  'Create Free Account',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // FOOTER
  // =========================================================================
  Widget _buildFooter(bool isDesktop) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 100 : 24,
        vertical: 40,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '© 2026 SplitNest. All rights reserved.',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF94A3B8),
                  fontSize: 14,
                ),
              ),
              Row(
                children: [
                  Text('Privacy', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B))),
                  const SizedBox(width: 24),
                  Text('Terms', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B))),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }
}

class _Hero3DScene extends StatefulWidget {
  final bool isMobile;
  const _Hero3DScene({Key? key, this.isMobile = false}) : super(key: key);
  @override
  State<_Hero3DScene> createState() => _Hero3DSceneState();
}

class _Hero3DSceneState extends State<_Hero3DScene> with SingleTickerProviderStateMixin {
  Offset _mousePosition = Offset.zero;
  late AnimationController _idleController;
  
  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _idleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) {
        setState(() {
          _mousePosition = event.localPosition;
        });
      },
      onExit: (_) {
        setState(() {
          _mousePosition = Offset.zero;
        });
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          
          final centerX = width / 2;
          final centerY = height / 2;
          
          final rotateX = _mousePosition == Offset.zero ? 0.0 : ((_mousePosition.dy - centerY) / centerY) * 0.15;
          final rotateY = _mousePosition == Offset.zero ? 0.0 : ((_mousePosition.dx - centerX) / centerX) * -0.15;

          return AnimatedBuilder(
            animation: _idleController,
            builder: (context, child) {
              final idleOffset = _idleController.value * 20.0;
              
              return CursorRegion(
                cursorState: CursorState.custom,
                customText: 'Interact',
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Transform(
                      alignment: FractionalOffset.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001) 
                        ..rotateX(rotateX)
                        ..rotateY(rotateY)
                        ..translate(0.0, -idleOffset, 0.0),
                      child: Image.asset(
                        'assets/images/3d_premium_nest.png',
                        width: widget.isMobile ? width * 0.8 : width * 0.6,
                        fit: BoxFit.contain,
                      ),
                    ),
                    
                    Positioned(
                      top: height * 0.15 + (idleOffset * 0.5),
                      left: widget.isMobile ? 0 : width * 0.1,
                      child: Transform(
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateX(rotateX * 1.5)
                          ..rotateY(rotateY * 1.5)
                          ..translate(rotateY * -40, rotateX * -40, 0.0),
                        child: _buildGlassCard('Total Balance', '₹4,250', true),
                      ),
                    ),
                    
                    Positioned(
                      bottom: height * 0.15 - (idleOffset * 0.8),
                      right: widget.isMobile ? 0 : width * 0.05,
                      child: Transform(
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateX(rotateX * 0.8)
                          ..rotateY(rotateY * 0.8)
                          ..translate(rotateY * 50, rotateX * 50, 0.0),
                        child: _buildGlassCard('You Will Receive', '+₹2,500', true, isPositive: true),
                      ),
                    ),
                    
                    Positioned(
                      bottom: height * 0.25 - (idleOffset * 0.3),
                      left: widget.isMobile ? 20 : width * 0.15,
                      child: Transform(
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateX(rotateX * 1.2)
                          ..rotateY(rotateY * 1.2)
                          ..translate(rotateY * -30, rotateX * -60, 0.0),
                        child: _buildGlassCard('NEST', '5 members', false),
                      ),
                    ),
                  ],
                ),
              );
            }
          );
        }
      ),
    );
  }

  Widget _buildGlassCard(String title, String value, bool isCurrency, {bool? isPositive}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                spreadRadius: -5,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isPositive == true ? const Color(0xFF10B981) : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScrollIndicator extends StatefulWidget {
  @override
  State<_ScrollIndicator> createState() => _ScrollIndicatorState();
}

class _ScrollIndicatorState extends State<_ScrollIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  
  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animController.value * 10),
          child: child,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Scroll to explore',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 24,
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Container(
                width: 4,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF94A3B8),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF7B61FF).withOpacity(0.03)
      ..strokeWidth = 1.0;
      
    const step = 60.0;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

