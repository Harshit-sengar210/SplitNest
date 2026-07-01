import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// A premium success animation overlay with confetti particles,
/// a glowing checkmark, and a golden ring burst effect.
class SuccessAnimation extends StatefulWidget {
  final String title;
  final String subtitle;
  final VoidCallback onComplete;
  final Duration displayDuration;

  const SuccessAnimation({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onComplete,
    this.displayDuration = const Duration(milliseconds: 2800),
  });

  @override
  State<SuccessAnimation> createState() => _SuccessAnimationState();
}

class _SuccessAnimationState extends State<SuccessAnimation>
    with TickerProviderStateMixin {
  late AnimationController _checkController;
  late AnimationController _ringController;
  late AnimationController _confettiController;
  late AnimationController _fadeController;

  late Animation<double> _checkScale;
  late Animation<double> _checkOpacity;
  late Animation<double> _ringScale;
  late Animation<double> _ringOpacity;
  late Animation<double> _textSlide;
  late Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();

    // Ring burst
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _ringScale = Tween<double>(begin: 0.0, end: 2.5).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeOutCubic),
    );
    _ringOpacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeOut),
    );

    // Checkmark
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.elasticOut),
    );
    _checkOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _checkController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // Confetti
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    // Text fade-in
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _textSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    // Ring burst first
    _ringController.forward();
    await Future.delayed(const Duration(milliseconds: 200));

    // Checkmark bounces in
    _checkController.forward();
    _confettiController.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    // Text fades in
    _fadeController.forward();

    // Wait for display duration then complete
    await Future.delayed(widget.displayDuration);
    if (mounted) {
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    _checkController.dispose();
    _ringController.dispose();
    _confettiController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ring + Check + Confetti stack
            SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Ring burst
                  AnimatedBuilder(
                    animation: _ringController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _ringOpacity.value,
                        child: Transform.scale(
                          scale: _ringScale.value,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: context.colors.primaryGold,
                                width: 3,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Confetti particles
                  AnimatedBuilder(
                    animation: _confettiController,
                    builder: (context, _) {
                      return CustomPaint(
                        size: const Size(200, 200),
                        painter: _ConfettiPainter(
                          progress: _confettiController.value,
                          contextColors: context.colors,
                        ),
                      );
                    },
                  ),

                  // Gold checkmark circle
                  AnimatedBuilder(
                    animation: _checkController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _checkOpacity.value,
                        child: Transform.scale(
                          scale: _checkScale.value,
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: context.colors.primaryGold,
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              color: context.colors.background,
                              size: 48,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Success text
            AnimatedBuilder(
              animation: _fadeController,
              builder: (context, _) {
                return Opacity(
                  opacity: _textOpacity.value,
                  child: Transform.translate(
                    offset: Offset(0, _textSlide.value),
                    child: Column(
                      children: [
                        Text(
                          widget.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.colors.primaryGold,
                              ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          widget.subtitle,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: context.colors.textSecondary,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints animated confetti particles radiating outward.
class _ConfettiPainter extends CustomPainter {
  final double progress;
  final int particleCount;
  final List<_Particle> _particles;

  _ConfettiPainter({
    required this.progress,
    required AppColorsExtension contextColors,
    this.particleCount = 20,
  }) : _particles = List.generate(particleCount, (i) => _Particle(i, particleCount, contextColors));

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (final p in _particles) {
      final distance = p.speed * progress * 100;
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      final dx = center.dx + cos(p.angle) * distance;
      final dy = center.dy + sin(p.angle) * distance;

      final paint = Paint()
        ..color = p.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(dx, dy), p.radius * (1.0 - progress * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _Particle {
  final double angle;
  final double speed;
  final double radius;
  final Color color;

  static final _rng = Random(42);

  _Particle(int index, int total, AppColorsExtension contextColors)
      : angle = (index / total) * 2 * pi + _rng.nextDouble() * 0.5,
        speed = 0.6 + _rng.nextDouble() * 0.8,
        radius = 2.5 + _rng.nextDouble() * 3.0,
        color = _getRandomColor(contextColors);

  static Color _getRandomColor(AppColorsExtension contextColors) {
    final colors = [
      contextColors.primaryGold,
      const Color(0xFFF3DF95),
      const Color(0xFFB3923B),
      contextColors.softBronze,
      const Color(0xFFFFD700),
      const Color(0xFFDAA520),
    ];
    return colors[_rng.nextInt(colors.length)];
  }
}
