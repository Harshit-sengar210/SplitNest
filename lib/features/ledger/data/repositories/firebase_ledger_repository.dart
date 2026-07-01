import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/ledger_transaction.dart';
import '../../domain/models/ledger_summary.dart';
import '../../domain/repositories/ledger_repository.dart';

class FirebaseLedgerRepository implements LedgerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _transactionsRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('ledger')
        .doc('transactions')
        .collection('transactions');
  }

  DocumentReference _summaryRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('ledger')
        .doc('summary');
  }

  @override
  Stream<List<LedgerTransaction>> streamTransactions(String userId) {
    return _transactionsRef(userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => LedgerTransaction.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  @override
  Stream<LedgerSummary?> streamSummary(String userId) {
    return _summaryRef(userId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return LedgerSummary.zero();
      }
      return LedgerSummary.fromMap(doc.data() as Map<String, dynamic>);
    });
  }

  @override
  Future<void> addTransaction(LedgerTransaction transaction) async {
    final docRef = _transactionsRef(transaction.userId).doc();
    final updatedTx = transaction.copyWith(transactionId: docRef.id);
    await docRef.set(updatedTx.toMap());
    await _recalculateAndSaveSummary(transaction.userId);
  }

  @override
  Future<void> updateTransaction(LedgerTransaction transaction) async {
    await _transactionsRef(transaction.userId)
        .doc(transaction.transactionId)
        .set(transaction.toMap());
    await _recalculateAndSaveSummary(transaction.userId);
  }

  @override
  Future<void> deleteTransaction(String userId, String transactionId) async {
    await _transactionsRef(userId).doc(transactionId).delete();
    await _recalculateAndSaveSummary(userId);
  }

  Future<void> _recalculateAndSaveSummary(String userId) async {
    final snapshot = await _transactionsRef(userId).get();
    double totalIncome = 0.0;
    double totalExpense = 0.0;
    double totalLend = 0.0;
    double totalBorrow = 0.0;

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) continue;
      final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
      final type = (data['type'] as String? ?? '').toLowerCase();

      if (type == 'income') {
        totalIncome += amount;
      } else if (type == 'expense') {
        totalExpense += amount;
      } else if (type == 'lend') {
        totalLend += amount;
      } else if (type == 'borrow') {
        totalBorrow += amount;
      }
    }

    final netBalance = totalIncome - totalExpense + totalLend - totalBorrow;

    final summary = LedgerSummary(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      totalLend: totalLend,
      totalBorrow: totalBorrow,
      netBalance: netBalance,
      updatedAt: DateTime.now(),
    );

    await _summaryRef(userId).set(summary.toMap());
  }
}
