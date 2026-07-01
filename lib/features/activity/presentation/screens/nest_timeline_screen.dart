import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../domain/models/activity.dart';
import '../providers/activity_provider.dart';

// ─── Timeline Screen ──────────────────────────────────────────────────────────
// A full-page, real-time activity feed for a single Nest.
// Grouped by date (Today / Yesterday / Day name / date string).

class NestTimelineScreen extends ConsumerStatefulWidget {
  final String nestId;
  final String nestName;

  const NestTimelineScreen({
    super.key,
    required this.nestId,
    required this.nestName,
  });

  @override
  ConsumerState<NestTimelineScreen> createState() => _NestTimelineScreenState();
}

class _NestTimelineScreenState extends ConsumerState<NestTimelineScreen>
    with SingleTickerProviderStateMixin {
  String _selectedFilter = 'All';
  late final AnimationController _entryController;

  static const _filters = ['All', 'Expenses', 'Settlements', 'Members'];

  // Design tokens
  static const _bg = Color(0xFF0E0E16);
  static const _surface = Color(0xFF1A1A2E);
  static const _card = Color(0xFF16213E);
  static const _purple = Color(0xFF7B61FF);
  static const _purpleDark = Color(0xFF5B3FD9);
  static const _accent = Color(0xFF00D4AA);
  static const _textPrimary = Color(0xFFF1F1F6);
  static const _textSecondary = Color(0xFF8B8EA8);
  static const _divider = Color(0xFF252540);

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  // ─── Icon + Color for each event type ──────────────────────────────────────
  _EventStyle _styleForType(String type) {
    switch (type) {
      case 'expense_added':
        return _EventStyle(
          icon: Icons.receipt_long_rounded,
          color: const Color(0xFF7B61FF),
          label: 'Expense Added',
        );
      case 'expense_updated':
        return _EventStyle(
          icon: Icons.edit_rounded,
          color: const Color(0xFF4A90E2),
          label: 'Expense Updated',
        );
      case 'expense_deleted':
        return _EventStyle(
          icon: Icons.delete_outline_rounded,
          color: const Color(0xFFEF4444),
          label: 'Expense Deleted',
        );
      case 'settlement_recorded':
        return _EventStyle(
          icon: Icons.done_all_rounded,
          color: const Color(0xFF00D4AA),
          label: 'Settlement',
        );
      case 'settlement_partial':
        return _EventStyle(
          icon: Icons.payments_rounded,
          color: const Color(0xFFF59E0B),
          label: 'Partial Payment',
        );
      case 'settlement_completed':
        return _EventStyle(
          icon: Icons.check_circle_rounded,
          color: const Color(0xFF00D4AA),
          label: 'Fully Settled',
        );
      case 'member_joined':
        return _EventStyle(
          icon: Icons.person_add_rounded,
          color: const Color(0xFF34D399),
          label: 'Member Joined',
        );
      case 'member_left':
        return _EventStyle(
          icon: Icons.person_remove_rounded,
          color: const Color(0xFFF97316),
          label: 'Member Left',
        );
      case 'nest_created':
      case 'group_created':
        return _EventStyle(
          icon: Icons.home_rounded,
          color: const Color(0xFFEC4899),
          label: 'Nest Created',
        );
      default:
        return _EventStyle(
          icon: Icons.info_outline_rounded,
          color: _textSecondary,
          label: 'Activity',
        );
    }
  }

  bool _matchesFilter(Activity a) {
    if (_selectedFilter == 'All') return true;
    switch (_selectedFilter) {
      case 'Expenses':
        return a.type.startsWith('expense_');
      case 'Settlements':
        return a.type.startsWith('settlement_');
      case 'Members':
        return a.type.startsWith('member_') || a.type.contains('created');
      default:
        return true;
    }
  }

  // ─── Date group label ───────────────────────────────────────────────────────
  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDay = DateTime(dt.year, dt.month, dt.day);

    if (itemDay == today) return 'Today';
    if (itemDay == yesterday) return 'Yesterday';
    if (today.difference(itemDay).inDays < 7) {
      return DateFormat('EEEE').format(dt); // e.g. "Monday"
    }
    return DateFormat('MMM d, y').format(dt);
  }

  // ─── Relative time ──────────────────────────────────────────────────────────
  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final timelineAsync =
        ref.watch(groupTimelineStreamProvider(widget.nestId));

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Premium App Bar ─────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: _bg,
            surfaceTintColor: Colors.transparent,
            expandedHeight: 140,
            pinned: true,
            leading: IconButton(
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _divider),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: _textPrimary, size: 16),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.only(left: 20, bottom: 16, right: 20),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Timeline',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    widget.nestName,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: _purple,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF13133A),
                      Color(0xFF0E0E16),
                    ],
                  ),
                ),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 60, right: 24),
                    child: _buildLiveIndicator(),
                  ),
                ),
              ),
            ),
          ),

          // ── Filter Chips ────────────────────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _FilterHeaderDelegate(
              child: Container(
                color: _bg,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _filters.map((f) {
                      final selected = _selectedFilter == f;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedFilter = f),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: selected
                                  ? const LinearGradient(
                                      colors: [_purpleDark, _purple])
                                  : null,
                              color: selected ? null : _surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected
                                    ? Colors.transparent
                                    : _divider,
                              ),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: _purple.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Text(
                              f,
                              style: GoogleFonts.inter(
                                color:
                                    selected ? Colors.white : _textSecondary,
                                fontSize: 12.5,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),

          // ── Content ─────────────────────────────────────────────────────────
          timelineAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  color: _purple,
                  strokeWidth: 2.5,
                ),
              ),
            ),
            error: (err, _) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline_rounded,
                        color: Colors.red.shade400, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Failed to load timeline',
                      style: GoogleFonts.inter(
                          color: _textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      err.toString(),
                      style: GoogleFonts.inter(
                          color: _textSecondary, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            data: (activities) {
              final filtered =
                  activities.where(_matchesFilter).toList();

              if (filtered.isEmpty) {
                return SliverFillRemaining(
                  child: _buildEmpty(),
                );
              }

              // Group by date label
              final Map<String, List<Activity>> grouped = {};
              for (final a in filtered) {
                final label = _dateLabel(a.createdAt);
                (grouped[label] ??= []).add(a);
              }

              final entries = grouped.entries.toList();

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, idx) {
                    int activityIndex = 0;
                    int runningIdx = 0;
                    for (int g = 0; g < entries.length; g++) {
                      final groupSize = entries[g].value.length;
                      // Header item
                      if (runningIdx == idx) {
                        return _buildDateHeader(entries[g].key);
                      }
                      runningIdx++;
                      for (int i = 0; i < groupSize; i++) {
                        if (runningIdx == idx) {
                          final isLast = i == groupSize - 1 &&
                              g == entries.length - 1;
                          return _buildTimelineItem(
                            entries[g].value[i],
                            activityIndex,
                            isLast: isLast,
                          );
                        }
                        runningIdx++;
                        activityIndex++;
                      }
                    }
                    return const SizedBox.shrink();
                  },
                  childCount: filtered.length + grouped.length,
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 60)),
        ],
      ),
    );
  }

  // ─── Live indicator ─────────────────────────────────────────────────────────
  Widget _buildLiveIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accent.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: _accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'LIVE',
            style: GoogleFonts.inter(
              color: _accent,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Date header ────────────────────────────────────────────────────────────
  Widget _buildDateHeader(String label) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _textSecondary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              color: _divider,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Timeline item ──────────────────────────────────────────────────────────
  Widget _buildTimelineItem(
    Activity activity,
    int index, {
    bool isLast = false,
  }) {
    final style = _styleForType(activity.type);

    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _entryController,
          curve: Interval(
            (index * 0.05).clamp(0.0, 0.9),
            ((index * 0.05) + 0.3).clamp(0.0, 1.0),
            curve: Curves.easeOut,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left timeline line + icon
              SizedBox(
                width: 44,
                child: Column(
                  children: [
                    // Icon circle
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            style.color.withOpacity(0.9),
                            style.color.withOpacity(0.5),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: style.color.withOpacity(0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(style.icon,
                          color: Colors.white, size: 18),
                    ),
                    // Vertical line (not on last)
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                style.color.withOpacity(0.4),
                                style.color.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Card
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _divider, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row
                        Row(
                          children: [
                            // Type badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: style.color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                style.label,
                                style: GoogleFonts.inter(
                                  color: style.color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _relativeTime(activity.createdAt),
                              style: GoogleFonts.inter(
                                color: _textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Title
                        Text(
                          activity.title,
                          style: GoogleFonts.outfit(
                            color: _textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Description
                        Text(
                          activity.description,
                          style: GoogleFonts.inter(
                            color: _textSecondary,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                        // Amount chip
                        if (activity.amount != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: style.color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: style.color.withOpacity(0.25),
                                  ),
                                ),
                                child: Text(
                                  '₹${activity.amount!.toStringAsFixed(0)}',
                                  style: GoogleFonts.outfit(
                                    color: style.color,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        // Actor name
                        if (activity.userName.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.person_outline_rounded,
                                  color: _textSecondary, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                activity.userName,
                                style: GoogleFonts.inter(
                                  color: _textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Empty state ─────────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _purple.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.timeline_rounded,
                color: _purple, size: 40),
          ),
          const SizedBox(height: 20),
          Text(
            'No activity yet',
            style: GoogleFonts.outfit(
              color: _textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Actions in this nest will\nappear here in real time.',
            style: GoogleFonts.inter(
              color: _textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Internal helpers ──────────────────────────────────────────────────────────

class _EventStyle {
  final IconData icon;
  final Color color;
  final String label;

  const _EventStyle({
    required this.icon,
    required this.color,
    required this.label,
  });
}

class _FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  const _FilterHeaderDelegate({required this.child});

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      child;

  @override
  double get maxExtent => 58;

  @override
  double get minExtent => 58;

  @override
  bool shouldRebuild(covariant _FilterHeaderDelegate oldDelegate) =>
      oldDelegate.child != child;
}
