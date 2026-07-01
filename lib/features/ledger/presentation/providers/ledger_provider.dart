import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/ledger_transaction.dart';
import '../../domain/models/ledger_summary.dart';
import '../../domain/repositories/ledger_repository.dart';
import '../../data/repositories/firebase_ledger_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final ledgerRepositoryProvider = Provider<LedgerRepository>((ref) {
  return FirebaseLedgerRepository();
});

final ledgerTransactionsProvider = StreamProvider<List<LedgerTransaction>>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final userId = authState.user?.id;
  if (userId == null) return const Stream.empty();
  return ref.watch(ledgerRepositoryProvider).streamTransactions(userId);
});

final ledgerSummaryProvider = StreamProvider<LedgerSummary?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final userId = authState.user?.id;
  if (userId == null) return const Stream.empty();
  return ref.watch(ledgerRepositoryProvider).streamSummary(userId);
});

class LedgerController {
  final Ref _ref;
  LedgerController(this._ref);

  Future<void> addTransaction({
    required String title,
    required String description,
    required double amount,
    required String type, // expense, income, lend, borrow
    required String categoryId,
    required String categoryName,
    required String paymentMethod,
    required DateTime date,
    String? attachmentUrl,
    String? personName,
    String? personUserId,
    required String status, // pending, completed
  }) async {
    final userId = _ref.read(authNotifierProvider).user?.id;
    if (userId == null) throw Exception('User not authenticated');

    final transaction = LedgerTransaction(
      transactionId: '',
      userId: userId,
      title: title,
      description: description,
      amount: amount,
      type: type,
      categoryId: categoryId,
      categoryName: categoryName,
      paymentMethod: paymentMethod,
      date: date,
      attachmentUrl: attachmentUrl,
      personName: personName,
      personUserId: personUserId,
      status: status,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _ref.read(ledgerRepositoryProvider).addTransaction(transaction);
  }

  Future<void> updateTransaction(LedgerTransaction transaction) async {
    final updated = transaction.copyWith(updatedAt: DateTime.now());
    await _ref.read(ledgerRepositoryProvider).updateTransaction(updated);
  }

  Future<void> deleteTransaction(String transactionId) async {
    final userId = _ref.read(authNotifierProvider).user?.id;
    if (userId == null) throw Exception('User not authenticated');
    await _ref.read(ledgerRepositoryProvider).deleteTransaction(userId, transactionId);
  }

  Future<void> settleTransaction(String transactionId, List<LedgerTransaction> currentTransactions) async {
    final tx = currentTransactions.firstWhere((t) => t.transactionId == transactionId);
    final updated = tx.copyWith(status: 'completed', updatedAt: DateTime.now());
    await updateTransaction(updated);
  }
}

final ledgerControllerProvider = Provider<LedgerController>((ref) {
  return LedgerController(ref);
});
