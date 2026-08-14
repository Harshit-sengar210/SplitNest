import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../providers/balance_providers.dart';
import '../widgets/split_balance_card.dart';
import '../widgets/settlement_bottom_sheet.dart';
import '../../../members/presentation/providers/member_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../groups/domain/models/group.dart';
import '../../../groups/domain/models/cycle_stats.dart';

// Number of balance entries shown before the expand/collapse toggle.
const int _kCollapsedCount = 5;

class BalancesScreen extends ConsumerStatefulWidget {
  final String groupId;

  const BalancesScreen({super.key, required this.groupId});

  @override
  ConsumerState<BalancesScreen> createState() => _BalancesScreenState();
}

class _BalancesScreenState extends ConsumerState<BalancesScreen>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  late final AnimationController _expandController;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final splitsAsync = ref.watch(nestSplitsProvider(widget.groupId));
    final membersAsync = ref.watch(nestMembersStreamProvider(widget.groupId));
    final groupAsync = ref.watch(groupDetailProvider(widget.groupId));
    final cycleAsync = ref.watch(cycleStatsProvider(widget.groupId));
    final summaryAsync = ref.watch(balanceSummaryProvider(widget.groupId));
    final currentUserId = ref.watch(authNotifierProvider).user?.id ?? '';
    final colors = context.colors;

    final Map<String, String?> membersPhotoMap = membersAsync.maybeWhen(
      data: (members) => {for (final m in members) m.id: m.profileImage},
      orElse: () => {},
    );

    return Scaffold(
      backgroundColor: colors.background,
      appBar: const AppHeader(title: 'Member Balances'),
      bottomNavigationBar: _StickyActionBar(groupId: widget.groupId),
      body: splitsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF7B61FF),
            strokeWidth: 2.5,
          ),
        ),
        error: (e, _) => _buildErrorState(e.toString(), colors),
        data: (splits) {
          final visibleCount =
              _isExpanded ? splits.length : _kCollapsedCount.clamp(0, splits.length);
          final hiddenCount = splits.length - _kCollapsedCount;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Group Header Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: groupAsync.when(
                    data: (group) => cycleAsync.when(
                      data: (cycle) =>
                          _GroupHeaderCard(group: group, cycle: cycle, colors: colors),
                      loading: () =>
                          _GroupHeaderCard(group: group, cycle: null, colors: colors),
                      error: (_, __) =>
                          _GroupHeaderCard(group: group, cycle: null, colors: colors),
                    ),
                    loading: () => const SizedBox(
                      height: 120,
                      child: Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF7B61FF), strokeWidth: 2),
                      ),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ),

              // 2. Balance Summary Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: _BalanceSummaryCard(summaryAsync: summaryAsync, colors: colors),
                ),
              ),

              // 3. Balance list header
              if (splits.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 18,
                          decoration: BoxDecoration(
                            color: colors.primaryGold,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Balances (${splits.length})',
                          style: GoogleFonts.plusJakartaSans(
                            color: colors.textWhite,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        _pendingChip(splits, colors),
                      ],
                    ),
                  ),
                ),

              // 4. Empty state
              if (splits.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(colors),
                ),

              // 5. Balance cards (top N or all)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final splitCtx = splits[index];
                      return Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: SplitBalanceCard(
                          groupId: widget.groupId,
                          expense: splitCtx.expense,
                          split: splitCtx.split,
                          currentUserId: currentUserId,
                          debtorPhotoUrl: membersPhotoMap[splitCtx.split.userId],
                          creditorPhotoUrl: membersPhotoMap[splitCtx.split.paidBy],
                        ),
                      );
                    },
                    childCount: visibleCount,
                  ),
                ),
              ),

              // 6. Expand / Collapse toggle
              if (splits.length > _kCollapsedCount)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _ExpandCollapseButton(
                      isExpanded: _isExpanded,
                      hiddenCount: hiddenCount,
                      onTap: _toggleExpanded,
                      colors: colors,
                    ),
                  ),
                ),

              // Bottom padding so content isn't hidden by sticky bar
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }

  Widget _pendingChip(List<ExpenseSplitContext> splits, AppColorsExtension colors) {
    final pendingCount =
        splits.where((s) => s.split.pendingAmount > 0.01).length;
    if (pendingCount == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.primaryGold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$pendingCount pending',
        style: GoogleFonts.plusJakartaSans(
          color: colors.primaryGold,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppColorsExtension colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.primaryGold.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.account_balance_wallet_outlined,
                  color: colors.primaryGold, size: 56),
            ),
            const SizedBox(height: 24),
            Text(
              'No member balances yet',
              style: GoogleFonts.plusJakartaSans(
                color: colors.textWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create expenses to start tracking how much members owe and paid.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                  color: colors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message, AppColorsExtension colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              'An error occurred',
              style: GoogleFonts.plusJakartaSans(
                  color: colors.textWhite, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                    color: colors.textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Group Header Card
// ─────────────────────────────────────────────────────────────────────────────

class _GroupHeaderCard extends StatelessWidget {
  final Group group;
  final CycleStats? cycle;
  final AppColorsExtension colors;

  const _GroupHeaderCard({
    required this.group,
    required this.cycle,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0.##', 'en_IN');
    final totalExp = cycle?.totalExpenses ?? group.totalExpenses;
    final totalPending = cycle?.totalPending ?? group.totalPending;
    final totalSettled = cycle?.totalSettled ?? group.totalSettled;

    final cycleStart = cycle?.cycleStart;
    final cycleEnd = cycle?.cycleEnd;
    final cycleLabel = (cycleStart != null && cycleEnd != null)
        ? '${DateFormat('MMM d').format(cycleStart)} – ${DateFormat('MMM d, y').format(cycleEnd)}'
        : null;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: colors.primaryGold.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: colors.primaryGold.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        colors.primaryGold.withValues(alpha: 0.3),
                        colors.primaryGold.withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                        color: colors.primaryGold.withValues(alpha: 0.2)),
                  ),
                  child: group.imageUrl != null && group.imageUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            group.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Icon(Icons.home_rounded,
                                    color: colors.primaryGold, size: 24),
                          ),
                        )
                      : Icon(Icons.home_rounded,
                          color: colors.primaryGold, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: GoogleFonts.plusJakartaSans(
                          color: colors.textWhite,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _chip(group.type, Icons.category_rounded, colors),
                          _chip('${group.membersCount} members',
                              Icons.people_rounded, colors),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (cycleLabel != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.date_range_rounded,
                      size: 13, color: colors.textMuted),
                  const SizedBox(width: 5),
                  Text(
                    'Cycle: $cycleLabel',
                    style: GoogleFonts.plusJakartaSans(
                        color: colors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                _statItem('Total Bills', '₹${fmt.format(totalExp)}',
                    colors.textSecondary, colors),
                _vDivider(colors),
                _statItem('Pending', '₹${fmt.format(totalPending)}',
                    const Color(0xFFFFB300), colors),
                _vDivider(colors),
                _statItem('Settled', '₹${fmt.format(totalSettled)}',
                    colors.success, colors),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, IconData icon, AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.accentBrown.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: colors.textMuted),
          const SizedBox(width: 4),
          Text(label,
              style:
                  GoogleFonts.plusJakartaSans(color: colors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color valueColor,
      AppColorsExtension colors) {
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: GoogleFonts.plusJakartaSans(
                    color: valueColor, fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          const SizedBox(height: 2),
          Text(label,
              style:
                  GoogleFonts.plusJakartaSans(color: colors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _vDivider(AppColorsExtension colors) {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: colors.accentBrown.withValues(alpha: 0.4),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Balance Summary Card
// ─────────────────────────────────────────────────────────────────────────────

class _BalanceSummaryCard extends StatelessWidget {
  final AsyncValue<BalanceSummary> summaryAsync;
  final AppColorsExtension colors;

  const _BalanceSummaryCard({required this.summaryAsync, required this.colors});

  @override
  Widget build(BuildContext context) {
    return summaryAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (summary) {
        final net = summary.net;
        final netColor = net > 0.01
            ? colors.success
            : net < -0.01
                ? colors.error
                : colors.textSecondary;
        final netLabel =
            net > 0.01 ? 'You get back' : net < -0.01 ? 'You owe overall' : 'All settled';

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                colors.primaryGold.withValues(alpha: 0.08),
                colors.primaryGold.withValues(alpha: 0.03),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
                color: colors.primaryGold.withValues(alpha: 0.15), width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_balance_wallet_rounded,
                        size: 16, color: colors.primaryGold),
                    const SizedBox(width: 6),
                    Text(
                      'Your Balance Summary',
                      style: GoogleFonts.plusJakartaSans(
                          color: colors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _pill(
                      label: 'You Will Receive',
                      value: '₹${summary.willReceive.toStringAsFixed(0)}',
                      color: colors.success,
                      icon: Icons.arrow_downward_rounded,
                    ),
                    const SizedBox(width: 10),
                    _pill(
                      label: 'You Will Pay',
                      value: '₹${summary.willPay.toStringAsFixed(0)}',
                      color: const Color(0xFFFFB300),
                      icon: Icons.arrow_upward_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: netColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: netColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Net Balance',
                          style: GoogleFonts.plusJakartaSans(
                              color: colors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('₹${net.abs().toStringAsFixed(0)}',
                              style: GoogleFonts.plusJakartaSans(
                                  color: netColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          Text(netLabel,
                              style: GoogleFonts.plusJakartaSans(
                                  color: netColor.withValues(alpha: 0.8),
                                  fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _pill({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(label,
                      style: GoogleFonts.plusJakartaSans(
                          color: colors.textMuted, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(value,
                style: GoogleFonts.plusJakartaSans(
                    color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Expand / Collapse Button
// ─────────────────────────────────────────────────────────────────────────────

class _ExpandCollapseButton extends StatelessWidget {
  final bool isExpanded;
  final int hiddenCount;
  final VoidCallback onTap;
  final AppColorsExtension colors;

  const _ExpandCollapseButton({
    required this.isExpanded,
    required this.hiddenCount,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isExpanded
              ? colors.card
              : colors.primaryGold.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: colors.primaryGold.withValues(alpha: 0.2), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedRotation(
              turns: isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: Icon(Icons.keyboard_arrow_down_rounded,
                  color: colors.primaryGold, size: 20),
            ),
            const SizedBox(width: 8),
            Text(
              isExpanded
                  ? 'Show Less'
                  : '+$hiddenCount More Balance${hiddenCount == 1 ? '' : 's'}',
              style: GoogleFonts.plusJakartaSans(
                  color: colors.primaryGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sticky Bottom Action Bar
// ─────────────────────────────────────────────────────────────────────────────

class _StickyActionBar extends ConsumerWidget {
  final String groupId;

  const _StickyActionBar({required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final splitsAsync = ref.watch(nestSplitsProvider(groupId));
    final currentUserId = ref.watch(authNotifierProvider).user?.id ?? '';

    // Find the first unsettled split where current user is creditor/owner.
    ExpenseSplitContext? firstSettleable;
    final splits = splitsAsync.value;
    if (splits != null) {
      for (final ctx in splits) {
        if (ctx.split.paidBy == currentUserId &&
            ctx.split.pendingAmount > 0.01 &&
            ctx.split.status != 'completed') {
          firstSettleable = ctx;
          break;
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(
          top: BorderSide(
              color: colors.primaryGold.withValues(alpha: 0.15), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Settle Up (primary)
              Expanded(
                flex: 5,
                child: _ActionButton(
                  label: 'Settle Up',
                  icon: Icons.handshake_rounded,
                  isPrimary: true,
                  enabled: firstSettleable != null,
                  colors: colors,
                  onTap: firstSettleable != null
                      ? () => _handleSettleUp(context, ref, firstSettleable!)
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              // Members
              Expanded(
                flex: 3,
                child: _ActionButton(
                  label: 'Members',
                  icon: Icons.people_rounded,
                  isPrimary: false,
                  enabled: true,
                  colors: colors,
                  onTap: () {
                    // Pop balances and return to group detail (members tab)
                    if (context.canPop()) context.pop();
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Cycle
              Expanded(
                flex: 3,
                child: _ActionButton(
                  label: 'Cycle',
                  icon: Icons.loop_rounded,
                  isPrimary: false,
                  enabled: true,
                  colors: colors,
                  onTap: () => context.push('/groups/$groupId/cycle'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSettleUp(
      BuildContext context, WidgetRef ref, ExpenseSplitContext firstSettleable) {
    final splits = ref.read(nestSplitsProvider(groupId)).value ?? [];
    final currentUserId = ref.read(authNotifierProvider).user?.id ?? '';
    final settleable = splits
        .where((ctx) =>
            ctx.split.paidBy == currentUserId &&
            ctx.split.pendingAmount > 0.01 &&
            ctx.split.status != 'completed')
        .toList();

    if (settleable.length <= 1) {
      // Only one pending entry — open settlement sheet directly
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => SettlementBottomSheet(
          groupId: groupId,
          expense: firstSettleable.expense,
          split: firstSettleable.split,
        ),
      );
    } else {
      // Multiple pending entries — show picker first
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _SettleUpPickerSheet(
          groupId: groupId,
          settleable: settleable,
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action Button
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final bool enabled;
  final AppColorsExtension colors;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.enabled,
    required this.colors,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = enabled
        ? colors.primaryGold
        : colors.primaryGold.withValues(alpha: 0.35);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary
              ? effectiveColor
              : effectiveColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: isPrimary
              ? null
              : Border.all(color: effectiveColor.withValues(alpha: 0.3)),
          boxShadow: isPrimary && enabled
              ? [
                  BoxShadow(
                    color: colors.primaryGold.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 18,
                color: isPrimary ? Colors.white : effectiveColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                  color: isPrimary ? Colors.white : effectiveColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Settle Up Picker Sheet (multiple pending splits)
// ─────────────────────────────────────────────────────────────────────────────

class _SettleUpPickerSheet extends StatelessWidget {
  final String groupId;
  final List<ExpenseSplitContext> settleable;

  const _SettleUpPickerSheet({
    required this.groupId,
    required this.settleable,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
            color: colors.accentBrown.withValues(alpha: 0.3), width: 1.5),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                      color: colors.textMuted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Select Balance to Settle',
                  style: GoogleFonts.plusJakartaSans(
                      color: colors.textWhite,
                      fontSize: 17,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('${settleable.length} balances pending your confirmation',
                  style: GoogleFonts.plusJakartaSans(
                      color: colors.textSecondary, fontSize: 13)),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: settleable.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final ctx = settleable[i];
                    return _PickerTile(
                      ctx: ctx,
                      colors: colors,
                      onTap: () {
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => SettlementBottomSheet(
                            groupId: groupId,
                            expense: ctx.expense,
                            split: ctx.split,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Picker Tile
// ─────────────────────────────────────────────────────────────────────────────

class _PickerTile extends StatelessWidget {
  final ExpenseSplitContext ctx;
  final AppColorsExtension colors;
  final VoidCallback onTap;

  const _PickerTile({
    required this.ctx,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: colors.accentBrown.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ctx.expense.title,
                      style: GoogleFonts.plusJakartaSans(
                          color: colors.textWhite,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(ctx.split.memberName,
                      style: GoogleFonts.plusJakartaSans(
                          color: colors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Text(
              '₹${ctx.split.pendingAmount.toStringAsFixed(0)}',
              style: GoogleFonts.plusJakartaSans(
                  color: colors.primaryGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded,
                color: colors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
