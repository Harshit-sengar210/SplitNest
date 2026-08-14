import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InAppNotificationOverlay {
  static void show({
    required BuildContext context,
    required String title,
    required String body,
    VoidCallback? onTap,
  }) {
    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    // Animation controller for slide/fade
    final animationController = AnimationController(
      vsync: overlayState,
      duration: const Duration(milliseconds: 300),
    );

    void removeOverlay() {
      animationController.reverse().then((_) {
        overlayEntry.remove();
        animationController.dispose();
      });
    }

    overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: _InAppNotificationWidget(
              title: title,
              body: body,
              animationController: animationController,
              onTap: () {
                onTap?.call();
                removeOverlay();
              },
              onDismiss: removeOverlay,
            ),
          ),
        );
      },
    );

    overlayState.insert(overlayEntry);
    animationController.forward();

    // Auto dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (overlayEntry.mounted) {
        removeOverlay();
      }
    });
  }
}

class _InAppNotificationWidget extends StatelessWidget {
  final String title;
  final String body;
  final AnimationController animationController;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _InAppNotificationWidget({
    required this.title,
    required this.body,
    required this.animationController,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOutCubic,
    ));

    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: animationController,
        child: GestureDetector(
          onTap: onTap,
          onVerticalDragUpdate: (details) {
            if (details.primaryDelta! < -5) {
              onDismiss();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937), // Dark premium color
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7B61FF).withOpacity(0.2), // Purple glow
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: const Color(0xFF7B61FF).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B61FF).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: Color(0xFFA78BFA),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        body,
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFFD1D5DB),
                          fontSize: 13,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onDismiss,
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.close_rounded,
                      color: Color(0xFF9CA3AF),
                      size: 20,
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
