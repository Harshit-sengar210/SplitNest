import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WebsiteFaqScreen extends StatefulWidget {
  const WebsiteFaqScreen({super.key});

  @override
  State<WebsiteFaqScreen> createState() => _WebsiteFaqScreenState();
}

class _WebsiteFaqScreenState extends State<WebsiteFaqScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _titleOpacity;
  late Animation<Offset> _titleSlide;
  late Animation<double> _listOpacity;
  late Animation<Offset> _listSlide;

  final faqs = [
    {
      'q': 'Is SplitNest free to use?',
      'a': 'Yes! The core functionality of SplitNest, including creating Nests, adding expenses, and calculating settlements, is completely free.'
    },
    {
      'q': 'How does the Smart Settlement work?',
      'a': 'Our algorithm looks at all the debts within a Nest and simplifies them. For example, if A owes B \$10, and B owes C \$10, SplitNest will just tell A to pay C \$10, eliminating the middle transaction.'
    },
    {
      'q': 'Can I use SplitNest for travel?',
      'a': 'Absolutely! Nests are perfect for group travel. You can log expenses in different currencies (coming soon) and see exactly who paid for what during the trip.'
    },
    {
      'q': 'Is my financial data secure?',
      'a': 'We take security seriously. We use industry-standard encryption for all data transmission and storage. We do not store your bank credentials.'
    },
  ];

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.4, curve: Curves.easeIn))
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic))
    );
    _listOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.3, 0.7, curve: Curves.easeIn))
    );
    _listSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic))
    );

    _mainController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 1000;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -200,
            right: -200,
            child: Container(
              width: 800,
              height: 800,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF334155).withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          SingleChildScrollView(
            child: Center(
              child: Container(
                width: isDesktop ? 800 : size.width * 0.9,
                padding: EdgeInsets.symmetric(vertical: isDesktop ? 128 : 64),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeTransition(
                      opacity: _titleOpacity,
                      child: SlideTransition(
                        position: _titleSlide,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF334155).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                'FAQ',
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF334155),
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Common Questions.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: isDesktop ? 56 : 32,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                                letterSpacing: -1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 64),
                    
                    // FAQ List
                    FadeTransition(
                      opacity: _listOpacity,
                      child: SlideTransition(
                        position: _listSlide,
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: faqs.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            return _FaqItem(
                              question: faqs[index]['q']!,
                              answer: faqs[index]['a']!,
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqItem extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _isExpanded ? const Color(0xFF7B61FF).withOpacity(0.3) : Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.question,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox(width: double.infinity, height: 0),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      widget.answer,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        color: const Color(0xFF64748B),
                        height: 1.5,
                      ),
                    ),
                  ),
                  crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
