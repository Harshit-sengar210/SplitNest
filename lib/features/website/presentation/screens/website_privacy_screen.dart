import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WebsitePrivacyScreen extends StatelessWidget {
  const WebsitePrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 64 : 24,
          vertical: 48,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy Policy',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isDesktop ? 48 : 36,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Effective Date: August 14, 2026',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 48),
                _buildSectionTitle('1. Introduction'),
                _buildParagraph(
                    'Welcome to SplitNest. Your privacy is important to us. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application and website (collectively, the "Service"). Please read this privacy policy carefully. If you do not agree with the terms of this privacy policy, please do not access the application.'),
                _buildSectionTitle('2. Information We Collect'),
                _buildParagraph(
                    'We may collect information about you in a variety of ways. The information we may collect via the Application includes:'),
                _buildBulletPoint('Personal Data: Personally identifiable information, such as your name, email address, and phone number, that you voluntarily give to us when you register with the Application or when you choose to participate in various activities related to the Application.'),
                _buildBulletPoint('Derivative Data: Information our servers automatically collect when you access the Application, such as your native actions that are integral to the Application, as well as other interactions with the Application and other users via server log files.'),
                _buildBulletPoint('Financial Data: Financial information related to your transactions, expenses, and balances shared within your groups (Nests). SplitNest does not store your direct banking credentials or credit card numbers on our servers.'),
                _buildSectionTitle('3. Use of Your Information'),
                _buildParagraph(
                    'Having accurate information about you permits us to provide you with a smooth, efficient, and customized experience. Specifically, we may use information collected about you via the Application to:'),
                _buildBulletPoint('Create and manage your account.'),
                _buildBulletPoint('Facilitate expense splitting, calculations, and group ledger management.'),
                _buildBulletPoint('Email you regarding your account or order.'),
                _buildBulletPoint('Fulfill and manage purchases, orders, payments, and other transactions related to the Application.'),
                _buildBulletPoint('Increase the efficiency and operation of the Application.'),
                _buildSectionTitle('4. Disclosure of Your Information'),
                _buildParagraph(
                    'We may share information we have collected about you in certain situations. Your information may be disclosed as follows:'),
                _buildBulletPoint('By Law or to Protect Rights: If we believe the release of information about you is necessary to respond to legal process, to investigate or remedy potential violations of our policies, or to protect the rights, property, and safety of others.'),
                _buildBulletPoint('Third-Party Service Providers: We may share your information with third parties that perform services for us or on our behalf, including payment processing, data analysis, email delivery, hosting services, customer service, and marketing assistance.'),
                _buildBulletPoint('Other Users: Your name, profile picture, and expense data are visible to other users within the Nests (groups) you join or create.'),
                _buildSectionTitle('5. Security of Your Information'),
                _buildParagraph(
                    'We use administrative, technical, and physical security measures to help protect your personal information. While we have taken reasonable steps to secure the personal information you provide to us, please be aware that despite our efforts, no security measures are perfect or impenetrable, and no method of data transmission can be guaranteed against any interception or other type of misuse.'),
                _buildSectionTitle('6. Policy for Children'),
                _buildParagraph(
                    'We do not knowingly solicit information from or market to children under the age of 13. If we learn that we have collected personal information from a child under age 13 without verification of parental consent, we will delete that information as quickly as possible.'),
                _buildSectionTitle('7. Contact Us'),
                _buildParagraph(
                    'If you have questions or comments about this Privacy Policy, please contact us at:'),
                const SizedBox(height: 8),
                Text(
                  'Email: splitnest0@gmail.com\nPhone: +91-9599676325\nWebsite: https://cyberlim.com',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    color: const Color(0xFF0F172A),
                    height: 1.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 64),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 32, bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          color: const Color(0xFF475569),
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              color: const Color(0xFF7B61FF),
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                color: const Color(0xFF475569),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
