import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_header.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> with TickerProviderStateMixin {
  bool _twoFactorEnabled = true;
  bool _profileVisible = true;
  bool _groupsVisible = false;

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

  void _showDeleteAccountDialog() {
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 40),
                ),
                const SizedBox(height: 24),
                Text(
                  'Delete Account',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF1F2937),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you absolutely sure you want to delete your account? This action is permanent and cannot be undone.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF6B7280),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF4B5563),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Account deletion requested.'),
                              backgroundColor: Color(0xFFEF4444),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: Text(
                          'Delete',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const AppHeader(
        title: 'Security Settings',
      ),
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
                    _SectionTitle(title: 'Account Security'),
                    const SizedBox(height: 16),
                    _buildCardGroup(
                      children: [
                        _buildActionItem(
                          icon: Icons.lock_outline_rounded,
                          iconColor: const Color(0xFF7B61FF),
                          title: 'Change Password',
                          subtitle: 'Last changed 3 months ago',
                          onTap: () {},
                        ),
                        _buildDivider(),
                        _buildToggleItem(
                          icon: Icons.verified_user_outlined,
                          iconColor: const Color(0xFF6CA8FF),
                          title: 'Two-Factor Authentication',
                          subtitle: 'Adds an extra layer of security',
                          value: _twoFactorEnabled,
                          onChanged: (val) => setState(() => _twoFactorEnabled = val),
                        ),
                        _buildDivider(),
                        _buildActionItem(
                          icon: Icons.devices_rounded,
                          iconColor: const Color(0xFFA78BFA),
                          title: 'Active Sessions',
                          subtitle: 'Manage devices logged into your account',
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    _SectionTitle(title: 'Privacy'),
                    const SizedBox(height: 16),
                    _buildCardGroup(
                      children: [
                        _buildToggleItem(
                          icon: Icons.visibility_outlined,
                          iconColor: const Color(0xFF10B981),
                          title: 'Profile Visibility',
                          subtitle: 'Allow others to find your profile',
                          value: _profileVisible,
                          onChanged: (val) => setState(() => _profileVisible = val),
                        ),
                        _buildDivider(),
                        _buildToggleItem(
                          icon: Icons.groups_outlined,
                          iconColor: const Color(0xFFF59E0B),
                          title: 'Group Visibility',
                          subtitle: 'Show which groups you are part of',
                          value: _groupsVisible,
                          onChanged: (val) => setState(() => _groupsVisible = val),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),

                    _SectionTitle(title: 'Danger Zone', isDanger: true),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFFEE2E2), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEF4444).withOpacity(0.03),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _showDeleteAccountDialog,
                          borderRadius: BorderRadius.circular(22),
                          splashColor: const Color(0xFFEF4444).withOpacity(0.05),
                          highlightColor: const Color(0xFFEF4444).withOpacity(0.02),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                _build3DIcon(Icons.delete_outline_rounded, const Color(0xFFEF4444)),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Delete Account',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: const Color(0xFFEF4444),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Permanently remove your data',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: const Color(0xFF9CA3AF),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: Color(0xFFEF4444), size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
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
            color: const Color(0xFF7B61FF).withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(color: Color(0xFFF3F4F6), height: 1, indent: 76);
  }

  Widget _build3DIcon(IconData icon, Color primaryColor) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            primaryColor.withOpacity(0.85),
            primaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.35),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        splashColor: const Color(0xFF7B61FF).withOpacity(0.05),
        highlightColor: const Color(0xFF7B61FF).withOpacity(0.02),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              _build3DIcon(icon, iconColor),
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
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF6B7280),
                        fontSize: 12,
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

  Widget _buildToggleItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _build3DIcon(icon, iconColor),
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
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF7B61FF),
            activeTrackColor: const Color(0xFF7B61FF).withOpacity(0.3),
            inactiveThumbColor: const Color(0xFF9CA3AF),
            inactiveTrackColor: const Color(0xFFE5E7EB),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isDanger;
  const _SectionTitle({required this.title, this.isDanger = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          color: isDanger ? const Color(0xFFEF4444) : const Color(0xFF9CA3AF),
          fontSize: 12,
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
                    const Color(0xFFA78BFA).withOpacity(0.2),
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
