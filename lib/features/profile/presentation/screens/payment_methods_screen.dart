import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/app_header.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> with TickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  void _showAddPaymentMethodDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7B61FF), Color(0xFF6CA8FF)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7B61FF).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.add_card_rounded, color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Add Payment Method',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF1F2937),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Link a credit/debit card or bank account to settle up bills instantly.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF6B7280),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                _buildDialogOption(
                  icon: Icons.credit_card_rounded,
                  title: 'Credit or Debit Card',
                  subtitle: 'Supports Visa, Mastercard, AMEX',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Card scanning placeholder', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
                        backgroundColor: const Color(0xFF7B61FF),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildDialogOption(
                  icon: Icons.account_balance_rounded,
                  title: 'Bank Account',
                  subtitle: 'Link via Plaid securely',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Plaid linking placeholder', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
                        backgroundColor: const Color(0xFF7B61FF),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: const Color(0xFF7B61FF).withOpacity(0.05),
        highlightColor: const Color(0xFF7B61FF).withOpacity(0.02),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8E5FF),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF7B61FF), size: 18),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF1F2937),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF6B7280),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFD1D5DB), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const AppHeader(title: 'Payment Methods'),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF5F3FF),
              Color(0xFFFFFFFF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            _BackgroundShapes(floatAnimation: _floatAnimation),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    _SectionTitle(title: 'Your Cards'),
                    const SizedBox(height: 16),

                    // Card 1
                    _buildCreditCard(
                      cardHolder: 'HARSHIT SHARMA',
                      cardNumber: '•••• •••• •••• 8432',
                      expiry: '08/29',
                      cardType: 'VISA',
                      colors: [const Color(0xFF7B61FF), const Color(0xFF6CA8FF)],
                    ),
                    const SizedBox(height: 20),

                    // Card 2
                    _buildCreditCard(
                      cardHolder: 'HARSHIT SHARMA',
                      cardNumber: '•••• •••• •••• 1092',
                      expiry: '12/28',
                      cardType: 'MASTERCARD',
                      colors: [const Color(0xFF312E81), const Color(0xFF8B5CF6)],
                    ),
                    const SizedBox(height: 32),

                    _SectionTitle(title: 'Linked Bank Accounts'),
                    const SizedBox(height: 16),
                    _buildCardGroup(
                      children: [
                        _buildBankItem(
                          bankName: 'Chase Bank',
                          accountType: 'Savings Account (•••• 9871)',
                          icon: Icons.account_balance_rounded,
                        ),
                        const Divider(color: Color(0xFFF3F4F6), height: 1, indent: 72),
                        _buildBankItem(
                          bankName: 'HDFC Bank',
                          accountType: 'Checking Account (•••• 2341)',
                          icon: Icons.account_balance_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),

                    // Add Payment Method Button
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(29),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7B61FF), Color(0xFF6CA8FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7B61FF).withOpacity(0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _showAddPaymentMethodDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(29)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'LINK PAYMENT METHOD',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditCard({
    required String cardHolder,
    required String cardNumber,
    required String expiry,
    required String cardType,
    required List<Color> colors,
  }) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colors[0].withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Decorative light glare overlay
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.04),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.contactless_rounded, color: Colors.white, size: 20),
                      ),
                      Text(
                        cardType,
                        style: GoogleFonts.outfit(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    cardNumber,
                    style: GoogleFonts.shareTechMono(
                      color: Colors.white,
                      fontSize: 22,
                      letterSpacing: 2.0,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CARD HOLDER',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cardHolder,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EXPIRES',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            expiry,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardGroup({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B61FF).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildBankItem({
    required String bankName,
    required String accountType,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF7B61FF).withOpacity(0.85),
                  const Color(0xFF7B61FF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7B61FF).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bankName,
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF1F2937),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  accountType,
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFFEF4444), size: 20),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          color: const Color(0xFF9CA3AF),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _BackgroundShapes extends StatelessWidget {
  final Animation<double> floatAnimation;

  const _BackgroundShapes({required this.floatAnimation});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 100,
          left: -40,
          child: AnimatedBuilder(
            animation: floatAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, floatAnimation.value * 12),
                child: child,
              );
            },
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFA78BFA).withOpacity(0.18),
                    const Color(0xFFA78BFA).withOpacity(0.01),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 120,
          right: -50,
          child: AnimatedBuilder(
            animation: floatAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -floatAnimation.value * 15),
                child: child,
              );
            },
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6CA8FF).withOpacity(0.18),
                    const Color(0xFF6CA8FF).withOpacity(0.01),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
