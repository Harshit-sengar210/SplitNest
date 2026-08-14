import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/group.dart';
import '../../domain/models/cycle_stats.dart';
import '../providers/groups_provider.dart';
import '../../../activity/domain/models/activity.dart';
import '../../../activity/presentation/providers/activity_provider.dart';

class CycleScreen extends ConsumerStatefulWidget {
  final String groupId;
  final bool isEmbedded;

  const CycleScreen({
    super.key,
    required this.groupId,
    this.isEmbedded = false,
  });

  @override
  ConsumerState<CycleScreen> createState() => _CycleScreenState();
}

class _CycleScreenState extends ConsumerState<CycleScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(cycleStatsProvider(widget.groupId));
    final timelineAsync = ref.watch(groupTimelineStreamProvider(widget.groupId));
    final groupAsync = ref.watch(groupDetailProvider(widget.groupId));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Theme Colors
    final primaryColor = context.colors.primaryGold;
    final surfaceColor = context.colors.card;
    final textPrimary = context.colors.textWhite;
    final textSecondary = context.colors.textSecondary;
    final textMuted = context.colors.textMuted;
    
    return Scaffold(
      backgroundColor: widget.isEmbedded ? Colors.transparent : context.colors.background,
      body: Stack(
        children: [
          // Background soft glowing blob vectors
          if (!widget.isEmbedded) ...[
            Positioned(
              top: -80,
              right: -50,
              child: _GlowingBlob(
                color: primaryColor.withOpacity(0.12),
                size: 260,
              ),
            ),
            Positioned(
              bottom: 100,
              left: -80,
              child: _GlowingBlob(
                color: const Color(0xFF00D4AA).withOpacity(0.08),
                size: 300,
              ),
            ),
          ],
          
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header (App bar) - only when not embedded
                if (!widget.isEmbedded)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (context.canPop()) {
                                context.pop();
                              }
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF2D2544) : const Color(0xFFE5E7EB),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: textPrimary,
                                size: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Billing Cycle',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                groupAsync.when(
                                  data: (g) => Text(
                                    g.name,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: primaryColor,
                                    ),
                                  ),
                                  loading: () => const SizedBox.shrink(),
                                  error: (_, __) => const SizedBox.shrink(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Top Card Section
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      child: statsAsync.when(
                        data: (stats) => _buildTopSummaryCard(
                          context,
                          stats,
                          isDark,
                          primaryColor,
                          surfaceColor,
                          textPrimary,
                          textSecondary,
                        ),
                        loading: () => _buildSummaryCardShimmer(context, surfaceColor, isDark),
                        error: (err, _) => Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Center(
                            child: Text(
                              'Error loading cycle stats: $err',
                              style: TextStyle(color: context.colors.error),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Recent Activities Title
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                    child: Text(
                      'Recent Cycle Activity',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),

                // Recent Activities List
                statsAsync.when(
                  data: (stats) {
                    return timelineAsync.when(
                      data: (activities) {
                        // Filter activities falling inside this billing cycle
                        final cycleActivities = activities.where((activity) {
                          return activity.createdAt.isAfter(stats.cycleStart) &&
                                 activity.createdAt.isBefore(stats.cycleEnd.add(const Duration(days: 1)));
                        }).toList();

                        if (cycleActivities.isEmpty) {
                          return SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40.0),
                              child: _buildEmptyState(textSecondary),
                            ),
                          );
                        }

                        return SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final activity = cycleActivities[index];
                                return _buildActivityCard(
                                  context: context,
                                  activity: activity,
                                  index: index,
                                  isDark: isDark,
                                  surfaceColor: surfaceColor,
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                  primaryColor: primaryColor,
                                );
                              },
                              childCount: cycleActivities.length,
                            ),
                          ),
                        );
                      },
                      loading: () => const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ),
                      error: (err, _) => SliverToBoxAdapter(
                        child: Center(child: Text('Error loading activities: $err')),
                      ),
                    );
                  },
                  loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                  error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
                ),
                
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Summary Card Builder ───────────────────────────────────────────────────
  Widget _buildTopSummaryCard(
    BuildContext context,
    CycleStats stats,
    bool isDark,
    Color primaryColor,
    Color surfaceColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final double settledPercent = stats.totalExpenses > 0 
        ? (stats.totalSettled / stats.totalExpenses).clamp(0.0, 1.0) 
        : 1.0;

    final dateRangeFormat = DateFormat('d MMM');
    final cycleStartStr = dateRangeFormat.format(stats.cycleStart);
    final cycleEndStr = dateRangeFormat.format(stats.cycleEnd);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor.withOpacity(isDark ? 0.65 : 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : primaryColor.withOpacity(0.12),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(isDark ? 0.08 : 0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card Header: Title + Date bounds
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Financial Cycle',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_month_rounded, size: 14, color: primaryColor),
                          const SizedBox(width: 6),
                          Text(
                            '$cycleStartStr → $cycleEndStr',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Image.asset(
                    'assets/images/3d_calendar.png',
                    width: 44,
                    height: 44,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // circular Progress Gauge
              Center(
                child: SizedBox(
                  width: 140,
                  height: 140,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: settledPercent),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return CustomPaint(
                        painter: GradientCircularProgressPainter(
                          progress: value,
                          primaryColor: primaryColor,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${(value * 100).toStringAsFixed(0)}%',
                                style: GoogleFonts.outfit(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: textPrimary,
                                ),
                              ),
                              Text(
                                'Settled',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Statistics Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = (constraints.maxWidth - 20) / 3;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 12,
                    children: [
                      _buildGridItem(
                        title: 'Expenses',
                        value: '₹${NumberFormat('#,##,###').format(stats.totalExpenses)}',
                        asset: 'assets/images/3d_ledger.png',
                        color: primaryColor,
                        width: itemWidth,
                        isDark: isDark,
                      ),
                      _buildGridItem(
                        title: 'Settled',
                        value: '₹${NumberFormat('#,##,###').format(stats.totalSettled)}',
                        asset: 'assets/images/3d_premium_nest.png',
                        color: const Color(0xFF10B981),
                        width: itemWidth,
                        isDark: isDark,
                      ),
                      _buildGridItem(
                        title: 'Pending',
                        value: '₹${NumberFormat('#,##,###').format(stats.totalPending)}',
                        asset: 'assets/images/3d_coins.png',
                        color: const Color(0xFFF59E0B),
                        width: itemWidth,
                        isDark: isDark,
                      ),
                      _buildGridItem(
                        title: 'Transactions',
                        value: '${stats.totalTransactions}',
                        asset: 'assets/images/3d_profile_txs.png',
                        color: const Color(0xFF6CA8FF),
                        width: (constraints.maxWidth - 10) / 2,
                        isDark: isDark,
                      ),
                      _buildGridItem(
                        title: 'Members',
                        value: '${stats.memberCount}',
                        asset: 'assets/images/3d_people.png',
                        color: const Color(0xFFA78BFA),
                        width: (constraints.maxWidth - 10) / 2,
                        isDark: isDark,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Grid Item Builder ──────────────────────────────────────────────────────
  Widget _buildGridItem({
    required String title,
    required String value,
    required String asset,
    required Color color,
    required double width,
    required bool isDark,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : color.withOpacity(0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFF8376A5) : const Color(0xFF6B7280),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Image.asset(
                asset,
                width: 20,
                height: 20,
                fit: BoxFit.contain,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── Activity Item Card Builder ─────────────────────────────────────────────
  Widget _buildActivityCard({
    required BuildContext context,
    required Activity activity,
    required int index,
    required bool isDark,
    required Color surfaceColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color primaryColor,
  }) {
    final style = _getActivityStyle(activity.type);
    
    // Status mappings
    String statusLabel = 'Completed';
    Color statusColor = const Color(0xFF10B981);
    if (activity.type == 'expense_added' || activity.type == 'expense_created') {
      statusLabel = 'Pending';
      statusColor = const Color(0xFFEF4444);
    } else if (activity.type == 'settlement_partial') {
      statusLabel = 'Partial';
      statusColor = const Color(0xFFF59E0B);
    }

    final relativeTimeStr = _getRelativeTime(activity.createdAt);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 50).clamp(0, 400)),
      curve: Curves.easeOutQuad,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 16 * (1.0 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12.0),
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // 3D Activity Icon
                  Container(
                    width: 48,
                    height: 48,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: style.color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Image.asset(
                      style.asset,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Title, Sub, Amount, Time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 8,
                              backgroundColor: primaryColor.withOpacity(0.15),
                              child: Text(
                                activity.userName.isNotEmpty 
                                    ? activity.userName[0].toUpperCase() 
                                    : '?',
                                style: TextStyle(
                                  fontSize: 7, 
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                '${activity.userName} • $relativeTimeStr',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Amount & Status Chip
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (activity.amount != null)
                        Text(
                          '₹${NumberFormat('#,##,###').format(activity.amount)}',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        )
                      else
                        const SizedBox(height: 18),
                      const SizedBox(height: 6),
                      
                      // Status Chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: statusColor.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          statusLabel,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
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
      },
    );
  }

  // ── Helper activity style mapper ──────────────────────────────────────────
  _ActivityStyle _getActivityStyle(String type) {
    switch (type) {
      case 'expense_added':
      case 'expense_created':
        return const _ActivityStyle(
          asset: 'assets/images/3d_ledger.png',
          color: Color(0xFF7B61FF),
        );
      case 'expense_updated':
        return const _ActivityStyle(
          asset: 'assets/images/3d_ledger.png',
          color: Color(0xFF6CA8FF),
        );
      case 'expense_deleted':
        return const _ActivityStyle(
          asset: 'assets/images/3d_pie_chart.png',
          color: Color(0xFFEF4444),
        );
      case 'settlement_recorded':
      case 'settlement_completed':
        return const _ActivityStyle(
          asset: 'assets/images/3d_blue_wallet.png',
          color: Color(0xFF10B981),
        );
      case 'settlement_partial':
        return const _ActivityStyle(
          asset: 'assets/images/3d_wallet.png',
          color: Color(0xFFF59E0B),
        );
      default:
        return const _ActivityStyle(
          asset: 'assets/images/3d_bell.png',
          color: Color(0xFFA78BFA),
        );
    }
  }

  // ── Helper relative time calculator ────────────────────────────────────────
  String _getRelativeTime(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return DateFormat('d MMM').format(dateTime);
    }
  }

  // ── Empty State Helper ─────────────────────────────────────────────────────
  Widget _buildEmptyState(Color textSecondary) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/3d_pie_chart.png',
            width: 70,
            height: 70,
          ),
          const SizedBox(height: 12),
          Text(
            'No activity in this cycle',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Shimmer Summary Card Shimmer Placeholder ──────────────────────────────
  Widget _buildSummaryCardShimmer(BuildContext context, Color surfaceColor, bool isDark) {
    return Container(
      height: 380,
      decoration: BoxDecoration(
        color: surfaceColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2.5),
      ),
    );
  }
}

// ── Glowing Blob Widget ──────────────────────────────────────────────────────
class _GlowingBlob extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowingBlob({
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 70.0, sigmaY: 70.0),
        child: Container(
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.transparent),
        ),
      ),
    );
  }
}

// ── Custom Gradient Radial Gauge Painter ─────────────────────────────────────
class GradientCircularProgressPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;

  GradientCircularProgressPainter({
    required this.progress,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 12.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Draw background track
    final paintBg = Paint()
      ..color = primaryColor.withOpacity(0.08)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, paintBg);

    if (progress <= 0) return;

    // Draw progress arc with gradient
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paintProgress = Paint()
      ..shader = ui.Gradient.sweep(
        center,
        [
          primaryColor.withOpacity(0.4),
          primaryColor,
          const Color(0xFF00D4AA), // Premium neon teal
          primaryColor.withOpacity(0.4),
        ],
        [0.0, 0.5, 0.75, 1.0],
        TileMode.clamp,
        -math.pi / 2,
        math.pi * 3 / 2,
      )
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paintProgress,
    );
  }

  @override
  bool shouldRepaint(covariant GradientCircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.primaryColor != primaryColor;
  }
}

class _ActivityStyle {
  final String asset;
  final Color color;

  const _ActivityStyle({
    required this.asset,
    required this.color,
  });
}
