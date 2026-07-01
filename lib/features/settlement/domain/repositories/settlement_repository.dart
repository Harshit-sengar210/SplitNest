import '../models/settlement.dart';
import '../models/balance.dart';

abstract class SettlementRepository {
  Future<List<Settlement>> getSettlements(String groupId);
  Stream<List<Settlement>> streamSettlements(String groupId);
  
  Future<List<Balance>> getBalances(String groupId);
  Stream<List<Balance>> streamBalances(String groupId);
  
  Future<Settlement> createSettlement({
    required String groupId,
    required String expenseId,
    required String splitId,
    required double amount,
  });

  Future<void> settleDebt({
    required String groupId,
    required String debtorId,
    required String creditorId,
    required double amount,
  });
}
