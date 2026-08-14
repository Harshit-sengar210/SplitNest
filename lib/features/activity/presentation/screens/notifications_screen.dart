import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/app_notification.dart';
import '../providers/notification_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Theme constants
// ─────────────────────────────────────────────────────────────────────────────
const _kPrimary   = Color(0xFF7B61FF);
const _kSecondary = Color(0xFF9B8BFF);
const _kBg        = Color(0xFFF5F4FF);
const _kCard      = Color(0xFFFFFFFF);
const _kText      = Color(0xFF1A1A2E);
const _kTextSub   = Color(0xFF6B7280);
const _kTextMuted = Color(0xFF9CA3AF);
const _kUnread    = Color(0xFF7B61FF);

class _NotificationVisuals {
  final IconData iconData;
  final Color iconBgColor1;
  final Color iconBgColor2;
  final String imagePath;
  const _NotificationVisuals({
    required this.iconData,
    required this.iconBgColor1,
    required this.iconBgColor2,
    required this.imagePath,
  });
}

_NotificationVisuals _getNotificationVisuals(String type) {
  switch (type) {
    case 'expense_added':
    case 'expense_updated':
    case 'expense_deleted':
      return const _NotificationVisuals(
        iconData: Icons.group_rounded,
        iconBgColor1: Color(0xFF7B61FF),
        iconBgColor2: Color(0xFF9B8BFF),
        imagePath: 'assets/icons/icon_people_3d.png',
      );
    case 'payment_received':
      return const _NotificationVisuals(
        iconData: Icons.account_balance_wallet_rounded,
        iconBgColor1: Color(0xFF2DC88A),
        iconBgColor2: Color(0xFF56E0A8),
        imagePath: 'assets/icons/icon_wallet_3d.png',
      );
    case 'payment_request':
      return const _NotificationVisuals(
        iconData: Icons.card_giftcard_rounded,
        iconBgColor1: Color(0xFFE84393),
        iconBgColor2: Color(0xFFFF88BB),
        imagePath: 'assets/icons/icon_money_3d.png',
      );
    case 'member_joined':
    case 'member_removed':
      return const _NotificationVisuals(
        iconData: Icons.person_add_rounded,
        iconBgColor1: Color(0xFFF5A623),
        iconBgColor2: Color(0xFFFFCC66),
        imagePath: 'assets/icons/icon_people_3d.png',
      );
    case 'settlement_received':
    case 'settlement_paid':
      return const _NotificationVisuals(
        iconData: Icons.flight_rounded,
        iconBgColor1: Color(0xFF4A90E2),
        iconBgColor2: Color(0xFF74B3FF),
        imagePath: 'assets/icons/icon_airplane_3d.png',
      );
    case 'nest_created':
    case 'nest_updated':
      return const _NotificationVisuals(
        iconData: Icons.add_home_work_rounded,
        iconBgColor1: Color(0xFF7B61FF),
        iconBgColor2: Color(0xFF9B8BFF),
        imagePath: 'assets/icons/icon_people_3d.png',
      );
    case 'chat_message':
      return const _NotificationVisuals(
        iconData: Icons.chat_bubble_outline_rounded,
        iconBgColor1: Color(0xFF7B61FF),
        iconBgColor2: Color(0xFF9B8BFF),
        imagePath: 'assets/icons/icon_bell_3d.png',
      );
    case 'receipt_scanned':
      return const _NotificationVisuals(
        iconData: Icons.document_scanner_rounded,
        iconBgColor1: Color(0xFF2DC88A),
        iconBgColor2: Color(0xFF56E0A8),
        imagePath: 'assets/icons/icon_wallet_3d.png',
      );
    case 'reminder':
      return const _NotificationVisuals(
        iconData: Icons.alarm_rounded,
        iconBgColor1: Color(0xFFE84393),
        iconBgColor2: Color(0xFFFF88BB),
        imagePath: 'assets/icons/icon_bell_3d.png',
      );
    case 'system_update':
    default:
      return const _NotificationVisuals(
        iconData: Icons.campaign_rounded,
        iconBgColor1: Color(0xFF7B61FF),
        iconBgColor2: Color(0xFF9B8BFF),
        imagePath: 'assets/icons/icon_bell_3d.png',
      );
  }
}

