import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/ledger_provider.dart';

class LedgerHistoryScreen extends ConsumerWidget {
  const LedgerHistoryScreen({super.key});

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'income':
        return const Color(0xFF2DC88A); // Green
      case 'expense':
        return const Color(0xFFEF4444); // Red
      case 'lend':
        return const Color(0xFF3B82F6); // Blue
      case 'borrow':
        return const Color(0xFFFF8C42); // Orange
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food & dining':
        return Icons.restaurant;
      case 'shopping':
        return Icons.shopping_bag;
      case 'transport':
        return Icons.directions_car;
      case 'entertainment':
        return Icons.movie;
      case 'bills & utilities':
        return Icons.receipt;
      case 'salary':
        return Icons.payments;
      case 'investment':
        return Icons.trending_up;
      case 'repayment':
        return Icons.sync;
      case 'other':
      default:
        return Icons.category;
    }
  }

  Widget _build3DIcon(IconData icon, Color color) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.4),
            blurRadius: 4,
            offset: const Offset(-2, -2),
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
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(ledgerTransactionsProvider);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.colors.card,
              shape: BoxShape.circle,
              border: Border.all(color: context.colors.accentBrown.withOpacity(0.2)),
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: context.colors.textWhite),
          ),
        ),
        title: Text(
          'Transaction History',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: context.colors.textWhite,
          ),
        ),
        centerTitle: true,
      ),
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: TextStyle(color: context.colors.error))),
        data: (transactions) {
          if (transactions.isEmpty) {
            return Center(
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
                      Icons.history,
                      size: 72,
                      color: Color(0xFF8C52FF),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Transactions Found',
                    style: GoogleFonts.plusJakartaSans(
                      color: context.colors.textWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20.0),
            physics: const BouncingScrollPhysics(),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
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
          );
        },
      ),
    );
  }
}
