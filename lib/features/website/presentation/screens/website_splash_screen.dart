import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WebsiteSplashScreen extends StatefulWidget {
  const WebsiteSplashScreen({super.key});

  @override
  State<WebsiteSplashScreen> createState() => _WebsiteSplashScreenState();
}

class _WebsiteSplashScreenState extends State<WebsiteSplashScreen> with TickerProviderStateMixin {
  late AnimationController _heartbeatController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _ringScaleAnimation;
  late Animation<double> _ringOpacityAnimation;
  
  late AnimationController _textFadeController;
  late Animation<double> _textOpacityAnimation;
  
  bool _isAnimationDone = false;
  bool _isNavigating = false;
  
  @override
  void initState() {
    super.initState();
    
    // Heartbeat & Ring Controller (Looping subtle pulse after initial beats)
    _heartbeatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Sequence: 1.0 -> 1.10 -> 0.97 -> 1.06 -> 1.0 (Beat 1 & 2)
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.10).chain(CurveTween(curve: Curves.easeOut)), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.10, end: 0.97).chain(CurveTween(curve: Curves.easeInOut)), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.97, end: 1.06).chain(CurveTween(curve: Curves.easeInOut)), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.06, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 10), // Pause
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.10).chain(CurveTween(curve: Curves.easeOut)), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.10, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 20),
    ]).animate(_heartbeatController);

    // Rings expanding
    _ringScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.3).chain(CurveTween(curve: Curves.easeOut)), weight: 45),
      TweenSequenceItem(tween: ConstantTween(1.3), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.8).chain(CurveTween(curve: Curves.easeInOut)), weight: 40),
    ]).animate(_heartbeatController);

    _ringOpacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.4, end: 0.0).chain(CurveTween(curve: Curves.easeOut)), weight: 45),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.4).chain(CurveTween(curve: Curves.easeIn)), weight: 40),
    ]).animate(_heartbeatController);

    // Text Fade Controller
    _textFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _textOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textFadeController, curve: Curves.easeIn)
    );

    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    // Start heartbeat
    _heartbeatController.forward();
    
    // Wait for first heartbeat to finish then fade text
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) _textFadeController.forward();
    });

    // Wait for the full main animation to complete
    await Future.delayed(const Duration(milliseconds: 1800));
    
    if (mounted) {
      setState(() {
        _isAnimationDone = true;
      });
      // Set to a subtle continuous pulse while waiting
      _heartbeatController.repeat(reverse: true, period: const Duration(milliseconds: 2000));
      _checkNavigation();
    }
  }

  @override
  void dispose() {
    _heartbeatController.dispose();
    _textFadeController.dispose();
    super.dispose();
  }

  void _checkNavigation() {
    if (!mounted || _isNavigating || !_isAnimationDone) return;
    
    _isNavigating = true;
    
    // Smooth transition delay before actually navigating
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        context.go('/website');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use a soft lavender/purple gradient background
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF), // Light lavender
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFDFBFF),
                  Color(0xFFF3EDFF),
                ],
              ),
            ),
          ),
          
          // Rings & Logo
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 280,
                height: 280,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Ring
                    AnimatedBuilder(
                      animation: _heartbeatController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _ringScaleAnimation.value * 1.2,
                          child: Opacity(
                            opacity: _ringOpacityAnimation.value * 0.5,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Color(0xFF7B61FF),
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                    ),
                    
                    // Inner Ring
                    AnimatedBuilder(
                      animation: _heartbeatController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _ringScaleAnimation.value,
                          child: Opacity(
                            opacity: _ringOpacityAnimation.value,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Color(0xFF7B61FF).withValues(alpha: 0.5),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                    ),
                    
                    // 3D Logo
                    AnimatedBuilder(
                      animation: _heartbeatController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Image.asset(
                            'assets/images/splitnest_logo_final.png',
                            width: 200,
                            height: 200,
                            fit: BoxFit.contain,
                          ),
                        );
                      }
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Wordmark & Tagline
              FadeTransition(
                opacity: _textOpacityAnimation,
                child: Column(
                  children: [
                    const Text(
                      'SplitNest',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Split Smart, Live Easy.',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
