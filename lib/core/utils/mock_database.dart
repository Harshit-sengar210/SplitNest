import 'dart:async';
import '../../features/groups/domain/models/group.dart';
import '../../features/groups/domain/models/cycle_stats.dart';
import '../../features/groups/domain/models/cycle_report.dart';
import '../../features/expenses/domain/models/expense.dart';
import '../../features/settlement/domain/models/settlement.dart';
import '../../features/settlement/domain/models/balance.dart';
import '../../features/activity/domain/models/activity.dart';
import '../../features/activity/domain/models/app_notification.dart';

class MockDatabase {
  static final MockDatabase _instance = MockDatabase._internal();
  factory MockDatabase() => _instance;

  MockDatabase._internal() {
    _initData();
  }

  final List<Group> groups = [];
  final List<Expense> expenses = [];
  final List<Balance> balances = [];
  final List<Settlement> settlements = [];
  final List<Activity> activities = [];
  final List<AppNotification> notifications = [];
  final List<CycleReport> cycleReports = [];

  // Notifications system stream
  final StreamController<String> _notificationsController = StreamController<String>.broadcast();
  Stream<String> get notificationsStream => _notificationsController.stream;

  void addNotification({
    required String title,
    required String description,
    required String type,
    String? relatedItemId,
    String? groupId,
  }) {
    notifications.insert(0, AppNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}_${notifications.length}',
      title: title,
      description: description,
      type: type,
      relatedItemId: relatedItemId,
      groupId: groupId,
      timestamp: DateTime.now(),
      isRead: false,
    ));
    triggerChange();
  }

  int _changeCount = 0;
  // Stream to notify repositories when database state changes (real-time updates)
  final StreamController<int> _changeController = StreamController<int>.broadcast();
  Stream<int> get changeStream => _changeController.stream;

  void triggerChange() {
    _changeCount++;
    _changeController.add(_changeCount);
  }

  void triggerNotification(String message) {
    _notificationsController.add(message);
  }

  void _initData() {
    final now = DateTime.now();

    // Initialize initial mock notifications
    notifications.addAll([
      AppNotification(
        id: 'notif_1',
        title: 'Flat 402 Roomies',
        description: 'Rahul added a new expense\nDinner at Zomato - ₹850',
        type: 'expense_added',
        relatedItemId: 'exp_2',
        groupId: 'nest_1',
        timestamp: now.subtract(const Duration(minutes: 2)),
        isRead: false,
      ),
      AppNotification(
        id: 'notif_2',
        title: 'Payment Received',
        description: 'You received ₹1,200 from Priya\nfor Goa Trip',
        type: 'payment_received',
        relatedItemId: '3',
        timestamp: now.subtract(const Duration(minutes: 15)),
        isRead: false,
      ),
      AppNotification(
        id: 'notif_3',
        title: 'New Member Joined',
        description: 'Arjun joined "Europe Trip 2026"\ngroup',
        type: 'member_joined',
        groupId: 'nest_2',
        timestamp: now.subtract(const Duration(hours: 1)),
        isRead: false,
      ),
      AppNotification(
        id: 'notif_4',
        title: 'Europe Trip 2026',
        description: 'Your expense was settled by\nVikas - ₹2,500',
        type: 'settlement_received',
        relatedItemId: 'settle_1',
        groupId: 'nest_2',
        timestamp: now.subtract(const Duration(hours: 5)),
        isRead: true,
      ),
      AppNotification(
        id: 'notif_5',
        title: 'New Nest Created',
        description: 'Vikas created the "Europe Trip 2026"\nnest',
        type: 'nest_created',
        groupId: 'nest_2',
        timestamp: now.subtract(const Duration(days: 1)),
        isRead: true,
      ),
      AppNotification(
        id: 'notif_6',
        title: 'Invite Bonus Earned',
        description: 'You earned ₹50 for inviting\nRohit to SplitNest',
        type: 'payment_received',
        timestamp: now.subtract(const Duration(days: 1)),
        isRead: true,
      ),
      AppNotification(
        id: 'notif_7',
        title: 'Payment Reminder',
        description: 'Settle your pending balance of ₹450\nin Flat 402 Roomies',
        type: 'payment_request',
        groupId: 'nest_1',
        timestamp: now.subtract(const Duration(days: 1)),
        isRead: true,
      ),
      AppNotification(
        id: 'notif_8',
        title: 'System Update',
        description: "We've updated our privacy policy\nand terms of service",
        type: 'system_update',
        timestamp: now.subtract(const Duration(days: 2)),
        isRead: true,
      ),
    ]);

    // 1. Initialize Groups
    groups.addAll([
      Group(
        id: 'nest_1',
        name: 'Flat 402 Roomies',
        description: 'Monthly flat rent, utility splits, and household items.',
        membersCount: 4,
        pendingBalance: 0.0, // Calculated dynamically
        type: 'Flatmates',
        status: 'Settled',
        createdBy: 'user_me',
        createdAt: now.subtract(const Duration(days: 30)),
        totalExpenses: 0.0, // Calculated dynamically
        totalPending: 0.0,  // Calculated dynamically
        totalSettled: 0.0,  // Calculated dynamically
        inviteCode: 'FLAT402',
        members: [
          GroupMember(id: 'user_me', name: 'You', email: 'user@example.com', role: MemberRole.admin, photoUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80'),
          GroupMember(id: 'user_sarah', name: 'Sarah', email: 'sarah@example.com', role: MemberRole.member, photoUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=150&q=80'),
          GroupMember(id: 'user_mike', name: 'Mike', email: 'mike@example.com', role: MemberRole.member, photoUrl: 'https://images.unsplash.com/photo-1599566150163-29194dcaad36?auto=format&fit=crop&w=150&q=80'),
          GroupMember(id: 'user_emily', name: 'Emily', email: 'emily@example.com', role: MemberRole.member, photoUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?auto=format&fit=crop&w=150&q=80'),
        ],
      ),
      Group(
        id: 'nest_2',
        name: 'Europe Trip 2026',
        description: 'Flight bookings, hostel stay, and daily travel expenses.',
        membersCount: 4,
        pendingBalance: 0.0,
        type: 'Travel',
        status: 'Settled',
        createdBy: 'user_aman',
        createdAt: now.subtract(const Duration(days: 15)),
        totalExpenses: 0.0,
        totalPending: 0.0,
        totalSettled: 0.0,
        inviteCode: 'EURO26',
        members: [
          GroupMember(id: 'user_me', name: 'You', email: 'user@example.com', role: MemberRole.member, photoUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80'),
          GroupMember(id: 'user_aman', name: 'Aman', email: 'aman@example.com', role: MemberRole.admin, photoUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=150&q=80'),
          GroupMember(id: 'user_rohit', name: 'Rohit', email: 'rohit@example.com', role: MemberRole.member, photoUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43E?auto=format&fit=crop&w=150&q=80'),
          GroupMember(id: 'user_deepak', name: 'Deepak', email: 'deepak@example.com', role: MemberRole.member, photoUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=150&q=80'),
        ],
      ),
    ]);

    // 2. Initialize Initial Expenses
    expenses.addAll([
      Expense(
        id: 'exp_1',
        title: 'Internet Bill',
        amount: 60.00,
        category: 'Utilities',
        groupId: 'nest_1',
        paidByUserId: 'user_sarah',
        splits: [
          const ExpenseSplit(userId: 'user_sarah', amount: 20.0),
          const ExpenseSplit(userId: 'user_me', amount: 20.0),
          const ExpenseSplit(userId: 'user_mike', amount: 20.0),
        ],
        date: now.subtract(const Duration(days: 4)),
        splitMethod: 'Equal',
      ),
      Expense(
        id: 'exp_2',
        title: 'Grocery Shopping',
        amount: 120.00,
        category: 'Groceries',
        groupId: 'nest_1',
        paidByUserId: 'user_me',
        splits: [
          const ExpenseSplit(userId: 'user_me', amount: 40.0),
          const ExpenseSplit(userId: 'user_sarah', amount: 40.0),
          const ExpenseSplit(userId: 'user_mike', amount: 40.0),
        ],
        date: now.subtract(const Duration(days: 2)),
        splitMethod: 'Equal',
      ),
      Expense(
        id: 'exp_3',
        title: 'Vegetables',
        amount: 240.00,
        category: 'Groceries',
        groupId: 'nest_2',
        paidByUserId: 'user_aman',
        splits: [
          const ExpenseSplit(userId: 'user_aman', amount: 60.0),
          const ExpenseSplit(userId: 'user_rohit', amount: 60.0),
          const ExpenseSplit(userId: 'user_deepak', amount: 60.0),
          const ExpenseSplit(userId: 'user_me', amount: 60.0),
        ],
        date: now.subtract(const Duration(days: 1)),
        splitMethod: 'Equal',
      ),
    ]);

    // 3. Log initial activities matching setup
    activities.addAll([
      Activity(
        id: 'act_init_1',
        groupId: 'nest_1',
        actorId: 'user_me',
        activityType: 'group_created',
        title: 'Group Created',
        description: 'You created the group Flat 402 Roomies',
        createdAt: now.subtract(const Duration(days: 30)),
        actorName: 'You',
        groupName: 'Flat 402 Roomies',
      ),
      Activity(
        id: 'act_init_2',
        groupId: 'nest_1',
        actorId: 'user_sarah',
        activityType: 'member_joined',
        title: 'Member Joined',
        description: 'Sarah joined Flat 402 Roomies',
        createdAt: now.subtract(const Duration(days: 29)),
        actorName: 'Sarah',
        groupName: 'Flat 402 Roomies',
      ),
      Activity(
        id: 'act_init_3',
        groupId: 'nest_1',
        actorId: 'user_mike',
        activityType: 'member_joined',
        title: 'Member Joined',
        description: 'Mike joined Flat 402 Roomies',
        createdAt: now.subtract(const Duration(days: 29)),
        actorName: 'Mike',
        groupName: 'Flat 402 Roomies',
      ),
      Activity(
        id: 'act_init_4',
        groupId: 'nest_1',
        actorId: 'user_emily',
        activityType: 'member_joined',
        title: 'Member Joined',
        description: 'Emily joined Flat 402 Roomies',
        createdAt: now.subtract(const Duration(days: 28)),
        actorName: 'Emily',
        groupName: 'Flat 402 Roomies',
      ),
      Activity(
        id: 'act_init_5',
        groupId: 'nest_1',
        actorId: 'user_sarah',
        activityType: 'expense_created',
        title: 'Expense Added',
        description: 'Sarah added Internet Bill',
        amount: 60.0,
        relatedId: 'exp_1',
        createdAt: now.subtract(const Duration(days: 4)),
        actorName: 'Sarah',
        groupName: 'Flat 402 Roomies',
      ),
      Activity(
        id: 'act_init_6',
        groupId: 'nest_1',
        actorId: 'user_me',
        activityType: 'expense_created',
        title: 'Expense Added',
        description: 'You added Grocery Shopping',
        amount: 120.0,
        relatedId: 'exp_2',
        createdAt: now.subtract(const Duration(days: 2)),
        actorName: 'You',
        groupName: 'Flat 402 Roomies',
      ),
      Activity(
        id: 'act_init_7',
        groupId: 'nest_2',
        actorId: 'user_aman',
        activityType: 'group_created',
        title: 'Group Created',
        description: 'Aman created the group Europe Trip 2026',
        createdAt: now.subtract(const Duration(days: 15)),
        actorName: 'Aman',
        groupName: 'Europe Trip 2026',
      ),
      Activity(
        id: 'act_init_8',
        groupId: 'nest_2',
        actorId: 'user_me',
        activityType: 'member_joined',
        title: 'Member Joined',
        description: 'You joined Europe Trip 2026',
        createdAt: now.subtract(const Duration(days: 14)),
        actorName: 'You',
        groupName: 'Europe Trip 2026',
      ),
      Activity(
        id: 'act_init_9',
        groupId: 'nest_2',
        actorId: 'user_rohit',
        activityType: 'member_joined',
        title: 'Member Joined',
        description: 'Rohit joined Europe Trip 2026',
        createdAt: now.subtract(const Duration(days: 14)),
        actorName: 'Rohit',
        groupName: 'Europe Trip 2026',
      ),
      Activity(
        id: 'act_init_10',
        groupId: 'nest_2',
        actorId: 'user_deepak',
        activityType: 'member_joined',
        title: 'Member Joined',
        description: 'Deepak joined Europe Trip 2026',
        createdAt: now.subtract(const Duration(days: 14)),
        actorName: 'Deepak',
        groupName: 'Europe Trip 2026',
      ),
      Activity(
        id: 'act_init_11',
        groupId: 'nest_2',
        actorId: 'user_aman',
        activityType: 'expense_created',
        title: 'Expense Added',
        description: 'Aman added Vegetables',
        amount: 240.0,
        relatedId: 'exp_3',
        createdAt: now.subtract(const Duration(days: 1)),
        actorName: 'Aman',
        groupName: 'Europe Trip 2026',
      ),
    ]);

    recalculateAllBalances();
    _seedCycleHistory();
  }

  // ── Cycle History Seeding ─────────────────────────────────────────────────
  void _seedCycleHistory() {
    // Pre-populate 3 past completed cycles for each existing nest so the
    // history view has realistic data from day 1.
    final now = DateTime.now();

    // Helper: build a CycleReport with generated stats
    CycleReport _make({
      required String id,
      required String groupId,
      required DateTime start,
      required DateTime end,
      required double expenses,
      required double settled,
      required int txns,
      required int members,
    }) {
      return CycleReport(
        id: id,
        groupId: groupId,
        cycleStart: start,
        cycleEnd: end,
        totalExpenses: expenses,
        totalSettled: settled,
        totalPending: (expenses - settled).clamp(0, double.infinity),
        totalTransactions: txns,
        memberCount: members,
        archivedAt: end,
      );
    }

    // ── nest_1 (Flat 402 Roomies, cycleDate=1) ───────────────────────────
    cycleReports.addAll([
      _make(
        id: 'cr_nest1_mar',
        groupId: 'nest_1',
        start: DateTime(now.year, now.month - 3, 1),
        end: DateTime(now.year, now.month - 2, 1),
        expenses: 1850,
        settled: 1850,
        txns: 6,
        members: 4,
      ),
      _make(
        id: 'cr_nest1_apr',
        groupId: 'nest_1',
        start: DateTime(now.year, now.month - 2, 1),
        end: DateTime(now.year, now.month - 1, 1),
        expenses: 2400,
        settled: 2400,
        txns: 8,
        members: 4,
      ),
      _make(
        id: 'cr_nest1_may',
        groupId: 'nest_1',
        start: DateTime(now.year, now.month - 1, 1),
        end: DateTime(now.year, now.month, 1),
        expenses: 3600,
        settled: 2800,
        txns: 11,
        members: 4,
      ),
    ]);

    // ── nest_2 (Europe Trip 2026, cycleDate=1) ───────────────────────────
    cycleReports.addAll([
      _make(
        id: 'cr_nest2_mar',
        groupId: 'nest_2',
        start: DateTime(now.year, now.month - 3, 1),
        end: DateTime(now.year, now.month - 2, 1),
        expenses: 6200,
        settled: 6200,
        txns: 10,
        members: 4,
      ),
      _make(
        id: 'cr_nest2_apr',
        groupId: 'nest_2',
        start: DateTime(now.year, now.month - 2, 1),
        end: DateTime(now.year, now.month - 1, 1),
        expenses: 8500,
        settled: 8500,
        txns: 15,
        members: 4,
      ),
      _make(
        id: 'cr_nest2_may',
        groupId: 'nest_2',
        start: DateTime(now.year, now.month - 1, 1),
        end: DateTime(now.year, now.month, 1),
        expenses: 12200,
        settled: 9800,
        txns: 22,
        members: 4,
      ),
    ]);
  }

  // ── Cycle History API ─────────────────────────────────────────────────────

  /// Returns all archived [CycleReport]s for [groupId], newest first.
  List<CycleReport> getCycleHistory(String groupId) {
    return cycleReports
        .where((r) => r.groupId == groupId)
        .toList()
      ..sort((a, b) => b.cycleStart.compareTo(a.cycleStart));
  }

  /// Checks whether the cycle that ended most recently (i.e., the one
  /// immediately before the current cycle) has been archived. If not,
  /// it archives it now — this is the automatic "roll-over" behaviour.
  void checkAndArchiveIfNeeded(String groupId) {
    final groupIdx = groups.indexWhere((g) => g.id == groupId);
    if (groupIdx == -1) return;

    final group = groups[groupIdx];
    final bounds = _cycleBounds(group.settlementCycleDate);
    final currentStart = bounds.start;

    // Previous cycle window
    final prevEnd = currentStart;
    final prevStart = _prevCycleStart(currentStart, group.settlementCycleDate);

    // Build a stable ID for this period
    final reportId =
        'cr_${groupId}_auto_${prevStart.millisecondsSinceEpoch}';

    // Skip if already archived (by ID or by matching period)
    final alreadyArchived = cycleReports.any((r) =>
        r.groupId == groupId &&
        r.cycleStart.isAtSameMomentAs(prevStart) &&
        r.cycleEnd.isAtSameMomentAs(prevEnd));
    if (alreadyArchived) return;

    // Compute stats for the previous period from stored data (period-specific for expenses/settlements, but cumulative for pending balance)
    final prevExpenses = expenses
        .where((e) =>
            e.groupId == groupId &&
            !e.date.isBefore(prevStart) &&
            e.date.isBefore(prevEnd))
        .toList();

    final prevSettlements = settlements
        .where((s) =>
            s.groupId == groupId &&
            !s.createdAt.isBefore(prevStart) &&
            s.createdAt.isBefore(prevEnd))
        .toList();

    final totalExp =
        prevExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final totalSettledAmt =
        prevSettlements.fold(0.0, (sum, s) => sum + s.amount);
    final totalTxns = prevExpenses.length + prevSettlements.length;

    // Cumulative balance up to prevEnd (debts are never automatically erased when cycle ends)
    final cumulativeExp = expenses
        .where((e) => e.groupId == groupId && e.date.isBefore(prevEnd))
        .fold(0.0, (sum, e) => sum + e.amount);
    final cumulativeSettled = settlements
        .where((s) => s.groupId == groupId && s.createdAt.isBefore(prevEnd))
        .fold(0.0, (sum, s) => sum + s.amount);
    final prevPending = (cumulativeExp - cumulativeSettled).clamp(0.0, double.infinity);

    cycleReports.add(CycleReport(
      id: reportId,
      groupId: groupId,
      cycleStart: prevStart,
      cycleEnd: prevEnd,
      totalExpenses: totalExp,
      totalSettled: totalSettledAmt,
      totalPending: prevPending,
      totalTransactions: totalTxns,
      memberCount: group.members.length,
      archivedAt: prevEnd,
    ));

    triggerChange();
  }

  /// Computes the start of the previous cycle given the current cycle's
  /// start and the [cycleDay].
  static DateTime _prevCycleStart(DateTime currentStart, int cycleDay) {
    int year = currentStart.year;
    int month = currentStart.month - 1;
    if (month < 1) {
      month = 12;
      year--;
    }
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = cycleDay > lastDay ? lastDay : cycleDay;
    return DateTime(year, month, day);
  }

  void recalculateAllBalances() {
    balances.clear();
    for (final exp in expenses) {
      _applyExpenseToBalances(exp);
    }
    _updateGroupSummaries();
  }

  void _applyExpenseToBalances(Expense exp) {
    final payer = exp.paidByUserId;
    for (final split in exp.splits) {
      final participant = split.userId;
      if (participant == payer) continue;
      _addDebtInternal(exp.groupId, participant, payer, split.amount);
    }
  }

  void _addDebtInternal(String groupId, String fromUser, String toUser, double amount) {
    final sameIndex = balances.indexWhere(
      (b) => b.groupId == groupId && b.fromUserId == fromUser && b.toUserId == toUser
    );
    if (sameIndex != -1) {
      balances[sameIndex] = balances[sameIndex].copyWith(
        amount: balances[sameIndex].amount + amount,
        updatedAt: DateTime.now(),
      );
      return;
    }

    final oppIndex = balances.indexWhere(
      (b) => b.groupId == groupId && b.fromUserId == toUser && b.toUserId == fromUser
    );
    if (oppIndex != -1) {
      final existingAmt = balances[oppIndex].amount;
      if (existingAmt > amount) {
        balances[oppIndex] = balances[oppIndex].copyWith(
          amount: existingAmt - amount,
          updatedAt: DateTime.now(),
        );
      } else if (existingAmt == amount) {
        balances.removeAt(oppIndex);
      } else {
        balances.removeAt(oppIndex);
        balances.add(Balance(
          groupId: groupId,
          fromUserId: fromUser,
          toUserId: toUser,
          amount: amount - existingAmt,
          updatedAt: DateTime.now(),
        ));
      }
      return;
    }

    balances.add(Balance(
      groupId: groupId,
      fromUserId: fromUser,
      toUserId: toUser,
      amount: amount,
      updatedAt: DateTime.now(),
    ));
  }

  void addExpense(Expense exp) {
    expenses.add(exp);
    _applyExpenseToBalances(exp);
    
    // Log Activity
    final actorName = _getUserNameById(exp.groupId, exp.paidByUserId);
    final group = groups.firstWhere((g) => g.id == exp.groupId);
    logActivity(
      groupId: exp.groupId,
      actorId: exp.paidByUserId,
      type: 'expense_created',
      title: 'Expense Added',
      description: '${actorName == 'You' ? 'You' : actorName} added ${exp.title}',
      amount: exp.amount,
      relatedId: exp.id,
      actorName: actorName,
      groupName: group.name,
    );

    // Add Notification
    addNotification(
      title: 'Expense Added',
      description: '${actorName == 'You' ? 'You' : actorName} added "${exp.title}" - ₹${exp.amount.toInt()}',
      type: 'expense_added',
      relatedItemId: exp.id,
      groupId: exp.groupId,
    );

    // Notify
    triggerNotification('${actorName == 'You' ? 'You' : actorName} added expense "${exp.title}" of ₹${exp.amount.toInt()} in ${group.name}');

    _updateGroupSummaries();
    triggerChange();
  }

  void updateExpense(Expense newExp) {
    final idx = expenses.indexWhere((e) => e.id == newExp.id);
    if (idx != -1) {
      expenses[idx] = newExp;
      recalculateAllBalances();

      final actorName = _getUserNameById(newExp.groupId, newExp.paidByUserId);
      final group = groups.firstWhere((g) => g.id == newExp.groupId);
      logActivity(
        groupId: newExp.groupId,
        actorId: 'user_me', // actor performing operation
        type: 'expense_updated',
        title: 'Expense Updated',
        description: 'Expense "${newExp.title}" was updated',
        amount: newExp.amount,
        relatedId: newExp.id,
        actorName: 'You',
        groupName: group.name,
      );

      // Add Notification
      addNotification(
        title: 'Expense Updated',
        description: 'Expense "${newExp.title}" was updated - ₹${newExp.amount.toInt()}',
        type: 'expense_updated',
        relatedItemId: newExp.id,
        groupId: newExp.groupId,
      );

      triggerNotification('Expense "${newExp.title}" was updated in ${group.name}');
      triggerChange();
    }
  }

  void deleteExpense(String expenseId) {
    final idx = expenses.indexWhere((e) => e.id == expenseId);
    if (idx != -1) {
      final exp = expenses[idx];
      expenses.removeAt(idx);
      recalculateAllBalances();

      final group = groups.firstWhere((g) => g.id == exp.groupId);
      logActivity(
        groupId: exp.groupId,
        actorId: 'user_me',
        type: 'expense_deleted',
        title: 'Expense Deleted',
        description: 'Expense "${exp.title}" was deleted',
        amount: exp.amount,
        relatedId: exp.id,
        actorName: 'You',
        groupName: group.name,
      );

      // Add Notification
      addNotification(
        title: 'Expense Deleted',
        description: 'Expense "${exp.title}" was deleted',
        type: 'expense_deleted',
        relatedItemId: exp.id,
        groupId: exp.groupId,
      );

      triggerNotification('Expense "${exp.title}" was deleted in ${group.name}');
      triggerChange();
    }
  }

  void settleUp(String groupId, String paidBy, String receivedBy, double amount) {
    final sId = 'settle_${DateTime.now().millisecondsSinceEpoch}';
    
    // Save Settlement
    settlements.add(Settlement(
      id: sId,
      groupId: groupId,
      expenseId: 'mock_expense',
      splitId: 'mock_split',
      payerId: paidBy,
      receiverId: receivedBy,
      amount: amount,
      status: 'completed',
      createdBy: receivedBy,
      createdAt: DateTime.now(),
    ));

    // Update splits status using FIFO allocation of cumulative settlements
    final debtorSettlements = settlements
        .where((s) => s.groupId == groupId && s.payerId == paidBy && s.receiverId == receivedBy)
        .toList();
    double totalPaidSoFar = debtorSettlements.fold(0.0, (sum, s) => sum + s.amount);

    final debtorExpenses = expenses
        .where((e) => e.groupId == groupId && e.paidByUserId == receivedBy)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    for (final exp in debtorExpenses) {
      final splitIndex = exp.splits.indexWhere((s) => s.userId == paidBy);
      if (splitIndex == -1) continue;

      final split = exp.splits[splitIndex];
      final splitAmount = split.amount;

      final double allocated = totalPaidSoFar >= splitAmount ? splitAmount : totalPaidSoFar;
      totalPaidSoFar -= allocated;

      final isFullySettled = (allocated >= splitAmount - 0.01);

      final updatedSplit = split.copyWith(
        status: isFullySettled ? 'completed' : 'pending',
        isSettled: isFullySettled,
        settledAt: isFullySettled ? DateTime.now() : null,
      );

      final updatedSplits = List<ExpenseSplit>.from(exp.splits);
      updatedSplits[splitIndex] = updatedSplit;

      final expIndex = expenses.indexWhere((e) => e.id == exp.id);
      if (expIndex != -1) {
        expenses[expIndex] = exp.copyWith(splits: updatedSplits);
      }
    }

    // Reduce balance
    final sameIndex = balances.indexWhere(
      (b) => b.groupId == groupId && b.fromUserId == paidBy && b.toUserId == receivedBy
    );
    if (sameIndex != -1) {
      final existingAmt = balances[sameIndex].amount;
      if (existingAmt > amount) {
        balances[sameIndex] = balances[sameIndex].copyWith(
          amount: existingAmt - amount,
          updatedAt: DateTime.now(),
        );
      } else if (existingAmt == amount) {
        balances.removeAt(sameIndex);
      } else {
        balances.removeAt(sameIndex);
        balances.add(Balance(
          groupId: groupId,
          fromUserId: receivedBy,
          toUserId: paidBy,
          amount: amount - existingAmt,
          updatedAt: DateTime.now(),
        ));
      }
    } else {
      final oppIndex = balances.indexWhere(
        (b) => b.groupId == groupId && b.fromUserId == receivedBy && b.toUserId == paidBy
      );
      if (oppIndex != -1) {
        balances[oppIndex] = balances[oppIndex].copyWith(
          amount: balances[oppIndex].amount + amount,
          updatedAt: DateTime.now(),
        );
      } else {
        balances.add(Balance(
          groupId: groupId,
          fromUserId: receivedBy,
          toUserId: paidBy,
          amount: amount,
          updatedAt: DateTime.now(),
        ));
      }
    }

    // Log Activity
    final payerName = _getUserNameById(groupId, paidBy);
    final receiverName = _getUserNameById(groupId, receivedBy);
    final group = groups.firstWhere((g) => g.id == groupId);
    logActivity(
      groupId: groupId,
      actorId: paidBy,
      type: 'settlement_completed',
      title: 'Settlement Completed',
      description: '${payerName == 'You' ? 'You' : payerName} paid ${receiverName == 'You' ? 'you' : receiverName} ₹${amount.toInt()}',
      amount: amount,
      relatedId: sId,
      actorName: payerName,
      groupName: group.name,
    );

    // Add Notification
    if (receivedBy == 'user_me') {
      addNotification(
        title: 'Settlement Received',
        description: '${payerName == 'You' ? 'You' : payerName} paid you ₹${amount.toInt()}',
        type: 'settlement_received',
        relatedItemId: sId,
        groupId: groupId,
      );
    } else if (paidBy == 'user_me') {
      addNotification(
        title: 'Settlement Paid',
        description: 'You settled ₹${amount.toInt()} with ${receiverName == 'You' ? 'you' : receiverName}',
        type: 'settlement_paid',
        relatedItemId: sId,
        groupId: groupId,
      );
    } else {
      addNotification(
        title: 'Settlement Completed',
        description: '${payerName} settled ₹${amount.toInt()} with ${receiverName}',
        type: 'settlement_paid',
        relatedItemId: sId,
        groupId: groupId,
      );
    }

    triggerNotification('${payerName == 'You' ? 'You' : payerName} settled ₹${amount.toInt()} with ${receiverName == 'You' ? 'you' : receiverName} in ${group.name}');

    _updateGroupSummaries();
    triggerChange();
  }

  void addMember(String groupId, String email) {
    final idx = groups.indexWhere((g) => g.id == groupId);
    if (idx != -1) {
      final old = groups[idx];
      final memberName = email.split('@').first;
      final capitalizedName = memberName[0].toUpperCase() + memberName.substring(1);
      final memberId = 'user_${memberName.toLowerCase()}';
      
      final newMember = GroupMember(
        id: memberId,
        name: capitalizedName,
        email: email,
        role: MemberRole.member,
        joinedAt: DateTime.now(),
      );

      groups[idx] = old.copyWith(
        membersCount: old.membersCount + 1,
        members: [...old.members, newMember],
      );

      logActivity(
        groupId: groupId,
        actorId: memberId,
        type: 'member_joined',
        title: 'Member Joined',
        description: '$capitalizedName joined the group',
        createdAt: DateTime.now(),
        actorName: capitalizedName,
        groupName: old.name,
      );

      // Add Notification
      addNotification(
        title: 'Member Joined',
        description: '$capitalizedName joined Nest "${old.name}"',
        type: 'member_joined',
        groupId: groupId,
      );

      triggerNotification('$capitalizedName joined group ${old.name}');
      _updateGroupSummaries();
      triggerChange();
    }
  }

  void removeMember(String groupId, String userId) {
    final idx = groups.indexWhere((g) => g.id == groupId);
    if (idx != -1) {
      final old = groups[idx];
      final memberIdx = old.members.indexWhere((m) => m.id == userId);
      if (memberIdx != -1) {
        final memberName = old.members[memberIdx].name;
        final updatedMembers = List<GroupMember>.from(old.members)..removeAt(memberIdx);
        
        groups[idx] = old.copyWith(
          membersCount: updatedMembers.length,
          members: updatedMembers,
        );

        // Remove active balances involving this user (recalculated)
        balances.removeWhere((b) => b.groupId == groupId && (b.fromUserId == userId || b.toUserId == userId));

        logActivity(
          groupId: groupId,
          actorId: userId,
          type: 'member_left',
          title: 'Member Left',
          description: '$memberName left the group',
          createdAt: DateTime.now(),
          actorName: memberName,
          groupName: old.name,
        );

        // Add Notification
        addNotification(
          title: 'Member Removed',
          description: '$memberName was removed/left from Nest "${old.name}"',
          type: 'member_removed',
          groupId: groupId,
        );

        triggerNotification('$memberName left group ${old.name}');
        _updateGroupSummaries();
        triggerChange();
      }
    }
  }

  void createGroup(Group newGroup) {
    groups.insert(0, newGroup);
    
    logActivity(
      groupId: newGroup.id,
      actorId: newGroup.createdBy,
      type: 'group_created',
      title: 'Group Created',
      description: '${newGroup.createdBy == 'user_me' ? 'You' : 'Admin'} created the group ${newGroup.name}',
      createdAt: newGroup.createdAt,
      actorName: 'You',
      groupName: newGroup.name,
    );

    // Add Notification
    addNotification(
      title: 'Nest Created',
      description: 'Nest "${newGroup.name}" was successfully created',
      type: 'nest_created',
      groupId: newGroup.id,
    );

    triggerNotification('You created the group "${newGroup.name}"');
    _updateGroupSummaries();
    triggerChange();
  }

  void updateGroupImage(String groupId, String? imageUrl) {
    final idx = groups.indexWhere((g) => g.id == groupId);
    if (idx != -1) {
      final old = groups[idx];
      groups[idx] = old.copyWith(
        groupImage: imageUrl,
        imageUrl: imageUrl,
      );
      
      logActivity(
        groupId: groupId,
        actorId: 'user_me',
        type: 'group_updated',
        title: 'Group Icon Updated',
        description: 'You updated the group picture',
        createdAt: DateTime.now(),
        actorName: 'You',
        groupName: old.name,
      );

      // Add Notification
      addNotification(
        title: 'Nest Updated',
        description: 'Icon was updated for Nest "${old.name}"',
        type: 'nest_updated',
        groupId: groupId,
      );

      triggerNotification('You updated the group picture for "${old.name}"');
      triggerChange();
    }
  }

  void logActivity({
    required String groupId,
    required String actorId,
    required String type,
    required String title,
    required String description,
    double? amount,
    String? relatedId,
    DateTime? createdAt,
    String? actorName,
    String? groupName,
  }) {
    activities.insert(0, Activity(
      id: 'act_${DateTime.now().millisecondsSinceEpoch}_${activities.length}',
      groupId: groupId,
      actorId: actorId,
      activityType: type,
      title: title,
      description: description,
      amount: amount,
      relatedId: relatedId,
      createdAt: createdAt ?? DateTime.now(),
      actorName: actorName,
      groupName: groupName,
    ));
  }

  void _updateGroupSummaries() {
    for (int i = 0; i < groups.length; i++) {
      final g = groups[i];
      final groupExpenses = expenses.where((e) => e.groupId == g.id);
      final groupSettlements = settlements.where((s) => s.groupId == g.id);
      final groupBalances = balances.where((b) => b.groupId == g.id);

      final totalExp = groupExpenses.fold(0.0, (sum, e) => sum + e.amount);
      final totalPend = groupBalances.fold(0.0, (sum, b) => sum + b.amount);
      final totalSettled = groupSettlements.fold(0.0, (sum, s) => sum + s.amount);

      double myPendingBalance = 0.0;
      for (final b in groupBalances) {
        if (b.toUserId == 'user_me') {
          myPendingBalance += b.amount;
        } else if (b.fromUserId == 'user_me') {
          myPendingBalance -= b.amount;
        }
      }

      String status = 'Settled';
      if (myPendingBalance > 0.01) {
        status = 'Owed';
      } else if (myPendingBalance < -0.01) {
        status = 'You owe';
      }

      groups[i] = g.copyWith(
        totalExpenses: totalExp,
        totalPending: totalPend,
        totalSettled: totalSettled,
        pendingBalance: myPendingBalance,
        status: status,
      );
    }
  }

  String _getUserNameById(String groupId, String userId) {
    if (userId == 'user_me') return 'You';
    try {
      final group = groups.firstWhere((g) => g.id == groupId);
      final member = group.members.firstWhere((m) => m.id == userId);
      return member.name;
    } catch (_) {
      return 'Someone';
    }
  }

  /// Returns cycle start/end dates for a given cycleDay (1-31) relative to now.
  static ({DateTime start, DateTime end}) _cycleBounds(int cycleDay) {
    final now = DateTime.now();

    DateTime clamp(int year, int month, int day) {
      final lastDay = DateTime(year, month + 1, 0).day;
      return DateTime(year, month, day > lastDay ? lastDay : day);
    }

    if (now.day >= cycleDay) {
      return (
        start: clamp(now.year, now.month, cycleDay),
        end: clamp(now.year, now.month + 1, cycleDay),
      );
    } else {
      return (
        start: clamp(now.year, now.month - 1, cycleDay),
        end: clamp(now.year, now.month, cycleDay),
      );
    }
  }

  /// Computes cycle statistics for a given group, filtered to the current
  /// billing cycle. Reacts to any call of [triggerChange].
  CycleStats getCycleStats(String groupId) {
    final groupIdx = groups.indexWhere((g) => g.id == groupId);
    if (groupIdx == -1) {
      return CycleStats(
        groupId: groupId,
        cycleStart: DateTime.now(),
        cycleEnd: DateTime.now(),
        totalExpenses: 0,
        totalSettled: 0,
        totalPending: 0,
        totalTransactions: 0,
        memberCount: 0,
      );
    }

    final group = groups[groupIdx];
    final bounds = _cycleBounds(group.settlementCycleDate);
    final cycleStart = group.customStartDate ?? bounds.start;
    final cycleEnd = group.customEndDate ?? bounds.end;

    // Filter expenses within [cycleStart, cycleEnd)
    final cycleExpenses = expenses.where((e) =>
        e.groupId == groupId &&
        !e.date.isBefore(cycleStart) &&
        e.date.isBefore(cycleEnd)).toList();

    // Filter settlements within [cycleStart, cycleEnd)
    final cycleSettlements = settlements.where((s) =>
        s.groupId == groupId &&
        !s.createdAt.isBefore(cycleStart) &&
        s.createdAt.isBefore(cycleEnd)).toList();

    final totalExp = cycleExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final totalSettledAmt =
        cycleSettlements.fold(0.0, (sum, s) => sum + s.amount);
    
    // Cumulative balance up to cycleEnd (debts are never automatically erased when cycle ends)
    final cumulativeExp = expenses
        .where((e) => e.groupId == groupId && e.date.isBefore(cycleEnd))
        .fold(0.0, (sum, e) => sum + e.amount);
    final cumulativeSettled = settlements
        .where((s) => s.groupId == groupId && s.createdAt.isBefore(cycleEnd))
        .fold(0.0, (sum, s) => sum + s.amount);
    final totalPending = (cumulativeExp - cumulativeSettled).clamp(0.0, double.infinity);
    
    final totalTxns = cycleExpenses.length + cycleSettlements.length;

    return CycleStats(
      groupId: groupId,
      cycleStart: cycleStart,
      cycleEnd: cycleEnd,
      totalExpenses: totalExp,
      totalSettled: totalSettledAmt,
      totalPending: totalPending,
      totalTransactions: totalTxns,
      memberCount: group.members.length,
    );
  }

  void clearDatabase() {
    groups.clear();
    expenses.clear();
    balances.clear();
    settlements.clear();
    activities.clear();
    notifications.clear();
    cycleReports.clear();
    triggerChange();
  }

  void resetToDefault() {
    groups.clear();
    expenses.clear();
    balances.clear();
    settlements.clear();
    activities.clear();
    notifications.clear();
    cycleReports.clear();
    _initData();
    triggerChange();
  }
}

