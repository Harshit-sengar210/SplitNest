import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/message.dart';
import 'package:intl/intl.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final timeStr = DateFormat.jm().format(message.timestamp);
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Premium bubble decoration
    final bubbleDecoration = BoxDecoration(
      gradient: isMe
          ? LinearGradient(
              colors: [colors.primaryGold, colors.primaryGold.withBlue(220)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : null,
      color: isMe 
          ? null 
          : (isDark ? colors.card : Colors.white),
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(20),
        topRight: const Radius.circular(20),
        bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
        bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
      ),
      border: Border.all(
        color: isMe
            ? Colors.white.withOpacity(0.12)
            : (isDark ? Colors.white.withOpacity(0.06) : colors.accentBrown.withOpacity(0.5)),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: isMe 
              ? colors.primaryGold.withOpacity(0.2) 
              : Colors.black.withOpacity(isDark ? 0.25 : 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            GestureDetector(
              onTap: () {
                // Profile view action
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.primaryGold.withOpacity(0.25),
                    width: 1.5,
                  ),
                ),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: colors.accentBrown,
                  backgroundImage: message.senderPhoto != null && message.senderPhoto!.isNotEmpty
                      ? NetworkImage(message.senderPhoto!)
                      : null,
                  child: message.senderPhoto == null || message.senderPhoto!.isEmpty
                      ? Text(
                          message.senderName.isNotEmpty ? message.senderName[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: colors.primaryGold,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 6, bottom: 4),
                    child: Text(
                      message.senderName,
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: bubbleDecoration,
                  child: _buildMessageContent(context, textTheme),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, right: 4, left: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeStr,
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (message.isEdited) ...[
                        const SizedBox(width: 4),
                        Text(
                          '• Edited',
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                          size: 14,
                          color: message.isRead ? colors.primaryGold : colors.textMuted,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, TextTheme textTheme) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (message.expenseDetails != null) {
      return _buildRichExpenseCard(context, textTheme);
    }
    
    if (message.imageUrl != null) {
      final img = message.imageUrl!;
      Widget imageWidget;
      if (img.startsWith('http://') || img.startsWith('https://')) {
        imageWidget = Image.network(img, fit: BoxFit.cover);
      } else if (img.startsWith('data:image')) {
        final base64Str = img.contains(',') ? img.split(',')[1] : img;
        imageWidget = Image.memory(base64Decode(base64Str), fit: BoxFit.cover);
      } else {
        imageWidget = Image.network(img, fit: BoxFit.cover);
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageWidget,
          ),
          if (message.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              message.text,
              style: TextStyle(color: isMe ? Colors.white : colors.textWhite),
            ),
          ],
        ],
      );
    }

    return Text(
      message.text,
      style: TextStyle(
        color: isMe ? Colors.white : colors.textWhite,
        fontSize: 14.5,
        height: 1.35,
      ),
    );
  }

  Widget _buildRichExpenseCard(BuildContext context, TextTheme textTheme) {
    final expense = message.expenseDetails!;
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isMe ? Colors.white.withOpacity(0.15) : colors.background,
                shape: BoxShape.circle,
                border: Border.all(color: isMe ? Colors.white.withOpacity(0.2) : colors.primaryGold.withOpacity(0.2)),
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                color: isMe ? Colors.white : colors.primaryGold,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  style: textTheme.titleMedium?.copyWith(
                    color: isMe ? Colors.white : colors.textWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '\$${expense.amount.toStringAsFixed(2)}',
                  style: textTheme.bodyLarge?.copyWith(
                    color: isMe ? Colors.white.withOpacity(0.9) : colors.primaryGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Divider(color: isMe ? Colors.white.withOpacity(0.2) : colors.accentBrown.withOpacity(0.5)),
        const SizedBox(height: 8),
        Text(
          'Split among ${expense.splits.length} members',
          style: textTheme.bodySmall?.copyWith(
            color: isMe ? Colors.white.withOpacity(0.8) : colors.textSecondary,
          ),
        ),
        if (expense.splitMethod == 'Equal' && expense.splits.isNotEmpty)
          Text(
            '\$${(expense.amount / expense.splits.length).toStringAsFixed(2)} each',
            style: textTheme.bodyMedium?.copyWith(
              color: isMe ? Colors.white : colors.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }
}
