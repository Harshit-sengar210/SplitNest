import 'package:cloud_firestore/cloud_firestore.dart';

class SplitService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveSplits(String nestId, String expenseId, List<Map<String, dynamic>> splitsData) async {
    final batch = _firestore.batch();
    for (final data in splitsData) {
      final memberId = data['memberId'] as String;
      final ref = _firestore
          .collection('nests')
          .doc(nestId)
          .collection('expenses')
          .doc(expenseId)
          .collection('splits')
          .doc(memberId);
      batch.set(ref, data);
    }
    await batch.commit();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamSplits(String nestId, String expenseId) {
    return _firestore
        .collection('nests')
        .doc(nestId)
        .collection('expenses')
        .doc(expenseId)
        .collection('splits')
        .snapshots();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getSplits(String nestId, String expenseId) {
    return _firestore
        .collection('nests')
        .doc(nestId)
        .collection('expenses')
        .doc(expenseId)
        .collection('splits')
        .get();
  }
}
