import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WebsitePlaceholderScreen extends StatelessWidget {
  final String title;

  const WebsitePlaceholderScreen({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 48,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'This page is under construction.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
