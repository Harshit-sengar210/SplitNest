import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/balances/presentation/providers/balance_providers.dart';
import '../../features/groups/presentation/providers/groups_provider.dart';

/// Immutable snapshot of the current user's balance across all nests.
class HomeBalanceState {
  /// Total amount others owe the current user (positive).
  final double owedToYou;

  /// Total amount the current user owes others (positive).
  final double youOwe;

  /// Net balance: owedToYou − youOwe.
  final double totalBalance;

  const HomeBalanceState({
    required this.owedToYou,
    required this.youOwe,
    required this.totalBalance,
  });

  static const empty = HomeBalanceState(
    owedToYou: 0,
    youOwe: 0,
    totalBalance: 0,
  );
}

/// Provides real-time balance data for the Home Screen.
/// Now powered entirely by Firebase through balance_providers.
final homeBalanceProvider = Provider<HomeBalanceState>((ref) {
  final groupsState = ref.watch(groupsListProvider);
  if (groupsState.isLoading) return HomeBalanceState.empty;

  double receive = 0;
  double pay = 0;

  for (final group in groupsState.groups) {
    final groupSummary = ref.watch(balanceSummaryProvider(group.id));
    if (groupSummary.hasValue) {
      receive += groupSummary.value!.willReceive;
      pay += groupSummary.value!.willPay;
    }
  }

  return HomeBalanceState(
    owedToYou: receive,
    youOwe: pay,
    totalBalance: receive - pay,
  );
});

/// Whether the current user is considered "new" (no data yet).
/// Now relies on Firebase groups.
final isNewUserProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.value;
  if (user == null) {
    return true; // Default to new user if not logged in
  }

  final groupsState = ref.watch(groupsListProvider);
  if (groupsState.isLoading) return false;

  return groupsState.groups.isEmpty;
});

