import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../groups/presentation/providers/groups_provider.dart';
import '../../../ledger/presentation/providers/ledger_provider.dart';
import 'package:splitnest/features/expenses/domain/models/expense.dart';
import 'package:splitnest/features/groups/domain/models/group.dart';
import '../providers/analytics_provider.dart';

class CalendarEvent {
  final String id;
  final String title;
  final String description;
  final double amount;
  final DateTime dateTime;
  final String
  type; // 'Expense', 'Settlement', 'Pending', 'Payment', 'CycleStart', 'CycleEnd'
  final Color color;
  final String routePath;
  final String category;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.dateTime,
    required this.type,
    required this.color,
    required this.routePath,
    this.category = '',
  });
}

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime _currentMonth = DateTime.now();
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Generate 42 days (6 weeks) for calendar month grid starting from Monday
  List<DateTime> _generateCalendarDays(DateTime monthDate) {
    final firstDayOfMonth = DateTime(monthDate.year, monthDate.month, 1);
    final int prefixDays =
        firstDayOfMonth.weekday - 1; // weekday: 1 (Mon) to 7 (Sun)
    final startOfGrid = firstDayOfMonth.subtract(Duration(days: prefixDays));
    return List.generate(42, (index) => startOfGrid.add(Duration(days: index)));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  @override
  Widget build(BuildContext context) {
    final groupsState = ref.watch(groupsListProvider);
    final allEvents = ref.watch(calendarEventsProvider);

    // Group all events by date (ignoring time)
    Map<String, List<CalendarEvent>> eventsByDate = {};
    for (final ev in allEvents) {
      final dateKey =
          '${ev.dateTime.year}-${ev.dateTime.month}-${ev.dateTime.day}';
      eventsByDate.putIfAbsent(dateKey, () => []).add(ev);
    }

    // Filter events for the current selected month
    final monthEvents = allEvents
        .where((e) => _isSameMonth(e.dateTime, _currentMonth))
        .toList();

    return Scaffold(
      backgroundColor: const Color(
        0xFFF3F0FF,
      ), // Premium soft light violet background
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            // Tab Bar with 3D styling
            _buildTabBar(),

            // Tab View Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(eventsByDate),
                  _buildExpensesTab(monthEvents),
                  _buildSettlementsTab(monthEvents),
                  _buildAnalyticsTab(allEvents, groupsState.groups),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7B61FF).withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF7B61FF),
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analytics Center',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1A3F),
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Financial Ops & Predictive Trends',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF8C8CA1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B61FF).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorPadding: const EdgeInsets.symmetric(
          vertical: 2,
          horizontal: 0,
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: 16),
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withOpacity(0.35),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF8C8CA1),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Expenses'),
          Tab(text: 'Settlements'),
          Tab(text: 'Analytics'),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. OVERVIEW TAB (Calendar Month grid + date specific list)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildOverviewTab(Map<String, List<CalendarEvent>> eventsByDate) {
    final gridDays = _generateCalendarDays(_currentMonth);
    final selectedDayKey =
        '${_selectedDay.year}-${_selectedDay.month}-${_selectedDay.day}';
    final selectedDayEvents = eventsByDate[selectedDayKey] ?? [];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Month Selector Panel
            _buildMonthSelector(),
            const SizedBox(height: 16),

            // Month View Calendar Panel
            _buildMonthCalendar(gridDays, eventsByDate),
            const SizedBox(height: 24),

            // Selected Day Header
            _buildSelectedDayHeader(),
            const SizedBox(height: 12),

            // Selected Day Events List
            _buildEventsList(selectedDayEvents),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    final monthName = DateFormat('MMMM yyyy').format(_currentMonth);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEBE9F5), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF7B61FF),
              size: 16,
            ),
            onPressed: () {
              setState(() {
                _currentMonth = DateTime(
                  _currentMonth.year,
                  _currentMonth.month - 1,
                  1,
                );
              });
            },
          ),
          Text(
            monthName,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A3F),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0xFF7B61FF),
              size: 16,
            ),
            onPressed: () {
              setState(() {
                _currentMonth = DateTime(
                  _currentMonth.year,
                  _currentMonth.month + 1,
                  1,
                );
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMonthCalendar(
    List<DateTime> gridDays,
    Map<String, List<CalendarEvent>> eventsByDate,
  ) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B61FF).withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFEBE9F5), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdays.map((day) {
              return SizedBox(
                width: 36,
                child: Center(
                  child: Text(
                    day.substring(0, 1),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF8C8CA1),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFEBE9F5)),
          const SizedBox(height: 12),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 10,
              crossAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            itemCount: 42,
            itemBuilder: (context, index) {
              final day = gridDays[index];
              final isSelected = _isSameDay(day, _selectedDay);
              final isToday = _isSameDay(day, DateTime.now());
              final isCurrentMonth = day.month == _currentMonth.month;

              final dateKey = '${day.year}-${day.month}-${day.day}';
              final dayEvents = eventsByDate[dateKey] ?? [];

              final uniqueTypes = dayEvents.map((e) => e.type).toSet();

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDay = day;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    border: isToday && !isSelected
                        ? Border.all(color: const Color(0xFF7B61FF), width: 1.5)
                        : null,
                    color: isSelected
                        ? null
                        : isToday
                        ? const Color(0xFFEDE9FE)
                        : Colors.transparent,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        top: 6,
                        child: Text(
                          '${day.day}',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: isSelected || isToday
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : isCurrentMonth
                                ? const Color(0xFF1A1A3F)
                                : const Color(0xFFC5C5D3),
                          ),
                        ),
                      ),
                      if (uniqueTypes.isNotEmpty)
                        Positioned(
                          bottom: 4,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: uniqueTypes.take(4).map((type) {
                              Color dotColor;
                              switch (type) {
                                case 'Expense':
                                  dotColor = const Color(0xFF7B61FF);
                                  break;
                                case 'Settlement':
                                  dotColor = const Color(0xFF10B981);
                                  break;
                                case 'Pending':
                                  dotColor = const Color(0xFFEF4444);
                                  break;
                                case 'Payment':
                                  dotColor = const Color(0xFF3B82F6);
                                  break;
                                case 'CycleStart':
                                  dotColor = const Color(0xFF8B5CF6);
                                  break;
                                case 'CycleEnd':
                                  dotColor = const Color(0xFFD946EF);
                                  break;
                                default:
                                  dotColor = Colors.grey;
                              }

                              return Container(
                                width: 4.5,
                                height: 4.5,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 0.8,
                                ),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? Colors.white : dotColor,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDayHeader() {
    final formattedDate = DateFormat('EEEE, d MMMM yyyy').format(_selectedDay);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            formattedDate,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A3F),
            ),
          ),
        ),
        GestureDetector(
          onTap: _showColorLegendSheet,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF7B61FF).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF7B61FF),
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  'Legend',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF7B61FF),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventsList(List<CalendarEvent> events) {
    if (events.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFEBE9F5)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              color: Color(0xFF7B61FF),
              size: 20,
            ),
            const SizedBox(height: 12),
            Text(
              'No Operations Scheduled',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A3F),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Add expenses or payments to populate this date.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF8C8CA1),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final ev = events[index];

        IconData iconData;
        String typeLabel;
        switch (ev.type) {
          case 'Expense':
            iconData = Icons.receipt_long_rounded;
            typeLabel = 'Group Expense';
            break;
          case 'PersonalExpense':
            iconData = Icons.receipt_rounded;
            typeLabel = 'Personal Expense';
            break;
          case 'Settlement':
            iconData = Icons.handshake_rounded;
            typeLabel = 'Group Settlement';
            break;
          case 'PersonalSettlement':
            iconData = Icons.currency_exchange_rounded;
            typeLabel = 'Personal Settlement';
            break;
          case 'PendingExpense':
          case 'PendingSettlement':
          case 'Pending':
            iconData = Icons.hourglass_empty_rounded;
            typeLabel = 'Pending Transaction';
            break;
          case 'Income':
            iconData = Icons.savings_rounded;
            typeLabel = 'Income';
            break;
          case 'Payment':
            iconData = Icons.check_circle_rounded;
            typeLabel = 'Payment Complete';
            break;
          case 'CycleStart':
            iconData = Icons.play_circle_filled_rounded;
            typeLabel = 'Cycle Start';
            break;
          case 'CycleEnd':
            iconData = Icons.cached_rounded;
            typeLabel = 'Cycle Rollover';
            break;
          default:
            iconData = Icons.event_rounded;
            typeLabel = 'Event';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEBE9F5)),
          ),
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              onTap: () => context.push(ev.routePath),
              leading: CircleAvatar(
                backgroundColor: ev.color.withOpacity(0.08),
                child: Icon(iconData, color: ev.color, size: 18),
              ),
              title: Text(
                ev.title,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A3F),
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    typeLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: ev.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ev.description,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF6B6B8A),
                    ),
                  ),
                ],
              ),
              trailing: ev.amount > 0
                  ? Text(
                      '₹${ev.amount.toStringAsFixed(0)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: ev.color,
                      ),
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. EXPENSES TAB (Expense category breakdown & list)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildExpensesTab(List<CalendarEvent> monthEvents) {
    final expenses = monthEvents.where((e) => e.type == 'Expense' || e.type == 'PersonalExpense' || e.type == 'PendingExpense').toList();
    final double totalExpenses = expenses.fold(0.0, (sum, e) => sum + e.amount);

    // Group expenses by category
    Map<String, double> categoriesMap = {};
    for (final exp in expenses) {
      final cat = exp.category.isNotEmpty ? exp.category : 'Others';
      categoriesMap[cat] = (categoriesMap[cat] ?? 0.0) + exp.amount;
    }

    // Sort categories largest first
    final sortedCategories = categoriesMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            // Premium 3D Card showing monthly total
            _buildFintech3DCard(
              title: 'Total Expenses This Month',
              value: '₹${totalExpenses.toStringAsFixed(0)}',
              subtitle: 'Across active Nest groups',
              gradientColors: [
                const Color(0xFF7B61FF),
                const Color(0xFF6366F1),
              ],
              illustration: Icons.trending_up_rounded,
            ),
            const SizedBox(height: 24),

            // Category Breakdown Title
            Text(
              'Category Breakdown',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A3F),
              ),
            ),
            const SizedBox(height: 12),

            if (sortedCategories.isEmpty)
              _buildEmptyState('No expenses logged for this month.')
            else
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFEBE9F5)),
                ),
                child: Column(
                  children: sortedCategories.map((entry) {
                    final catName = entry.key;
                    final amt = entry.value;
                    final pct = totalExpenses > 0 ? amt / totalExpenses : 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                catName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: const Color(0xFF1A1A3F),
                                ),
                              ),
                              Text(
                                '₹${amt.toStringAsFixed(0)} (${(pct * 100).toStringAsFixed(0)}%)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: const Color(0xFF7B61FF),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: pct.clamp(0.0, 1.0),
                              minHeight: 8,
                              backgroundColor: const Color(0xFFF3F0FF),
                              color: const Color(0xFF7B61FF),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 24),

            // Expense List Section
            Text(
              'Expense Logs',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A3F),
              ),
            ),
            const SizedBox(height: 12),
            if (expenses.isEmpty)
              _buildEmptyState('No transactions found.')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: expenses.length,
                itemBuilder: (context, index) {
                  final exp = expenses[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFEBE9F5)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: ListTile(
                        onTap: () => context.push(exp.routePath),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFF3F0FF),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: Color(0xFF7B61FF),
                            size: 18,
                          ),
                        ),
                        title: Text(
                          exp.title,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1A3F),
                          ),
                        ),
                        subtitle: Text(
                          DateFormat('dd MMM yyyy').format(exp.dateTime),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF8C8CA1),
                          ),
                        ),
                        trailing: Text(
                          '₹${exp.amount.toStringAsFixed(0)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF7B61FF),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. SETTLEMENTS TAB (Settlement summaries & histories)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildSettlementsTab(List<CalendarEvent> monthEvents) {
    final settlements = monthEvents
        .where((e) => e.type == 'Settlement' || e.type == 'PersonalSettlement' || e.type == 'PendingSettlement')
        .toList();
    final double totalSettlements = settlements.fold(
      0.0,
      (sum, e) => sum + e.amount,
    );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            // Premium Green 3D card
            _buildFintech3DCard(
              title: 'Total Settled This Month',
              value: '₹${totalSettlements.toStringAsFixed(0)}',
              subtitle: 'Debt clearings & group payouts',
              gradientColors: [
                const Color(0xFF10B981),
                const Color(0xFF059669),
              ],
              illustration: Icons.check_circle_outline_rounded,
            ),
            const SizedBox(height: 24),

            // Historical Settlement timeline
            Text(
              'Settlement Log',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A3F),
              ),
            ),
            const SizedBox(height: 12),
            if (settlements.isEmpty)
              _buildEmptyState('No settlements recorded for this month.')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: settlements.length,
                itemBuilder: (context, index) {
                  final set = settlements[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFEBE9F5)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: ListTile(
                        onTap: () => context.push(set.routePath),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFE8F5E9),
                          child: const Icon(
                            Icons.handshake_rounded,
                            color: Color(0xFF10B981),
                            size: 18,
                          ),
                        ),
                        title: Text(
                          set.title,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1A3F),
                          ),
                        ),
                        subtitle: Text(
                          set.description,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF6B6B8A),
                          ),
                        ),
                        trailing: Text(
                          '₹${set.amount.toStringAsFixed(0)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 4. ANALYTICS TAB (Custom charts and trends)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildAnalyticsTab(List<CalendarEvent> allEvents, List<Group> groups) {
    // 1. Calculate category statistics for Donut chart
    final expenses = allEvents.where((e) => e.type == 'Expense' || e.type == 'PersonalExpense' || e.type == 'PendingExpense').toList();
    final double totalExpenses = expenses.fold(0.0, (sum, e) => sum + e.amount);

    Map<String, double> categoryDistribution = {};
    for (final exp in expenses) {
      final cat = exp.category.isNotEmpty ? exp.category : 'Others';
      categoryDistribution[cat] =
          (categoryDistribution[cat] ?? 0.0) + exp.amount;
    }

    // Pie chart values & colors
    final colorsList = [
      const Color(0xFF7B61FF), // Purple
      const Color(0xFF10B981), // Green
      const Color(0xFF3B82F6), // Blue
      const Color(0xFFFF8C42), // Orange
      const Color(0xFFD946EF), // Fuchsia
      const Color(0xFFEF4444), // Red
    ];

    List<double> chartValues = [];
    List<Color> chartColors = [];
    int colorIdx = 0;

    categoryDistribution.forEach((key, val) {
      chartValues.add(val);
      chartColors.add(colorsList[colorIdx % colorsList.length]);
      colorIdx++;
    });

    // 2. Expense Trend over last 6 months
    final now = DateTime.now();
    List<double> monthlyTotals = List.filled(6, 0.0);
    List<String> monthLabels = List.filled(6, '');

    for (int i = 0; i < 6; i++) {
      final monthDate = DateTime(now.year, now.month - (5 - i), 1);
      monthLabels[i] = DateFormat('MMM').format(monthDate);

      monthlyTotals[i] = expenses
          .where(
            (e) =>
                e.dateTime.year == monthDate.year &&
                e.dateTime.month == monthDate.month,
          )
          .fold(0.0, (sum, e) => sum + e.amount);
    }

    // 3. Double bar chart: Settled vs Pending comparison per month (last 4 months)
    List<double> monthlySettled = List.filled(4, 0.0);
    List<double> monthlyPending = List.filled(4, 0.0);
    List<String> comparisonLabels = List.filled(4, '');

    for (int i = 0; i < 4; i++) {
      final monthDate = DateTime(now.year, now.month - (3 - i), 1);
      comparisonLabels[i] = DateFormat('MMM').format(monthDate);

      // Settled in this month
      monthlySettled[i] = allEvents
          .where(
            (e) =>
                (e.type == 'Settlement' || e.type == 'PersonalSettlement') &&
                e.dateTime.year == monthDate.year &&
                e.dateTime.month == monthDate.month,
          )
          .fold(0.0, (sum, e) => sum + e.amount);

      // Pending (ledger status Pending) in this month
      monthlyPending[i] = allEvents
          .where(
            (e) =>
                (e.type == 'Pending' || e.type == 'PendingExpense' || e.type == 'PendingSettlement') &&
                e.dateTime.year == monthDate.year &&
                e.dateTime.month == monthDate.month,
          )
          .fold(0.0, (sum, e) => sum + e.amount);
    }

    // 4. Monthly Comparison (This vs Last)
    final thisMonthExp = monthlyTotals.last;
    final lastMonthExp = monthlyTotals[monthlyTotals.length - 2];
    double monthlyDiffPct = 0.0;
    if (lastMonthExp > 0) {
      monthlyDiffPct = ((thisMonthExp - lastMonthExp) / lastMonthExp) * 100;
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Donut Pie Chart Card
            Text(
              'Category Allocation',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A3F),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: const Color(0xFFEBE9F5)),
              ),
              child: Column(
                children: [
                  if (categoryDistribution.isEmpty)
                    _buildEmptyState('No expense data available.')
                  else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 140,
                          height: 140,
                          child: CustomPaint(
                            painter: DonutChartPainter(
                              values: chartValues,
                              colors: chartColors,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Legend
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: categoryDistribution.entries.map((entry) {
                        final catName = entry.key;
                        final amt = entry.value;
                        final index = categoryDistribution.keys
                            .toList()
                            .indexOf(catName);
                        final color = chartColors[index];
                        final pct = totalExpenses > 0
                            ? (amt / totalExpenses * 100)
                            : 0.0;

                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$catName: ${pct.toStringAsFixed(0)}%',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A1A3F),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Expense Trend Card (Line Chart)
            Text(
              'Expense Trend (Last 6 Months)',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A3F),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: const Color(0xFFEBE9F5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 140,
                    child: CustomPaint(
                      painter: LineChartPainter(
                        values: monthlyTotals,
                        labels: monthLabels,
                        lineColor: const Color(0xFF7B61FF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Settlement vs Pending (Double Bar Chart)
            Text(
              'Settlements vs Pending Requests',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A3F),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: const Color(0xFFEBE9F5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 140,
                    child: CustomPaint(
                      painter: BarChartPainter(
                        settledValues: monthlySettled,
                        pendingValues: monthlyPending,
                        labels: comparisonLabels,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            color: const Color(0xFF10B981),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Settled',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            color: const Color(0xFFEF4444),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Pending',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Monthly Comparison (Delta)
            Text(
              'Monthly Comparison',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A3F),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: const Color(0xFFEBE9F5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Last Month',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF8C8CA1),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${lastMonthExp.toStringAsFixed(0)}',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1A3F),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1.5,
                    height: 40,
                    color: const Color(0xFFEBE9F5),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'This Month',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF8C8CA1),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${thisMonthExp.toStringAsFixed(0)}',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1A3F),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: monthlyDiffPct >= 0
                          ? const Color(0xFFFFEBEE)
                          : const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          monthlyDiffPct >= 0
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          color: monthlyDiffPct >= 0
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF10B981),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${monthlyDiffPct.abs().toStringAsFixed(0)}%',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: monthlyDiffPct >= 0
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Cycle Comparison (Nest vs Nest comparison)
            Text(
              'Cycle Settlement Comparison',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A3F),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: const Color(0xFFEBE9F5)),
              ),
              child: Column(
                children: [
                  if (groups.isEmpty)
                    _buildEmptyState('No Nest groups active.')
                  else
                    ...groups.map((group) {
                      final stats = ref
                          .watch(cycleStatsProvider(group.id))
                          .value;
                      final pct = (stats != null && stats.totalExpenses > 0)
                          ? (stats.totalSettled / stats.totalExpenses)
                          : 0.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  group.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: const Color(0xFF1A1A3F),
                                  ),
                                ),
                                Text(
                                  '${(pct * 100).toStringAsFixed(0)}% Settled',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: const Color(0xFF8B5CF6),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: pct.clamp(0.0, 1.0),
                                minHeight: 6,
                                backgroundColor: const Color(0xFFF3F0FF),
                                color: const Color(0xFF8B5CF6),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Bills: ₹${(stats?.totalExpenses ?? 0).toStringAsFixed(0)} • Pending: ₹${(stats?.totalPending ?? 0).toStringAsFixed(0)}',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: const Color(0xFF8C8CA1),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildFintech3DCard({
    required String title,
    required String value,
    required String subtitle,
    required List<Color> gradientColors,
    required IconData illustration,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withOpacity(0.15),
            child: Icon(illustration, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEBE9F5)),
      ),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: const Color(0xFF8C8CA1),
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  void _showColorLegendSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Calendar Color Coding',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1A3F),
                ),
              ),
              const SizedBox(height: 16),
              _buildLegendRow(
                const Color(0xFF7B61FF),
                'Expense (Purple)',
                'Group expense split transaction',
              ),
              _buildLegendRow(
                const Color(0xFF10B981),
                'Settlement (Green)',
                'Group settlement payment',
              ),
              _buildLegendRow(
                const Color(0xFFEF4444),
                'Pending (Red)',
                'Unsettled personal ledger request',
              ),
              _buildLegendRow(
                const Color(0xFF3B82F6),
                'Payment (Blue)',
                'Settled personal ledger transaction',
              ),
              _buildLegendRow(
                const Color(0xFF8B5CF6),
                'Cycle Start (Indigo)',
                'Start of a nest billing cycle',
              ),
              _buildLegendRow(
                const Color(0xFFD946EF),
                'Cycle End (Fuchsia)',
                'End/Rollover of a nest billing cycle',
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendRow(Color color, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A3F),
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF8C8CA1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTERS FOR CHARTS
// ─────────────────────────────────────────────────────────────────────────────

// Donut Pie Chart Painter
class DonutChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  DonutChartPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final double total = values.fold(0.0, (sum, val) => sum + val);
    if (total == 0.0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -math.pi / 2;

    for (int i = 0; i < values.length; i++) {
      final sweepAngle = (values[i] / total) * 2 * math.pi;

      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = colors[i];

      // Draw segment slice
      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);

      startAngle += sweepAngle;
    }

    // Draw center cutout for Donut chart effect (glassmorphism/white)
    final cutoutPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;

    canvas.drawCircle(center, radius * 0.6, cutoutPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Glowing Line Chart Painter for Expense Trend
class LineChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final Color lineColor;

  LineChartPainter({
    required this.values,
    required this.labels,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final double maxVal = values.reduce(math.max);
    final double divisor = maxVal == 0 ? 1.0 : maxVal;

    final int numPoints = values.length;
    final double stepX = size.width / (numPoints - 1);

    final List<Offset> points = [];
    for (int i = 0; i < numPoints; i++) {
      final x = i * stepX;
      final y = size.height - 24 - (values[i] / divisor) * (size.height - 40);
      points.add(Offset(x, y));
    }

    for (int i = 0; i < numPoints; i++) {
      // Draw X label
      final textSpan = TextSpan(
        text: labels[i],
        style: GoogleFonts.plusJakartaSans(
          color: const Color(0xFF8C8CA1),
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      );
      final tp = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(points[i].dx - tp.width / 2, size.height - 14));
    }

    // 2. Draw Area Gradient
    if (points.isNotEmpty) {
      final areaPath = Path()..moveTo(points.first.dx, size.height - 24);
      for (final p in points) {
        areaPath.lineTo(p.dx, p.dy);
      }
      areaPath.lineTo(points.last.dx, size.height - 24);
      areaPath.close();

      final areaPaint = Paint()
        ..shader = LinearGradient(
          colors: [lineColor.withOpacity(0.35), lineColor.withOpacity(0.0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTRB(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill;

      canvas.drawPath(areaPath, areaPaint);
    }

    // 3. Draw Trend Line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // 4. Draw Glow Shadow
    final glowPaint = Paint()
      ..color = lineColor.withOpacity(0.2)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, glowPaint);

    // 5. Draw Dots & Amount tooltips
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      canvas.drawCircle(p, 5.0, dotPaint);
      canvas.drawCircle(p, 5.0, borderPaint);

      // Draw tiny amount label above point if > 0
      if (values[i] > 0) {
        final amtSpan = TextSpan(
          text: '₹${values[i].toStringAsFixed(0)}',
          style: GoogleFonts.plusJakartaSans(
            color: lineColor,
            fontSize: 8,
            fontWeight: FontWeight.w800,
          ),
        );
        final amtTp = TextPainter(
          text: amtSpan,
          textDirection: ui.TextDirection.ltr,
        );
        amtTp.layout();
        amtTp.paint(canvas, Offset(p.dx - amtTp.width / 2, p.dy - 16));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Side-by-side Double Bar Chart Painter for Settlements (Green) vs Pending (Red)
class BarChartPainter extends CustomPainter {
  final List<double> settledValues;
  final List<double> pendingValues;
  final List<String> labels;

  BarChartPainter({
    required this.settledValues,
    required this.pendingValues,
    required this.labels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (settledValues.isEmpty) return;

    final double maxVal = [...settledValues, ...pendingValues].reduce(math.max);
    final double divisor = maxVal == 0 ? 1.0 : maxVal;

    final int numGroups = settledValues.length;
    final double padding = 20.0;
    final double groupWidth = (size.width - 2 * padding) / numGroups;
    final double barWidth = groupWidth * 0.28;

    for (int i = 0; i < numGroups; i++) {
      final double groupCenterX = padding + (i * groupWidth) + (groupWidth / 2);

      // Y positions
      final double settledY =
          size.height - 24 - (settledValues[i] / divisor) * (size.height - 40);
      final double pendingY =
          size.height - 24 - (pendingValues[i] / divisor) * (size.height - 40);

      // 1. Draw Settled Bar (Green)
      final settledPaint = Paint()
        ..color = const Color(0xFF10B981)
        ..style = PaintingStyle.fill;
      final settledRect = Rect.fromLTRB(
        groupCenterX - barWidth - 2,
        settledY,
        groupCenterX - 2,
        size.height - 24,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(settledRect, const Radius.circular(4)),
        settledPaint,
      );

      // 2. Draw Pending Bar (Red)
      final pendingPaint = Paint()
        ..color = const Color(0xFFEF4444)
        ..style = PaintingStyle.fill;
      final pendingRect = Rect.fromLTRB(
        groupCenterX + 2,
        pendingY,
        groupCenterX + barWidth + 2,
        size.height - 24,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(pendingRect, const Radius.circular(4)),
        pendingPaint,
      );

      // 3. Draw Labels
      final labelSpan = TextSpan(
        text: labels[i],
        style: GoogleFonts.plusJakartaSans(
          color: const Color(0xFF8C8CA1),
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      );
      final labelTp = TextPainter(
        text: labelSpan,
        textDirection: ui.TextDirection.ltr,
      );
      labelTp.layout();
      labelTp.paint(
        canvas,
        Offset(groupCenterX - labelTp.width / 2, size.height - 14),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
