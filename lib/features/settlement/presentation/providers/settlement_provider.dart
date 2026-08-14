import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

// Fetch a single settlement across all nests or by specific nest
final settlementDetailProvider = FutureProvider.family<Settlement?, ({String id, String? groupId})>((ref, args) async {
  final firestore = FirebaseFirestore.instance;
  if (args.groupId != null) {
    final doc = await firestore.collection('nests').doc(args.groupId).collection('settlements').doc(args.id).get();
    if (doc.exists) return Settlement.fromMap(doc.data()!);
  }
  
  // Fallback
  final snapshot = await firestore.collectionGroup('settlements').where('settlementId', isEqualTo: args.id).limit(1).get();
  if (snapshot.docs.isNotEmpty) {
    return Settlement.fromMap(snapshot.docs.first.data());
  }
  return null;
});
