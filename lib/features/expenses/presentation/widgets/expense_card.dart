import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/expense.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback onTap;

  const ExpenseCard({
    super.key,
    required this.expense,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bool isUserPayer = expense.paidByUserId == 'user_me'; // Mock check

    // Find user's split if any
    final userSplit = expense.splits.where((s) => s.userId == 'user_me').firstOrNull;
    final double userShare = userSplit?.amount ?? 0.0;
    
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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.colors.accentBrown.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.colors.background,
                shape: BoxShape.circle,
                border: Border.all(color: context.colors.primaryGold.withOpacity(0.2)),
              ),
              child: Icon(categoryIcon, color: context.colors.primaryGold, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title, 
                    style: textTheme.titleMedium?.copyWith(
                      color: context.colors.textWhite, 
                      fontWeight: FontWeight.bold,
                    )
                  ),
                  SizedBox(height: 4),
                  Text(
                    isUserPayer ? 'You paid ₹${expense.amount.toStringAsFixed(0)}' : '${expense.paidByName} paid ₹${expense.amount.toStringAsFixed(0)}',
                    style: textTheme.bodySmall?.copyWith(color: context.colors.textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isUserPayer 
                    ? 'You lent ₹${(expense.amount - userShare).toStringAsFixed(0)}' 
                    : 'You borrowed ₹${userShare.toStringAsFixed(0)}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: isUserPayer ? context.colors.success : context.colors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${expense.date.month}/${expense.date.day}', 
                  style: textTheme.bodySmall?.copyWith(color: context.colors.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
