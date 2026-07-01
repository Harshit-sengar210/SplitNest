import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:splitnest/features/groups/domain/calculators/cycle_calculator.dart';
import '../providers/groups_provider.dart';
import '../../domain/models/group.dart';
import '../../../expenses/presentation/providers/expenses_provider.dart';
import '../../../expenses/domain/models/expense.dart';
import '../../../expenses/presentation/widgets/expense_card.dart';
import '../../../chat/presentation/widgets/chat_tab.dart';
import '../../../settlement/presentation/providers/settlement_provider.dart';
import '../../../settlement/domain/models/balance.dart';
import '../../../activity/presentation/providers/activity_provider.dart';
import '../../../activity/domain/models/activity.dart';
import '../../../activity/presentation/screens/nest_timeline_screen.dart';
import '../../../../core/widgets/premium_image_selector.dart';
import 'dart:convert';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../members/presentation/providers/member_providers.dart';
import 'cycle_screen.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _kPurple = Color(0xFF7B61FF);
const _kPurpleDark = Color(0xFF5A3FD6);
const _kPurpleLight = Color(0xFFF5F3FF);
const _kBlue = Color(0xFF4F8EF7);
const _kCard = Colors.white;
const _kBg1 = Color(0xFFF5F3FF);
const _kBg2 = Color(0xFFFFFFFF);
const _kText = Color(0xFF1A1A2E);
const _kSub = Color(0xFF6B7280);
const _kSuccess = Color(0xFF22C55E);
const _kError = Color(0xFFEF4444);

class GroupDetailScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _tabIndex = 0;
  final _inviteEmailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      if (!mounted) return;
      setState(() => _tabIndex = _tabController.index);
    });
    
    // Set this group as the active nest
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(authNotifierProvider.notifier).updateActiveNestId(widget.groupId);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _inviteEmailController.dispose();
    super.dispose();
  }

  String _getCurrentCycleString(int cycleDay) {
    final ref = DateTime.now();
    
    // Helper to clamp a day to a valid day for a specific year and month.
    DateTime getClampedDate(int year, int month, int targetDay) {
      final lastDay = DateTime(year, month + 1, 0).day;
      final clampedDay = targetDay > lastDay ? lastDay : targetDay;
      return DateTime(year, month, clampedDay);
    }

    DateTime start;
    DateTime end;

    if (ref.day >= cycleDay) {
      start = getClampedDate(ref.year, ref.month, cycleDay);
      end = getClampedDate(ref.year, ref.month + 1, cycleDay);
    } else {
      start = getClampedDate(ref.year, ref.month - 1, cycleDay);
      end = getClampedDate(ref.year, ref.month, cycleDay);
    }

    final startStr = DateFormat('d MMM').format(start);
    final endStr = DateFormat('d MMM').format(end);
    return '$startStr → $endStr';
  }

  Future<void> _handleCreateCycle(String groupId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final bounds = CycleCalculator.calculateCycleBounds(cycleDay: 1);
      final cycleId = 'cycle_${bounds.start.year}_${bounds.start.month.toString().padLeft(2, '0')}_${DateTime.now().millisecondsSinceEpoch}';

      // Get member count
      final membersSnap = await firestore.collection('nests').doc(groupId).collection('members').get();
      final memberCount = membersSnap.docs.length;

      final batch = firestore.batch();
      final nestRef = firestore.collection('nests').doc(groupId);
      final cycleRef = nestRef.collection('Cycle').doc(cycleId);

      batch.update(nestRef, {
        'currentCycleId': cycleId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      batch.set(cycleRef, {
        'cycleId': cycleId,
        'cycleStartDate': Timestamp.fromDate(bounds.start),
        'cycleEndDate': Timestamp.fromDate(bounds.end),
        'totalExpenses': 0.0,
        'totalSettled': 0.0,
        'totalPending': 0.0,
        'totalTransactions': 0,
        'memberCount': memberCount,
        'settledPercentage': 0.0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Financial cycle created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create cycle: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupDetailProvider(widget.groupId));

    return groupAsync.when(
      data: (group) => _buildScaffold(group),
      loading: () => Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_kBg1, _kBg2],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: _kPurple,
              strokeWidth: 2.5,
            ),
          ),
        ),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: _kBg1,
        body: Center(
          child: Text(error.toString(),
              style: const TextStyle(color: _kError)),
        ),
      ),
    );
  }

  Widget _buildScaffold(Group group) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_kBg1, _kBg2],
          ),
        ),
        child: Stack(
          children: [
            // Subtle background floating shapes
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kPurple.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              left: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kBlue.withValues(alpha: 0.05),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _buildAppBar(group),
                  _buildGroupHeader(group),
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        ChatTab(group: group),
                        _buildExpensesTab(group),
                        _buildMembersTab(group),
                        _buildBalanceTab(group),
                        _buildActivityTimelineTab(group),
                        _buildCycleTab(group),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedScale(
        scale: _tabIndex == 1 ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kPurpleDark, _kPurple],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: _kPurple.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push('/expenses/add'),
              borderRadius: BorderRadius.circular(30),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Add Expense',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(Group group) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/dashboard');
              }
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: _kText, size: 18),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _showShareMenu(group),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.share_rounded,
                  color: _kPurple, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupHeader(Group group) {
    final isAdmin = group.members
        .any((m) => m.id == 'user_me' && m.role == MemberRole.admin);

    final currentCycleIdAsync = ref.watch(currentCycleIdProvider(group.id));
    final currentCycleId = currentCycleIdAsync.value;
    final hasNoActiveCycle = currentCycleIdAsync.hasValue && (currentCycleId == null || currentCycleId.isEmpty);

    final cycleAsync = ref.watch(cycleStatsProvider(group.id));

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kPurple, _kPurpleDark],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _kPurple.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Row: Image, Name, Badges, Share Button
          Row(
            children: [
              GestureDetector(
                onTap: isAdmin ? () => _handleGroupImageUpdate(group) : null,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _buildGroupImageWidget(group),
                      ),
                    ),
                    if (isAdmin)
                      Positioned(
                        bottom: -4,
                        right: -4,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _kPurple,
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(Icons.camera_alt_rounded,
                              color: _kPurple, size: 11),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            group.type,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${group.membersCount} members',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF86EFAC).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF86EFAC).withValues(alpha: 0.5)),
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
                              const SizedBox(width: 4),
                              const Text(
                                'Active',
                                style: TextStyle(
                                  color: Color(0xFF86EFAC),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showShareMenu(group),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.share_rounded, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),

          // Middle Section: Dedicated Current Cycle Card
          hasNoActiveCycle
              ? Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Color(0xFFFFB6B6), size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'No Active Cycle',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _handleCreateCycle(group.id),
                        icon: const Icon(Icons.add_rounded, size: 16, color: _kPurple),
                        label: Text(
                          'Create Cycle',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: _kPurple,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : cycleAsync.when(
                  data: (stats) {
                    final startStr = DateFormat('d MMM').format(stats.cycleStart);
                    final endStr = DateFormat('d MMM').format(stats.cycleEnd);
                    final dateRange = '$startStr → $endStr';
                    final daysRemaining = stats.cycleEnd.difference(DateTime.now()).inDays;
                    final daysStr = daysRemaining > 0 
                        ? '$daysRemaining days left' 
                        : (daysRemaining == 0 ? 'Ends today' : 'Cycle ended');

                    final totalSec = stats.cycleEnd.difference(stats.cycleStart).inSeconds;
                    final elapsedSec = DateTime.now().difference(stats.cycleStart).inSeconds;
                    final progress = totalSec > 0 ? (elapsedSec / totalSec).clamp(0.0, 1.0) : 0.0;

                    return Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Current Financial Cycle',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                daysStr,
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF86EFAC),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            dateRange,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.white.withValues(alpha: 0.1),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF86EFAC)),
                              minHeight: 5,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => Container(
                    margin: const EdgeInsets.only(top: 16),
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    ),
                  ),
                  error: (err, _) => Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Error: $err', style: const TextStyle(color: Colors.white)),
                  ),
                ),

          // Bottom Section: Three Financial Summary Cards
          hasNoActiveCycle
              ? Container(
                  margin: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          label: 'Total Bills',
                          value: '₹0',
                          color: Colors.white,
                          bgColor: Colors.white.withValues(alpha: 0.15),
                          icon: Icons.receipt_long_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSummaryCard(
                          label: 'Pending',
                          value: '₹0',
                          color: const Color(0xFFFFB6B6),
                          bgColor: Colors.white.withValues(alpha: 0.15),
                          icon: Icons.hourglass_top_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSummaryCard(
                          label: 'Settled',
                          value: '₹0',
                          color: const Color(0xFF86EFAC),
                          bgColor: Colors.white.withValues(alpha: 0.15),
                          icon: Icons.check_circle_rounded,
                        ),
                      ),
                    ],
                  ),
                )
              : cycleAsync.when(
                  data: (stats) {
                    return Container(
                      margin: const EdgeInsets.only(top: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              label: 'Total Bills',
                              value: '₹${stats.totalExpenses.toInt()}',
                              color: Colors.white,
                              bgColor: Colors.white.withValues(alpha: 0.15),
                              icon: Icons.receipt_long_rounded,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildSummaryCard(
                              label: 'Pending',
                              value: '₹${stats.totalPending.toInt()}',
                              color: const Color(0xFFFFB6B6),
                              bgColor: Colors.white.withValues(alpha: 0.15),
                              icon: Icons.hourglass_top_rounded,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildSummaryCard(
                              label: 'Settled',
                              value: '₹${stats.totalSettled.toInt()}',
                              color: const Color(0xFF86EFAC),
                              bgColor: Colors.white.withValues(alpha: 0.15),
                              icon: Icons.check_circle_rounded,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => Container(
                    margin: const EdgeInsets.only(top: 16),
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                  ),
                  error: (err, _) => const SizedBox.shrink(),
                ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: _kPurple,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: _kPurple,
          unselectedLabelColor: _kSub,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'Chat'),
            Tab(text: 'Expenses'),
            Tab(text: 'Members'),
            Tab(text: 'Balance'),
            Tab(text: 'Timeline'),
            Tab(text: 'Cycle'),
          ],
        ),
      ),
    );
  }

  // ── Group image ──────────────────────────────────────────────────────────────
  Widget _buildGroupImageWidget(Group group) {
    final imagePath = group.groupImage ?? group.imageUrl;
    if (imagePath == null || imagePath.isEmpty) {
      return Icon(_getGroupIcon(group.type), color: Colors.white, size: 30);
    }
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(imagePath, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Icon(_getGroupIcon(group.type), color: Colors.white, size: 30));
    }
    if (imagePath.startsWith('data:image')) {
      try {
        final b64 =
            imagePath.contains(',') ? imagePath.split(',')[1] : imagePath;
        return Image.memory(base64Decode(b64), fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Icon(_getGroupIcon(group.type), color: Colors.white, size: 30));
      } catch (_) {
        return Icon(_getGroupIcon(group.type), color: Colors.white, size: 30);
      }
    }
    if (imagePath.startsWith('assets/')) {
      return Image.asset(imagePath,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              Icon(_getGroupIcon(group.type), color: Colors.white, size: 30));
    }
    return Icon(_getGroupIcon(group.type), color: Colors.white, size: 30);
  }

  void _handleGroupImageUpdate(Group group) async {
    final result = await PremiumImageSelector.show(context,
        title: 'EDIT NEST PICTURE');
    if (result != null) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: _kPurple),
        ),
      );
      try {
        await ref
            .read(groupsListProvider.notifier)
            .updateGroupImage(group.id, result);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Nest picture updated!'),
              backgroundColor: _kSuccess,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed: $e'),
              backgroundColor: _kError,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }
  }

  IconData _getGroupIcon(String type) {
    switch (type.toLowerCase()) {
      case 'flatmates':
        return Icons.home_rounded;
      case 'travel':
        return Icons.flight_takeoff_rounded;
      case 'office':
        return Icons.work_rounded;
      case 'friends':
        return Icons.face_rounded;
      case 'family':
        return Icons.favorite_rounded;
      default:
        return Icons.widgets_rounded;
    }
  }

  // ── Cycle / Lifecycle Tab ──────────────────────────────────────────────────
  Widget _buildCycleTab(Group group) {
    return CycleScreen(
      groupId: group.id,
      isEmbedded: true,
    );
  }

  Widget _buildExpensesTab(Group group) {
    final expensesAsync = ref.watch(nestExpensesStreamProvider(group.id));

    return expensesAsync.when(
      data: (expenses) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nest History',
                style: TextStyle(
                    color: _kText, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _kCard,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2)),
                  ],
                ),
                child: const Icon(Icons.filter_list_rounded,
                    color: _kPurple, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (expenses.isEmpty)
            _buildEmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'No expenses yet',
                subtitle: 'Start adding expenses to track your splits')
          else
            ...expenses.map((expense) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ExpenseCard(
                    expense: expense,
                    onTap: () => _showExpenseActions(expense),
                  ),
                )),
        ],
      ),
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(
            color: _kPurple,
            strokeWidth: 2.5,
          ),
        ),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text(
            'Error loading expenses: $error',
            style: const TextStyle(color: _kError),
          ),
        ),
      ),
    );
  }

  // ── Members Tab ──────────────────────────────────────────────────────────────
  Widget _buildMembersTab(Group group) {
    final creatorIsMe = group.createdBy == FirebaseAuth.instance.currentUser?.uid;
    final membersAsync = ref.watch(nestMembersStreamProvider(group.id));

    return membersAsync.when(
      data: (members) {
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          children: [
            // Invite card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: _kPurple.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Invite Members',
                    style: TextStyle(
                        color: _kText,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: _kPurpleLight,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: TextField(
                            controller: _inviteEmailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: _kText, fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'Invite by Email',
                              hintStyle: TextStyle(color: _kSub, fontSize: 14),
                              prefixIcon:
                                  Icon(Icons.email_outlined, color: _kPurple, size: 20),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          final email = _inviteEmailController.text.trim();
                          if (email.isNotEmpty && email.contains('@')) {
                            ref
                                .read(groupsListProvider.notifier)
                                .inviteMember(
                                    groupId: group.id, email: email)
                                .then((_) {
                              _inviteEmailController.clear();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Invited $email!'),
                                  backgroundColor: _kSuccess,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Enter a valid email'),
                                backgroundColor: _kError,
                              ),
                            );
                          }
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_kPurpleDark, _kPurple],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: _kPurple.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.send_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Group Members',
                  style: TextStyle(
                      color: _kText, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                TextButton.icon(
                  onPressed: () => context.push('/groups/${group.id}/balances'),
                  icon: const Icon(Icons.account_balance_wallet_rounded, size: 16, color: _kPurple),
                  label: const Text(
                    'View Balances',
                    style: TextStyle(color: _kPurple, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (members.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('No members found.', style: TextStyle(color: _kSub)),
                ),
              )
            else
              ...members.map((member) {
                final isMe = member.id == currentUserId;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _kCard,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: _kPurpleLight,
                        backgroundImage: member.profileImage != null && member.profileImage!.isNotEmpty
                            ? NetworkImage(member.profileImage!)
                            : null,
                        child: (member.profileImage == null || member.profileImage!.isEmpty)
                            ? Text(
                                member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : 'M',
                                style: const TextStyle(
                                    color: _kPurple, fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isMe ? 'You' : member.fullName,
                              style: const TextStyle(
                                  color: _kText, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              member.email,
                              style: const TextStyle(
                                  color: _kSub, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Invited badge
                      if (member.status == 'invited') ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.amber.withOpacity(0.4)),
                          ),
                          child: const Text(
                            'Invited',
                            style: TextStyle(
                              color: Color(0xFFD97706),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      // Role badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: member.role == 'owner'
                              ? _kPurple.withValues(alpha: 0.1)
                              : _kPurpleLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          member.role == 'owner' ? 'Owner' : 'Member',
                          style: TextStyle(
                            color: member.role == 'owner'
                                ? _kPurple
                                : _kSub,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (creatorIsMe && !isMe)
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded,
                              color: _kSub, size: 20),
                          color: _kCard,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          onSelected: (val) {
                            if (val == 'remove') {
                              _showRemoveMemberConfirmation(group.id, member.id, member.fullName);
                            } else if (val == 'promote') {
                              ref
                                  .read(groupsListProvider.notifier)
                                  .promoteToAdmin(group.id, member.id);
                            }
                          },
                          itemBuilder: (context) => [
                            if (member.role != 'owner')
                              const PopupMenuItem(
                                value: 'promote',
                                child: Text('Promote to Owner',
                                    style: TextStyle(color: _kText)),
                              ),
                            const PopupMenuItem(
                              value: 'remove',
                              child: Text('Remove from Nest',
                                  style: TextStyle(color: _kError)),
                            ),
                          ],
                        ),
                    ],
                  ),
                );
              }),
            if (!creatorIsMe) ...[
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => _showLeaveGroupConfirmation(group),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _kError.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      'Leave Nest',
                      style: TextStyle(
                          color: _kError,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(
            color: _kPurple,
            strokeWidth: 2.5,
          ),
        ),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text(
            'Error loading members: $error',
            style: const TextStyle(color: _kError),
          ),
        ),
      ),
    );
  }

  // ── Balance Tab ──────────────────────────────────────────────────────────────
  Widget _buildBalanceTab(Group group) {
    final balancesAsync = ref.watch(groupBalancesProvider(group.id));

    return balancesAsync.when(
      data: (balances) {
        double owedToYou = 0.0;
        double youOwe = 0.0;
        for (final b in balances) {
          if (b.toUserId == 'user_me') owedToYou += b.amount;
          else if (b.fromUserId == 'user_me') youOwe += b.amount;
        }
        final net = owedToYou - youOwe;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
          children: [
            // Net Balance Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: net >= 0
                      ? [const Color(0xFF22C55E), const Color(0xFF16A34A)]
                      : [_kError, const Color(0xFFC21414)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color:
                        (net >= 0 ? _kSuccess : _kError).withValues(alpha: 0.3),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'YOUR NET BALANCE',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${net >= 0 ? '+' : ''}₹${net.toInt()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(children: [
                        const Text('You Are Owed',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text('₹${owedToYou.toInt()}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                      ]),
                      Container(
                          width: 1,
                          height: 30,
                          color: Colors.white.withValues(alpha: 0.3)),
                      Column(children: [
                        const Text('You Owe',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text('₹${youOwe.toInt()}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                      ]),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Who Owes Who',
              style: TextStyle(
                  color: _kText, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            if (balances.isEmpty)
              _buildEmptyState(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'All balances settled! 👍',
                  subtitle: 'Everyone is even in this group')
            else
              ...balances.map((b) {
                final fromName = _getMemberNameById(group, b.fromUserId);
                final toName = _getMemberNameById(group, b.toUserId);
                final isYouOwe = b.fromUserId == 'user_me';
                final isYouOwed = b.toUserId == 'user_me';

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: _kCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isYouOwe
                          ? _kError.withValues(alpha: 0.15)
                          : isYouOwed
                              ? _kSuccess.withValues(alpha: 0.15)
                              : Colors.transparent,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Text(fromName,
                            style: const TextStyle(
                                color: _kText, fontWeight: FontWeight.bold)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.arrow_forward_rounded,
                              color: _kSub, size: 14),
                        ),
                        Text(toName,
                            style: const TextStyle(
                                color: _kText, fontWeight: FontWeight.bold)),
                      ]),
                      Text(
                        '₹${b.amount.toInt()}',
                        style: TextStyle(
                          color: isYouOwe
                              ? _kError
                              : isYouOwed
                                  ? _kSuccess
                                  : _kSub,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 24),
            // Settle Up Button
            GestureDetector(
              onTap: () => _showSettleUpBottomSheet(group, balances),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kPurpleDark, _kPurple],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: _kPurple.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'SETTLE UP',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => context.push('/groups/${group.id}/balances'),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: _kPurple,
                    width: 1.5,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'VIEW MEMBER BALANCES',
                    style: TextStyle(
                      color: _kPurple,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => context.push('/groups/${group.id}/cycle'),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: _kPurple,
                    width: 1.5,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'VIEW BILLING CYCLE',
                    style: TextStyle(
                      color: _kPurple,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: _kPurple, strokeWidth: 2)),
      error: (e, _) => Center(
          child: Text(e.toString(),
              style: const TextStyle(color: _kError))),
    );
  }

  // ── Activity Timeline Tab ────────────────────────────────────────────────────
  Widget _buildActivityTimelineTab(Group group) {
    final timelineAsync = ref.watch(groupTimelineStreamProvider(group.id));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(group.id, 'All'),
                      const SizedBox(width: 8),
                      _buildFilterChip(group.id, 'Expenses'),
                      const SizedBox(width: 8),
                      _buildFilterChip(group.id, 'Settlements'),
                      const SizedBox(width: 8),
                      _buildFilterChip(group.id, 'Members'),
                    ],
                  ),
                ),
              ),
              // ── "See Full" button ──────────────────────────────────────────
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => NestTimelineScreen(
                      nestId: group.id,
                      nestName: group.name,
                    ),
                  ),
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color: _kPurpleLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: _kPurple.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.open_in_full_rounded,
                          color: _kPurple, size: 13),
                      SizedBox(width: 4),
                      Text(
                        'Full',
                        style: TextStyle(
                          color: _kPurple,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: timelineAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(
                    color: _kPurple, strokeWidth: 2)),
            error: (e, _) => Center(
              child: Text('Error loading timeline',
                  style: TextStyle(color: Colors.red.shade400)),
            ),
            data: (activities) {
              final filterType =
                  ref.watch(groupActivitiesProvider(group.id)).filterType;
              final filtered = activities.where((a) {
                switch (filterType) {
                  case 'Expenses':
                    return a.type.startsWith('expense_');
                  case 'Settlements':
                    return a.type.startsWith('settlement_');
                  case 'Members':
                    return a.type.startsWith('member_') ||
                        a.type.contains('created');
                  default:
                    return true;
                }
              }).toList();

              if (filtered.isEmpty) {
                return _buildEmptyState(
                    icon: Icons.timeline_rounded,
                    title: 'No activity yet',
                    subtitle: 'Group activity will appear here');
              }
              return ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  return _buildTimelineItem(filtered[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String groupId, String label) {
    final notifier =
        ref.read(groupActivitiesProvider(groupId).notifier);
    final activeFilter =
        ref.watch(groupActivitiesProvider(groupId)).filterType;
    final isActive = activeFilter == label;

    return GestureDetector(
      onTap: () => notifier.setFilter(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [_kPurpleDark, _kPurple],
                )
              : null,
          color: isActive ? null : _kCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : _kSub,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem(Activity activity) {
    final format = DateFormat('MMM dd, hh:mm a');
    final dateStr = format.format(activity.createdAt);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _kPurpleLight,
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: _kPurple.withValues(alpha: 0.3)),
                ),
                child: Icon(
                  _getTimelineIcon(activity.activityType),
                  color: _kPurple,
                  size: 16,
                ),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: _kPurple.withValues(alpha: 0.15),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        activity.title,
                        style: const TextStyle(
                          color: _kText,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        dateStr,
                        style:
                            const TextStyle(color: _kSub, fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity.description,
                    style:
                        const TextStyle(color: _kSub, fontSize: 12),
                  ),
                  if (activity.amount != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '₹${activity.amount!.toInt()}',
                      style: const TextStyle(
                          color: _kPurple,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTimelineIcon(String type) {
    switch (type) {
      case 'expense_created':
        return Icons.add_card_rounded;
      case 'expense_updated':
        return Icons.edit_rounded;
      case 'expense_deleted':
        return Icons.delete_outline_rounded;
      case 'settlement_completed':
        return Icons.done_all_rounded;
      case 'member_joined':
        return Icons.person_add_rounded;
      case 'member_left':
        return Icons.person_remove_rounded;
      case 'group_created':
        return Icons.group_add_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  String _getMemberNameById(Group group, String id) {
    if (id == 'user_me') return 'You';
    try {
      return group.members.firstWhere((m) => m.id == id).name;
    } catch (_) {
      return 'Someone';
    }
  }

  Widget _buildEmptyState(
      {required IconData icon,
      required String title,
      required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _kPurpleLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _kPurple, size: 32),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    color: _kText,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            const SizedBox(height: 6),
            Text(subtitle,
                style: const TextStyle(color: _kSub, fontSize: 12),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ── Action sheets ────────────────────────────────────────────────────────────
  void _showShareMenu(Group group) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            const Text('Invite Members',
                style: TextStyle(
                    color: _kText, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildShareOption(
              icon: Icons.link_rounded,
              title: 'Copy Invite Link',
              onTap: () {
                ref
                    .read(groupsListProvider.notifier)
                    .generateShareLink(group.id)
                    .then((link) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Link copied: $link'),
                        backgroundColor: _kSuccess),
                  );
                });
              },
            ),
            const SizedBox(height: 10),
            _buildShareOption(
              icon: Icons.qr_code_rounded,
              title:
                  'Invite Code: ${group.inviteCode ?? "GENERATE"}',
              onTap: () {
                if (group.inviteCode == null) {
                  ref
                      .read(groupsListProvider.notifier)
                      .generateInviteCode(group.id);
                }
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _kPurpleLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _kPurple.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: _kPurple, size: 18),
            ),
            const SizedBox(width: 14),
            Text(title,
                style: const TextStyle(
                    color: _kText, fontWeight: FontWeight.w600)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: _kSub, size: 14),
          ],
        ),
      ),
    );
  }

  void _showExpenseActions(Expense expense) {
    final creatorIsMe = expense.paidByUserId == 'user_me';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Text(
              expense.title,
              style: const TextStyle(
                  color: _kText,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (creatorIsMe)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: _kError),
                title: const Text('Delete Expense',
                    style: TextStyle(color: _kError)),
                onTap: () {
                  ref
                      .read(expensesProvider(expense.groupId).notifier)
                      .deleteExpense(expense.id)
                      .then((_) => Navigator.pop(context));
                },
              ),
            ListTile(
              leading:
                  const Icon(Icons.info_outline_rounded, color: _kPurple),
              title: const Text('View Split Details',
                  style: TextStyle(color: _kText)),
              onTap: () {
                Navigator.pop(context);
                context.push('/expenses/detail/${expense.id}?groupId=${expense.groupId}');
              },
            ),
          ],
        ),
      ),
    );
  }


  void _showSettleUpBottomSheet(
      Group group, List<Balance> balances) {
    final Map<String, double> balanceSummary = {};
    for (final b in balances) {
      if (b.fromUserId == 'user_me') {
        balanceSummary[b.toUserId] =
            (balanceSummary[b.toUserId] ?? 0) + b.amount;
      } else if (b.toUserId == 'user_me') {
        balanceSummary[b.fromUserId] =
            (balanceSummary[b.fromUserId] ?? 0) - b.amount;
      }
    }

    final candidates = group.members
        .where((m) =>
            m.id != 'user_me' && balanceSummary.containsKey(m.id))
        .toList();

    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active balances to settle!'),
          backgroundColor: _kSuccess,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 40,
              height: 4,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Settle Up with Member',
              style: TextStyle(
                  color: _kText, fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              itemCount: candidates.length,
              itemBuilder: (context, index) {
                final member = candidates[index];
                final bal = balanceSummary[member.id] ?? 0.0;
                final youOwe = bal > 0;
                final displayBal = bal.abs().toInt();

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: _kPurpleLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _kPurple.withValues(alpha: 0.15),
                      child: Text(member.name[0],
                          style: const TextStyle(
                              color: _kPurple, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(member.name,
                        style: const TextStyle(
                            color: _kText, fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      youOwe
                          ? 'You owe ₹$displayBal'
                          : 'Owes you ₹$displayBal',
                      style: TextStyle(
                          color: youOwe ? _kError : _kSuccess,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded,
                        color: _kPurple, size: 14),
                    onTap: () {
                      Navigator.pop(context);
                      _showSettlementAmountDialog(group, member, bal);
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSettlementAmountDialog(
      Group group, GroupMember member, double balance) {
    final controller =
        TextEditingController(text: balance.abs().toStringAsFixed(0));
    bool isFullSettlement = true;
    final youOwe = balance > 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: _kCard,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22)),
          title: Text(
            youOwe ? 'Pay ${member.name}' : 'Receive from ${member.name}',
            style: const TextStyle(
                color: _kText, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Net balance: ₹${balance.abs().toInt()}',
                style: TextStyle(
                    color: youOwe ? _kError : _kSuccess,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        isFullSettlement = true;
                        controller.text =
                            balance.abs().toStringAsFixed(0);
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          gradient: isFullSettlement
                              ? const LinearGradient(
                                  colors: [_kPurpleDark, _kPurple])
                              : null,
                          color:
                              isFullSettlement ? null : _kPurpleLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('Full',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isFullSettlement
                                  ? Colors.white
                                  : _kSub,
                              fontWeight: FontWeight.bold,
                            )),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => isFullSettlement = false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          gradient: !isFullSettlement
                              ? const LinearGradient(
                                  colors: [_kPurpleDark, _kPurple])
                              : null,
                          color:
                              !isFullSettlement ? null : _kPurpleLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('Partial',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: !isFullSettlement
                                  ? Colors.white
                                  : _kSub,
                              fontWeight: FontWeight.bold,
                            )),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: _kPurpleLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: controller,
                  enabled: !isFullSettlement,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                      color: _kText, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    labelStyle: TextStyle(color: _kSub),
                    prefixText: '₹ ',
                    prefixStyle:
                        TextStyle(color: _kPurple, fontWeight: FontWeight.bold),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('CANCEL',
                  style: TextStyle(color: _kSub)),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text('CONFIRM',
                  style: TextStyle(
                      color: _kPurple, fontWeight: FontWeight.bold)),
              onPressed: () {
                final amt =
                    double.tryParse(controller.text.trim()) ?? 0.0;
                if (amt <= 0) return;
                if (youOwe) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Only the receiver can confirm this settlement. Please ask ${member.name} to confirm receipt.'),
                      backgroundColor: _kError,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                  Navigator.pop(context);
                  return;
                }

                ref
                    .read(settlementRepositoryProvider)
                    .settleDebt(
                      groupId: group.id,
                      debtorId: member.id,
                      creditorId: 'user_me',
                      amount: amt,
                    )
                    .then((_) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Settled ₹${amt.toInt()} with ${member.name}!'),
                      backgroundColor: _kSuccess,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }).catchError((err) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed: $err'),
                      backgroundColor: _kError,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveMemberConfirmation(
      String groupId, String memberId, String memberName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22)),
        title: Text('Remove $memberName?',
            style: const TextStyle(
                color: _kText, fontWeight: FontWeight.bold)),
        content: Text(
            'Are you sure you want to remove $memberName from this nest?',
            style: const TextStyle(color: _kSub)),
        actions: [
          TextButton(
            child: const Text('CANCEL',
                style: TextStyle(color: _kSub)),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('REMOVE',
                style: TextStyle(color: _kError)),
            onPressed: () {
              ref
                  .read(groupsListProvider.notifier)
                  .removeMember(groupId, memberId)
                  .then((_) => Navigator.pop(context));
            },
          ),
        ],
      ),
    );
  }

  void _showLeaveGroupConfirmation(Group group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22)),
        title: Text('Leave ${group.name}?',
            style: const TextStyle(
                color: _kText, fontWeight: FontWeight.bold)),
        content: const Text(
            'Are you sure you want to leave this nest group?',
            style: TextStyle(color: _kSub)),
        actions: [
          TextButton(
            child: const Text('CANCEL',
                style: TextStyle(color: _kSub)),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('LEAVE',
                style: TextStyle(color: _kError)),
            onPressed: () {
              ref
                  .read(groupsListProvider.notifier)
                  .leaveGroup(group.id, 'user_me')
                  .then((_) {
                Navigator.pop(context);
                context.pop();
              });
            },
          ),
        ],
      ),
    );
  }
}


