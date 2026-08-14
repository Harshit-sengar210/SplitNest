import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/glass_container.dart';
import '../providers/settlement_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../groups/presentation/providers/groups_provider.dart';

class SettlementDetailScreen extends ConsumerWidget {
  final String id;
  final String? groupId;
  final String title;
  final String amount;
  final int iconCodePoint;

  const SettlementDetailScreen({
    super.key,
    required this.id,
    this.groupId,
    required this.title,
    required this.amount,
    required this.iconCodePoint,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settlementAsync = ref.watch(settlementDetailProvider((id: id, groupId: groupId)));
    final currentUser = ref.watch(authStateChangesProvider).value;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: const AppHeader(title: 'Settlement Detail'),
      body: settlementAsync.when(
        data: (settlement) {
          if (settlement == null) {
            return Center(child: Text('Settlement not found', style: TextStyle(color: context.colors.textWhite)));
          }

          final isPayer = currentUser?.id == settlement.payerId;
          final isReceiver = currentUser?.id == settlement.receiverId;
          
          final payerName = isPayer ? 'You' : (settlement.payerName ?? 'Someone');
          final receiverName = isReceiver ? 'You' : (settlement.receiverName ?? 'Someone');
          
          final dateStr = DateFormat('MMMM d, h:mm a').format(settlement.createdAt);
          final actualAmount = '₹${settlement.amount.toStringAsFixed(0)}';
          final txnId = settlement.id.toUpperCase();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Header Info
                Center(
                  child: Column(
                    children: [
                      Hero(
                        tag: 'activity_icon_$id',
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: context.colors.card,
                            border: Border.all(color: context.colors.primaryGold.withOpacity(0.3)),
                          ),
                          padding: const EdgeInsets.all(24),
                          child: Icon(
                            _getSafeIcon(iconCodePoint),
                            color: context.colors.primaryGold,
                            size: 48,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.colors.textWhite, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        actualAmount,
                        style: TextStyle(color: context.colors.success, fontSize: 36, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 14, color: context.colors.textSecondary),
                          const SizedBox(width: 8),
                          Text(dateStr, style: TextStyle(color: context.colors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),

                // Settlement Information
                GlassContainer(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SETTLEMENT INFO', style: TextStyle(color: context.colors.textSecondary, letterSpacing: 1.5, fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildParticipant(context, payerName, 'Paid'),
                          Icon(Icons.arrow_forward_rounded, color: context.colors.primaryGold),
                          _buildParticipant(context, receiverName, 'Received'),
                        ],
                      ),
                      Divider(color: context.colors.accentBrown.withOpacity(0.3), height: 48),
                      
                      _buildDetailRow(context, 'Payment Method', 'Internal Settlement'),
                      const SizedBox(height: 16),
                      _buildDetailRow(context, 'Transaction ID', txnId),
                      const SizedBox(height: 16),
                      
                      // Group Name dynamically loaded
                      Consumer(
                        builder: (context, ref, child) {
                          final groupAsync = ref.watch(groupDetailProvider(settlement.groupId));
                          return groupAsync.when(
                            data: (group) => _buildDetailRow(context, 'Group', group.name),
                            loading: () => _buildDetailRow(context, 'Group', 'Loading...'),
                            error: (_, __) => _buildDetailRow(context, 'Group', 'Unknown Group'),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: context.colors.primaryGold)),
        error: (err, stack) => Center(child: Text('Error loading settlement: $err', style: TextStyle(color: context.colors.textWhite))),
      ),
    );
  }

  IconData _getSafeIcon(int codePoint) {
    if (codePoint == Icons.done_all_rounded.codePoint) return Icons.done_all_rounded;
    if (codePoint == Icons.attach_money.codePoint) return Icons.attach_money;
    if (codePoint == Icons.account_balance.codePoint) return Icons.account_balance;
    if (codePoint == Icons.receipt.codePoint) return Icons.receipt;
    if (codePoint == Icons.payment.codePoint) return Icons.payment;
    return Icons.receipt_long_rounded;
  }

  Widget _buildParticipant(BuildContext context, String name, String role) {
    return Column(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: context.colors.card,
          child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: TextStyle(color: context.colors.primaryGold, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        Text(name, style: TextStyle(color: context.colors.textWhite, fontWeight: FontWeight.bold)),
        Text(role, style: TextStyle(color: context.colors.textSecondary, fontSize: 10)),
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: context.colors.textSecondary)),
        Flexible(
          child: Text(
            value, 
            style: TextStyle(color: context.colors.textWhite, fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
