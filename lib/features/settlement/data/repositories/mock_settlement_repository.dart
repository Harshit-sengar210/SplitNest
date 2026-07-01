import '../../domain/models/settlement.dart';
import '../../domain/models/balance.dart';
import '../../domain/repositories/settlement_repository.dart';
import '../../../../core/utils/mock_database.dart';

class MockSettlementRepository implements SettlementRepository {
  final MockDatabase _db = MockDatabase();

  @override
  Future<List<Settlement>> getSettlements(String groupId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _db.settlements.where((s) => s.groupId == groupId).toList();
  }

  @override
  Stream<List<Settlement>> streamSettlements(String groupId) async* {
    yield await getSettlements(groupId);
    await for (final _ in _db.changeStream) {
      yield await getSettlements(groupId);
    }
  }

  @override
  Future<List<Balance>> getBalances(String groupId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _db.balances.where((b) => b.groupId == groupId).toList();
  }

  @override
  Stream<List<Balance>> streamBalances(String groupId) async* {
    yield await getBalances(groupId);
    await for (final _ in _db.changeStream) {
      yield await getBalances(groupId);
    }
  }

  @override
  Future<Settlement> createSettlement({
    required String groupId,
    required String expenseId,
    required String splitId,
    required double amount,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    throw UnimplementedError('Mock createSettlement not adapted to owner-based flow.');
  }

  @override
  Future<void> settleDebt({
    required String groupId,
    required String debtorId,
    required String creditorId,
    required double amount,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _db.settleUp(groupId, debtorId, creditorId, amount);
  }
}
