import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WebsiteGenericContentScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;

  const WebsiteGenericContentScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.accentColor = const Color(0xFF7B61FF),
  });

  @override
  State<WebsiteGenericContentScreen> createState() => _WebsiteGenericContentScreenState();
}

class _WebsiteGenericContentScreenState extends State<WebsiteGenericContentScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOutCubic)
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeIn)
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
    final isDesktop = size.width > 800;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: size.height / 2 - 400,
            left: size.width / 2 - 400,
            child: Container(
              width: 800,
              height: 800,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    widget.accentColor.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          Center(
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _opacityAnimation,
                child: Container(
                  width: isDesktop ? 800 : size.width * 0.9,
                  padding: EdgeInsets.all(isDesktop ? 64 : 32),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: Colors.white),
                    boxShadow: [
                      BoxShadow(
                        color: widget.accentColor.withOpacity(0.1),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: widget.accentColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.icon,
                          size: 64,
                          color: widget.accentColor,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        widget.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: isDesktop ? 48 : 32,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        widget.subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: isDesktop ? 20 : 16,
                          color: const Color(0xFF475569),
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),
                      // Mock UI elements to represent content
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildMockCard(widget.accentColor.withOpacity(0.2)),
                          const SizedBox(width: 16),
                          _buildMockCard(widget.accentColor.withOpacity(0.5)),
                          const SizedBox(width: 16),
                          _buildMockCard(widget.accentColor),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockCard(Color color) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
