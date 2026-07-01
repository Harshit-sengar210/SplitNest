import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GoldButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;
  final Widget? icon;
  final double width;
  final double height;
  final double borderRadius;

  const GoldButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.icon,
    this.width = double.infinity,
    this.height = 56.0,
    this.borderRadius = 12.0, // Updated to 12px
  });

  @override
  State<GoldButton> createState() => _GoldButtonState();
}

class _GoldButtonState extends State<GoldButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonDisabled = widget.onPressed == null || widget.isLoading;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: buttonDisabled ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Opacity(
          opacity: buttonDisabled ? 0.6 : 1.0,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: widget.isSecondary
                ? BoxDecoration(
                    color: context.colors.card, // White background
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    border: Border.all(
                      color: context.colors.accentBrown, // Gold border
                      width: 1.0, // Thin border
                    ),
                  )
                : BoxDecoration(
                    color: context.colors.primaryGold, // Solid primary gold background
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    // No shadows or glows
                  ),
            child: Center(
              child: widget.isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.isSecondary ? context.colors.primaryGold : context.colors.textWhite,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          widget.icon!,
                          const SizedBox(width: 10),
                        ],
                        Text(
                          widget.text,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: widget.isSecondary
                                ? context.colors.primaryGold
                                : context.colors.textWhite, // Primary Text (dark) for Primary Button
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
