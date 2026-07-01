import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../expenses/domain/models/expense.dart';
import 'settlement_bottom_sheet.dart';

class SplitBalanceCard extends StatelessWidget {
  final String groupId;
  final Expense expense;
  final ExpenseSplit split;
  final String currentUserId;
  final String? debtorPhotoUrl;
  final String? creditorPhotoUrl;

  const SplitBalanceCard({
    super.key,
    required this.groupId,
    required this.expense,
    required this.split,
    required this.currentUserId,
    this.debtorPhotoUrl,
    this.creditorPhotoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isOwner = currentUserId == split.paidBy;
    final isDebtor = currentUserId == split.userId;
    
    // Determine status
    final isCompleted = split.pendingAmount <= 0.01 || split.status == 'completed';
    final isPartial = !isCompleted && split.settledAmount > 0.01;
    final isPending = !isCompleted && !isPartial;

    // Status colors and text
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isCompleted) {
      statusColor = colors.success;
      statusText = 'Completed';
      statusIcon = Icons.check_circle_rounded;
    } else if (isPartial) {
      statusColor = const Color(0xFF6CA8FF); // Progress blue
      statusText = 'Partial';
      statusIcon = Icons.star_half_rounded;
    } else {
      statusColor = const Color(0xFFFFB300); // Pending amber
      statusText = 'Pending';
      statusIcon = Icons.schedule_rounded;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isCompleted
              ? colors.success.withOpacity(0.15)
              : isPartial
                  ? const Color(0xFF6CA8FF).withOpacity(0.15)
                  : colors.accentBrown.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Expense Title, Category Icon, Date
            Row(
              children: [
                _buildCategoryIcon(expense.category, colors),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.title,
                        style: GoogleFonts.plusJakartaSans(
                          color: colors.textWhite,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('MMM dd, yyyy').format(expense.date),
                        style: GoogleFonts.plusJakartaSans(
                          color: colors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Chip
                _buildStatusChip(statusText, statusColor, statusIcon, colors),
              ],
            ),
            const SizedBox(height: 16),

            // Members and Debt Flow representation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Debtor Column
                Expanded(
                  child: Row(
                    children: [
                      _buildAvatar(split.memberName, debtorPhotoUrl, colors),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Owes',
                              style: GoogleFonts.plusJakartaSans(
                                color: colors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              isDebtor ? 'You' : split.memberName,
                              style: GoogleFonts.plusJakartaSans(
                                color: colors.textWhite,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Flow Arrow Icon
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: colors.textMuted.withOpacity(0.5),
                    size: 16,
                  ),
                ),

                // Creditor Column
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'To',
                              style: GoogleFonts.plusJakartaSans(
                                color: colors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              isOwner ? 'You' : split.paidByName,
                              style: GoogleFonts.plusJakartaSans(
                                color: colors.textWhite,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildAvatar(split.paidByName, creditorPhotoUrl, colors),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Divider line
            Divider(
              color: colors.accentBrown.withOpacity(0.1),
              height: 1,
            ),
            const SizedBox(height: 16),

            // Amount summary and Action button/Info card
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCompleted ? 'Settled Amount' : 'Amount Owed',
                        style: GoogleFonts.plusJakartaSans(
                          color: colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isCompleted
                            ? '₹${split.originalShare.toStringAsFixed(2)}'
                            : '₹${split.pendingAmount.toStringAsFixed(2)}',
                        style: GoogleFonts.plusJakartaSans(
                          color: isCompleted ? colors.success : colors.primaryGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      if (isPartial && !isCompleted) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Already settled: ₹${split.settledAmount.toStringAsFixed(1)} of ₹${split.originalShare.toStringAsFixed(1)}',
                          style: GoogleFonts.plusJakartaSans(
                            color: colors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
                
                // Show settle button or info card
                if (!isCompleted) ...[
                  if (isOwner)
                    ElevatedButton(
                      onPressed: () => _openSettlementSheet(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primaryGold,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Settle Up',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ],
            ),

            // Informational Card for Non-Owners when split is not completed
            if (!isCompleted && !isOwner) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.primaryGold.withOpacity(0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: colors.primaryGold,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isDebtor
                            ? 'You owe ₹${split.pendingAmount.toStringAsFixed(2)} to ${split.paidByName}. Waiting for ${split.paidByName} to confirm receipt.'
                            : '${split.memberName} owes ₹${split.pendingAmount.toStringAsFixed(2)} to ${split.paidByName}. Waiting for ${split.paidByName} to confirm receipt.',
                        style: GoogleFonts.plusJakartaSans(
                          color: colors.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openSettlementSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SettlementBottomSheet(
        groupId: groupId,
        expense: expense,
        split: split,
      ),
    );
  }

  Widget _buildStatusChip(String text, Color color, IconData icon, AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryIcon(String category, AppColorsExtension colors) {
    IconData iconData;
    switch (category.toLowerCase()) {
      case 'food':
      case 'dining':
      case 'restaurant':
        iconData = Icons.restaurant_rounded;
        break;
      case 'transport':
      case 'cab':
      case 'fuel':
      case 'travel':
        iconData = Icons.directions_car_rounded;
        break;
      case 'entertainment':
      case 'movies':
      case 'game':
        iconData = Icons.movie_rounded;
        break;
      case 'shopping':
      case 'groceries':
        iconData = Icons.shopping_bag_rounded;
        break;
      case 'bills':
      case 'utilities':
      case 'rent':
        iconData = Icons.receipt_rounded;
        break;
      default:
        iconData = Icons.receipt_long_rounded;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colors.primaryGold.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        iconData,
        color: colors.primaryGold,
        size: 20,
      ),
    );
  }

  Widget _buildAvatar(String name, String? photoUrl, AppColorsExtension colors) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: NetworkImage(photoUrl),
        backgroundColor: colors.background,
      );
    }
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            colors.primaryGold.withOpacity(0.8),
            colors.primaryGold,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
