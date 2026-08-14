import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../members/presentation/providers/member_providers.dart';
import '../../../expenses/presentation/providers/expenses_provider.dart';
import '../../../settlement/presentation/providers/settlement_provider.dart';
import '../../domain/repositories/balance_repository.dart';
import '../../data/repositories/firebase_balance_repository.dart';
import '../../domain/models/member_balance.dart';
import '../../../expenses/domain/models/expense.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
// Re-export group + cycle providers so the balance screen can access them
// without creating a cross-feature circular dependency.
export '../../../groups/presentation/providers/groups_provider.dart'
    show groupDetailProvider, cycleStatsProvider;
import '../../../groups/presentation/providers/groups_provider.dart';
import '../../../ledger/presentation/providers/ledger_provider.dart';


final balanceRepositoryProvider = Provider<BalanceRepository>((ref) {
  final memberRepo = ref.watch(memberRepositoryProvider);
  final expenseRepo = ref.watch(expensesRepositoryProvider);
  final settlementRepo = ref.watch(settlementRepositoryProvider);
  return FirebaseBalanceRepository(memberRepo, expenseRepo, settlementRepo);
});

final nestBalancesStreamProvider = StreamProvider.family<List<MemberBalance>, String>((ref, nestId) {
  final repository = ref.watch(balanceRepositoryProvider);
  return repository.streamBalances(nestId);
});

class ExpenseSplitContext {
  final Expense expense;
  final ExpenseSplit split;

  const ExpenseSplitContext({
    required this.expense,
    required this.split,
  });
}

final nestSplitsProvider = Provider.autoDispose.family<AsyncValue<List<ExpenseSplitContext>>, String>((ref, groupId) {
  final expensesAsync = ref.watch(nestExpensesStreamProvider(groupId));
  return expensesAsync.whenData((expenses) {
    final List<ExpenseSplitContext> list = [];
    for (final expense in expenses) {
      for (final split in expense.splits) {
        list.add(ExpenseSplitContext(expense: expense, split: split));
      }
    }
    list.sort((a, b) => b.expense.date.compareTo(a.expense.date));
    return list;
  });
});

// ── Balance Summary ───────────────────────────────────────────────────────────

class BalanceSummary {
  /// Total pending amount the current user will RECEIVE from others.
  final double willReceive;

  /// Total pending amount the current user will PAY to others.
  final double willPay;

  /// Total amount the user has paid in the group (lifetime).
  final double totalPaid;

  /// willReceive - willPay (positive = net creditor, negative = net debtor).
  double get net => willReceive - willPay;

  const BalanceSummary({required this.willReceive, required this.willPay, required this.totalPaid});

  static const empty = BalanceSummary(willReceive: 0, willPay: 0, totalPaid: 0);
}

/// Derives the current user's net balance in real time from the splits stream.
final balanceSummaryProvider =
    Provider.autoDispose.family<AsyncValue<BalanceSummary>, String>((ref, groupId) {
  final currentUserId = ref.watch(authNotifierProvider).user?.id ?? '';
  final splitsAsync = ref.watch(nestSplitsProvider(groupId));

  return splitsAsync.whenData((splits) {
    double receive = 0;
    double pay = 0;
    double paid = 0;

    for (final ctx in splits) {
      final split = ctx.split;
      
      // Calculate total lifetime paid by the user
      if (split.paidBy == currentUserId) {
        paid += split.amount;
      }

      // Skip completed splits for pending calculations
      if (split.pendingAmount <= 0.01 || split.status == 'completed') continue;

      if (split.paidBy == currentUserId) {
        // Someone owes the current user
        receive += split.pendingAmount;
      } else if (split.userId == currentUserId) {
        // Current user owes someone
        pay += split.pendingAmount;
      }
    }

    return BalanceSummary(willReceive: receive, willPay: pay, totalPaid: paid);
  });
});

/// Computes the overall cross-app net balance by aggregating:
/// 1. The total lifetime paid amount from all groups the user is part of.
final overallNetBalanceProvider = Provider<AsyncValue<double>>((ref) {
  final groupsState = ref.watch(groupsListProvider);
  if (groupsState.isLoading) return const AsyncValue.loading();
  
  double totalPaidAllGroups = 0.0;
  for (final group in groupsState.groups) {
    final groupSummary = ref.watch(balanceSummaryProvider(group.id));
    if (groupSummary.hasValue) {
      totalPaidAllGroups += groupSummary.value!.totalPaid;
    }
  }

  return AsyncValue.data(totalPaidAllGroups);
});

/// Computes the overall group balance summary (total willReceive and total willPay).
final overallGroupBalanceSummaryProvider = Provider<AsyncValue<BalanceSummary>>((ref) {
  final groupsState = ref.watch(groupsListProvider);
  if (groupsState.isLoading) return const AsyncValue.loading();
  
  double totalReceive = 0.0;
  double totalPay = 0.0;
  double totalPaid = 0.0;
  
  for (final group in groupsState.groups) {
    final groupSummary = ref.watch(balanceSummaryProvider(group.id));
    if (groupSummary.hasValue) {
      totalReceive += groupSummary.value!.willReceive;
      totalPay += groupSummary.value!.willPay;
      totalPaid += groupSummary.value!.totalPaid;
    }
  }

  return AsyncValue.data(BalanceSummary(willReceive: totalReceive, willPay: totalPay, totalPaid: totalPaid));
});
