import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/glass_container.dart';

class SettlementDetailScreen extends StatelessWidget {
  final String id;
  final String title;
  final String amount;
  final int iconCodePoint;

  const SettlementDetailScreen({
    super.key,
    required this.id,
    required this.title,
    required this.amount,
    required this.iconCodePoint,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: const AppHeader(title: 'Settlement Detail'),
      body: SingleChildScrollView(
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
                      padding: EdgeInsets.all(24),
                      child: Icon(
                        IconData(iconCodePoint, fontFamily: 'MaterialIcons'),
                        color: context.colors.primaryGold,
                        size: 48,
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.colors.textWhite, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    amount,
                    style: TextStyle(color: context.colors.success, fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 14, color: context.colors.textSecondary),
                      SizedBox(width: 8),
                      Text('Yesterday, 9:15 PM', style: TextStyle(color: context.colors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 40),

            // Settlement Information
            GlassContainer(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SETTLEMENT INFO', style: TextStyle(color: context.colors.textSecondary, letterSpacing: 1.5, fontSize: 10, fontWeight: FontWeight.bold)),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildParticipant(context, 'Aman', 'Paid'),
                      Icon(Icons.arrow_forward_rounded, color: context.colors.primaryGold),
                      _buildParticipant(context, 'You', 'Received'),
                    ],
                  ),
                  Divider(color: context.colors.accentBrown.withOpacity(0.3), height: 48),
                  _buildDetailRow(context, 'Payment Method', 'UPI Transfer'),
                  SizedBox(height: 16),
                  _buildDetailRow(context, 'Transaction ID', 'TXN984204820'),
                  SizedBox(height: 16),
                  _buildDetailRow(context, 'Group', 'Private Nest'),
                ],
              ),
            ),
            
            SizedBox(height: 32),
            
            // Notes
            GlassContainer(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('NOTE', style: TextStyle(color: context.colors.textSecondary, letterSpacing: 1.5, fontSize: 10, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  Text(
                    '"Thanks for covering dinner last week!"',
                    style: TextStyle(color: context.colors.textWhite, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipant(BuildContext context, String name, String role) {
    return Column(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: context.colors.card,
          child: Text(name[0], style: TextStyle(color: context.colors.primaryGold, fontWeight: FontWeight.bold)),
        ),
        SizedBox(height: 8),
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
        Text(value, style: TextStyle(color: context.colors.textWhite, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
