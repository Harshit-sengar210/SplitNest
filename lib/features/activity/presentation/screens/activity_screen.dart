import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../presentation/providers/activity_provider.dart';

// Helper class for unified timeline items
class _TimelineItem {
  final String id;
  final String type; // 'expense', 'settlement', 'group', 'member', 'chat', 'ledger'
  final String title;
  final String description;
  final double? amount;
  final bool isNegative;
  final DateTime timestamp;
  final String route;
  final String imageAsset;
  final String memberName;
  final String groupName;

  _TimelineItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.amount,
    required this.isNegative,
    required this.timestamp,
    required this.route,
    required this.imageAsset,
    required this.memberName,
    required this.groupName,
  });
}

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _selectedFilter = 'All';
  String _searchQuery = '';
  late AnimationController _coinsFloatController;

  final List<String> _filters = [
    'All', 'Expenses', 'Settlements', 'Groups', 'Personal Ledger'
  ];

  @override
  void initState() {
    super.initState();
    _coinsFloatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _coinsFloatController.dispose();
    _searchController.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {

    // 1. Fetch live states
    final activityState = ref.watch(globalActivitiesProvider);
    final ledgerTransactionsAsync = ref.watch(ledgerTransactionsProvider);
    final ledgerTransactions = ledgerTransactionsAsync.value ?? [];

    // 2. Compute ledger statistics
    final double willReceiveLedger = ledgerTransactions
        .where((t) => t.status.toLowerCase() == 'pending' && t.type.toLowerCase() == 'lend')
        .fold(0.0, (sum, t) => sum + t.amount);

    final double needToPayLedger = ledgerTransactions
        .where((t) => t.status.toLowerCase() == 'pending' && t.type.toLowerCase() == 'borrow')
        .fold(0.0, (sum, t) => sum + t.amount);

    final double netBalanceLedger = willReceiveLedger - needToPayLedger;

    // 3. Build unified activities list
    final List<_TimelineItem> allItems = [];

    // Map global activities
    for (final act in activityState.activities) {
      String type = 'group';
      String imageAsset = 'assets/icons/icon_house_3d.png';
      String route = '/groups/${act.groupId}';
      bool isNeg = false;

      if (act.activityType.startsWith('expense')) {
        type = 'expense';
        imageAsset = 'assets/icons/icon_receipt_3d.png';
        route = '/expenses/detail/${act.relatedId}?title=${Uri.encodeComponent(act.title)}&amount=₹${act.amount?.toInt() ?? 0}';
        isNeg = act.actorId != 'user_me';
      } else if (act.activityType == 'settlement_completed') {
        type = 'settlement';
        imageAsset = 'assets/icons/icon_wallet_3d.png';
        route = '/settlement/detail/${act.relatedId}?title=${Uri.encodeComponent(act.title)}&amount=₹${act.amount?.toInt() ?? 0}';
      } else if (act.activityType == 'member_joined' || act.activityType == 'member_left') {
        type = 'member';
        imageAsset = 'assets/icons/icon_people_3d.png';
      }

      allItems.add(_TimelineItem(
        id: act.id,
        type: type,
        title: act.title,
        description: act.description,
        amount: act.amount,
        isNegative: isNeg,
        timestamp: act.createdAt,
        route: route,
        imageAsset: imageAsset,
        memberName: act.actorName ?? 'Someone',
        groupName: act.groupName ?? '',
      ));
    }

    // Map ledger transactions
    for (final tx in ledgerTransactions) {
      final bool isNeg = tx.type.toLowerCase() == 'borrow' || tx.type.toLowerCase() == 'expense';
      allItems.add(_TimelineItem(
        id: 'ledger_${tx.transactionId}',
        type: 'ledger',
        title: tx.title,
        description: tx.description.isNotEmpty ? tx.description : tx.type,
        amount: tx.amount,
        isNegative: isNeg,
        timestamp: tx.date,
        route: '/personal-ledger',
        imageAsset: 'assets/icons/icon_money_3d.png',
        memberName: tx.personName ?? 'Someone',
        groupName: 'Personal Ledger',
      ));
    }

    // Premium Mock Chats for groups & all filter
    final DateTime now = DateTime.now();
    final mockChats = [
      _TimelineItem(
        id: 'chat_mock_1',
        type: 'chat',
        title: 'New Message',
        description: '"Can someone grab milk?"',
        timestamp: now.subtract(const Duration(minutes: 15)),
        route: '/groups/nest_1',
        imageAsset: 'assets/icons/icon_sparkles_3d.png',
        memberName: 'Aman',
        groupName: 'Flat 402 Roomies',
        isNegative: false,
      ),
      _TimelineItem(
        id: 'chat_mock_2',
        type: 'chat',
        title: 'New Message',
        description: '"I booked the flights for Europe!"',
        timestamp: now.subtract(const Duration(hours: 3)),
        route: '/groups/nest_2',
        imageAsset: 'assets/icons/icon_sparkles_3d.png',
        memberName: 'Sarah',
        groupName: 'Europe Trip 2026',
        isNegative: false,
      ),
    ];
    allItems.addAll(mockChats);

    // Sort all timeline items chronologically
    allItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // 4. Apply filter tabs
    List<_TimelineItem> filteredItems = allItems;
    if (_selectedFilter == 'Expenses') {
      filteredItems = allItems.where((item) => item.type == 'expense').toList();
    } else if (_selectedFilter == 'Settlements') {
      filteredItems = allItems.where((item) => item.type == 'settlement').toList();
    } else if (_selectedFilter == 'Groups') {
      filteredItems = allItems.where((item) => item.type == 'group' || item.type == 'member' || item.type == 'chat').toList();
    } else if (_selectedFilter == 'Personal Ledger') {
      filteredItems = allItems.where((item) => item.type == 'ledger').toList();
    }

    // 5. Apply search query
    if (_searchQuery.isNotEmpty) {
      filteredItems = filteredItems.where((item) =>
        item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        item.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        item.memberName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        item.groupName.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    // 6. Group filtered items by date
    final Map<String, List<_TimelineItem>> groupedActivities = {};
    for (final item in filteredItems) {
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final itemDate = DateTime(item.timestamp.year, item.timestamp.month, item.timestamp.day);

      String groupKey = 'Earlier';
      if (itemDate == today) {
        groupKey = 'Today';
      } else if (itemDate == yesterday) {
        groupKey = 'Yesterday';
      } else if (today.difference(itemDate).inDays < 7) {
        groupKey = 'This Week';
      }

      if (!groupedActivities.containsKey(groupKey)) {
        groupedActivities[groupKey] = [];
      }
      groupedActivities[groupKey]!.add(item);
    }

    final themeBg = const Color(0xFFFFFDF8); // Clean soft ivory background
    final themePrimary = const Color(0xFF7B61FF);
    final themeText = const Color(0xFF1A1A1A);
    final themeTextSecondary = const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: themeBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Header
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      'Activity',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: themeText,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track your expenses and personal transactions.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: themeTextSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // 2. Personal Ledger Summary Card
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 28),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF6B4EFF),
                        Color(0xFF8B6FFF),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6B4EFF).withOpacity(0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                      width: 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 16.0),
                          child: Row(
                            children: [
                              // Floating 3D Coins
                              AnimatedBuilder(
                                animation: _coinsFloatController,
                                builder: (_, child) {
                                  final dy = math.sin(_coinsFloatController.value * math.pi) * 6;
                                  return Transform.translate(
                                    offset: Offset(0, -dy),
                                    child: child,
                                  );
                                },
                                child: Image.asset(
                                  'assets/images/3d_coins.png',
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Ledger Statistics
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildLedgerRow(
                                      label: 'You Will Receive',
                                      amount: '₹${willReceiveLedger.toStringAsFixed(2)}',
                                      amountColor: const Color(0xFF56E0A8),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildLedgerRow(
                                      label: 'You Need To Pay',
                                      amount: '₹${needToPayLedger.toStringAsFixed(2)}',
                                      amountColor: const Color(0xFFFF88BB),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildLedgerRow(
                                      label: 'Net Balance',
                                      amount: '₹${netBalanceLedger.abs().toStringAsFixed(2)}',
                                      amountColor: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // View All Button (glassmorphic bottom bar)
                        Material(
                          color: Colors.white.withOpacity(0.08),
                          child: InkWell(
                            onTap: () => context.push('/personal-ledger'),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'View Personal Ledger',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      letterSpacing: 0.2,
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
                ),
              ),

              // 3. Search Bar & Filter Chips
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _searchController,
                      labelText: '',
                      hintText: 'Search activities...',
                      prefixIcon: Icons.search_rounded,
                    ),
                    const SizedBox(height: 18),
                    // Filters row
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _filters.length,
                        physics: const BouncingScrollPhysics(),
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final filter = _filters[index];
                          final isSelected = _selectedFilter == filter;
                          return ChoiceChip(
                            label: Text(
                              filter,
                              style: TextStyle(
                                color: isSelected ? Colors.white : themeTextSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: themePrimary,
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: isSelected ? Colors.transparent : const Color(0xFFE5E7EB),
                            ),
                            onSelected: (_) {
                              setState(() {
                                _selectedFilter = filter;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),

              // 4. Activity Timeline
              if (groupedActivities.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: Center(
                      child: Text(
                        'No activities match your filters.',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ),
                  ),
                )
              else
                ...groupedActivities.entries.map((entry) {
                  return SliverList(
                    delegate: SliverChildListDelegate([
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14.0),
                        child: Text(
                          entry.key,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF9CA3AF),
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      ...entry.value.map((activity) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildActivityCard(activity, context),
                      )),
                      const SizedBox(height: 16),
                    ]),
                  );
                }),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLedgerRow({
    required String label,
    required String amount,
    required Color amountColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white.withOpacity(0.85),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          amount,
          style: GoogleFonts.plusJakartaSans(
            color: amountColor,
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard(_TimelineItem activity, BuildContext context) {
    Color getIconBgColor() {
      switch (activity.type) {
        case 'expense':
          return const Color(0xFF7B61FF);
        case 'settlement':
          return const Color(0xFF2DC88A);
        case 'ledger':
          return const Color(0xFFE84393);
        case 'member':
        case 'group':
          return const Color(0xFFF5A623);
        case 'chat':
          return const Color(0xFF4A90E2);
        default:
          return const Color(0xFF7B61FF);
      }
    }

    final bg = getIconBgColor();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push(activity.route),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
              child: Row(
                children: [
                  // 3D icon box
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [bg, bg.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: bg.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(6.0),
                    child: Image.asset(
                      activity.imageAsset,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.widgets_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Middle text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1A1A),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              activity.memberName,
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 11,
                              ),
                            ),
                            if (activity.groupName.isNotEmpty) ...[
                              const Text(
                                ' • ',
                                style: TextStyle(
                                  color: Color(0xFF9CA3AF),
                                  fontSize: 11,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  activity.groupName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          activity.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF6B7280),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right side: Amount / Time
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (activity.amount != null)
                        Text(
                          '₹${activity.amount!.toInt()}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: activity.isNegative ? const Color(0xFFEF4444) : const Color(0xFF16A34A),
                            fontSize: 14,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        _getHumanizedTime(activity.timestamp),
                        style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
