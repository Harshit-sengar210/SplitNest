import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/ledger_provider.dart';
import '../../domain/models/ledger_summary.dart';
import '../../../../core/theme/app_colors.dart';

class LedgerScreen extends ConsumerStatefulWidget {
  const LedgerScreen({super.key});

  @override
  ConsumerState<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends ConsumerState<LedgerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'food':
      case 'dining':
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'travel':
      case 'transport':
      case 'cab':
        return Icons.directions_car_rounded;
      case 'bills':
      case 'utilities':
        return Icons.receipt_long_rounded;
      case 'salary':
      case 'income':
        return Icons.monetization_on_rounded;
      case 'lend':
      case 'borrow':
      case 'loan':
        return Icons.handshake_rounded;
      case 'entertainment':
      case 'movies':
        return Icons.local_activity_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'income':
        return const Color(0xFF2DC88A); // Green
      case 'expense':
        return const Color(0xFFEF4444); // Red
      case 'borrow':
        return const Color(0xFFFF8C42); // Orange
      case 'lend':
        return const Color(0xFF3B82F6); // Blue
      default:
        return Colors.purple;
    }
  }

  Widget _build3DIcon(IconData icon, Color primaryColor) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            primaryColor.withOpacity(0.8),
            primaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildQuickAction(String label, IconData icon, Color color, String defaultType) {
    return Expanded(
      child: GestureDetector(
        onTap: () => context.push('/personal-ledger/add?type=$defaultType'),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.15),
                    color.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: context.colors.textWhite,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(ledgerSummaryProvider);
    final transactionsAsync = ref.watch(ledgerTransactionsProvider);

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Custom premium app header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    if (Navigator.canPop(context))
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 44,
                          height: 44,
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: context.colors.card,
                            shape: BoxShape.circle,
                            border: Border.all(color: context.colors.accentBrown.withOpacity(0.2)),
                          ),
                          child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: context.colors.textWhite),
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Personal Ledger',
                            style: GoogleFonts.outfit(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: context.colors.textWhite,
                            ),
                          ),
                          Text(
                            'Independent personal finance manager',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: context.colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/personal-ledger/history'),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: context.colors.card,
                          shape: BoxShape.circle,
                          border: Border.all(color: context.colors.accentBrown.withOpacity(0.2)),
                        ),
                        child: Icon(Icons.history_rounded, size: 24, color: context.colors.textWhite),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Top Summary Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: summaryAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error: $err', style: TextStyle(color: context.colors.error))),
                  data: (summary) {
                    final sum = summary ?? LedgerSummary.zero();
                    return Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF5A3EFA),
                            Color(0xFF8C52FF),
                            Color(0xFFB37CFF),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6B4EFF).withOpacity(0.3),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Column(
                                children: [
                                  Text(
                                    'NET BALANCE',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  AnimatedBuilder(
                                    animation: _floatController,
                                    builder: (_, child) {
                                      final dy = math.sin(_floatController.value * math.pi) * 3;
                                      return Transform.translate(
                                        offset: Offset(0, dy),
                                        child: child,
                                      );
                                    },
                                    child: Text(
                                      '${sum.netBalance >= 0 ? '' : '-'}₹${sum.netBalance.abs().toStringAsFixed(2)}',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 36,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              height: 1,
                              color: Colors.white.withOpacity(0.15),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        'Income',
                                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₹${sum.totalIncome.toStringAsFixed(0)}',
                                        style: const TextStyle(color: Color(0xFF2DC88A), fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(width: 1, height: 30, color: Colors.white.withOpacity(0.15)),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        'Expenses',
                                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₹${sum.totalExpense.toStringAsFixed(0)}',
                                        style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        'You Will Receive',
                                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₹${sum.totalLend.toStringAsFixed(0)}',
                                        style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(width: 1, height: 30, color: Colors.white.withOpacity(0.15)),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        'You Owe',
                                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₹${sum.totalBorrow.toStringAsFixed(0)}',
                                        style: const TextStyle(color: Color(0xFFFF8C42), fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Quick Actions Block
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildQuickAction('Add Expense', Icons.arrow_outward_rounded, const Color(0xFFEF4444), 'expense'),
                    _buildQuickAction('Add Income', Icons.call_received_rounded, const Color(0xFF2DC88A), 'income'),
                    _buildQuickAction('Add Lend', Icons.upload_rounded, const Color(0xFF3B82F6), 'lend'),
                    _buildQuickAction('Add Borrow', Icons.download_rounded, const Color(0xFFFF8C42), 'borrow'),
                  ],
                ),
              ),
            ),

            // Recent Transactions header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Text(
                  'Recent Transactions',
                  style: GoogleFonts.outfit(
                    color: context.colors.textWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),

            // Transactions StreamBuilder / Riverpod stream list watcher
            transactionsAsync.when(
              loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
              error: (err, stack) => SliverToBoxAdapter(child: Center(child: Text('Error: $err', style: TextStyle(color: context.colors.error)))),
              data: (transactions) {
                if (transactions.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.purple.withOpacity(0.1),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              size: 72,
                              color: Color(0xFF8C52FF),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Your Personal Ledger is empty.',
                            style: GoogleFonts.plusJakartaSans(
                              color: context.colors.textWhite,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start adding expenses, incomes, lends or borrows to track your personal finances.',
                            style: GoogleFonts.inter(
                              color: context.colors.textSecondary,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7B61FF),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () => context.push('/personal-ledger/add'),
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: const Text('Add Transaction', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final tx = transactions[index];
                        final color = _getTypeColor(tx.type);
                        final dateStr = DateFormat('dd MMM yyyy').format(tx.date);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: context.colors.card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: context.colors.accentBrown.withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: InkWell(
                            onTap: () => context.push('/personal-ledger/detail/${tx.transactionId}'),
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  _build3DIcon(_getCategoryIcon(tx.categoryName), color),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tx.title,
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: context.colors.textWhite,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${tx.categoryName} • $dateStr',
                                          style: GoogleFonts.inter(
                                            color: context.colors.textSecondary,
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${tx.type == 'income' || tx.type == 'lend' ? '+' : '-'}₹${tx.amount.toStringAsFixed(0)}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: transactions.length,
                    ),
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}
