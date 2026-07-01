import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {});
    });
  }

  List<OnboardingSlide> _getSlides(BuildContext context) {
    return [
      OnboardingSlide(
        title: 'Split Expenses,\nElevate Living',
        description: 'Nest your group bills, compute balances instantly, and enjoy hassle-free shared expenses with flatmates or travel buddies.',
        icon: Icons.account_balance_wallet_outlined,
        gradientColor: context.colors.primaryGold,
        videoPath: 'assets/videos/pinsnap-574771971204515760.mp4',
      ),
      OnboardingSlide(
        title: 'Real-Time\nSettle Up',
        description: 'Keep track of who owes whom with state-of-the-art fintech summaries. Settle payments seamlessly in a single tap.',
        icon: Icons.swap_horiz_rounded,
        gradientColor: context.colors.softBronze,
        videoPath: 'assets/videos/pinsnap-811703532868767383-story1.mp4',
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _onSkipPressed() async {
    setState(() {
      _isNavigating = true;
    });
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      context.go('/login');
    }
  }

  void _onNextPressed(int totalSlides) {
    if (_currentPage == totalSlides - 1) {
      _onSkipPressed();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final slides = _getSlides(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final topAreaHeight = screenHeight * 0.58;

    return Scaffold(
      backgroundColor: context.colors.background,
      body: Stack(
        children: [
          // Top 60% Video Container with curved bottom
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topAreaHeight,
            child: ClipPath(
              clipper: ConvexUpClipper(),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  for (int i = 0; i < slides.length; i++)
                    if (slides[i].videoPath != null)
                      _VideoBackgroundWidget(
                        isVisible: _currentPage == i,
                        videoPath: slides[i].videoPath!,
                      ),
                ],
              ),
            ),
          ),

          // Mini brand signature top left
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 24,
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: context.goldGradient,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.nights_stay_outlined,
                      size: 12,
                      color: context.colors.background,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'SPLITNEST',
                  style: textTheme.labelLarge?.copyWith(
                    letterSpacing: 2.0,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Skip button top right
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 24,
            child: _currentPage < slides.length - 1
                ? TextButton(
                    onPressed: _onSkipPressed,
                    child: Text(
                      'SKIP',
                      style: textTheme.labelLarge?.copyWith(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                        letterSpacing: 1.0,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Overlapping Logo Badge at center of curve
          Positioned(
            top: topAreaHeight - 40 - 24, // 24 is half of badge height (48)
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: context.colors.background,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: const Color(0xFF8B5CF6).withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.auto_awesome,
                    color: Color(0xFF8B5CF6),
                    size: 22,
                  ),
                ),
              ),
            ),
          ),

          // Bottom 40% Content Area
          Positioned(
            top: topAreaHeight - 15,
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: AnimatedOpacity(
                opacity: _isNavigating ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: Column(
                  children: [
                    const SizedBox(height: 36),
                    // Step Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF8B5CF6).withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'STEP 0${_currentPage + 1}',
                        style: textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF8B5CF6),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),

                    // Page slider for text content
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: slides.length,
                        onPageChanged: _onPageChanged,
                        itemBuilder: (context, index) {
                          final slide = slides[index];
                          
                          // Calculate the page scroll delta for custom transitions
                          double pageOffset = 0.0;
                          if (_pageController.hasClients && _pageController.position.haveDimensions) {
                            pageOffset = _pageController.page ?? 0.0;
                          } else {
                            pageOffset = _currentPage.toDouble();
                          }
                          final double delta = index - pageOffset;
                          
                          // Custom page transitions: scale down, fade, and translate X slightly (parallax)
                          final double opacity = (1 - delta.abs() * 1.2).clamp(0.0, 1.0);
                          final double scale = (1 - delta.abs() * 0.15).clamp(0.85, 1.0);
                          final double translationX = delta * 150.0;
                          
                          return Opacity(
                            opacity: opacity,
                            child: Transform(
                              transform: Matrix4.identity()
                                ..translate(translationX, 0.0)
                                ..scale(scale),
                              alignment: Alignment.center,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Slide Title
                                    Text(
                                      slide.title,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        height: 1.25,
                                        color: context.colors.textWhite,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // Slide Description
                                    Text(
                                      slide.description,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: context.colors.textSecondary,
                                        height: 1.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Footer section (Indicator & Buttons)
                    Padding(
                      padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 24.0),
                      child: SizedBox(
                        height: 56,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Page Indicators centered
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                slides.length,
                                (index) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  height: 6,
                                  width: _currentPage == index ? 24 : 6,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(3),
                                    color: _currentPage == index
                                        ? const Color(0xFF8B5CF6)
                                        : const Color(0xFF8B5CF6).withOpacity(0.2),
                                  ),
                                ),
                              ),
                            ),
                            
                            // Action Button (arrow in right bottom corner)
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () => _onNextPressed(slides.length),
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8B5CF6),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF8B5CF6).withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingSlide {
  final String title;
  final String description;
  final IconData icon;
  final Color gradientColor;
  final String? videoPath;

  OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradientColor,
    this.videoPath,
  });
}

class _VideoBackgroundWidget extends StatefulWidget {
  final bool isVisible;
  final String videoPath;

  const _VideoBackgroundWidget({
    required this.isVisible,
    required this.videoPath,
  });

  @override
  State<_VideoBackgroundWidget> createState() => _VideoBackgroundWidgetState();
}

class _VideoBackgroundWidgetState extends State<_VideoBackgroundWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    debugPrint('🎥 [VideoBackground] Initializing video: ${widget.videoPath}');
    // Premium cinematic background
    _controller = VideoPlayerController.asset(widget.videoPath);
    
    _controller.initialize().then((_) {
      debugPrint('🎥 [VideoBackground] Initialization complete: ${widget.videoPath}');
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _controller.setVolume(0);
        _controller.setLooping(true);
        if (widget.isVisible) {
          debugPrint('🎥 [VideoBackground] Auto-playing: ${widget.videoPath}');
          _controller.play();
        }
      }
    }).catchError((error) {
      debugPrint('🎥 [VideoBackground] ERROR loading video: $error');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    });

    _controller.addListener(() {
      if (_controller.value.hasError) {
        debugPrint('🎥 [VideoBackground] Playback ERROR: ${_controller.value.errorDescription}');
        if (mounted && !_hasError) {
          setState(() {
            _hasError = true;
          });
        }
      }
    });
  }

  @override
  void didUpdateWidget(_VideoBackgroundWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible && _isInitialized && !_hasError) {
        debugPrint('🎥 [VideoBackground] Resuming playback: ${widget.videoPath}');
        _controller.play();
      } else if (!_hasError) {
        debugPrint('🎥 [VideoBackground] Pausing playback: ${widget.videoPath}');
        _controller.pause();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      // Fallback image/container when video fails to load
      return Container(
        color: context.colors.background,
        child: Center(
          child: Icon(Icons.videocam_off_rounded, color: context.colors.primaryGold.withOpacity(0.3), size: 64),
        ),
      );
    }

    if (!_isInitialized) {
      // Loading indicator while initializing
      return Container(
        color: context.colors.background,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(context.colors.primaryGold),
          ),
        ),
      );
    }

    return AnimatedOpacity(
      opacity: widget.isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller.value.size.width,
              height: _controller.value.size.height,
              child: VideoPlayer(_controller),
            ),
          ),
        ],
      ),
    );
  }
}

class ConvexUpClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height);
    
    // Curves smoothly upwards towards the center
    final controlPoint = Offset(size.width / 2, size.height - 40);
    final endPoint = Offset(size.width, size.height);
    
    path.quadraticBezierTo(
      controlPoint.dx,
      controlPoint.dy,
      endPoint.dx,
      endPoint.dy,
    );
    
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