String _getNotificationCategory(String type) {
  switch (type) {
    case 'expense_added':
    case 'expense_updated':
    case 'expense_deleted':
    case 'settlement_received':
    case 'settlement_paid':
    case 'nest_created':
    case 'nest_updated':
    case 'chat_message':
      return 'activity';
    case 'payment_request':
    case 'payment_received':
      return 'payments';
    case 'member_joined':
    case 'member_removed':
      return 'invites';
    case 'system_update':
    case 'receipt_scanned':
    case 'reminder':
    default:
      return 'updates';
  }
}

String _getNotificationRoute(AppNotification n) {
  switch (n.type) {
    case 'expense_added':
    case 'expense_updated':
    case 'expense_deleted':
      final id = n.relatedItemId ?? '1';
      final title = Uri.encodeComponent(n.title);
      final desc = Uri.encodeComponent(n.description.replaceAll('\n', ' '));
      final groupParam = n.groupId != null ? '&groupId=${n.groupId}' : '';
      return '/expenses/detail/$id?title=$title&amount=$desc$groupParam';
    case 'settlement_received':
    case 'settlement_paid':
      final id = n.relatedItemId ?? '1';
      final title = Uri.encodeComponent(n.title);
      final desc = Uri.encodeComponent(n.description.replaceAll('\n', ' '));
      final groupParam = n.groupId != null ? '&groupId=${n.groupId}' : '';
      return '/settlement/detail/$id?title=$title&amount=$desc$groupParam';
    case 'nest_created':
    case 'nest_updated':
      final id = n.groupId ?? 'nest_1';
      return '/groups/$id';
    case 'member_joined':
    case 'member_removed':
      if (n.relatedItemId != null) {
        return '/members/detail/${n.relatedItemId}';
      }
      final id = n.groupId ?? 'nest_1';
      return '/groups/$id';
    case 'chat_message':
      final id = n.groupId ?? 'nest_1';
      return '/groups/$id';
    case 'receipt_scanned':
      return '/expenses/add';
    case 'payment_request':
    case 'payment_received':
      final id = n.relatedItemId ?? '1';
      return '/personal-ledger/detail/$id';
    case 'reminder':
      final id = n.groupId ?? 'nest_1';
      return '/groups/$id';
    case 'system_update':
    default:
      return '/profile/about';
  }
}

String _getNotificationSection(DateTime timestamp) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final compareDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

  if (compareDate == today) {
    return 'Today';
  } else if (compareDate == yesterday) {
    return 'Yesterday';
  } else {
    return 'Earlier';
  }
}

