import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/ledger_transaction.dart';
import '../../domain/models/ledger_summary.dart';
import '../../domain/repositories/ledger_repository.dart';
import '../../../activity/data/services/notification_writer.dart';

class FirebaseLedgerRepository implements LedgerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _resolveUserId(String userId) {
    if (userId == 'user_me') {
      final currentUser = FirebaseAuth.instance.currentUser;
      return currentUser?.uid ?? userId;
    }
    return userId;
  }

  CollectionReference _transactionsRef(String userId) {
    return _firestore
        .collection('users')
        .doc(_resolveUserId(userId))
        .collection('ledger')
        .doc('transactions')
        .collection('transactions');
  }

  DocumentReference _summaryRef(String userId) {
    return _firestore
        .collection('users')
        .doc(_resolveUserId(userId))
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
          .where((tx) => tx.source == 'personal')
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

    if (transaction.personUserId != null && transaction.personUserId!.isNotEmpty) {
      NotificationWriter.sendToUser(
        targetUserId: transaction.personUserId!,
        title: 'New Ledger Entry',
        description: 'A ${transaction.type} entry of ₹${transaction.amount.toStringAsFixed(0)} was added involving you.',
        type: 'payment_request',
        relatedItemId: docRef.id,
      );
    }
  }

  @override
  Future<void> updateTransaction(LedgerTransaction transaction) async {
    await _transactionsRef(transaction.userId)
        .doc(transaction.transactionId)
        .set(transaction.toMap());
    await _recalculateAndSaveSummary(transaction.userId);

    if (transaction.status == 'completed' && transaction.personUserId != null && transaction.personUserId!.isNotEmpty) {
      NotificationWriter.sendToUser(
        targetUserId: transaction.personUserId!,
        title: 'Ledger Entry Completed',
        description: 'The ${transaction.type} entry of ₹${transaction.amount.toStringAsFixed(0)} was marked as completed.',
        type: 'payment_received',
        relatedItemId: transaction.transactionId,
      );
    }
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
      
      final source = data['source'] as String? ?? 'group';
      if (source != 'personal') continue;
      
      final status = (data['status'] as String? ?? 'pending').toLowerCase();
      if (status != 'completed') continue;

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
