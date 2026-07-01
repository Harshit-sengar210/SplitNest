import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/glass_container.dart';

class MemberDetailScreen extends StatelessWidget {
  final String memberId;

  const MemberDetailScreen({
    super.key,
    required this.memberId,
  });

  @override
  Widget build(BuildContext context) {
    // Generate a capitalized name from the ID for the mock
    final name = memberId[0].toUpperCase() + memberId.substring(1);
    
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: const AppHeader(title: 'Member Profile'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Header Info
            Center(
              child: Column(
                children: [
                  Hero(
                    tag: 'member_avatar_$memberId',
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: context.colors.primaryGold, width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: context.colors.card,
                        backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=$memberId'),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    name,
                    style: TextStyle(color: context.colors.textWhite, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.colors.primaryGold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.colors.primaryGold.withOpacity(0.5)),
                    ),
                    child: Text(
                      'Group Member',
                      style: TextStyle(color: context.colors.primaryGold, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 40),

            // Financial Summary
            Row(
              children: [
                Expanded(
                  child: GlassContainer(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text('YOU OWE', style: TextStyle(color: context.colors.textSecondary, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                        SizedBox(height: 12),
                        Text('₹120', style: TextStyle(color: context.colors.error, fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: GlassContainer(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text('OWES YOU', style: TextStyle(color: context.colors.textSecondary, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                        SizedBox(height: 12),
                        Text('₹450', style: TextStyle(color: context.colors.success, fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 32),
            
            // Recent Activity with this member
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Recent Activity', style: TextStyle(color: context.colors.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 16),
            
            GlassContainer(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildActivityRow(context, Icons.restaurant_rounded, 'Dinner Split', 'Owes ₹250', 'Today', true),
                  Divider(color: context.colors.accentBrown.withOpacity(0.2), height: 24),
                  _buildActivityRow(context, Icons.local_taxi_rounded, 'Cab Ride', 'You owe ₹120', 'Yesterday', false),
                  Divider(color: context.colors.accentBrown.withOpacity(0.2), height: 24),
                  _buildActivityRow(context, Icons.done_all_rounded, 'Settlement', 'Paid ₹500', 'Last Week', true),
                ],
              ),
            ),
            
            SizedBox(height: 40),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.notifications_active_rounded, color: context.colors.primaryGold),
                    label: Text('REMIND', style: TextStyle(color: context.colors.primaryGold)),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: context.colors.primaryGold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.payments_rounded, color: context.colors.background),
                    label: Text('SETTLE UP', style: TextStyle(color: context.colors.background, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: context.colors.primaryGold,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityRow(BuildContext context, IconData icon, String title, String amount, String time, bool isPositive) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: context.colors.background,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: context.colors.primaryGold, size: 20),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: context.colors.textWhite, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text(time, style: TextStyle(color: context.colors.textSecondary, fontSize: 11)),
            ],
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            color: isPositive ? context.colors.success : context.colors.error,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
