import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/settlement.dart';
import '../../domain/models/balance.dart';
import '../../domain/repositories/settlement_repository.dart';
import '../../data/repositories/firebase_settlement_repository.dart';
import '../../../members/presentation/providers/member_providers.dart';
import '../../../expenses/presentation/providers/expenses_provider.dart';

final settlementRepositoryProvider = Provider<SettlementRepository>((ref) {
  final memberRepo = ref.watch(memberRepositoryProvider);
  final expenseRepo = ref.watch(expensesRepositoryProvider);
  return FirebaseSettlementRepository(memberRepo, expenseRepo);
});

// Real-time provider for group balances
final groupBalancesProvider = StreamProvider.family<List<Balance>, String>((ref, groupId) {
  final repository = ref.watch(settlementRepositoryProvider);
  return repository.streamBalances(groupId);
});

// Real-time provider for group settlements
final groupSettlementsProvider = StreamProvider.family<List<Settlement>, String>((ref, groupId) {
  final repository = ref.watch(settlementRepositoryProvider);
  return repository.streamSettlements(groupId);
});
