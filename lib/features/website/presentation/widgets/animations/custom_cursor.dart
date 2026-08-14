import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'cursor_provider.dart';

class CustomCursorWrapper extends ConsumerStatefulWidget {
  final Widget child;
  const CustomCursorWrapper({Key? key, required this.child}) : super(key: key);

  @override
  ConsumerState<CustomCursorWrapper> createState() => _CustomCursorWrapperState();
}

class _CustomCursorWrapperState extends ConsumerState<CustomCursorWrapper> {
  Offset _mousePosition = Offset.zero;
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    // Disable custom cursor on mobile touch devices
    final isDesktop = MediaQuery.of(context).size.width > 800;
    if (!isDesktop) return widget.child;

    final cursorState = ref.watch(cursorStateProvider);
    final customText = ref.watch(cursorCustomTextProvider);
    
    return MouseRegion(
      cursor: SystemMouseCursors.none,
      onHover: (event) {
        setState(() {
          _mousePosition = event.position;
          _isHovering = true;
        });
      },
      onExit: (_) {
        setState(() {
          _isHovering = false;
        });
      },
      child: Stack(
        children: [
          widget.child,
          if (_isHovering)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 150), // Increased for lagging/heavy feel
              curve: Curves.easeOutQuad,
              left: _mousePosition.dx,
              top: _mousePosition.dy,
              child: IgnorePointer(
                child: _buildCursor(cursorState, customText),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCursor(CursorState state, String customText) {
    final bool isNormal = state == CursorState.normal;
    final String text = _getCursorText(state, customText);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300), // Slightly longer transform for premium feel
      curve: Curves.easeOutBack, // Bouncy/spring physics for the shape transformation
      transform: Matrix4.translationValues(
        isNormal ? -8.0 : -40.0,
        isNormal ? -8.0 : -40.0,
        0,
      ),
      width: isNormal ? 16 : 80,
      height: isNormal ? 16 : 80,
      decoration: BoxDecoration(
        color: isNormal ? const Color(0xFF7B61FF) : const Color(0xFF7B61FF).withOpacity(0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B61FF).withOpacity(0.3),
            blurRadius: isNormal ? 8 : 20,
            spreadRadius: isNormal ? 0 : 5,
          )
        ],
      ),
      alignment: Alignment.center,
      child: isNormal
          ? null
          : AnimatedOpacity(
              opacity: isNormal ? 0 : 1,
              duration: const Duration(milliseconds: 200),
              child: Text(
                text,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
    );
  }

  String _getCursorText(CursorState state, String customText) {
    switch (state) {
      case CursorState.explore:
        return 'Explore';
      case CursorState.open:
        return 'Open';
      case CursorState.download:
        return 'Download';
      case CursorState.custom:
        return customText;
      default:
        return '';
    }
  }
}

class CursorRegion extends ConsumerWidget {
  final Widget child;
  final CursorState cursorState;
  final String? customText;

  const CursorRegion({
    Key? key,
    required this.child,
    required this.cursorState,
    this.customText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MouseRegion(
      cursor: SystemMouseCursors.none,
      onEnter: (_) {
        ref.read(cursorStateProvider.notifier).state = cursorState;
        if (customText != null) {
          ref.read(cursorCustomTextProvider.notifier).state = customText!;
        }
      },
      onExit: (_) {
        ref.read(cursorStateProvider.notifier).state = CursorState.normal;
      },
      child: child,
    );
  }
}
