import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_colors.dart';
import 'glass_container.dart';
import 'gold_button.dart';

/// Preset black-and-gold luxury avatar images from Unsplash.
class PremiumPresets {
  static const List<Map<String, String>> presets = [
    {
      'name': 'Gold Silk',
      'url': 'https://images.unsplash.com/photo-1536924940846-227afb31e2a5?q=80&w=300&auto=format&fit=crop',
    },
    {
      'name': 'Golden Foil',
      'url': 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=300&auto=format&fit=crop',
    },
    {
      'name': 'Luxury Lines',
      'url': 'https://images.unsplash.com/photo-1604871000636-074fa5117945?q=80&w=300&auto=format&fit=crop',
    },
    {
      'name': 'Aura Gold',
      'url': 'https://images.unsplash.com/photo-1541701494587-cb58502866ab?q=80&w=300&auto=format&fit=crop',
    },
  ];
}

class PremiumImageSelector {
  /// Shows the premium selection sheet and returns the selected image (preset URL or base64 data URI).
  static Future<String?> show(BuildContext context, {required String title}) async {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.4), // Lighter barrier
      builder: (context) => _ImageSelectorSheet(title: title),
    );
  }
}

class _ImageSelectorSheet extends StatefulWidget {
  final String title;

  const _ImageSelectorSheet({required this.title});

  @override
  State<_ImageSelectorSheet> createState() => _ImageSelectorSheetState();
}

class _ImageSelectorSheetState extends State<_ImageSelectorSheet> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();
      final base64String = 'data:image/png;base64,${base64.encode(bytes)}';

      if (!mounted) return;
      _showPreviewDialog(base64String);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e', style: TextStyle(color: context.colors.textWhite)),
          backgroundColor: context.colors.error,
        ),
      );
    }
  }

  void _showPreviewDialog(String imagePathOrBase64) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5), // Lighter barrier
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return _ImagePreviewDialog(
          imagePathOrBase64: imagePathOrBase64,
          onApply: (value) {
            Navigator.pop(context); // Close preview
            Navigator.pop(context, value); // Return selected image
          },
          onCancel: () {
            Navigator.pop(context); // Close preview
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: context.colors.background, // Solid background instead of gradient
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: context.colors.accentBrown, width: 1.5),
        // Removed boxShadow
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          Text(
            widget.title,
            style: textTheme.titleLarge?.copyWith(
              color: context.colors.textWhite,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Primary Actions (Camera & Gallery)
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.camera_alt_rounded,
                  label: 'TAKE PHOTO',
                  onTap: () => _pickImage(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.photo_library_rounded,
                  label: 'CHOOSE GALLERY',
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Presets Title
          Text(
            'CHOOSE FROM LUXURY PRESETS',
            style: textTheme.labelSmall?.copyWith(
              color: context.colors.primaryGold,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          // Preset Avatars Horizontal Scroll
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: PremiumPresets.presets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final preset = PremiumPresets.presets[index];
                return GestureDetector(
                  onTap: () => _showPreviewDialog(preset['url']!),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: context.colors.accentBrown, width: 1.5),
                          // Removed boxShadow
                          image: DecorationImage(
                            image: NetworkImage(preset['url']!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        preset['name']!,
                        style: textTheme.bodySmall?.copyWith(
                          color: context.colors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        opacity: 0.05,
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.colors.accentBrown.withOpacity(0.3),
                shape: BoxShape.circle,
                border: Border.all(color: context.colors.primaryGold.withOpacity(0.3), width: 1),
              ),
              child: Icon(icon, color: context.colors.primaryGold, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: context.colors.textWhite,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePreviewDialog extends StatefulWidget {
  final String imagePathOrBase64;
  final Function(String) onApply;
  final VoidCallback onCancel;

  const _ImagePreviewDialog({
    required this.imagePathOrBase64,
    required this.onApply,
    required this.onCancel,
  });

  @override
  State<_ImagePreviewDialog> createState() => _ImagePreviewDialogState();
}

class _ImagePreviewDialogState extends State<_ImagePreviewDialog> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 8.0, end: 24.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  ImageProvider _getImageProvider() {
    final path = widget.imagePathOrBase64;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }
    if (path.startsWith('data:image')) {
      final base64Str = path.contains(',') ? path.split(',')[1] : path;
      return MemoryImage(base64Decode(base64Str));
    }
    return NetworkImage(path); // Fallback
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'PREVIEW IMAGE',
                style: textTheme.titleMedium?.copyWith(
                  color: context.colors.primaryGold,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Confirm the crop and fit for your profile picture',
                style: textTheme.bodySmall?.copyWith(color: context.colors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const Spacer(),

              // Circular Glow Preview
              Center(
                child: AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: context.colors.primaryGold, width: 2.5),
                        // Removed boxShadow
                      ),
                      child: ClipOval(
                        child: Image(
                          image: _getImageProvider(),
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(color: context.colors.primaryGold),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: context.colors.card,
                              child: Icon(Icons.error_outline_rounded, color: context.colors.error, size: 48),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Spacer(),

              // Actions
              GoldButton(
                text: 'APPLY IMAGE',
                onPressed: () => widget.onApply(widget.imagePathOrBase64),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: context.colors.accentBrown, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    foregroundColor: context.colors.textWhite,
                  ),
                  child: const Text(
                    'CANCEL',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
