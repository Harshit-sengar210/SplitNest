import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/mock_database.dart';
import '../providers/auth_provider.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> with TickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  late AnimationController _sparkleController;
  late Animation<double> _sparkleAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _sparkleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  void _onSignOutPressed() {
    ref.read(authNotifierProvider.notifier).signOut();
  }

  void _showJoinNestSheet(BuildContext context) {
    final codeController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Join Existing Nest',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the invite code shared by your friend to access the shared expenses.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: const Color(0xFF6B7280),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: codeController,
                autofocus: true,
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.characters,
                maxLength: 8,
                decoration: InputDecoration(
                  hintText: 'e.g. FLAT402',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF9CA3AF),
                    fontWeight: FontWeight.bold,
                  ),
                  counterText: '',
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 2),
                  ),
                ),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final code = codeController.text.trim();
                  if (code.isNotEmpty) {
                    Navigator.pop(context);
                    
                    // Reset to default database values, simulating joining an existing setup
                    MockDatabase().resetToDefault();
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Joined Nest successfully with code "$code"!'),
                        backgroundColor: const Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );

                    try {
                      await ref.read(authNotifierProvider.notifier).updateActiveNestId('nest_1');
                      if (context.mounted) {
                        context.go('/dashboard');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to update active nest: $e'),
                            backgroundColor: const Color(0xFFEF4444),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C5CFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Join Nest',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FF), // Light lavender background
      body: Stack(
        children: [
          // Ambient Glowing backgrounds
          Positioned(
            top: -150,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C5CFF).withOpacity(0.08),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 200,
            right: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC5B8FF).withOpacity(0.12),
                    blurRadius: 120,
                    spreadRadius: 60,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top Navigation / Logout Bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              onPressed: _onSignOutPressed,
                              icon: const Icon(Icons.logout_rounded, color: Color(0xFF7C5CFF), size: 22),
                              tooltip: 'Sign Out',
                            ),
                          ],
                        ),

                        // Centered glowing circular SplitNest logo with ripples & sparkles
                        Center(
                          child: SizedBox(
                            width: 100,
                            height: 100,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Ripples
                                Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF7C5CFF).withOpacity(0.06),
                                  ),
                                ),
                                Container(
                                  width: 76,
                                  height: 76,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF7C5CFF).withOpacity(0.1),
                                  ),
                                ),
                                // Main Logo Badge
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF7C5CFF), Color(0xFF9070FF)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF7C5CFF).withOpacity(0.35),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.nights_stay_outlined,
                                    size: 28,
                                    color: Colors.white,
                                  ),
                                ),
                                // Sparkles
                                Positioned(
                                  top: 10,
                                  left: 10,
                                  child: FadeTransition(
                                    opacity: _sparkleAnimation,
                                    child: const Icon(Icons.auto_awesome, color: Color(0xFF7C5CFF), size: 14),
                                  ),
                                ),
                                Positioned(
                                  bottom: 15,
                                  right: 5,
                                  child: FadeTransition(
                                    opacity: _sparkleAnimation,
                                    child: const Icon(Icons.auto_awesome, color: Color(0xFF7C5CFF), size: 12),
                                  ),
                                ),
                                Positioned(
                                  top: 25,
                                  right: 15,
                                  child: ScaleTransition(
                                    scale: _sparkleAnimation,
                                    child: const Icon(Icons.star_rounded, color: Color(0xFF7C5CFF), size: 8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Title & Subtitle
                        Text(
                          'Welcome to SplitNest',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF1E1A34),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Let's build your first shared space.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Hero Illustration
                        Center(
                          child: SizedBox(
                            height: 240,
                            width: double.infinity,
                            child: Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                // Cozy purple bird nest with birds in center
                                Positioned(
                                  bottom: 10,
                                  child: _FloatingWrapper(
                                    floatAnimation: _floatAnimation,
                                    offsetMultiplier: -5,
                                    child: Image.asset(
                                      'assets/images/3d_bird_nest.png',
                                      width: 170,
                                      height: 170,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                
                                // Small modern house (Top/Left)
                                Positioned(
                                  left: 30,
                                  top: 15,
                                  child: _FloatingWrapper(
                                    floatAnimation: _floatAnimation,
                                    offsetMultiplier: 14,
                                    child: Image.asset(
                                      'assets/images/3d_house.png',
                                      width: 58,
                                      height: 58,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                
                                // Wallet (Bottom/Left)
                                Positioned(
                                  left: 20,
                                  bottom: 25,
                                  child: _FloatingWrapper(
                                    floatAnimation: _floatAnimation,
                                    offsetMultiplier: -11,
                                    child: Image.asset(
                                      'assets/images/3d_wallet.png',
                                      width: 54,
                                      height: 54,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                
                                // Coins (Top/Right)
                                Positioned(
                                  right: 40,
                                  top: 25,
                                  child: _FloatingWrapper(
                                    floatAnimation: _floatAnimation,
                                    offsetMultiplier: 10,
                                    child: Image.asset(
                                      'assets/images/3d_coins.png',
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                
                                // Indoor Plant (Middle/Right)
                                Positioned(
                                  right: 20,
                                  bottom: 75,
                                  child: _FloatingWrapper(
                                    floatAnimation: _floatAnimation,
                                    offsetMultiplier: -9,
                                    child: Image.asset(
                                      'assets/images/3d_plant.png',
                                      width: 52,
                                      height: 52,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),

                                // Luggage (Bottom/Right)
                                Positioned(
                                  right: 45,
                                  bottom: 15,
                                  child: _FloatingWrapper(
                                    floatAnimation: _floatAnimation,
                                    offsetMultiplier: 13,
                                    child: Image.asset(
                                      'assets/images/3d_luggage.png',
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),

                                // Floating geometric dots / shapes
                                Positioned(
                                  left: 80,
                                  bottom: 150,
                                  child: _FloatingWrapper(
                                    floatAnimation: _floatAnimation,
                                    offsetMultiplier: 8,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF7C5CFF),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 100,
                                  top: 10,
                                  child: _FloatingWrapper(
                                    floatAnimation: _floatAnimation,
                                    offsetMultiplier: -12,
                                    child: Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFC5B8FF),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Section Title
                        Text(
                          "Choose how you'd like to get started",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E1A34),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Card 1: Create a Nest
                        _buildGlassCard(
                          context: context,
                          iconPath: 'assets/images/3d_house.png',
                          title: 'Create a Nest',
                          description: 'Create a new expense group for friends, roommates, family, trips, or events.',
                          onTap: () => context.push('/groups/create'),
                        ),
                        const SizedBox(height: 14),

                        // Card 2: Join a Nest
                        _buildGlassCard(
                          context: context,
                          iconPath: 'assets/images/3d_people.png',
                          title: 'Join a Nest',
                          description: 'Join an existing group using an invitation code or shared link.',
                          onTap: () => _showJoinNestSheet(context),
                        ),
                        const Spacer(),
                        const SizedBox(height: 24),

                        // Bottom Section: Security
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.shield_outlined,
                              color: Color(0xFF7C5CFF),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Your data is encrypted and securely protected.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF7C7A8F),
                              ),
                            ),
                          ],
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

  Widget _buildGlassCard({
    required BuildContext context,
    required String iconPath,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.55),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.45),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C5CFF).withOpacity(0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                // Left 3D Icon illustration
                Image.asset(
                  iconPath,
                  width: 54,
                  height: 54,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 16),
                
                // Title and Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: const Color(0xFF1E1A34),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Right circular purple arrow button
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF7C5CFF),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 16,
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

class _FloatingWrapper extends StatelessWidget {
  final Widget child;
  final Animation<double> floatAnimation;
  final double offsetMultiplier;

  const _FloatingWrapper({
    required this.child,
    required this.floatAnimation,
    required this.offsetMultiplier,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, floatAnimation.value * offsetMultiplier),
          child: child,
        );
      },
      child: child,
    );
  }
}

// Container background extension to avoid using non-standard attributes directly
extension GlowingBoxDecoration on BoxDecoration {
  static final Map<BoxDecoration, bool> _glowRegistry = {};

  BoxDecoration copyWithBlur(bool blur) {
    final copy = copyWith();
    _glowRegistry[copy] = blur;
    return copy;
  }

  bool get hasBlur => _glowRegistry[this] ?? false;
}
