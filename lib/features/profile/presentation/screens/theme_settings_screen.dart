import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/glass_container.dart';

class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  Widget _buildThemeOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required ThemeMode mode,
    required ThemeMode currentMode,
    required WidgetRef ref,
  }) {
    final isSelected = mode == currentMode;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GestureDetector(
        onTap: () {
          ref.read(themeProvider.notifier).setThemeMode(mode);
        },
        child: GlassContainer(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? context.colors.primaryGold.withOpacity(0.1) : context.colors.background,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? context.colors.primaryGold : context.colors.accentBrown,
                  ),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? context.colors.primaryGold : context.colors.textSecondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? context.colors.primaryGold : context.colors.textWhite,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: context.colors.primaryGold,
                  size: 24,
                )
              else
                Icon(
                  Icons.circle_outlined,
                  color: context.colors.textMuted,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentThemeMode = ref.watch(themeProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: const AppHeader(title: 'Theme Settings'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Choose your aesthetic.',
              style: textTheme.bodyLarge?.copyWith(color: context.colors.textSecondary),
            ),
            const SizedBox(height: 32),
            _buildThemeOption(
              context: context,
              title: 'System Default',
              subtitle: 'Automatically switch based on your device settings.',
              icon: Icons.brightness_auto_rounded,
              mode: ThemeMode.system,
              currentMode: currentThemeMode,
              ref: ref,
            ),
            _buildThemeOption(
              context: context,
              title: 'Midnight Gold',
              subtitle: 'Luxury dark theme for a sleek, premium experience.',
              icon: Icons.dark_mode_rounded,
              mode: ThemeMode.dark,
              currentMode: currentThemeMode,
              ref: ref,
            ),
            _buildThemeOption(
              context: context,
              title: 'Ivory Gold',
              subtitle: 'Elegant light theme for clarity and contrast.',
              icon: Icons.light_mode_rounded,
              mode: ThemeMode.light,
              currentMode: currentThemeMode,
              ref: ref,
            ),
          ],
        ),
      ),
    );
  }
}
