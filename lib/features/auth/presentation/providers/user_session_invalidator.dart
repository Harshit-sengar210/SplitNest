import 'package:flutter_riverpod/flutter_riverpod.dart';

// Groups / Nests
import '../../../nests/presentation/providers/nest_provider.dart';
import '../../../groups/presentation/providers/groups_provider.dart';

// Ledger
import '../../../ledger/presentation/providers/ledger_provider.dart';

// Notifications / Activity
import '../../../activity/presentation/providers/notification_provider.dart';
import '../../../activity/presentation/providers/activity_provider.dart';

// Balances / DB
import '../../../../core/providers/balance_provider.dart';

/// Invalidates every Riverpod provider that holds user-specific data.
///
/// Accepts an [invalidate] callback so it works from both [Ref] (inside
/// providers/notifiers) and [WidgetRef] (inside widgets):
///
///   // From a StateNotifier / Provider:
///   invalidateAllUserProviders(_ref.invalidate);
///
///   // From a ConsumerWidget / ConsumerState:
///   invalidateAllUserProviders(ref.invalidate);
///
void invalidateAllUserProviders(void Function(ProviderOrFamily) invalidate) {
  // Groups / Nests
  invalidate(groupsListProvider);
  invalidate(createdNestsStreamProvider);
  invalidate(activeNestIdStreamProvider);
  invalidate(userNestsProvider);
  invalidate(filteredNestsProvider);
  invalidate(nestsSearchQueryProvider);
  invalidate(currentNestProvider);

  // Ledger
  invalidate(ledgerTransactionsProvider);
  invalidate(ledgerSummaryProvider);

  // Notifications / Activity
  invalidate(notificationsStreamProvider);
  invalidate(globalActivitiesProvider);

  // Balances / Dashboard
  invalidate(homeBalanceProvider);
  invalidate(isNewUserProvider);
  invalidate(globalCycleStatsProvider);

}
