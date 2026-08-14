import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

class AnimatedGradientBackground extends StatefulWidget {
  const AnimatedGradientBackground({super.key});

  @override
  State<AnimatedGradientBackground> createState() => _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final orbSize = size.width * 0.8;

    return Stack(
      children: [
        // Base Background
        Container(color: const Color(0xFFF9FAFB)), // Light subtle gray-white

        // Top Left Purple Orb
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final xOffset = sin(_controller.value * 2 * pi) * 40;
            final yOffset = cos(_controller.value * 2 * pi) * 40;
            return Positioned(
              top: -orbSize * 0.3 + yOffset,
              left: -orbSize * 0.2 + xOffset,
              child: child!,
            );
          },
          child: Container(
            width: orbSize,
            height: orbSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color(0x667B61FF), // Soft Purple
                  Color(0x007B61FF), // Transparent
                ],
              ),
            ),
          ),
        ),

        // Top Right Blue/Cyan Orb
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final xOffset = cos(_controller.value * 2 * pi) * 50;
            final yOffset = sin(_controller.value * 2 * pi) * 50;
            return Positioned(
              top: -orbSize * 0.2 + yOffset,
              right: -orbSize * 0.3 + xOffset,
              child: child!,
            );
          },
          child: Container(
            width: orbSize,
            height: orbSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color(0x444285F4), // Soft Blue
                  Color(0x004285F4), // Transparent
                ],
              ),
            ),
          ),
        ),

        // Blur Filter to create glassmorphic effect
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(color: Colors.transparent),
          ),
        ),
      ],
    );
  }
}
