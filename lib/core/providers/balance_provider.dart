import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../utils/mock_database.dart';
import 'database_provider.dart';

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
///
/// Reads directly from [MockDatabase] (the singleton) so there is no async
/// delay.  Rebuilds automatically whenever any expense, settlement, or group
/// mutation fires [triggerChange] via [databaseChangeProvider].
final homeBalanceProvider = Provider<HomeBalanceState>((ref) {
  // Re-compute whenever the database emits a change.
  ref.watch(databaseChangeProvider);

  final db = MockDatabase();

  double owedToYou = 0.0;
  double youOwe = 0.0;

  // Iterate over every balance entry across all groups.
  for (final b in db.balances) {
    if (b.toUserId == 'user_me') {
      // Someone owes the current user.
      owedToYou += b.amount;
    } else if (b.fromUserId == 'user_me') {
      // Current user owes someone.
      youOwe += b.amount;
    }
  }

  return HomeBalanceState(
    owedToYou: owedToYou,
    youOwe: youOwe,
    totalBalance: owedToYou - youOwe,
  );
});

/// Whether the current user is considered "new" (no data yet).
///
/// A user is new when they have zero nests. This provider rebuilds whenever
/// the database changes or the user authentication state changes.
final isNewUserProvider = Provider<bool>((ref) {
  ref.watch(databaseChangeProvider);

  final authState = ref.watch(authStateChangesProvider);
  final user = authState.value;
  if (user == null) {
    return true; // Default to new user if not logged in
  }

  final db = MockDatabase();
  final hasActiveNests = db.groups.any((g) => g.createdBy == user.id || g.members.any((m) => m.id == user.id));
  return !hasActiveNests;
});
