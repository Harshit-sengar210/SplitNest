import '../models/ledger_transaction.dart';
import '../models/ledger_summary.dart';

abstract class LedgerRepository {
  Stream<List<LedgerTransaction>> streamTransactions(String userId);
  Stream<LedgerSummary?> streamSummary(String userId);
  Future<void> addTransaction(LedgerTransaction transaction);
  Future<void> updateTransaction(LedgerTransaction transaction);
  Future<void> deleteTransaction(String userId, String transactionId);
}
