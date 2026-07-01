import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final bool hasUnsavedChanges;
  final VoidCallback? onBackPress;
  final List<Widget>? actions;

  const AppHeader({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.hasUnsavedChanges = false,
    this.onBackPress,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  Future<bool> _showDiscardDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: context.colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: context.colors.softBronze, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.colors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.warning_amber_rounded, color: context.colors.error, size: 40),
              ),
              SizedBox(height: 20),
              Text(
                'Discard changes?',
                style: TextStyle(
                  color: context.colors.textWhite,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You have unsaved changes. Are you sure you want to discard them and go back?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Continue Editing',
                        style: TextStyle(color: context.colors.textWhite, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.error,
                        foregroundColor: context.colors.textWhite,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Discard & Go Back',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }

  void _handleBack(BuildContext context) async {
    if (onBackPress != null) {
      onBackPress!();
      return;
    }
    if (hasUnsavedChanges) {
      final shouldDiscard = await _showDiscardDialog(context);
      if (shouldDiscard && context.mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/dashboard');
        }
      }
    } else {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showDiscardDialog(context);
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop(result);
        }
      },
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        centerTitle: false,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [
              if (showBackButton) ...[
                AppHeaderBackButton(
                  onTap: () => _handleBack(context),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: context.colors.textWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: actions,
      ),
    );
  }
}

class AppHeaderBackButton extends StatefulWidget {
  final VoidCallback onTap;
  const AppHeaderBackButton({super.key, required this.onTap});

  @override
  State<AppHeaderBackButton> createState() => _AppHeaderBackButtonState();
}

class _AppHeaderBackButtonState extends State<AppHeaderBackButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.colors.card,
            shape: BoxShape.circle,
            border: Border.all(
              color: context.colors.accentBrown, // Gold border
              width: 1,
            ),
            // Removed boxShadow
          ),
          child: Padding(
            padding: EdgeInsets.only(left: 6.0), // center chevron
            child: Icon(
              Icons.arrow_back_ios,
              color: context.colors.primaryGold,
              size: 16,
            ),
          ),
        ),
      ),
    );
  }
}
