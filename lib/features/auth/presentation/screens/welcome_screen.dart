import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/user_session_invalidator.dart';
import '../widgets/animated_gradient_background.dart';
import '../../../groups/domain/repositories/invite_repository.dart';

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
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
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
                    Navigator.pop(sheetContext);

                    try {
                      // Real join logic
                      await ref.read(inviteRepositoryProvider).joinNestFromInvite(code);
                      
                      // Refresh auth state to pull the newly set activeNestId
                      await ref.read(authNotifierProvider.notifier).refreshUser();

                      invalidateAllUserProviders(ref.invalidate);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Joined Nest successfully!'),
                            backgroundColor: const Color(0xFF10B981),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        context.go('/dashboard');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString().replaceAll('Exception: ', '')),
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
    final double screenHeight = MediaQuery.of(context).size.height;

    // Responsive scaling based on viewport height
    final double logoSize = (screenHeight * 0.11).clamp(70.0, 90.0);
    final double welcomeTitleSize = (screenHeight * 0.035).clamp(20.0, 25.0);
    final double welcomeSubtitleSize = (screenHeight * 0.019).clamp(13.0, 15.0);
    final double cardPaddingVertical = (screenHeight * 0.015).clamp(10.0, 16.0);
    final double cardSpacing = (screenHeight * 0.02).clamp(10.0, 16.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FF), // Light lavender background
      body: Stack(
        children: [
          // Ambient Glowing backgrounds
          const AnimatedGradientBackground(),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

                return SingleChildScrollView(
                  physics: isKeyboardOpen ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                      maxHeight: isKeyboardOpen ? double.infinity : constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Top Navigation / Logout Bar
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  onPressed: _onSignOutPressed,
                                  icon: const Icon(Icons.logout_rounded, color: Color(0xFF7C5CFF), size: 20),
                                  tooltip: 'Sign Out',
                                ),
                              ],
                            ),

                            // Centered SplitNest logo (constrained responsive size)
                            Center(
                              child: SizedBox(
                                width: logoSize,
                                height: logoSize,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Ripples
                                    Container(
                                      width: logoSize * 0.9,
                                      height: logoSize * 0.9,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF7C5CFF).withOpacity(0.06),
                                      ),
                                    ),
                                    Container(
                                      width: logoSize * 0.76,
                                      height: logoSize * 0.76,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF7C5CFF).withOpacity(0.1),
                                      ),
                                    ),
                                    // Main Logo Badge
                                    Container(
                                      width: logoSize * 0.6,
                                      height: logoSize * 0.6,
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
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.nights_stay_outlined,
                                        size: logoSize * 0.28,
                                        color: Colors.white,
                                      ),
                                    ),
                                    // Sparkles
                                    Positioned(
                                      top: logoSize * 0.1,
                                      left: logoSize * 0.1,
                                      child: FadeTransition(
                                        opacity: _sparkleAnimation,
                                        child: Icon(Icons.auto_awesome, color: const Color(0xFF7C5CFF), size: logoSize * 0.14),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: logoSize * 0.15,
                                      right: logoSize * 0.05,
                                      child: FadeTransition(
                                        opacity: _sparkleAnimation,
                                        child: Icon(Icons.auto_awesome, color: const Color(0xFF7C5CFF), size: logoSize * 0.12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: cardSpacing * 0.7),

                            // Title & Subtitle
                            Text(
                              'Welcome to SplitNest',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: welcomeTitleSize,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF1E1A34),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Let's build your first shared space.",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: welcomeSubtitleSize,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                            SizedBox(height: cardSpacing * 1.5),

                            // Section Title
                            Text(
                              "Choose how you'd like to get started",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1E1A34),
                              ),
                            ),
                            SizedBox(height: cardSpacing),

                            // Card 1: Create a Nest
                            _buildGlassCard(
                              context: context,
                              iconPath: 'assets/images/3d_house.png',
                              title: 'Create a Nest',
                              description: 'Start a new shared expense group',
                              buttonText: 'Create',
                              onTap: () => context.push('/groups/create'),
                              isPrimaryButton: true,
                              paddingVertical: cardPaddingVertical,
                            ),
                            SizedBox(height: cardSpacing),

                            // Card 2: Join a Nest
                            _buildGlassCard(
                              context: context,
                              iconPath: 'assets/images/3d_invite_gift.png',
                              title: 'Join a Nest',
                              description: 'Enter invite code to join a group',
                              buttonText: 'Join',
                              onTap: () => _showJoinNestSheet(context),
                              isPrimaryButton: false,
                              paddingVertical: cardPaddingVertical,
                            ),
                            const Spacer(),
                            SizedBox(height: cardSpacing),

                            // Skip Button
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  context.go('/dashboard');
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Skip for now',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF6B7280),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: Color(0xFF6B7280),
                                      size: 12,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
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
    required String buttonText,
    required VoidCallback onTap,
    required bool isPrimaryButton,
    required double paddingVertical,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.55),
            borderRadius: BorderRadius.circular(20),
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
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: paddingVertical),
          child: Row(
            children: [
              // Left 3D Icon illustration
              Image.asset(
                iconPath,
                width: 48,
                height: 48,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              
              // Title and Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: const Color(0xFF1E1A34),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                        color: const Color(0xFF6B7280),
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Action Button (comfortable touch target area)
              GestureDetector(
                onTap: onTap,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 70),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: isPrimaryButton
                        ? const LinearGradient(
                            colors: [Color(0xFF7C5CFF), Color(0xFF9070FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isPrimaryButton
                        ? null
                        : const Color(0xFF7C5CFF).withOpacity(0.12),
                    boxShadow: isPrimaryButton
                        ? [
                            BoxShadow(
                              color: const Color(0xFF7C5CFF).withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      buttonText,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isPrimaryButton ? Colors.white : const Color(0xFF7C5CFF),
                      ),
                    ),
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
