import '../../domain/models/split_model.dart';
import '../../domain/repositories/split_repository.dart';
import '../services/split_service.dart';

class FirebaseSplitRepository implements SplitRepository {
  final SplitService _service;

  FirebaseSplitRepository(this._service);

  @override
  Future<void> saveSplits(String nestId, String expenseId, List<SplitModel> splits) async {
    final splitsData = splits.map((s) => s.toMap()).toList();
    await _service.saveSplits(nestId, expenseId, splitsData);
  }

  @override
  Stream<List<SplitModel>> streamSplits(String nestId, String expenseId) {
    return _service.streamSplits(nestId, expenseId).map((snapshot) {
      return snapshot.docs.map((doc) => SplitModel.fromMap(doc.data())).toList();
    });
  }

  @override
  Future<List<SplitModel>> getSplits(String nestId, String expenseId) async {
    final snapshot = await _service.getSplits(nestId, expenseId);
    return snapshot.docs.map((doc) => SplitModel.fromMap(doc.data())).toList();
  }
}
