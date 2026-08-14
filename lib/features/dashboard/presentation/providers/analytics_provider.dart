import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../groups/presentation/providers/groups_provider.dart';
import '../../../expenses/presentation/providers/expenses_provider.dart';
import '../../../settlement/presentation/providers/settlement_provider.dart';
import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../screens/calendar_screen.dart' show CalendarEvent;
import '../../../groups/domain/models/group.dart';

// Provides a unified list of CalendarEvents for the Analytics Center
final calendarEventsProvider = Provider<List<CalendarEvent>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  final currentUserId = user?.id ?? 'user_me';

  final groupsState = ref.watch(groupsListProvider);
  final groups = groupsState.groups;
  
  final List<CalendarEvent> events = [];

  // 1. Group Expenses (Purple)
  for (final group in groups) {
    final expensesAsync = ref.watch(nestExpensesStreamProvider(group.id));
    final expenses = expensesAsync.value ?? [];
    
    for (final exp in expenses) {
      final paidByName = group.members.firstWhere(
        (m) => m.id == exp.paidByUserId, 
        orElse: () => group.members.first
      ).name;
      
      final isMyExpense = exp.paidByUserId == currentUserId;
      final mySplit = exp.splits.where((s) => s.userId == currentUserId).toList();
      final isInvolved = isMyExpense || mySplit.isNotEmpty;
      
      if (!isInvolved) continue;

      String desc;
      double displayAmt;
      
      if (isMyExpense && mySplit.isEmpty) {
        desc = 'Paid fully on behalf of ${group.name}';
        displayAmt = exp.amount;
      } else if (isMyExpense) {
        final myShare = mySplit.first.amount;
        displayAmt = exp.amount - myShare;
        desc = 'You paid ₹${exp.amount.toStringAsFixed(0)} for "${exp.title}" (Your share: ₹${myShare.toStringAsFixed(0)})';
      } else {
        displayAmt = mySplit.first.amount;
        desc = '${paidByName == user?.displayName ? 'You' : paidByName} paid for "${exp.title}" in ${group.name} — your share: ₹${displayAmt.toStringAsFixed(0)}';
      }

      events.add(
        CalendarEvent(
          id: 'expense_${exp.id}',
          title: exp.title,
          description: desc,
          amount: displayAmt,
          dateTime: exp.date,
          type: 'Expense',
          color: const Color(0xFF7B61FF), // Purple
          routePath: '/expenses/detail/${exp.id}?groupId=${group.id}',
          category: exp.category,
        ),
      );
    }
  }

  // 2. Group Settlements (Green)
  for (final group in groups) {
    final settlementsAsync = ref.watch(groupSettlementsProvider(group.id));
    final settlements = settlementsAsync.value ?? [];
    
    for (final set in settlements) {
      final iAmPayer = set.payerId == currentUserId;
      final iAmReceiver = set.receiverId == currentUserId;
      if (!iAmPayer && !iAmReceiver) continue;

      final otherId = iAmPayer ? set.receiverId : set.payerId;
      final otherName = group.members.firstWhere(
        (m) => m.id == otherId, 
        orElse: () => group.members.first
      ).name;
      
      final title = iAmPayer ? 'Settlement Paid' : 'Settlement Received';
      final desc = iAmPayer
          ? 'You settled with $otherName in ${group.name}'
          : '$otherName settled with you in ${group.name}';

      events.add(
        CalendarEvent(
          id: 'settlement_${set.id}',
          title: title,
          description: desc,
          amount: set.amount,
          dateTime: set.createdAt,
          type: 'Settlement',
          color: const Color(0xFF10B981), // Green
          routePath: '/settlement/detail/${set.id}', 
        ),
      );
    }
  }

  // 3. Ledger Transactions: Pending (Red) and Payment (Blue)
  final ledgerTransactionsAsync = ref.watch(ledgerTransactionsProvider);
  final ledgerTransactions = ledgerTransactionsAsync.value ?? [];
  
  for (final tx in ledgerTransactions) {
    final desc = tx.type == 'lend'
        ? 'You gave money to ${tx.personName ?? 'Someone'}'
        : tx.type == 'borrow'
        ? 'Borrowed money from ${tx.personName ?? 'Someone'}'
        : tx.type == 'income'
        ? 'Received income: ${tx.title}'
        : 'Expense: ${tx.title}';

    final isPending = tx.status == 'pending';
    
    String eventType;
    if (tx.type == 'expense') {
      eventType = isPending ? 'PendingExpense' : 'PersonalExpense';
    } else if (tx.type == 'lend' || tx.type == 'borrow') {
      eventType = isPending ? 'PendingSettlement' : 'PersonalSettlement';
    } else if (tx.type == 'income') {
      eventType = 'Income';
    } else {
      eventType = isPending ? 'Pending' : 'Payment';
    }

    events.add(
      CalendarEvent(
        id: 'ledger_${tx.transactionId}',
        title: tx.title,
        description: '$desc${tx.description.isNotEmpty ? ' (${tx.description})' : ''}',
        amount: tx.amount,
        dateTime: tx.date,
        type: eventType,
        color: isPending
            ? const Color(0xFFEF4444)
            : (tx.type == 'income' || tx.type == 'borrow' ? const Color(0xFF10B981) : const Color(0xFF3B82F6)),
        routePath: '/personal-ledger/detail/${tx.transactionId}',
      ),
    );
  }

  // 4. Cycle Start & End Dates
  for (final group in groups) {
    final statsAsync = ref.watch(cycleStatsProvider(group.id));
    final stats = statsAsync.value;
    if (stats != null) {
      events.add(
        CalendarEvent(
          id: 'cyclestart_current_${group.id}',
          title: '${group.name} Cycle Start',
          description: 'New billing cycle started today (Date: ${DateFormat('dd MMM').format(stats.cycleStart)})',
          amount: 0.0,
          dateTime: stats.cycleStart,
          type: 'CycleStart',
          color: const Color(0xFF8B5CF6), // Indigo
          routePath: '/groups/${group.id}',
        ),
      );

      events.add(
        CalendarEvent(
          id: 'cycleend_current_${group.id}',
          title: '${group.name} Cycle End',
          description: 'Current billing cycle rolls over today (Date: ${DateFormat('dd MMM').format(stats.cycleEnd)})',
          amount: 0.0,
          dateTime: stats.cycleEnd,
          type: 'CycleEnd',
          color: const Color(0xFFD946EF), // Fuchsia/Pink
          routePath: '/groups/${group.id}',
        ),
      );
    }

    final historyAsync = ref.watch(cycleHistoryProvider(group.id));
    final history = historyAsync.value ?? [];
    for (final report in history) {
      events.add(
        CalendarEvent(
          id: 'cyclestart_hist_${report.id}',
          title: '${group.name} Cycle Start (Archived)',
          description: 'Archived billing cycle started on ${DateFormat('dd MMM yyyy').format(report.cycleStart)}',
          amount: 0.0,
          dateTime: report.cycleStart,
          type: 'CycleStart',
          color: const Color(0xFF8B5CF6),
          routePath: '/groups/${group.id}',
        ),
      );

      events.add(
        CalendarEvent(
          id: 'cycleend_hist_${report.id}',
          title: '${group.name} Cycle End (Archived)',
          description: 'Archived billing cycle rolled over on ${DateFormat('dd MMM yyyy').format(report.cycleEnd)}',
          amount: 0.0,
          dateTime: report.cycleEnd,
          type: 'CycleEnd',
          color: const Color(0xFFD946EF),
          routePath: '/groups/${group.id}',
        ),
      );
    }
  }

  return events;
});
