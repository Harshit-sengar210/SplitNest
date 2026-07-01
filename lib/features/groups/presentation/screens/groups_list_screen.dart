import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../nests/presentation/providers/nest_provider.dart';

class GroupsListScreen extends ConsumerWidget {
  const GroupsListScreen({super.key});

  // Map category strings to the user-provided images
  String _iconForType(String type) {
    final t = type.toLowerCase();
    if (t.contains('flat') || t.contains('roommate')) {
      return 'assets/images/Screenshot_2026-06-09_195719-removebg-preview.png';
    } else if (t.contains('family')) {
      return 'assets/images/Screenshot_2026-06-09_202834-removebg-preview.png';
    } else if (t.contains('travel') || t.contains('trip')) {
      return 'assets/images/Screenshot_2026-06-09_202702-removebg-preview.png';
    } else if (t.contains('office') || t.contains('work')) {
      return 'assets/images/Screenshot_2026-06-09_203124-removebg-preview.png';
    } else if (t.contains('friend') || t.contains('college')) {
      return 'assets/images/Screenshot_2026-06-09_130728-removebg-preview.png';
    } else {
      // Custom / unknown — default
      return 'assets/images/Screenshot_2026-06-09_203447-removebg-preview.png';
    }
  }

  String _getHumanizedTime(DateTime? dateTime) {
    if (dateTime == null) return 'Never';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nestsAsyncValue = ref.watch(filteredNestsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Lavender/purple background matching the design system
    final bgColor = isDark ? const Color(0xFF0B0907) : const Color(0xFFEAE6F8);
    final cardColor = isDark ? const Color(0xFF17120D) : Colors.white;
    final headerTextColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subtitleColor = isDark ? const Color(0xFFB7A58B) : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── TOP SECTION (non-scrollable header) ──────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nests',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: headerTextColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Keep track of your active shared groups.',
                        style: TextStyle(
                          fontSize: 13,
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ),
                  // + button
                  GestureDetector(
                    onTap: () => context.push('/groups/create'),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Color(0xFF7C5CBF),
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── HERO BANNER ──────────────────────────────────────────────
            SizedBox(
              height: 160,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  // Decorative floating bubbles
                  Positioned(
                    left: 30,
                    top: 20,
                    child: _FloatingBubble(
                      size: 48,
                      color: const Color(0xFF9B7FD4),
                      child: const Icon(Icons.people_alt_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                  Positioned(
                    left: 22,
                    top: 78,
                    child: _FloatingBubble(
                      size: 36,
                      color: const Color(0xFF4CAF50),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                  Positioned(
                    right: 36,
                    top: 18,
                    child: _FloatingBubble(
                      size: 42,
                      color: const Color(0xFFF8BBD0),
                      child: const Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 20),
                    ),
                  ),
                  Positioned(
                    right: 20,
                    top: 72,
                    child: _FloatingBubble(
                      size: 20,
                      color: const Color(0xFFB39DDB).withOpacity(0.7),
                    ),
                  ),
                  Positioned(
                    right: 80,
                    top: 10,
                    child: _FloatingBubble(
                      size: 14,
                      color: const Color(0xFFCE93D8).withOpacity(0.5),
                    ),
                  ),
                  // Centered hero illustration
                  Positioned(
                    bottom: -10,
                    child: Image.asset(
                      'assets/images/Screenshot_2026-06-09_195411-removebg-preview.png',
                      height: 160,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),

            // ── SEARCH BAR ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: (q) => ref.read(nestsSearchQueryProvider.notifier).state = q,
                  style: TextStyle(
                    color: headerTextColor,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search nests...',
                    hintStyle: TextStyle(color: subtitleColor, fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded, color: subtitleColor, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                ),
              ),
            ),

            // ── NESTS LIST OR EMPTY STATE ──────────────────────────────────
            Expanded(
              child: nestsAsyncValue.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF7C5CBF)),
                ),
                error: (error, stack) => Center(
                  child: Text(
                    error.toString(),
                    style: const TextStyle(color: Color(0xFFEF4444)),
                  ),
                ),
                data: (nests) {
                  if (nests.isEmpty) {
                    return Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.nights_stay_outlined,
                              size: 64,
                              color: Color(0xFF7C5CBF),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No nests found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: headerTextColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create your first nest to start sharing expenses!',
                              style: TextStyle(
                                fontSize: 14,
                                color: subtitleColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () => context.push('/groups/create'),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Create Your First Nest'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7C5CBF),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: nests.length,
                    itemBuilder: (context, index) {
                      final nest = nests[index];
                      // Default ₹0 balance as requested
                      const balanceLabel = 'Settled up';
                      const balanceValue = '';
                      const isOwed = null;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _GroupCard(
                          iconAsset: (nest.coverImage != null && nest.coverImage!.isNotEmpty)
                              ? nest.coverImage!
                              : _iconForType(nest.category),
                          title: nest.name,
                          subtitle: '${nest.memberCount} members • ${nest.category} • Active ${_getHumanizedTime(nest.lastActivity ?? nest.createdAt)}',
                          balanceLabel: balanceLabel,
                          balanceValue: balanceValue,
                          isOwed: isOwed,
                          cardColor: cardColor,
                          headerTextColor: headerTextColor,
                          subtitleColor: subtitleColor,
                          onTap: () => context.push('/groups/${nest.nestId}'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable card widget ─────────────────────────────────────────────────────
class _GroupCard extends StatelessWidget {
  final String iconAsset;
  final String title;
  final String subtitle;
  final String balanceLabel;
  final String balanceValue;
  final bool? isOwed;
  final Color cardColor;
  final Color headerTextColor;
  final Color subtitleColor;
  final VoidCallback onTap;

  const _GroupCard({
    required this.iconAsset,
    required this.title,
    required this.subtitle,
    required this.balanceLabel,
    required this.balanceValue,
    required this.isOwed,
    required this.cardColor,
    required this.headerTextColor,
    required this.subtitleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final balanceColor = isOwed == null
        ? const Color(0xFF6B7280)
        : isOwed!
            ? const Color(0xFF16A34A)
            : const Color(0xFFEF4444);

    final balanceBg = isOwed == null
        ? const Color(0xFFF3F4F6)
        : isOwed!
            ? const Color(0xFFDCFCE7)
            : const Color(0xFFFFE4E4);

    final arrowIcon = isOwed == null
        ? Icons.check_circle_outline_rounded
        : isOwed!
            ? Icons.arrow_upward_rounded
            : Icons.arrow_downward_rounded;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // 3D Category icon
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  iconAsset,
                  width: 56,
                  height: 56,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stack) => Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEAE6F8),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    child: const Icon(Icons.group_rounded, color: Color(0xFF7C5CBF), size: 28),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name & subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: headerTextColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Balance badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: balanceBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(arrowIcon, color: balanceColor, size: 13),
                        const SizedBox(width: 3),
                        Text(
                          balanceLabel,
                          style: TextStyle(
                            fontSize: 10,
                            color: balanceColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (balanceValue.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        balanceValue,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: balanceColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),

              // Arrow
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: subtitleColor.withOpacity(0.5),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Floating bubble decoration ───────────────────────────────────────────────
class _FloatingBubble extends StatelessWidget {
  final double size;
  final Color color;
  final Widget? child;

  const _FloatingBubble({required this.size, required this.color, this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child != null ? Center(child: child) : null,
    );
  }
}
