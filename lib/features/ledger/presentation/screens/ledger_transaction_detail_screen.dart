import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/gold_button.dart';
import '../../../../core/widgets/glass_container.dart';
import '../providers/ledger_provider.dart';
import '../../domain/models/ledger_transaction.dart';

class LedgerTransactionDetailScreen extends ConsumerWidget {
  final String transactionId;

  const LedgerTransactionDetailScreen({
    super.key,
    required this.transactionId,
  });

  void _settleTransaction(BuildContext context, WidgetRef ref, List<LedgerTransaction> transactions) {
    ref.read(ledgerControllerProvider).settleTransaction(transactionId, transactions);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Transaction marked as completed!', style: TextStyle(color: context.colors.textWhite)),
        backgroundColor: context.colors.success.withOpacity(0.8),
      ),
    );
  }

  void _deleteTransaction(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Transaction', style: TextStyle(color: context.colors.textWhite, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete this transaction? This action cannot be undone.', style: TextStyle(color: context.colors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: context.colors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(ledgerControllerProvider).deleteTransaction(transactionId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Transaction deleted successfully', style: TextStyle(color: context.colors.textWhite)),
                    backgroundColor: context.colors.error.withOpacity(0.8),
                  ),
                );
                context.pop(); // Go back to Personal Ledger screen
              }
            },
            child: Text('Delete', style: TextStyle(color: context.colors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final transactionsAsync = ref.watch(ledgerTransactionsProvider);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: const AppHeader(
        title: 'Transaction Details',
      ),
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: TextStyle(color: context.colors.error))),
        data: (transactions) {
          final transaction = transactions.cast<LedgerTransaction?>().firstWhere(
                (t) => t?.transactionId == transactionId,
                orElse: () => null,
              );

          if (transaction == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Transaction not found', style: TextStyle(color: context.colors.textWhite, fontSize: 16)),
                  const SizedBox(height: 16),
                  GoldButton(
                    text: 'GO BACK',
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
            );
          }

          final isPending = transaction.status == 'pending';
          final typeLower = transaction.type.toLowerCase();
          final isIncoming = typeLower == 'income' || typeLower == 'lend';
          final txColor = isIncoming ? const Color(0xFF2DC88A) : const Color(0xFFEF4444);

          String displayType = transaction.type;
          if (transaction.type == 'expense') displayType = 'Expense';
          if (transaction.type == 'income') displayType = 'Income';
          if (transaction.type == 'lend') displayType = 'Lend';
          if (transaction.type == 'borrow') displayType = 'Borrow';

          final dateStr = DateFormat('dd MMM yyyy').format(transaction.date);
          final initials = (transaction.personName ?? 'Me').trim().split(' ').map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').take(2).join('');

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Section - Amount & Avatar
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                  decoration: BoxDecoration(
                    color: context.colors.card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isPending 
                          ? context.colors.primaryGold.withOpacity(0.3) 
                          : context.colors.accentBrown.withOpacity(0.1),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              context.colors.accentBrown.withOpacity(0.6),
                              context.colors.accentBrown.withOpacity(0.2),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: context.colors.primaryGold.withOpacity(0.5),
                            width: 2.0,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: textTheme.headlineMedium?.copyWith(
                              color: context.colors.primaryGold,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        transaction.title,
                        style: textTheme.titleLarge?.copyWith(
                          color: context.colors.textWhite,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${transaction.amount.toStringAsFixed(2)}',
                        style: textTheme.displaySmall?.copyWith(
                          color: txColor,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Metadata Detail Fields
                Text(
                  'TRANSACTION INFO',
                  style: textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                GlassContainer(
                  opacity: 0.03,
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildDetailRow(context, 'Transaction Type', displayType, valueColor: txColor),
                      _buildDivider(context),
                      _buildDetailRow(context, 'Category', transaction.categoryName),
                      _buildDivider(context),
                      _buildDetailRow(context, 'Payment Method', transaction.paymentMethod),
                      _buildDivider(context),
                      _buildDetailRow(context, 'Date', dateStr),
                      if (transaction.personName != null) ...[
                        _buildDivider(context),
                        _buildDetailRow(context, 'With Person', transaction.personName!),
                      ],
                      _buildDivider(context),
                      _buildDetailRow(
                        context, 
                        'Status', 
                        '', 
                        customValue: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPending 
                                ? context.colors.primaryGold.withOpacity(0.1) 
                                : context.colors.textSecondary.withOpacity(0.05),
                            border: Border.all(
                              color: isPending 
                                  ? context.colors.primaryGold 
                                  : context.colors.textSecondary.withOpacity(0.2),
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            transaction.status.toUpperCase(),
                            style: TextStyle(
                              color: isPending ? context.colors.primaryGold : context.colors.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Note Section
                Text(
                  'NOTE',
                  style: textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.colors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: context.colors.accentBrown.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    transaction.description.isNotEmpty ? transaction.description : 'No note added for this transaction.',
                    style: TextStyle(
                      color: transaction.description.isNotEmpty ? context.colors.textWhite : context.colors.textMuted,
                      fontSize: 14,
                      height: 1.4,
                      fontStyle: transaction.description.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Settle Action (Only if Pending)
                if (isPending) ...[
                  GoldButton(
                    text: 'MARK AS COMPLETED',
                    onPressed: () => _settleTransaction(context, ref, transactions),
                  ),
                  const SizedBox(height: 16),
                ],

                // Edit & Delete Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: context.colors.primaryGold),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: Icon(Icons.edit_rounded, color: context.colors.primaryGold, size: 20),
                        label: Text(
                          'Edit',
                          style: TextStyle(
                            color: context.colors.primaryGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () => context.push('/personal-ledger/edit/${transaction.transactionId}'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: context.colors.error.withOpacity(0.5)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: Icon(Icons.delete_outline_rounded, color: context.colors.error, size: 20),
                        label: Text(
                          'Delete',
                          style: TextStyle(
                            color: context.colors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () => _deleteTransaction(context, ref),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, 
    String label, 
    String value, {
    Color? valueColor,
    Widget? customValue,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: context.colors.textSecondary,
              fontSize: 14,
            ),
          ),
          customValue ?? Text(
            value,
            style: TextStyle(
              color: valueColor ?? context.colors.textWhite,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Divider(
        color: context.colors.accentBrown.withOpacity(0.2),
        height: 1,
      ),
    );
  }
}
