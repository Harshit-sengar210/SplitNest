import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';

class PlaceholderSettingScreen extends StatelessWidget {
  final String title;

  const PlaceholderSettingScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.colors.primaryGold, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          title,
          style: TextStyle(color: context.colors.textWhite, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.colors.card,
                border: Border.all(color: context.colors.primaryGold.withOpacity(0.3), width: 1),
              ),
              child: Icon(Icons.settings_outlined, color: context.colors.primaryGold, size: 48),
            ),
            SizedBox(height: 24),
            Text(
              '$title Settings',
              style: TextStyle(color: context.colors.textWhite, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'Interactive Placeholder UI',
              style: TextStyle(color: context.colors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
