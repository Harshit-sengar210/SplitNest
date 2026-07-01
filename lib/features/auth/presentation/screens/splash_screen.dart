import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  // Animation timings
  late Animation<double> _appearanceAnimation; // 0.0 -> 0.3
  late Animation<double> _splitAnimation;      // 0.3 -> 0.7
  late Animation<double> _successAnimation;    // 0.7 -> 0.85
  late Animation<double> _brandFadeAnimation;  // 0.8 -> 1.0

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    _appearanceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.25, curve: Curves.easeOutBack),
      ),
    );

    _splitAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 0.65, curve: Curves.easeInOutQuad),
      ),
    );

    _successAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.65, 0.8, curve: Curves.elasticOut),
      ),
    );

    _brandFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.78, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isAnimationDone = true;
        });
        _checkNavigation();
      }
    });
    _controller.forward();
  }

  bool _isAnimationDone = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _checkNavigation() {
    if (!mounted) return;
    if (!_isAnimationDone) return;
    
    final authState = ref.read(authNotifierProvider);
    if (authState.isLoading) return;
    
    final user = authState.user;
    if (user != null) {
      if (user.activeNestId == null) {
        context.go('/welcome');
      } else {
        context.go('/dashboard');
      }
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (!next.isLoading) {
        _checkNavigation();
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // 3 avatar endpoints relative to the center of stack
    final avatarOffsets = [
      const Offset(0, -110),     // Person 1 (Top)
      const Offset(-95, 75),     // Person 2 (Bottom Left)
      const Offset(95, 75),      // Person 3 (Bottom Right)
    ];

    final avatarImages = [
      'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80',
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=150&q=80',
      'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?auto=format&fit=crop&w=150&q=80',
    ];

    return Scaffold(
      backgroundColor: context.colors.background,
      body: Stack(
        children: [
          // Background soft ambient glows
          Positioned(
            top: -150,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.08),
                    blurRadius: 120,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.08),
                    blurRadius: 120,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),

          // Main animation canvas
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final showBrand = _brandFadeAnimation.value > 0.0;
                
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Canvas containing bill-split visualization
                    SizedBox(
                      width: 320,
                      height: 320,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 1. Connection lines (from center to avatars)
                          for (int i = 0; i < avatarOffsets.length; i++)
                            CustomPaint(
                              painter: _LinePainter(
                                start: Offset.zero,
                                end: avatarOffsets[i],
                                progress: _splitAnimation.value,
                              ),
                            ),

                          // 2. The Avatars
                          for (int i = 0; i < avatarOffsets.length; i++)
                            Positioned(
                              left: 160 + avatarOffsets[i].dx - 32,
                              top: 160 + avatarOffsets[i].dy - 32,
                              child: Transform.scale(
                                scale: _appearanceAnimation.value,
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: const Color(0xFF8B5CF6).withOpacity(0.3),
                                      width: 2,
                                    ),
                                    image: DecorationImage(
                                      image: NetworkImage(avatarImages[i]),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          // 3. Central Receipt Card
                          Positioned(
                            child: Transform.scale(
                              scale: _appearanceAnimation.value * (1.0 - _successAnimation.value * 0.1),
                              child: Opacity(
                                opacity: 1.0 - _successAnimation.value * 0.8,
                                child: Container(
                                  width: 58,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E1E28) : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.12),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: const Color(0xFF8B5CF6).withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Mock Receipt lines
                                      Container(height: 5, width: 28, color: const Color(0xFF8B5CF6).withOpacity(0.4)),
                                      Container(height: 4, width: 40, color: Colors.grey.withOpacity(0.3)),
                                      Container(height: 4, width: 34, color: Colors.grey.withOpacity(0.3)),
                                      const Divider(height: 4, thickness: 1),
                                      Align(
                                        alignment: Alignment.bottomRight,
                                        child: Container(height: 5, width: 18, color: const Color(0xFF8B5CF6)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // 4. Flying Coins (Slide from center to avatars)
                          if (_splitAnimation.value > 0.0 && _splitAnimation.value < 1.0)
                            for (int i = 0; i < avatarOffsets.length; i++)
                              Positioned(
                                left: 160 + (avatarOffsets[i].dx * _splitAnimation.value) - 12,
                                top: 160 + (avatarOffsets[i].dy * _splitAnimation.value) - 12,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF8B5CF6),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0xFF8B5CF6),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.add,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),

                          // 5. Success Checkmark in center (appears when split completes)
                          if (_successAnimation.value > 0.0)
                            Positioned(
                              child: Transform.scale(
                                scale: _successAnimation.value,
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0xFF10B981),
                                        blurRadius: 16,
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 36,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),
                    
                    // 6. Brand Name & Slogan (Fades in dynamically)
                    Opacity(
                      opacity: _brandFadeAnimation.value,
                      child: Column(
                        children: [
                          Text(
                            'SPLITNEST',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4.0,
                              color: const Color(0xFF8B5CF6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'SHARED EXPENSES. ELEVATED.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3.0,
                              color: context.colors.textSecondary,
                            ),
                          ),
                          if (_isAnimationDone && ref.watch(authNotifierProvider).isLoading) ...[
                            const SizedBox(height: 24),
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final double progress;

  _LinePainter({
    required this.start,
    required this.end,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8B5CF6).withOpacity(0.18)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(size.width / 2 + start.dx, size.height / 2 + start.dy);
    
    // Draw the connection line dynamically as progress updates
    final currentEnd = Offset(
      size.width / 2 + end.dx * progress,
      size.height / 2 + end.dy * progress,
    );
    path.lineTo(currentEnd.dx, currentEnd.dy);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
