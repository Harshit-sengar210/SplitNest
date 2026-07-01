import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';

class GoogleSignInButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> with TickerProviderStateMixin {
  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isHovered = false;

  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeIn),
    );

    _initializeVideo();
  }

  void _initializeVideo() {
    _videoController = VideoPlayerController.asset(
      'assets/videos/efc33f38-5594-11ee-985b-c7f9b5ce47f5.mp4',
    );

    _videoController!.initialize().then((_) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _videoController!.setVolume(0.0);
        _videoController!.setLooping(true);
        _videoController!.play();
      }
    }).catchError((error) {
      debugPrint('Error initializing Google Sign-In video: $error');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    });

    _videoController!.addListener(() {
      if (_videoController!.value.hasError) {
        if (mounted && !_hasError) {
          setState(() {
            _hasError = true;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;
    const cardBgColor = Colors.white;
    const textColor = Color(0xFF1F2937);

    Widget content;
    if (_hasError || !_isInitialized) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 70,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(
                Icons.g_mobiledata,
                color: Color(0xFF4285F4),
                size: 44,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (widget.isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4285F4)),
              ),
            )
          else
            Text(
              'Continue with Google',
              style: GoogleFonts.plusJakartaSans(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      );
    } else {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Google Video Animation Container (No overlays)
          Container(
            height: 70,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: VideoPlayer(_videoController!),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (widget.isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7B61FF)),
              ),
            )
          else
            Text(
              'Continue with Google',
              style: GoogleFonts.plusJakartaSans(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
        ],
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
              if (_isHovered && !isDisabled)
                BoxShadow(
                  color: const Color(0xFF7B61FF).withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: isDisabled ? null : widget.onPressed,
              onTapDown: (_) {
                if (!isDisabled) _scaleController.forward();
              },
              onTapCancel: () {
                _scaleController.reverse();
              },
              onHighlightChanged: (highlighted) {
                if (!highlighted) {
                  _scaleController.reverse();
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

