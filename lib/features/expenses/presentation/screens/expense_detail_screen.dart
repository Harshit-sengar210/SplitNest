import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/gold_button.dart';
import '../../../../core/widgets/app_header.dart';
import 'dart:convert';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_container.dart';
import '../providers/expenses_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/expense.dart';

class ExpenseDetailScreen extends ConsumerWidget {
  final String id;
  final String? groupId;

  const ExpenseDetailScreen({
    super.key,
    required this.id,
    this.groupId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final resolvedGroupId = groupId ?? ref.watch(activeNestIdProvider);

    if (resolvedGroupId == null) {
      return Scaffold(
        backgroundColor: context.colors.background,
        appBar: const AppHeader(title: 'Expense Detail'),
        body: const Center(
          child: Text(
            'Error: No active Nest group found.',
            style: TextStyle(color: Colors.redAccent),
          ),
        ),
      );
    }

    final expenseAsync = ref.watch(
      singleExpenseStreamProvider((groupId: resolvedGroupId, expenseId: id)),
    );

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: const AppHeader(title: 'Expense Detail'),
      body: expenseAsync.when(
        data: (expense) => _buildDetailContent(context, expense, textTheme),
        loading: () => Center(
          child: CircularProgressIndicator(
            color: context.colors.primaryGold,
            strokeWidth: 2.5,
          ),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Failed to load details: $error',
              style: const TextStyle(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailContent(BuildContext context, Expense expense, TextTheme textTheme) {
    final createdDateStr = DateFormat('MMM dd, yyyy - hh:mm a').format(expense.createdAt);
    final updatedDateStr = DateFormat('MMM dd, yyyy - hh:mm a').format(expense.updatedAt);
    final formattedAmount = '₹${expense.amount.toStringAsFixed(2)}';

    // Determine the color and icon for category
    IconData categoryIcon = Icons.receipt_long;
    switch (expense.category) {
      case 'Groceries':
        categoryIcon = Icons.shopping_basket_rounded;
        break;
      case 'Rent':
        categoryIcon = Icons.home_rounded;
        break;
      case 'Utilities':
        categoryIcon = Icons.bolt_rounded;
        break;
      case 'Travel':
        categoryIcon = Icons.flight_takeoff_rounded;
        break;
      case 'Party':
        categoryIcon = Icons.celebration_rounded;
        break;
      case 'Food':
        categoryIcon = Icons.restaurant_rounded;
        break;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Header Info
          Center(
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.colors.card,
                    border: Border.all(color: context.colors.primaryGold.withOpacity(0.3)),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Icon(
                    categoryIcon,
                    color: context.colors.primaryGold,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  expense.title,
                  style: TextStyle(
                    color: context.colors.textWhite,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  formattedAmount,
                  style: TextStyle(
                    color: context.colors.error,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: context.colors.accentBrown,
                      child: Text(
                        expense.paidByName.isNotEmpty ? expense.paidByName[0].toUpperCase() : 'P',
                        style: TextStyle(color: context.colors.primaryGold, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Paid by ${expense.paidByName}',
                      style: TextStyle(color: context.colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),

          // Detail list fields
          GlassContainer(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EXPENSE INFO',
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    letterSpacing: 1.5,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow(context, 'Category', expense.category),
                _buildDivider(context),
                _buildInfoRow(context, 'Split Type', expense.splitMethod),
                _buildDivider(context),
                _buildInfoRow(context, 'Currency', expense.currency),
                _buildDivider(context),
                _buildInfoRow(
                  context,
                  'Description',
                  expense.description != null && expense.description!.isNotEmpty
                      ? expense.description!
                      : 'No notes provided',
                ),
                _buildDivider(context),
                _buildInfoRow(context, 'Created Date', createdDateStr),
                _buildDivider(context),
                _buildInfoRow(context, 'Updated Date', updatedDateStr),
              ],
            ),
          ),
          
          if (expense.imageUrl != null && expense.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 24),
            GlassContainer(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ATTACHED BILL / RECEIPT',
                    style: TextStyle(
                      color: context.colors.textSecondary,
                      letterSpacing: 1.5,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: expense.imageUrl!.startsWith('data:image')
                        ? Image.memory(
                            base64Decode(expense.imageUrl!.split(',').last),
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            expense.imageUrl!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 200,
                                color: context.colors.accentBrown.withOpacity(0.3),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: context.colors.primaryGold,
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ],
          
          if (expense.splits.isNotEmpty) ...[
            const SizedBox(height: 32),
            GlassContainer(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SPLIT DETAILS',
                    style: TextStyle(
                      color: context.colors.textSecondary,
                      letterSpacing: 1.5,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...expense.splits.map((s) {
                    final isPaid = s.userId == expense.paidByUserId;
                    final isCurrentUser = s.userId == 'user_me' || 
                        s.userId == FirebaseAuth.instance.currentUser?.uid;
                        
                    final displayUser = isCurrentUser 
                        ? 'You' 
                        : (s.memberName.isNotEmpty && s.memberName != 'Someone' 
                            ? s.memberName 
                            : s.userId.replaceAll('user_', '').toUpperCase());
                            
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              displayUser, 
                              style: TextStyle(color: context.colors.textWhite, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '₹${s.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: isPaid ? context.colors.success : context.colors.textWhite,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: context.colors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: context.colors.textWhite,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      color: context.colors.accentBrown.withOpacity(0.3),
      height: 24,
      thickness: 1,
    );
  }
}
