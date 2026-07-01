import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../groups/presentation/screens/groups_list_screen.dart';
import '../../../expenses/presentation/screens/add_expense_screen.dart';
import '../../../ledger/presentation/screens/ledger_screen.dart';
import '../../../groups/presentation/providers/groups_provider.dart';
import '../../../activity/presentation/providers/activity_provider.dart';
import '../../../activity/presentation/providers/notification_provider.dart';
import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../../../core/providers/balance_provider.dart';
import '../../../../core/utils/mock_database.dart';
import '../../../activity/presentation/providers/notification_provider.dart';
import '../../../balances/presentation/providers/balance_providers.dart';

class _ActivityVisuals {
  final IconData icon;
  final Color color1;
  final Color color2;
  const _ActivityVisuals({required this.icon, required this.color1, required this.color2});
}

final thisMonthLedgerExpensesProvider = Provider<double>((ref) {
  final transactionsAsync = ref.watch(ledgerTransactionsProvider);
  final transactions = transactionsAsync.value ?? [];
  final now = DateTime.now();
  return transactions
      .where((t) => t.type.toLowerCase() == 'expense' && t.date.year == now.year && t.date.month == now.month)
      .fold(0.0, (sum, t) => sum + t.amount);
});

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final displayName = user?.displayName ?? 'SplitNester';

    final List<Widget> tabs = [
      _HomeTab(
        displayName: displayName,
        photoUrl: user?.photoUrl,
        onAvatarTap: () {
          setState(() {
            _currentIndex = 4;
          });
        },
        onSeeAllTap: () {
          setState(() {
            _currentIndex = 1;
          });
        },
      ),
      const GroupsListScreen(),
      const AddExpenseScreen(),
      const LedgerScreen(),
      _ProfileTab(user: user),
    ];

    return Scaffold(
      backgroundColor: (_currentIndex == 0 || _currentIndex == 4) ? const Color(0xFFF4F0FF) : context.colors.background,
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: tabs,
        ),
      ),
      bottomNavigationBar: _LuxuryBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

class _FloatingAnimationWrapper extends StatefulWidget {
  final Widget child;
  const _FloatingAnimationWrapper({required this.child});

  @override
  State<_FloatingAnimationWrapper> createState() => _FloatingAnimationWrapperState();
}

class _FloatingAnimationWrapperState extends State<_FloatingAnimationWrapper> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: widget.child,
        );
      },
    );
  }
}

class _FintechNestCard extends StatefulWidget {
  final String title;
  final String members;
  final String balance;
  final bool? isOwed;
  final IconData icon;
  final Color color;
  final String type;
  final String? groupImage;
  final VoidCallback? onTap;
  final bool isActive;

  const _FintechNestCard({
    required this.title,
    required this.members,
    required this.balance,
    required this.isOwed,
    required this.icon,
    required this.color,
    required this.type,
    this.groupImage,
    this.onTap,
    this.isActive = false,
  });

  @override
  State<_FintechNestCard> createState() => _FintechNestCardState();
}

class _FintechNestCardState extends State<_FintechNestCard> {
  bool _isHovered = false;
  double _scale = 1.0;

