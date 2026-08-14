import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/animations/custom_cursor.dart';
import '../widgets/animations/cursor_provider.dart';

class WebsiteDownloadScreen extends StatefulWidget {
  const WebsiteDownloadScreen({super.key});

  @override
  State<WebsiteDownloadScreen> createState() => _WebsiteDownloadScreenState();
}

class _WebsiteDownloadScreenState extends State<WebsiteDownloadScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOutCubic),
    );

    _mainController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: Colors.transparent, // Inherits gradient from shell
      body: SingleChildScrollView(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Center(
              child: Container(
                width: isDesktop ? 1200 : size.width * 0.9,
                padding: EdgeInsets.only(top: isDesktop ? 160 : 120, bottom: 80),
                child: Column(
                  children: [
                    // Hero Section
                    isDesktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(flex: 5, child: _buildLeftContent(isDesktop)),
                              const SizedBox(width: 64),
                              Expanded(flex: 6, child: _buildRightMockup(isDesktop)),
                            ],
                          )
                        : Column(
                            children: [
                              _buildLeftContent(isDesktop),
                              const SizedBox(height: 64),
                              _buildRightMockup(isDesktop),
                            ],
                          ),
                    const SizedBox(height: 80),
                    // Features Banner Section
                    _buildFeaturesBanner(isDesktop),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeftContent(bool isDesktop) {
    return Column(
      crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pill Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7B61FF).withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFF7B61FF), size: 16),
              const SizedBox(width: 8),
              Text(
                'Smart Money Splitting, Made Simple',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF7B61FF),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        // Heading
        Text(
          'Split Smart,\nLive Easy.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: isDesktop ? 64 : 48,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF0F172A),
            height: 1.1,
            letterSpacing: -2,
          ),
          textAlign: isDesktop ? TextAlign.left : TextAlign.center,
        ),
        const SizedBox(height: 24),
        // Subtitle
        Text(
          'SplitNest helps you split expenses, track balances and settle up with friends, family, or groups - effortlessly and accurately.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: isDesktop ? 18 : 16,
            color: const Color(0xFF64748B),
            height: 1.6,
          ),
          textAlign: isDesktop ? TextAlign.left : TextAlign.center,
        ),
        const SizedBox(height: 48),
        // Buttons
        Wrap(
          spacing: 24,
          runSpacing: 24,
          alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildDownloadAppButton(),
            _buildSeeHowItWorksButton(),
          ],
        ),
        const SizedBox(height: 48),
        // Avatars & Social Proof
        Row(
          mainAxisAlignment: isDesktop ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 40,
              child: Stack(
                children: [
                  _buildAvatar(0),
                  _buildAvatar(25),
                  _buildAvatar(50),
                  _buildAvatar(75),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Loved by 50K+ users',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                    fontSize: 14,
                  ),
                ),
                Text(
                  'all around the world',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF64748B),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatar(double leftPos) {
    return Positioned(
      left: leftPos,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: const Icon(Icons.person, color: Color(0xFF94A3B8), size: 24),
      ),
    );
  }

  Widget _buildDownloadAppButton() {
    return CursorRegion(
      cursorState: CursorState.download,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final url = Uri.base.resolve('downloads/splitnest-release.apk');
            if (await canLaunchUrl(url)) await launchUrl(url);
          },
          borderRadius: BorderRadius.circular(100),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF7B61FF),
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7B61FF).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Download the App',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.download_rounded, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeeHowItWorksButton() {
    return CursorRegion(
      cursorState: CursorState.explore,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {}, // Action for "See how it works" (e.g. video modal)
          borderRadius: BorderRadius.circular(100),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'See How It Works',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF7B61FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRightMockup(bool isDesktop) {
    return Image.asset(
      'assets/images/hero_phone.png',
      height: isDesktop ? 700 : 500,
      fit: BoxFit.contain,
    );
  }

  Widget _buildFeaturesBanner(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 24, vertical: 48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: isDesktop 
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _buildFeatureItem('assets/images/3d_profile_members.png', 'Create Nests', 'Create groups for trips, homes, or any occasion')),
                const SizedBox(width: 24),
                Expanded(child: _buildFeatureItem('assets/images/3d_premium_ledger.png', 'Add Expenses', 'Add bills in seconds and split easily')),
                const SizedBox(width: 24),
                Expanded(child: _buildFeatureItem('assets/images/3d_scan.png', 'Smart Balances', 'Automatic calculations with real-time updates')),
                const SizedBox(width: 24),
                Expanded(child: _buildFeatureItem('assets/images/3d_purple_wallet_hero.png', 'Settle Easily', 'Settle up directly and close debts')),
              ],
            )
          : Column(
              children: [
                _buildFeatureItem('assets/images/3d_profile_members.png', 'Create Nests', 'Create groups for trips, homes, or any occasion'),
                const SizedBox(height: 32),
                _buildFeatureItem('assets/images/3d_premium_ledger.png', 'Add Expenses', 'Add bills in seconds and split easily'),
                const SizedBox(height: 32),
                _buildFeatureItem('assets/images/3d_scan.png', 'Smart Balances', 'Automatic calculations with real-time updates'),
                const SizedBox(height: 32),
                _buildFeatureItem('assets/images/3d_purple_wallet_hero.png', 'Settle Easily', 'Settle up directly and close debts'),
              ],
            ),
    );
  }

  Widget _buildFeatureItem(String imgPath, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(imgPath, width: 48, height: 48, errorBuilder: (c,e,s) => const Icon(Icons.star, color: Color(0xFF7B61FF), size: 48)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