String _formatNotificationTime(DateTime timestamp) {
  final now = DateTime.now();
  final difference = now.difference(timestamp);

  if (difference.inMinutes < 1) {
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

class _FilterTab {
  final String label;
  final IconData icon;
  final Color color;
  const _FilterTab({required this.label, required this.icon, required this.color});
}

const _filterTabs = [
  _FilterTab(label: 'All', icon: Icons.grid_view_rounded, color: Color(0xFF7B61FF)),
  _FilterTab(label: 'Activity', icon: Icons.show_chart_rounded, color: Color(0xFF7B61FF)),
  _FilterTab(label: 'Payments', icon: Icons.account_balance_wallet_rounded, color: Color(0xFF2DC88A)),
  _FilterTab(label: 'Invites', icon: Icons.person_add_rounded, color: Color(0xFFF5A623)),
  _FilterTab(label: 'Updates', icon: Icons.campaign_rounded, color: Color(0xFF4A90E2)),
];

// ─────────────────────────────────────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────────────────────────────────────
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with TickerProviderStateMixin {
  late AnimationController _heroFloatController;
  late AnimationController _listController;
  late List<Animation<double>> _cardAnimations;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();

    _heroFloatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    final total = ref.read(notificationsProvider).length + 10;
    _cardAnimations = List.generate(total, (i) {
      final start = (i * 0.07).clamp(0.0, 0.9);
      final end   = (start + 0.4).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _listController,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    });

    _listController.forward();
  }

  @override
  void dispose() {
    _heroFloatController.dispose();
    _listController.dispose();
    super.dispose();
  }

  List<AppNotification> get _filteredNotifications {
    final list = ref.watch(notificationsProvider);
    if (_selectedTab == 0) return list;
    final categories = ['all', 'activity', 'payments', 'invites', 'updates'];
    final cat = categories[_selectedTab];
    return list.where((n) => _getNotificationCategory(n.type) == cat).toList();
  }

  @override
  Widget build(BuildContext context) {
    final sections = ['Today', 'Yesterday', 'Earlier'];

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildHero()),
            SliverToBoxAdapter(child: _buildFilterTabs()),
            ..._buildSections(sections),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _kCard,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _kPrimary.withOpacity(0.15),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: _kPrimary,
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return _FadeSlideIn(
      animation: _cardAnimations[0],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildBackButton(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notifications',
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: _kText,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Stay updated with your groups',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: _kTextSub,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            _buildFilterButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withOpacity(0.15),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [_kPrimary, _kSecondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Icon(Icons.filter_list_rounded, size: 22, color: Colors.white),
        ),
      ),
    );
  }

  // ── Hero ──────────────────────────────────────────────────────────────────
  Widget _buildHero() {
    final list = ref.watch(notificationsProvider);
    final unreadCount = list.where((n) => !n.isRead).length;

    return _FadeSlideIn(
      animation: _cardAnimations[1],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6B4EFF), Color(0xFF8B6FFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6B4EFF).withOpacity(0.45),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Sparkle decorations ✦
              Positioned(
                top: 18, left: 18,
                child: _SparkleIcon(controller: _heroFloatController, delay: 0.0, size: 14),
              ),
              Positioned(
                top: 52, left: 42,
                child: _SparkleIcon(controller: _heroFloatController, delay: 0.25, size: 9),
              ),
              Positioned(
                bottom: 24, left: 24,
                child: _SparkleIcon(controller: _heroFloatController, delay: 0.5, size: 11),
              ),
              Positioned(
                top: 22, right: 90,
                child: _SparkleIcon(controller: _heroFloatController, delay: 0.15, size: 10),
              ),
              Positioned(
                bottom: 30, right: 95,
                child: _SparkleIcon(controller: _heroFloatController, delay: 0.4, size: 8),
              ),

              // Text content
              Positioned(
                left: 22, top: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unreadCount == 0 ? 'You have no new' : 'You have $unreadCount new',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      'notifications',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Tap to view new updates',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.82),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // 3D Bell hero image
              Positioned(
                right: -6,
                top: -20,
                child: AnimatedBuilder(
                  animation: _heroFloatController,
                  builder: (_, child) {
                    final offset = math.sin(_heroFloatController.value * math.pi) * 8;
                    return Transform.translate(
                      offset: Offset(0, -offset),
                      child: child,
                    );
                  },
                  child: _Built3DBell(
                    controller: _heroFloatController,
                  ),
                ),
              ),

              // Unread badge
              if (unreadCount > 0)
                Positioned(
                  right: 82, top: 8,
                  child: AnimatedBuilder(
                    animation: _heroFloatController,
                    builder: (_, child) {
                      final offset = math.sin(_heroFloatController.value * math.pi) * 6;
                      return Transform.translate(
                        offset: Offset(0, -offset),
                        child: child,
                      );
                    },
                    child: Container(
                      width: 30, height: 30,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5A623),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFFF8C00),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$unreadCount',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Filter Tabs ────────────────────────────────────────────────────────────
  Widget _buildFilterTabs() {
    return _FadeSlideIn(
      animation: _cardAnimations[2],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(_filterTabs.length, (i) {
            final tab = _filterTabs[i];
            final selected = _selectedTab == i;
            return GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                width: 60,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? tab.color.withOpacity(0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: selected
                      ? Border.all(color: tab.color.withOpacity(0.35), width: 1.5)
                      : Border.all(color: Colors.transparent, width: 1.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: selected
                            ? tab.color.withOpacity(0.15)
                            : _kCard,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        tab.icon,
                        size: 22,
                        color: selected ? tab.color : _kTextMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tab.label,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? tab.color : _kTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSwipeBackground({
    required Alignment alignment,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: alignment,
      decoration: BoxDecoration(
        color: color.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: alignment == Alignment.centerLeft
            ? [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ]
            : [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, color: Colors.white, size: 24),
              ],
      ),
    );
  }

  // ── Notification Sections ─────────────────────────────────────────────────
  List<Widget> _buildSections(List<String> sections) {
    final widgets = <Widget>[];
    int animOffset = 3;

    final filtered = _filteredNotifications;

    for (final section in sections) {
      final sectionNotifs = filtered.where((n) => _getNotificationSection(n.timestamp) == section).toList();
      if (sectionNotifs.isEmpty) continue;

      // Section label
      final labelAnimIdx = animOffset.clamp(0, _cardAnimations.length - 1);
      widgets.add(SliverToBoxAdapter(
        child: _FadeSlideIn(
          animation: _cardAnimations[labelAnimIdx],
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 10),
            child: Text(
              section,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _kTextMuted,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
      ));
      animOffset++;

      // Cards
      for (final notif in sectionNotifs) {
        final cardAnimIdx = animOffset.clamp(0, _cardAnimations.length - 1);
        widgets.add(SliverToBoxAdapter(
          child: _FadeSlideIn(
            animation: _cardAnimations[cardAnimIdx],
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Dismissible(
                key: ValueKey(notif.id),
                background: _buildSwipeBackground(
                  alignment: Alignment.centerLeft,
                  color: _kPrimary,
                  icon: Icons.mark_chat_read_rounded,
                  label: 'Mark as Read',
                ),
                secondaryBackground: _buildSwipeBackground(
                  alignment: Alignment.centerRight,
                  color: const Color(0xFFE84393),
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete',
                ),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    if (!notif.isRead) {
                      ref.read(notificationServiceProvider).markAsRead(notif.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: _kText,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          content: Text(
                            'Notification marked as read',
                            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13),
                          ),
                        ),
                      );
                    }
                    return false; // Slides back in
                  } else {
                    ref.read(notificationServiceProvider).deleteNotification(notif.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: _kText,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        content: Text(
                          'Notification deleted',
                          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13),
                        ),
                      ),
                    );
                    return true; // Dismisses item
                  }
                },
                child: _NotificationCard(
                  data: notif,
                  onTap: () {
                    if (!notif.isRead) {
                      ref.read(notificationServiceProvider).markAsRead(notif.id);
                    }
                    context.push(_getNotificationRoute(notif));
                  },
                ),
              ),
            ),
          ),
        ));
        animOffset++;
      }
    }

    return widgets;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification Card Widget
// ─────────────────────────────────────────────────────────────────────────────
class _NotificationCard extends StatefulWidget {
  final AppNotification data;
  final VoidCallback onTap;
  const _NotificationCard({required this.data, required this.onTap});

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.5).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (!widget.data.isRead) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _NotificationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data.isRead && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visuals = _getNotificationVisuals(widget.data.type);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 14,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Colored 3D icon box
                      _ColoredIconBox(
                        iconData: visuals.iconData,
                        color1: visuals.iconBgColor1,
                        color2: visuals.iconBgColor2,
                        imagePath: visuals.imagePath,
                      ),

                      const SizedBox(width: 14),

                      // Text content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.data.title,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: !widget.data.isRead
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                      color: _kText,
                                      letterSpacing: -0.1,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatNotificationTime(widget.data.timestamp),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: _kTextMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              widget.data.description,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                color: _kTextSub,
                                height: 1.45,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Unread dot
                      if (!widget.data.isRead) ...[
                        const SizedBox(width: 10),
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (_, __) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 18 * _pulseAnimation.value,
                                  height: 18 * _pulseAnimation.value,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _kUnread.withOpacity(
                                      0.15 * (2.0 - _pulseAnimation.value),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 9,
                                  height: 9,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _kUnread,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ] else ...[
                        const SizedBox(width: 10),
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _kUnread.withOpacity(0.0),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Colored Icon Box — matching the reference image
// ─────────────────────────────────────────────────────────────────────────────
class _ColoredIconBox extends StatefulWidget {
  final IconData iconData;
  final Color color1;
  final Color color2;
  final String? imagePath;
  const _ColoredIconBox({
    required this.iconData,
    required this.color1,
    required this.color2,
    this.imagePath,
  });

  @override
  State<_ColoredIconBox> createState() => _ColoredIconBoxState();
}

class _ColoredIconBoxState extends State<_ColoredIconBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1800 + math.Random().nextInt(1200)),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (_, child) {
        final dy = math.sin(_floatController.value * math.pi) * 2.5;
        return Transform.translate(
          offset: Offset(0, -dy),
          child: child,
        );
      },
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [widget.color1, widget.color2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: widget.color1.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: widget.imagePath != null
              ? Image.asset(
                  widget.imagePath!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    widget.iconData,
                    color: Colors.white,
                    size: 26,
                  ),
                )
              : Icon(
                  widget.iconData,
                  color: Colors.white,
                  size: 26,
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Built-in 3D Bell fallback (if asset not found)
// ─────────────────────────────────────────────────────────────────────────────
class _Built3DBell extends StatelessWidget {
  final AnimationController controller;
  const _Built3DBell({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final offset = math.sin(controller.value * math.pi) * 6;
        return Transform.translate(
          offset: Offset(0, -offset),
          child: SizedBox(
            width: 150,
            height: 170,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Bell body shadow
                Positioned(
                  bottom: 18,
                  child: Container(
                    width: 80,
                    height: 14,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      color: Colors.black.withOpacity(0.2),
                    ),
                  ),
                ),
                // Bell body
                Positioned(
                  top: 20,
                  child: CustomPaint(
                    size: const Size(110, 110),
                    painter: _BellPainter(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BellPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFAA8AFF), Color(0xFF7B61FF)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(size.width * 0.5, size.height * 0.1)
      ..cubicTo(size.width * 0.1, size.height * 0.15,
                size.width * 0.0, size.height * 0.5,
                size.width * 0.05, size.height * 0.78)
      ..lineTo(size.width * 0.95, size.height * 0.78)
      ..cubicTo(size.width * 1.0, size.height * 0.5,
                size.width * 0.9, size.height * 0.15,
                size.width * 0.5, size.height * 0.1);
    canvas.drawPath(path, paint);

    // Bell bottom
    final bottomPaint = Paint()
      ..color = const Color(0xFF6B4EFF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.04, size.height * 0.75,
                      size.width * 0.92, size.height * 0.12),
        const Radius.circular(8),
      ),
      bottomPaint,
    );

    // Bell clapper
    final clapperPaint = Paint()
      ..color = const Color(0xFF5A3FE0);
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.92),
      size.width * 0.08,
      clapperPaint,
    );

    // Stem
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.44, 0,
                      size.width * 0.12, size.height * 0.12),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFF8B70FF),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Sparkle Icon ✦ for hero background
// ─────────────────────────────────────────────────────────────────────────────
class _SparkleIcon extends StatelessWidget {
  final AnimationController controller;
  final double delay;
  final double size;

  const _SparkleIcon({
    required this.controller,
    required this.delay,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final phase = (controller.value + delay) % 1.0;
        final opacity = (math.sin(phase * math.pi * 2) * 0.5 + 0.5).clamp(0.3, 1.0);
        final dy = math.sin(phase * math.pi * 2) * 3;
        return Transform.translate(
          offset: Offset(0, dy),
          child: Opacity(
            opacity: opacity,
            child: Text(
              '✦',
              style: TextStyle(
                color: Colors.white,
                fontSize: size,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fade + Slide In animation wrapper
// ─────────────────────────────────────────────────────────────────────────────
class _FadeSlideIn extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _FadeSlideIn({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final value = animation.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 22 * (1 - value)),
            child: child,
          ),
        );
      },
    );
  }
}
