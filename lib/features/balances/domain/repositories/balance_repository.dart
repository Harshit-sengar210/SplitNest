import '../models/member_balance.dart';

abstract class BalanceRepository {
  Future<List<MemberBalance>> calculateBalances(String nestId);
  Stream<List<MemberBalance>> streamBalances(String nestId);
}
