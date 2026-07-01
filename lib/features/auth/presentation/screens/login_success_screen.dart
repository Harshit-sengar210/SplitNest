import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class LoginSuccessScreen extends ConsumerStatefulWidget {
  final bool isNewUser;
  const LoginSuccessScreen({super.key, this.isNewUser = false});

  @override
  ConsumerState<LoginSuccessScreen> createState() => _LoginSuccessScreenState();
}

class _LoginSuccessScreenState extends ConsumerState<LoginSuccessScreen> with SingleTickerProviderStateMixin {
  late VideoPlayerController _videoController;
  bool _isInitialized = false;
  bool _isNavigating = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _initializeVideo();

    // Safety fallback timeout to prevent getting stuck
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted && !_isNavigating) {
        _navigateToDashboard();
      }
    });
  }

  void _initializeVideo() {
    _videoController = VideoPlayerController.asset(
      'assets/videos/246003ce-1185-11ee-a1fb-b35ad4109460.mp4',
    );

    _videoController.initialize().then((_) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _videoController.setVolume(0.0);
        _videoController.setLooping(false);
        _videoController.play();
        
        // Start fading in text shortly after video starts
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _fadeController.forward();
          }
        });
      }
    }).catchError((error) {
      debugPrint('Error loading success transition video: $error');
      if (mounted) {
        _navigateToDashboard();
      }
    });

    _videoController.addListener(_videoListener);
  }

  void _videoListener() {
    if (!mounted) return;
    
    final value = _videoController.value;
    if (value.isInitialized &&
        !value.isPlaying &&
        value.position >= value.duration) {
      _navigateToDashboard();
    }
  }

  void _navigateToDashboard() {
    if (!_isNavigating) {
      _isNavigating = true;
      final activeNestId = ref.read(activeNestIdProvider);
      if (activeNestId == null) {
        context.go('/welcome');
      } else {
        context.go('/dashboard');
      }
    }
  }

  @override
  void dispose() {
    _videoController.removeListener(_videoListener);
    _videoController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Disable back navigation
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Layer 1: Fullscreen Video Player
            if (_isInitialized)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              )
            else
              Container(
                color: Colors.black,
              ),

            // Subtle dark overlay to ensure text is highly readable
            Container(
              color: Colors.black.withValues(alpha: 0.3),
            ),

            // Layer 2: Overlay Content (Logo, Brand, Text)
            FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Premium Gold Logo Badge
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            context.colors.primaryGold,
                            context.colors.primaryGold.withValues(alpha: 0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: context.colors.primaryGold.withValues(alpha: 0.3),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.nights_stay_outlined,
                          size: 40,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Title
                    Text(
                      widget.isNewUser ? 'Welcome to SplitNest' : 'Welcome Back',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // Subtitle
                    Text(
                      widget.isNewUser ? 'Setting up your nesting space...' : 'Preparing your nests...',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.7),
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
