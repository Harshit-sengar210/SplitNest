import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../auth/presentation/providers/notification_settings_provider.dart';
import '../../../auth/domain/models/notification_settings.dart';

class PushAlertsScreen extends ConsumerStatefulWidget {
  const PushAlertsScreen({super.key});

  @override
  ConsumerState<PushAlertsScreen> createState() => _PushAlertsScreenState();
}

class _PushAlertsScreenState extends ConsumerState<PushAlertsScreen> with TickerProviderStateMixin {
  final Map<String, String> _examples = {
    'Expense Added': 'e.g. "Rohan added Dinner Splitting to Europe Trip 2026"',
    'Settlement Received': 'e.g. "Aman paid you \$50.00 for Flat Rent"',
    'Group Chat Messages': 'e.g. "Sarah: Can we settle the bills tonight?"',
    'Member Joined Group': 'e.g. "Rahul joined Flat 402 Roomies"',
    'Group Updates': 'e.g. "Goa Trip was marked as completed"',
    'Weekly Summary': 'e.g. "Your weekly summary: You spent \$120.00"',
  };

  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(notificationSettingsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const AppHeader(
        title: 'Push Alerts',
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF5F3FF),
              Color(0xFFFFFFFF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            _BackgroundShapes(floatAnimation: _floatAnimation),
            SafeArea(
              child: settingsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF7B61FF))),
                error: (err, stack) => Center(child: Text('Error: \$err')),
                data: (settings) {
                  if (settings == null) return const SizedBox.shrink();

                  final _alerts = {
                    'Expense Added': settings.expenseAlerts,
                    'Settlement Received': settings.settlementAlerts,
                    'Group Chat Messages': settings.chatAlerts,
                    'Member Joined Group': settings.memberAlerts,
                    'Group Updates': settings.groupAlerts,
                    'Weekly Summary': settings.weeklySummaryAlerts,
                  };

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    itemCount: _alerts.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final key = _alerts.keys.elementAt(index);
                      final value = _alerts[key]!;
                      final example = _examples[key]!;

                      return _buildToggleCard(
                        title: key,
                        example: example,
                        value: value,
                        onChanged: (val) {
                          NotificationSettings newSettings = settings;
                          if (key == 'Expense Added') newSettings = settings.copyWith(expenseAlerts: val);
                          if (key == 'Settlement Received') newSettings = settings.copyWith(settlementAlerts: val);
                          if (key == 'Group Chat Messages') newSettings = settings.copyWith(chatAlerts: val);
                          if (key == 'Member Joined Group') newSettings = settings.copyWith(memberAlerts: val);
                          if (key == 'Group Updates') newSettings = settings.copyWith(groupAlerts: val);
                          if (key == 'Weekly Summary') newSettings = settings.copyWith(weeklySummaryAlerts: val);
                          
                          ref.read(notificationSettingsProvider.notifier).updateSettings(newSettings);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleCard({
    required String title,
    required String example,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: value ? const Color(0xFF7B61FF).withOpacity(0.15) : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: value 
                ? const Color(0xFF7B61FF).withOpacity(0.08) 
                : const Color(0xFF7B61FF).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF1F2937),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  example,
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF6B7280),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF7B61FF),
            activeTrackColor: const Color(0xFF7B61FF).withOpacity(0.3),
            inactiveThumbColor: const Color(0xFF9CA3AF),
            inactiveTrackColor: const Color(0xFFE5E7EB),
          ),
        ],
      ),
    );
  }
}

class _BackgroundShapes extends StatelessWidget {
  final Animation<double> floatAnimation;

  const _BackgroundShapes({required this.floatAnimation});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 120,
          right: -30,
          child: AnimatedBuilder(
            animation: floatAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, floatAnimation.value * 15),
                child: child,
              );
            },
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6CA8FF).withOpacity(0.18),
                    const Color(0xFF6CA8FF).withOpacity(0.01),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          left: -40,
          child: AnimatedBuilder(
            animation: floatAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -floatAnimation.value * 12),
                child: child,
              );
            },
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFA78BFA).withOpacity(0.18),
                    const Color(0xFFA78BFA).withOpacity(0.01),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
