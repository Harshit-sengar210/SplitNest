import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/animations/custom_cursor.dart';
import '../widgets/animations/cursor_provider.dart';

class WebsiteShell extends StatelessWidget {
  final Widget child;

  const WebsiteShell({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      endDrawer: Drawer(
        child: Container(
          color: Colors.white,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                child: Center(
                  child: Image.asset(
                    'assets/images/splitnest_logo_final.png',
                    height:
                        120, // Increased height since logo contains text and slogan
                    errorBuilder: (c, e, s) => const Icon(
                      Icons.account_balance_wallet,
                      color: Color(0xFF7B61FF),
                      size: 64,
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home, color: Color(0xFF7B61FF)),
                title: Text(
                  'Home',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  context.pop(); // Close drawer
                  context.go('/');
                },
              ),
              ListTile(
                leading: const Icon(Icons.star, color: Color(0xFF7B61FF)),
                title: Text(
                  'Features',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  context.pop();
                  context.go('/features');
                },
              ),
              ListTile(
                leading: const Icon(Icons.lightbulb, color: Color(0xFF7B61FF)),
                title: Text(
                  'How it Works',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  context.pop();
                  context.go('/how-it-works');
                },
              ),
              ListTile(
                leading: const Icon(Icons.group_work, color: Color(0xFF7B61FF)),
                title: Text(
                  'Nests',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  context.pop();
                  context.go('/nests');
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.account_balance_wallet,
                  color: Color(0xFF7B61FF),
                ),
                title: Text(
                  'Ledger',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  context.pop();
                  context.go('/personal-ledger');
                },
              ),
              ListTile(
                leading: const Icon(Icons.info, color: Color(0xFF7B61FF)),
                title: Text(
                  'About',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  context.pop();
                  context.go('/about');
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip, color: Color(0xFF7B61FF)),
                title: Text(
                  'Privacy Policy',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  context.pop();
                  context.go('/privacy');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.login, color: Color(0xFF1E293B)),
                title: Text(
                  'Log in',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  context.pop();
                  context.go('/login');
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_add, color: Color(0xFF1E293B)),
                title: Text(
                  'Sign up',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  context.pop();
                  context.go('/register');
                },
              ),
            ],
          ),
        ),
      ),
      body: CustomCursorWrapper(
        child: Stack(
          children: [
            // The main page content
            Positioned.fill(child: child),

            // Floating Navbar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Builder(
                builder: (context) {
                  return _GlassNavbar();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassNavbar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
          child: Container(
            width: isDesktop ? 1200 : size.width - 32,
            margin: const EdgeInsets.only(top: 24),
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 24 : 12,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: Colors.white.withOpacity(0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7B61FF).withOpacity(0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Logo
                CursorRegion(
                  cursorState: CursorState.explore,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => context.go('/website'),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/splitnest_logo_final.png',
                            height:
                                52, // Increased height for vertical logo lockup
                            errorBuilder: (c, e, s) => const Icon(
                              Icons.account_balance_wallet,
                              color: Color(0xFF7B61FF),
                              size: 32,
                            ),
                          ),
                          // Removed Text('SplitNest') because the new logo image includes the text
                        ],
                      ),
                    ),
                  ),
                ),

                // Desktop Links
                if (isDesktop)
                  Row(
                    children: [
                      _NavItem('Features', '/features'),
                      _NavItem('How it Works', '/how-it-works'),
                      _NavItem('Nests', '/nests'),
                      _NavItem('Ledger', '/personal-ledger'),
                      _NavItem('About', '/about'),
                      _NavItem('Privacy', '/privacy'),
                    ],
                  ),

                // CTAs
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isDesktop) ...[
                      CursorRegion(
                        cursorState: CursorState.explore,
                        child: TextButton(
                          onPressed: () => context.go('/login'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF1E293B),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          child: Text(
                            'Log in',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CursorRegion(
                        cursorState: CursorState.explore,
                        child: TextButton(
                          onPressed: () => context.go('/register'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF1E293B),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          child: Text(
                            'Sign up',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    CursorRegion(
                      cursorState: CursorState.download,
                      child: ElevatedButton(
                        onPressed: () => context.go('/download'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7B61FF),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 24 : 16,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Download',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    if (!isDesktop) ...[
                      const SizedBox(width: 8),
                      CursorRegion(
                        cursorState: CursorState.explore,
                        child: IconButton(
                          onPressed: () {
                            Scaffold.of(context).openEndDrawer();
                          },
                          icon: const Icon(
                            Icons.menu,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ), // closes Row
          ), // closes Container
        ), // closes BackdropFilter
      ), // closes ClipRRect
    ); // closes Center
  }
}

class _NavItem extends StatefulWidget {
  final String title;
  final String route;

  const _NavItem(this.title, this.route);

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return CursorRegion(
      cursorState: CursorState.custom,
      customText: widget.title,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: () => context.go(widget.route),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            decoration: BoxDecoration(
              color: _isHovered
                  ? const Color(0xFF7B61FF).withOpacity(0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(100),
            ),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: _isHovered
                    ? const Color(0xFF7B61FF)
                    : const Color(0xFF64748B),
                fontSize: 15,
              ),
              child: Text(widget.title),
            ),
          ),
        ),
      ),
    );
  }
}
