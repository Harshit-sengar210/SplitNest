import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_header.dart';

class AboutAppScreen extends StatefulWidget {
  const AboutAppScreen({super.key});

  @override
  State<AboutAppScreen> createState() => _AboutAppScreenState();
}

class _AboutAppScreenState extends State<AboutAppScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));
    _fadeController.forward();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _showPrivacyPolicy() {
    _showLegalModal(
      title: 'Privacy Policy',
      content: 'Last updated: June 2026\n\n'
          'Your privacy is our utmost priority. SplitNest protects your financial data and profile details using industry-leading encryption. We do not sell or share your personal database records with third-party advertisers.\n\n'
          '1. Information Collection: We store your name, email, and split transactions purely to calculate balances in your active nests.\n\n'
          '2. Security Measures: All transactions are protected via secure tokens and database rules.\n\n'
          '3. Data Control: You can delete your account and clear all active history at any time from the Danger Zone under Security Settings.',
    );
  }

  void _showTermsOfService() {
    _showLegalModal(
      title: 'Terms & Conditions',
      content: 'Last updated: June 2026\n\n'
          'By using SplitNest, you agree to these platform guidelines:\n\n'
          '1. Acceptable Use: SplitNest is built to facilitate peer-to-peer balance tracking. Users are solely responsible for actual financial settlements made off-platform.\n\n'
          '2. Accuracy: Please ensure accurate inputs when creating group expenses. SplitNest does not verify external payment transactions.\n\n'
          '3. Subscription Terms: Gold Membership options auto-renew monthly until cancelled. Upgrades provide unlocked analytic insight modules.',
    );
  }

  void _showLicenses() {
    _showLegalModal(
      title: 'Open Source Licenses',
      content: 'SplitNest is made possible by these incredible open-source packages:\n\n'
          '• Flutter SDK (BSD 3-Clause)\n'
          '• Flutter Riverpod (MIT)\n'
          '• GoRouter (MIT)\n'
          '• Firebase Core & Firestore (Apache 2.0)\n'
          '• Google Fonts (OFL)\n'
          '• Cupertino Icons (MIT)\n\n'
          'We extend our gratitude to the developers contributing to the Flutter and open-source ecosystem.',
    );
  }

  void _showLegalModal({required String title, required String content}) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF1F2937),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF9CA3AF)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(
                      content,
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF6B7280),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(29),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7B61FF), Color(0xFF6CA8FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7B61FF).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(29)),
                    ),
                    child: Text('Close', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSocialIcon(IconData icon, String label) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening SplitNest $label...', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
              backgroundColor: const Color(0xFF7B61FF),
            ),
          );
        },
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7B61FF).withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: const Color(0xFF7B61FF), size: 20),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const AppHeader(title: 'About SplitNest'),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF5F3FF),
              Color(0xFFFFFFFF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            _BackgroundShapes(floatAnimation: _floatAnimation),
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),
                        // App Logo (Premium 3D style)
                        Center(
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF7B61FF), Color(0xFF6CA8FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF7B61FF).withOpacity(0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Container(
                                width: 84,
                                height: 84,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.layers_rounded,
                                    size: 40,
                                    color: Color(0xFF7B61FF),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // App Name
                        Center(
                          child: Text(
                            'SplitNest',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF1F2937),
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Version
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F3FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF7B61FF).withOpacity(0.2)),
                            ),
                            child: Text(
                              'v1.2.4 Gold Edition',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF7B61FF),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Tagline
                        Center(
                          child: Text(
                            'Premium Nesting. Seamless Splitting.',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF6B7280),
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),

                        // 1. About Us Card
                        _SectionTitle(title: 'About Us'),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7B61FF).withOpacity(0.04),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Text(
                            'SplitNest reimagines how you share expenses with roomies, friends, and travel partners. Designed with a luxury aesthetic and fluid UX, we make group balance tracking feel premium, fast, and secure.',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF4B5563),
                              fontSize: 13,
                              height: 1.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // 2. Features Overview Card
                        _SectionTitle(title: 'Key Features'),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7B61FF).withOpacity(0.04),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildFeatureRow(Icons.account_balance_wallet_outlined, const Color(0xFF7B61FF), 'Real-time Balances', 'Instant updates on who owes whom'),
                              const Divider(color: Color(0xFFF3F4F6), height: 24, indent: 56),
                              _buildFeatureRow(Icons.camera_alt_outlined, const Color(0xFF6CA8FF), 'Scan Receipts', 'Upload receipts for automated splitting'),
                              const Divider(color: Color(0xFFF3F4F6), height: 24, indent: 56),
                              _buildFeatureRow(Icons.chat_bubble_outline_rounded, const Color(0xFFA78BFA), 'Nest Chat Feed', 'Discuss specific expenses directly inside groups'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Legal & Doc Links
                        _SectionTitle(title: 'Legal & Licenses'),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7B61FF).withOpacity(0.04),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildLinkRow('Privacy Policy', _showPrivacyPolicy),
                              const Divider(color: Color(0xFFF3F4F6), height: 1, indent: 20, endIndent: 20),
                              _buildLinkRow('Terms & Conditions', _showTermsOfService),
                              const Divider(color: Color(0xFFF3F4F6), height: 1, indent: 20, endIndent: 20),
                              _buildLinkRow('Open Source Licenses', _showLicenses),
                            ],
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Developer credits
                        Center(
                          child: Text(
                            'Designed & Developed by',
                            style: GoogleFonts.plusJakartaSans(color: const Color(0xFF9CA3AF), fontSize: 11),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            'CYBERLIM',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF7B61FF),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Social Links
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildSocialIcon(Icons.language_rounded, 'Website'),
                            const SizedBox(width: 16),
                            _buildSocialIcon(Icons.code_rounded, 'GitHub'),
                            const SizedBox(width: 16),
                            _buildSocialIcon(Icons.alternate_email_rounded, 'Twitter'),
                          ],
                        ),
                        const SizedBox(height: 36),

                        // Visit Website Action
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton(
                            onPressed: () async {
                              final Uri url = Uri.parse('https://cyberlim.com');
                              if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Could not launch website', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  );
                                }
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF7B61FF), width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                              foregroundColor: const Color(0xFF7B61FF),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.open_in_new_rounded, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'VISIT OUR WEBSITE',
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, Color iconColor, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _build3DIcon(icon, iconColor),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF1F2937),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF6B7280),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _build3DIcon(IconData icon, Color primaryColor) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            primaryColor.withOpacity(0.85),
            primaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.35),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildLinkRow(String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      splashColor: const Color(0xFF7B61FF).withOpacity(0.04),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF1F2937),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF9CA3AF), size: 14),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          color: const Color(0xFF9CA3AF),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _BackgroundShapes extends StatelessWidget {
  final Animation<double> floatAnimation;

  const _BackgroundShapes({required this.floatAnimation});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 140,
          left: -45,
          child: AnimatedBuilder(
            animation: floatAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, floatAnimation.value * 12),
                child: child,
              );
            },
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFA78BFA).withOpacity(0.18),
                    const Color(0xFFA78BFA).withOpacity(0.01),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 150,
          right: -40,
          child: AnimatedBuilder(
            animation: floatAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -floatAnimation.value * 14),
                child: child,
              );
            },
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6CA8FF).withOpacity(0.18),
                    const Color(0xFF6CA8FF).withOpacity(0.01),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