  String _getGroupImage(String type) {
    if (widget.groupImage != null && widget.groupImage!.isNotEmpty) {
      return widget.groupImage!;
    }
    final t = type.toLowerCase();
    if (t.contains('flat') || t.contains('roommate') || t.contains('apartment')) {
      return 'assets/images/Screenshot_2026-06-09_195719-removebg-preview.png';
    } else if (t.contains('family') || t.contains('house')) {
      return 'assets/images/Screenshot_2026-06-09_202834-removebg-preview.png';
    } else if (t.contains('travel') || t.contains('trip') || t.contains('plane')) {
      return 'assets/images/Screenshot_2026-06-09_202702-removebg-preview.png';
    } else if (t.contains('office') || t.contains('work')) {
      return 'assets/images/Screenshot_2026-06-09_203124-removebg-preview.png';
    } else if (t.contains('friend') || t.contains('college')) {
      return 'assets/images/Screenshot_2026-06-09_130728-removebg-preview.png';
    } else {
      return 'assets/images/Screenshot_2026-06-09_203447-removebg-preview.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() {
        _isHovered = true;
        _scale = 1.03;
      }),
      onExit: (_) => setState(() {
        _isHovered = false;
        _scale = 1.0;
      }),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: 175,
          transform: Matrix4.identity()..scale(_scale),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.isActive
                  ? const Color(0xFF7B61FF)
                  : (_isHovered ? widget.color.withValues(alpha: 0.5) : const Color(0xFFE5E7EB)),
              width: widget.isActive ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isActive
                    ? const Color(0xFF7B61FF).withValues(alpha: 0.15)
                    : (_isHovered ? widget.color.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.04)),
                blurRadius: widget.isActive ? 16 : (_isHovered ? 20 : 12),
                offset: Offset(0, widget.isActive ? 6 : (_isHovered ? 8 : 4)),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 3D Cover Illustration Area
              Container(
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(22),
                    topRight: Radius.circular(22),
                  ),
                  gradient: LinearGradient(
                    colors: [widget.color.withValues(alpha: 0.12), widget.color.withValues(alpha: 0.04)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Image.asset(
                        _getGroupImage(widget.type),
                        width: 70,
                        height: 70,
                        fit: BoxFit.contain,
                      ),
                    ),
                    if (widget.isActive)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7B61FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Active',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Details
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.members,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (widget.isOwed == null)
                      Text(
                        widget.balance,
                        style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      )
                    else ...[
                      Text(
                        widget.isOwed! ? 'Owed' : 'You owe',
                        style: TextStyle(
                          color: widget.isOwed! ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.balance,
                        style: TextStyle(
                          color: widget.isOwed! ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 1. HOME TAB
// ==========================================
class _HomeTab extends ConsumerWidget {
  final String displayName;
  final String? photoUrl;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onSeeAllTap;

  const _HomeTab({
    required this.displayName,
    this.photoUrl,
    this.onAvatarTap,
    this.onSeeAllTap,
  });

  String _getHumanizedTime(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  _ActivityVisuals _getActivityVisuals(String type) {
    switch (type) {
      case 'expense_added':
      case 'expense_updated':
      case 'expense_deleted':
        return const _ActivityVisuals(
          icon: Icons.group_rounded,
          color1: Color(0xFF7B61FF),
          color2: Color(0xFF9B8BFF),
        );
      case 'payment_received':
      case 'payment_request':
        return const _ActivityVisuals(
          icon: Icons.account_balance_wallet_rounded,
          color1: Color(0xFF2DC88A),
          color2: Color(0xFF56E0A8),
        );
      case 'member_joined':
      case 'member_removed':
        return const _ActivityVisuals(
          icon: Icons.person_add_rounded,
          color1: Color(0xFFF5A623),
          color2: Color(0xFFFFCC66),
        );
      case 'settlement_received':
      case 'settlement_paid':
      case 'settlement_completed':
        return const _ActivityVisuals(
          icon: Icons.check_circle_rounded,
          color1: Color(0xFF10B981),
          color2: Color(0xFF34D399),
        );
      case 'nest_created':
      case 'nest_updated':
        return const _ActivityVisuals(
          icon: Icons.add_home_work_rounded,
          color1: Color(0xFF7B61FF),
          color2: Color(0xFF9B8BFF),
        );
      default:
        return const _ActivityVisuals(
          icon: Icons.notifications_active_rounded,
          color1: Color(0xFF7B61FF),
          color2: Color(0xFF9B8BFF),
        );
    }
  }

  IconData _getGroupIcon(String type) {
    switch (type.toLowerCase()) {
      case 'flatmates':
        return Icons.apartment_rounded;
      case 'travel':
        return Icons.flight_takeoff_rounded;
      case 'office':
        return Icons.business_rounded;
      case 'family':
        return Icons.home_rounded;
      default:
        return Icons.widgets_rounded;
    }
  }

  Color _getGroupColor(String type) {
    switch (type.toLowerCase()) {
      case 'flatmates':
        return const Color(0xFF7B61FF);
      case 'travel':
        return const Color(0xFF6CA8FF);
      case 'office':
        return const Color(0xFFA78BFA);
      case 'family':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF7B61FF);
    }
  }

  Widget _buildMini3DIcon(String type, Color primaryColor) {
    IconData iconData = Icons.receipt_long_rounded;
    Color iconColor = const Color(0xFF7B61FF);
    
    if (type == 'expense_created') {
      iconData = Icons.receipt_long_rounded;
      iconColor = const Color(0xFF7B61FF);
    } else if (type == 'settlement_completed') {
      iconData = Icons.check_circle_rounded;
      iconColor = const Color(0xFF10B981);
    } else if (type.contains('travel')) {
      iconData = Icons.flight_takeoff_rounded;
      iconColor = const Color(0xFF6CA8FF);
    } else if (type.contains('house') || type.contains('home')) {
      iconData = Icons.home_rounded;
      iconColor = const Color(0xFFA78BFA);
    }

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [iconColor.withValues(alpha: 0.15), iconColor.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  Widget _buildBalanceCard({
    required String label,
    required String amount,
    required Color amountColor,
    required Color iconColor,
    required Color iconBgColor,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF6B7280),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  amount,
                  style: GoogleFonts.plusJakartaSans(
                    color: amountColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconBgColor,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniLedgerCol({
    required String label,
    required String amount,
    required Color amountColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: amountColor,
          ),
        ),
      ],
    );
  }



  Widget _buildFeatureRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.15)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: const Color(0xFF9CA3AF), size: 20),
        ],
      ),
    );
  }

  void _showHowItWorksSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(28, 16, 28, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'How SplitNest Works',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 24),
            _howItWorksStep(
              step: '1',
              title: 'Create a Nest',
              description: 'Start a group for your flat, trip, or any shared expense.',
              color: const Color(0xFF7B61FF),
            ),
            const SizedBox(height: 16),
            _howItWorksStep(
              step: '2',
              title: 'Add Expenses',
              description: 'Log bills and split them equally or by custom amounts.',
              color: const Color(0xFF10B981),
            ),
            const SizedBox(height: 16),
            _howItWorksStep(
              step: '3',
              title: 'Settle Up',
              description: 'See who owes who and clear debts with one tap.',
              color: const Color(0xFF6CA8FF),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B61FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: Text(
                  'Got It!',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _howItWorksStep({
    required String step,
    required String title,
    required String description,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              step,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeNestId = ref.watch(activeNestIdProvider);
    if (activeNestId != null) {
      ref.watch(groupDetailProvider(activeNestId));
    }

    // 1. Fetch live states using dedicated Firestore StreamProviders
    final groupsState = ref.watch(groupsListProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final ledgerSummaryAsync = ref.watch(ledgerSummaryProvider);
    final thisMonthSpend = ref.watch(thisMonthLedgerExpensesProvider);
    final notificationsAsync = ref.watch(notificationsStreamProvider);

    final themeBg = const Color(0xFFFFFDF8); // Clean soft ivory/white background
    final themePrimary = const Color(0xFF7B61FF);
    final themeSecondary = const Color(0xFF6CA8FF);
    final themeText = const Color(0xFF1A1A1A);
    final themeTextSecondary = const Color(0xFF6B7280);
    final themeTextMuted = const Color(0xFF9CA3AF);

    final fintechColors = AppColorsExtension(
      background: themeBg,
      card: Colors.white,
      primaryGold: themePrimary,
      softBronze: themeSecondary,
      accentBrown: const Color(0xFFE5E7EB),
      textWhite: themeText,
      textSecondary: themeTextSecondary,
      textMuted: themeTextMuted,
      error: const Color(0xFFEF4444),
      success: const Color(0xFF10B981),
    );

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: themeBg,
        primaryColor: themePrimary,
        cardColor: Colors.white,
        textTheme: Theme.of(context).textTheme.copyWith(
          displayLarge: TextStyle(color: themeText, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(color: themeText, fontWeight: FontWeight.bold),
          displaySmall: TextStyle(color: themeText, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(color: themeText, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(color: themeText, fontWeight: FontWeight.w600),
          titleSmall: TextStyle(color: themeTextSecondary),
          bodyLarge: TextStyle(color: themeText),
          bodyMedium: TextStyle(color: themeTextSecondary),
          bodySmall: TextStyle(color: themeTextMuted),
        ),
        extensions: [fintechColors],
      ),
      child: Builder(
        builder: (context) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Welcome Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.menu_rounded,
                            color: Color(0xFF7B61FF),
                            size: 28,
                          ),
                          onPressed: () {},
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hi, ${displayName.isNotEmpty ? displayName : 'Harshit'}! 👋',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: themeText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Welcome back',
                              style: TextStyle(
                                fontSize: 13,
                                color: themeTextSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Notification icon with real-time unread badge
                        GestureDetector(
                          onTap: () => context.push('/notifications'),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Colors.white, Color(0xFFF3F4F6)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF7B61FF).withValues(alpha: 0.12),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                    BoxShadow(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      blurRadius: 4,
                                      offset: const Offset(0, -2),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.notifications_active_rounded,
                                    color: Color(0xFF7B61FF),
                                    size: 22,
                                  ),
                                ),
                              ),
                              if (unreadCount > 0)
                                Positioned(
                                  right: -2,
                                  top: -2,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF7B61FF),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 1.5),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$unreadCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Profile Avatar
                        GestureDetector(
                          onTap: onAvatarTap,
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: Colors.white,
                                width: 3.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: photoUrl != null && photoUrl!.isNotEmpty
                                  ? Image.network(photoUrl!, fit: BoxFit.cover)
                                  : Center(
                                      child: Text(
                                        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'H',
                                        style: TextStyle(
                                          color: themePrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 2. Top Wallet Card (Real-time computed Net Balance)
                ledgerSummaryAsync.when(
                  data: (summary) {
                    final totalIncome = summary?.totalIncome ?? 0.0;
                    final totalExpense = summary?.totalExpense ?? 0.0;
                    final totalLend = summary?.totalLend ?? 0.0;
                    final totalBorrow = summary?.totalBorrow ?? 0.0;
                    final netBalance = (totalIncome + totalLend) - (totalExpense + totalBorrow);
                    final monthlyDiff = totalIncome - totalExpense;
                    final monthlyText = monthlyDiff >= 0 
                        ? '+₹${monthlyDiff.toStringAsFixed(0)} this month' 
                        : '-₹${monthlyDiff.abs().toStringAsFixed(0)} this month';

                    return Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.white, Color(0xFFEFEAFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7B61FF).withValues(alpha: 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(24.0),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SplitNest',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF7B61FF),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Split Smart, Live Easy',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: themeTextSecondary,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Total Net Balance',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: themeTextSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹${netBalance.toStringAsFixed(2)}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: themeText,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: monthlyDiff >= 0 ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      monthlyDiff >= 0 ? Icons.arrow_outward_rounded : Icons.south_west_rounded,
                                      color: monthlyDiff >= 0 ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      monthlyText,
                                      style: GoogleFonts.plusJakartaSans(
                                        color: monthlyDiff >= 0 ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            right: -10,
                            top: -10,
                            bottom: -10,
                            child: SizedBox(
                              width: 140,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Positioned(
                                    top: 10,
                                    left: 10,
                                    child: Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFFA78BFA).withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 20,
                                    right: 0,
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ),
                                  _FloatingAnimationWrapper(
                                    child: Image.asset(
                                      'assets/images/Screenshot 2026-06-08 174019.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const _DashboardCardSkeleton(height: 180),
                  error: (err, _) => _DashboardCardError(message: err.toString()),
                ),
                const SizedBox(height: 28),

                // 3. Balance Overview
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Balance Overview',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: themeText,
                        fontSize: 18,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/personal-ledger'),
                      child: Text(
                        'View Details >',
                        style: TextStyle(
                          color: themePrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ledgerSummaryAsync.when(
                  data: (summary) {
                    final willReceive = summary?.totalLend ?? 0.0;
                    final willPay = summary?.totalBorrow ?? 0.0;
                    final netBalance = willReceive - willPay;

                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 1.4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      children: [
                        _buildBalanceCard(
                          label: 'You Will Receive',
                          amount: '₹${willReceive.toStringAsFixed(0)}',
                          amountColor: const Color(0xFF10B981),
                          iconColor: const Color(0xFF10B981),
                          iconBgColor: const Color(0xFFE8F5E9),
                          icon: Icons.arrow_upward_rounded,
                        ),
                        _buildBalanceCard(
                          label: 'You Need To Pay',
                          amount: '₹${willPay.toStringAsFixed(0)}',
                          amountColor: const Color(0xFFEF4444),
                          iconColor: const Color(0xFFEF4444),
                          iconBgColor: const Color(0xFFFFEBEE),
                          icon: Icons.arrow_downward_rounded,
                        ),
                        _buildBalanceCard(
                          label: 'This Month Spend',
                          amount: '₹${thisMonthSpend.toStringAsFixed(0)}',
                          amountColor: const Color(0xFFF59E0B),
                          iconColor: const Color(0xFFF59E0B),
                          iconBgColor: const Color(0xFFFEF3C7),
                          icon: Icons.shopping_bag_rounded,
                        ),
                        _buildBalanceCard(
                          label: 'Net Balance',
                          amount: '₹${netBalance.abs().toStringAsFixed(0)}',
                          amountColor: const Color(0xFF7B61FF),
                          iconColor: const Color(0xFF7B61FF),
                          iconBgColor: const Color(0xFFEEF2FF),
                          icon: Icons.trending_up_rounded,
                        ),
                      ],
                    );
                  },
                  loading: () => GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 1.4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: List.generate(4, (_) => const _DashboardCardSkeleton(height: 100)),
                  ),
                  error: (err, _) => _DashboardCardError(message: err.toString()),
                ),
                const SizedBox(height: 28),

                // 4. Current Financial Cycle Card
                _GlobalFinancialCycleCard(
                  onViewDetails: () => context.push('/personal-ledger'),
                ),
                const SizedBox(height: 28),

                // 5. Quick Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: themeText,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _QuickActionButton(
                        imagePath: 'assets/images/3d_wallet.png',
                        label: 'Add Expense',
                        onTap: () => context.push('/expenses/add'),
                      ),
                      const SizedBox(width: 12),
                      _QuickActionButton(
                        imagePath: 'assets/images/3d_people.png',
                        label: 'Create Nest',
                        onTap: () => context.push('/groups/create'),
                      ),
                      const SizedBox(width: 12),
                      _QuickActionButton(
                        imagePath: 'assets/images/3d_blue_wallet.png',
                        label: 'Settle Up',
                        onTap: () => context.push('/settlement'),
                      ),
                      const SizedBox(width: 12),
                      _QuickActionButton(
                        imagePath: 'assets/images/3d_scan.png',
                        label: 'Scan Slip',
                        onTap: () => context.push('/scan-receipt'),
                      ),
                      const SizedBox(width: 12),
                      _QuickActionButton(
                        imagePath: 'assets/images/3d_calendar.png',
                        label: 'Calendar',
                        onTap: () => context.push('/calendar'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 6. Active Nests
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Active Nests',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: themeText,
                        fontSize: 18,
                      ),
                    ),
                    TextButton(
                      onPressed: onSeeAllTap,
                      child: Text(
                        'See All',
                        style: TextStyle(color: themePrimary, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 210,
                  child: groupsState.isLoading
                      ? ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: 3,
                          itemBuilder: (_, __) => const Padding(
                            padding: EdgeInsets.only(right: 16.0),
                            child: _DashboardCardSkeleton(width: 175, height: 210),
                          ),
                        )
                      : groupsState.groups.isEmpty
                          ? Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.group_add_rounded, size: 48, color: Color(0xFF7B61FF)),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No active nests',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.bold,
                                      color: themeText,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Create a nest to start splitting expenses!',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: themeTextSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: () => context.push('/groups/create'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF7B61FF),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text('Create Your First Nest', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            )
                          : () {
                              final sortedGroups = [...groupsState.groups];
                              sortedGroups.sort((a, b) => (b.lastMessageTime ?? b.createdAt).compareTo(a.lastMessageTime ?? a.createdAt));

                              return ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: sortedGroups.length,
                                itemBuilder: (context, index) {
                                  final group = sortedGroups[index];
                                  return Consumer(
                                    builder: (context, ref, _) {
                                      final summaryAsync = ref.watch(balanceSummaryProvider(group.id));
                                      final summary = summaryAsync.value ?? BalanceSummary.empty;
                                      final isOwed = summary.net > 0.01 
                                          ? true 
                                          : (summary.net < -0.01 ? false : null);
                                      final balanceText = summary.net != 0 
                                          ? '₹${summary.net.abs().toStringAsFixed(2)}' 
                                          : 'Settled';

                                      return Padding(
                                        padding: const EdgeInsets.only(right: 16.0, bottom: 4.0),
                                        child: _FintechNestCard(
                                          title: group.name,
                                          members: '${group.membersCount} members',
                                          balance: balanceText,
                                          isOwed: isOwed,
                                          icon: _getGroupIcon(group.type),
                                          color: _getGroupColor(group.type),
                                          type: group.type,
                                          groupImage: group.groupImage,
                                          onTap: () => context.push('/groups/${group.id}'),
                                          isActive: group.id == activeNestId,
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            }(),
                ),
                const SizedBox(height: 32),

                // 7. Personal Ledger Summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Personal Ledger Summary',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: themeText,
                          fontSize: 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/personal-ledger'),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View All',
                            style: TextStyle(
                              color: themePrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: themePrimary,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ledgerSummaryAsync.when(
                  data: (summary) {
                    final income = summary?.totalIncome ?? 0.0;
                    final expense = summary?.totalExpense ?? 0.0;
                    final lend = summary?.totalLend ?? 0.0;
                    final borrow = summary?.totalBorrow ?? 0.0;
                    final net = (income + lend) - (expense + borrow);

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                          width: 1.0,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => context.push('/personal-ledger'),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFFE84393), Color(0xFFFF88BB)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        padding: const EdgeInsets.all(6.0),
                                        child: Image.asset(
                                          'assets/images/3d_coins.png',
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Flexible(
                                              child: _buildMiniLedgerCol(
                                                label: 'Income',
                                                amount: '₹${income.toStringAsFixed(0)}',
                                                amountColor: const Color(0xFF10B981),
                                              ),
                                            ),
                                            Flexible(
                                              child: _buildMiniLedgerCol(
                                                label: 'Expense',
                                                amount: '₹${expense.toStringAsFixed(0)}',
                                                amountColor: const Color(0xFFEF4444),
                                              ),
                                            ),
                                            Flexible(
                                              child: _buildMiniLedgerCol(
                                                label: 'Net Bal',
                                                amount: '₹${net.toStringAsFixed(0)}',
                                                amountColor: const Color(0xFF7B61FF),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  color: const Color(0xFFF9FAFB),
                                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'View Personal Ledger',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: themePrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        color: themePrimary,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  loading: () => const _DashboardCardSkeleton(height: 120),
                  error: (err, _) => _DashboardCardError(message: err.toString()),
                ),
                const SizedBox(height: 32),

                // 8. Recent Activity Section (Requirement 8)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: themeText,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                notificationsAsync.when(
                  data: (notifs) {
                    final recentList = notifs.take(5).toList();
                    if (recentList.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Center(
                          child: Text(
                            'No recent activities',
                            style: TextStyle(color: themeTextSecondary),
                          ),
                        ),
                      );
                    }
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: recentList.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
                        itemBuilder: (context, index) {
                          final activity = recentList[index];
                          final visuals = _getActivityVisuals(activity.type);
                          return ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [visuals.color1.withValues(alpha: 0.15), visuals.color2.withValues(alpha: 0.05)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Icon(visuals.icon, color: visuals.color1, size: 18),
                            ),
                            title: Text(
                              activity.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            subtitle: Text(
                              activity.description,
                              style: TextStyle(color: themeTextSecondary, fontSize: 11),
                            ),
                            trailing: Text(
                              _getHumanizedTime(activity.timestamp),
                              style: TextStyle(color: themeTextMuted, fontSize: 10),
                            ),
                            onTap: () {
                              if (activity.type.startsWith('expense') && activity.relatedItemId != null) {
                                context.push('/expenses/detail/${activity.relatedItemId}?groupId=${activity.groupId}');
                              } else if (activity.type.startsWith('settlement') && activity.relatedItemId != null) {
                                context.push('/settlement/detail/${activity.relatedItemId}');
                              } else if (activity.groupId != null) {
                                context.push('/groups/${activity.groupId}');
                              } else if (activity.relatedItemId != null) {
                                context.push('/personal-ledger/detail/${activity.relatedItemId}');
                              } else {
                                context.push('/personal-ledger');
                              }
                            },
                          );
                        },
                      ),
                    );
                  },
                  loading: () => Column(
                    children: List.generate(3, (_) => const Padding(
                      padding: EdgeInsets.only(bottom: 12.0),
                      child: _DashboardCardSkeleton(height: 60),
                    )),
                  ),
                  error: (err, _) => _DashboardCardError(message: err.toString()),
                ),
              ],
            ),
          );
        }
      ),
    );
  }
}


// ==========================================
// 5. PROFILE TAB
// ==========================================
// 5. PROFILE TAB
// ==========================================
class _ProfileTab extends ConsumerStatefulWidget {
  final dynamic user;
  const _ProfileTab({required this.user});

  @override
  ConsumerState<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<_ProfileTab> {
  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: context.colors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: context.colors.primaryGold.withOpacity(0.3), width: 1),
          ),
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.logout_rounded, color: context.colors.primaryGold, size: 48),
                SizedBox(height: 16),
                Text(
                  'Sign Out',
                  style: TextStyle(color: context.colors.textWhite, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Are you sure you want to sign out of your account?',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.colors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Cancel', style: TextStyle(color: context.colors.textWhite, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ref.read(authNotifierProvider.notifier).signOut();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colors.primaryGold,
                          foregroundColor: context.colors.background,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
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
    final displayName = widget.user?.displayName ?? 'SplitNester';
    final email = widget.user?.email ?? 'contact@splitnester.app';
    final phone = widget.user?.phone ?? '+91 98765 43210';

    // Watch providers for live statistics
    final groupsState = ref.watch(groupsListProvider);
    final ledgerTransactionsAsync = ref.watch(ledgerTransactionsProvider);
    final ledgerTransactions = ledgerTransactionsAsync.value ?? [];

    final totalNests = groupsState.groups.length;
    final totalTransactions = ledgerTransactions.length;
    final totalSpent = ledgerTransactions
        .where((t) => t.type.toLowerCase() == 'expense' || t.type.toLowerCase() == 'lend')
        .fold(0.0, (sum, t) => sum + t.amount);
    final activeMembers = groupsState.groups.fold(0, (sum, g) => sum + g.membersCount);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Profile Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Manage your account',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              // Settings gear icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Material(
                    color: Colors.transparent,
                    child: IconButton(
                      icon: const Icon(
                        Icons.settings_outlined,
                        color: Color(0xFF7B61FF),
                        size: 22,
                      ),
                      onPressed: () => context.push('/profile/edit'),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 2. Profile Detail Hero Card (Welcome Card) - matches reference design exactly
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7B61FF).withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 20, 0, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar with lavender filled circle background + edit badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFE8E0FF),
                      ),
                      child: ClipOval(
                        child: widget.user?.photoUrl != null && widget.user!.photoUrl!.isNotEmpty
                            ? Image.network(widget.user!.photoUrl!, fit: BoxFit.cover)
                            : Center(
                                child: Text(
                                  displayName.isNotEmpty ? displayName[0].toUpperCase() : 'S',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFF7B61FF),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 36,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => context.push('/profile/edit'),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: const Color(0xFF7B61FF),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                // Middle text details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi, $displayName! 👋',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1A1A1A),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Welcome back to SplitNest',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Email Pill
                      Row(
                        children: [
                          const Icon(
                            Icons.mail_outline_rounded,
                            color: Color(0xFF7B61FF),
                            size: 13,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              email,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF4F46E5),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Phone row
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_iphone_rounded,
                            color: Color(0xFF7B61FF),
                            size: 13,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            phone,
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF4F46E5),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Floating 3D wallet - large
                _FloatingAnimationWrapper(
                  child: Image.asset(
                    'assets/images/3d_profile_wallet.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // 3. Stats Row Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatsItem(
                  imagePath: 'assets/images/3d_profile_nests.png',
                  value: totalNests.toString(),
                  label: 'Total Nests',
                  iconColor: const Color(0xFF7B61FF),
                  bgColor: const Color(0xFFF3E8FF),
                ),
                _buildStatsItem(
                  imagePath: 'assets/images/3d_profile_txs.png',
                  value: totalTransactions.toString(),
                  label: 'Transactions',
                  iconColor: const Color(0xFF10B981),
                  bgColor: const Color(0xFFDCFCE7),
                ),
                _buildStatsItem(
                  imagePath: 'assets/images/3d_profile_spend.png',
                  value: '₹${totalSpent.toStringAsFixed(0)}',
                  label: 'Total Spent',
                  iconColor: const Color(0xFF6CA8FF),
                  bgColor: const Color(0xFFEFF6FF),
                ),
                _buildStatsItem(
                  icon: Icons.people_alt_rounded,
                  value: activeMembers.toString(),
                  label: 'Members',
                  iconColor: const Color(0xFFEF4444),
                  bgColor: const Color(0xFFFEE2E2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // 4. Settings Card Options List
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildMockupSettingsItem(
                  context,
                  imagePath: 'assets/images/icon_profile_info.png',
                  iconBg: const Color(0xFFE0F2FF),
                  iconColor: const Color(0xFF0284C7),
                  title: 'Personal Information',
                  subtitle: 'Update your personal details',
                  customRoute: '/profile/edit',
                ),
                const Divider(color: Color(0xFFF3F4F6), height: 1, indent: 76),
                _buildMockupSettingsItem(
                  context,
                  imagePath: 'assets/images/icon_security.png',
                  iconBg: const Color(0xFFF3E8FF),
                  iconColor: const Color(0xFF7B61FF),
                  title: 'Security',
                  subtitle: 'Change password and security settings',
                  customRoute: '/profile/security',
                ),
                const Divider(color: Color(0xFFF3F4F6), height: 1, indent: 76),
                _buildMockupSettingsItem(
                  context,
                  imagePath: 'assets/images/icon_notifications.png',
                  iconBg: const Color(0xFFDCFCE7),
                  iconColor: const Color(0xFF16A34A),
                  title: 'Notifications',
                  subtitle: 'Manage your notification preferences',
                  customRoute: '/profile/push-alerts',
                ),
                const Divider(color: Color(0xFFF3F4F6), height: 1, indent: 76),
                _buildMockupSettingsItem(
                  context,
                  imagePath: 'assets/images/icon_payment.png',
                  iconBg: const Color(0xFFFEF3C7),
                  iconColor: const Color(0xFFD97706),
                  title: 'Payment Methods',
                  subtitle: 'Manage your cards and bank accounts',
                  customRoute: '/profile/payment-methods',
                ),
                const Divider(color: Color(0xFFF3F4F6), height: 1, indent: 76),
                _buildMockupSettingsItem(
                  context,
                  imagePath: 'assets/images/icon_support.png',
                  iconBg: const Color(0xFFFCE7F3),
                  iconColor: const Color(0xFFDB2777),
                  title: 'Help & Support',
                  subtitle: 'Get help and contact support',
                  customRoute: '/profile/help-support',
                ),
                const Divider(color: Color(0xFFF3F4F6), height: 1, indent: 76),
                _buildMockupSettingsItem(
                  context,
                  imagePath: 'assets/images/icon_about.png',
                  iconBg: const Color(0xFFFCE7F3),
                  iconColor: const Color(0xFFDB2777),
                  title: 'About SplitNest',
                  subtitle: 'App information and terms',
                  customRoute: '/profile/about',
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // 5. Invite Friends Banner Card
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF7B61FF),
                  Color(0xFF9B85FF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7B61FF).withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.only(left: 20, top: 16, bottom: 16, right: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.22),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '🎁  Earn Rewards',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Invite Friends &\nEarn Together!',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Share SplitNest and get rewards\nfor every friend who joins.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.8),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        icon: const Icon(
                          Icons.share_rounded,
                          size: 14,
                          color: Color(0xFF7B61FF),
                        ),
                        label: Text(
                          'Invite Now',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: const Color(0xFF7B61FF),
                          ),
                        ),
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF7B61FF),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _FloatingAnimationWrapper(
                  child: Image.asset(
                    'assets/images/3d_invite_gift.png',
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    isAntiAlias: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // 6. Sign Out Button List Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _buildMockupSettingsItem(
              context,
              imagePath: 'assets/images/icon_signout.png',
              iconBg: const Color(0xFFFEE2E2),
              iconColor: const Color(0xFFEF4444),
              title: 'Sign Out',
              subtitle: 'Sign out from your account',
              onTapOverride: () => _showSignOutDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsItem({
    String? imagePath,
    IconData? icon,
    required String value,
    required String label,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: iconColor.withOpacity(0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: imagePath != null
                  ? Image.asset(
                      imagePath,
                      width: 38,
                      height: 38,
                      fit: BoxFit.contain,
                    )
                  : Icon(
                      icon,
                      color: iconColor,
                      size: 28,
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockupSettingsItem(
    BuildContext context, {
    IconData? icon,
    String? imagePath,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? customRoute,
    VoidCallback? onTapOverride,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTapOverride ?? () => context.push(customRoute ?? '/profile/settings'),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              imagePath != null
                  ? SizedBox(
                      width: 52,
                      height: 52,
                      child: Image.asset(
                        imagePath,
                        width: 52,
                        height: 52,
                        fit: BoxFit.contain,
                      ),
                    )
                  : Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: iconBg,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: iconColor.withOpacity(0.18),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          icon,
                          color: iconColor,
                          size: 24,
                        ),
                      ),
                    ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF9CA3AF),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatefulWidget {
  final IconData? icon;
  final String? imagePath;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    this.icon,
    this.imagePath,
    required this.label,
    required this.onTap,
  });

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.90).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: context.colors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: context.colors.accentBrown,
                width: 1,
              ),
              // Removed boxShadow
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  splashColor: context.colors.primaryGold.withOpacity(0.3),
                  highlightColor: context.colors.primaryGold.withOpacity(0.1),
                  onHighlightChanged: (isHighlighted) {
                    if (isHighlighted) {
                      _controller.forward();
                    } else {
                      _controller.reverse();
                    }
                  },
                  onTap: () {
                    // Small delay to let the ripple complete slightly before navigation
                    Future.delayed(const Duration(milliseconds: 150), () {
                      if (mounted) {
                        widget.onTap();
                      }
                    });
                  },
                  child: Center(
                    child: widget.imagePath != null
                        ? Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Image.asset(
                              widget.imagePath!,
                              fit: BoxFit.contain,
                            ),
                          )
                        : Icon(
                            widget.icon ?? Icons.help_outline,
                            color: context.colors.primaryGold,
                            size: 26,
                          ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            widget.label,
            style: textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}




class _LuxuryBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _LuxuryBottomNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': Icons.home_outlined, 'activeIcon': Icons.home_filled, 'label': 'Home'},
      {'icon': Icons.group_outlined, 'activeIcon': Icons.group_rounded, 'label': 'Groups'},
      {'icon': Icons.add_circle_outline_rounded, 'activeIcon': Icons.add_circle_rounded, 'label': 'Add'},
      {
        'imagePath': 'assets/images/3d_ledger.png',
        'icon': Icons.menu_book_rounded,
        'activeIcon': Icons.menu_book_rounded,
        'label': 'Ledger'
      },
      {'icon': Icons.person_outline_rounded, 'activeIcon': Icons.person_rounded, 'label': 'Profile'},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFFEDE9FA),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7B61FF).withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
            BoxShadow(
              color: const Color(0xFF5A3FD6).withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final isSelected = currentIndex == index;
              final item = items[index];

              return GestureDetector(
                onTap: () => onTap(index),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSelected ? 14 : 10,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFF7B61FF), Color(0xFF6CA8FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF7B61FF).withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                        child: item.containsKey('imagePath')
                            ? Opacity(
                                key: ValueKey(isSelected),
                                opacity: isSelected ? 1.0 : 0.6,
                                child: Image.asset(
                                  item['imagePath'] as String,
                                  width: 20,
                                  height: 20,
                                  fit: BoxFit.contain,
                                  color: isSelected ? Colors.white : null,
                                  colorBlendMode: isSelected ? BlendMode.srcIn : null,
                                ),
                              )
                            : Icon(
                                isSelected ? item['activeIcon'] as IconData : item['icon'] as IconData,
                                key: ValueKey(isSelected),
                                color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
                                size: 20,
                              ),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.centerLeft,
                        child: isSelected 
                          ? Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                item['label'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Global Financial Cycle Card — aggregates ALL nests
// ─────────────────────────────────────────────────────────────────────────────
class _GlobalFinancialCycleCard extends ConsumerWidget {
  final VoidCallback? onViewDetails;

  const _GlobalFinancialCycleCard({this.onViewDetails});

  String _fmtAmt(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(v % 1000 == 0 ? 0 : 1)}K';
    return '₹${v.toInt()}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(globalCycleStatsProvider);
    final pct = stats.settledPercent;
    final pctInt = (pct * 100).round();

    final fmt = DateFormat('d MMM');
    final dateRange = (stats.earliestCycleStart != null && stats.latestCycleEnd != null)
        ? '${fmt.format(stats.earliestCycleStart!)} → ${fmt.format(stats.latestCycleEnd!)}'
        : 'No active cycle';

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF5B2FD4),
            Color(0xFF8B5CF6),
            Color(0xFF6D28D9),
          ],
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.50),
            blurRadius: 36,
            spreadRadius: 0,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: const Color(0xFF4C1D95).withValues(alpha: 0.30),
            blurRadius: 64,
            spreadRadius: -10,
            offset: const Offset(0, 28),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Decorative orbs ─────────────────────────────────────────────
            Positioned(
              top: -40,
              right: -20,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              left: -15,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),

            // ── Main content ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top row: badge + illustration ───────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Live badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF86EFAC),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'CURRENT FINANCIAL CYCLE',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Date range
                            Text(
                              dateRange,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Across N nests
                            Text(
                              'Across ${stats.activeNestCount} Active ${stats.activeNestCount == 1 ? 'Nest' : 'Nests'}',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 3D calendar illustration + ring overlay
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Glow halo
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFA78BFA)
                                        .withValues(alpha: 0.35),
                                    blurRadius: 24,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            // Progress ring (background track)
                            SizedBox(
                              width: 90,
                              height: 90,
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: pct),
                                duration:
                                    const Duration(milliseconds: 1400),
                                curve: Curves.easeOutCubic,
                                builder: (ctx, v, _) => CustomPaint(
                                  painter: _DashArcPainter(progress: v),
                                ),
                              ),
                            ),
                            // Illustration in the centre
                            ClipOval(
                              child: Container(
                                width: 62,
                                height: 62,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      Colors.white.withValues(alpha: 0.12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Image.asset(
                                    'assets/images/3d_pie_chart.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                            // Pct label at bottom-right
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF86EFAC),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$pctInt%',
                                  style: const TextStyle(
                                    color: Color(0xFF14532D),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Divider ─────────────────────────────────────────────
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.22),
                        Colors.transparent,
                      ]),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ── Three stat tiles ────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _dashStat(
                        icon: Icons.receipt_long_rounded,
                        iconColor: const Color(0xFFC4B5FD),
                        label: 'Expenses',
                        value: _fmtAmt(stats.totalExpenses),
                      ),
                      Container(
                          width: 1,
                          height: 42,
                          color: Colors.white.withValues(alpha: 0.14)),
                      _dashStat(
                        icon: Icons.check_circle_rounded,
                        iconColor: const Color(0xFF86EFAC),
                        label: 'Settled',
                        value: _fmtAmt(stats.totalSettled),
                      ),
                      Container(
                          width: 1,
                          height: 42,
                          color: Colors.white.withValues(alpha: 0.14)),
                      _dashStat(
                        icon: Icons.hourglass_top_rounded,
                        iconColor: const Color(0xFFFBB6CE),
                        label: 'Pending',
                        value: _fmtAmt(stats.totalPending),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // ── Progress bar ────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Settlement Progress',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$pctInt% settled',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white.withValues(alpha: 0.60),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _DashProgressBar(progress: pct),

                  const SizedBox(height: 18),

                  // ── View Details button ─────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: onViewDetails,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'View Details',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dashStat({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 17),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white.withValues(alpha: 0.60),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─── Arc painter for dashboard ring ──────────────────────────────────────────
class _DashArcPainter extends CustomPainter {
  final double progress;
  _DashArcPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = (size.width - 10) / 2;

    // Track
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.14)
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    if (progress <= 0) return;

    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..shader = const SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: 3 * math.pi / 2,
          colors: [Color(0xFF86EFAC), Color(0xFF34D399)],
        ).createShader(rect)
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_DashArcPainter o) => o.progress != progress;
}

// ─── Animated progress bar for dashboard ─────────────────────────────────────
class _DashProgressBar extends StatelessWidget {
  final double progress;
  const _DashProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: progress),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => LayoutBuilder(
        builder: (_, constraints) => Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Stack(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 80),
              width: constraints.maxWidth * v.clamp(0.0, 1.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF86EFAC), Color(0xFF34D399)]),
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF86EFAC).withValues(alpha: 0.55),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _DashboardCardSkeleton extends StatelessWidget {
  final double? width;
  final double height;

  const _DashboardCardSkeleton({this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
        ),
      ),
    );
  }
}

class _DashboardCardError extends StatelessWidget {
  final String message;

  const _DashboardCardError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Error: $message',
              style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
