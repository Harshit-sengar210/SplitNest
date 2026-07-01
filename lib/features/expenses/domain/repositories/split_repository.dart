import '../models/split_model.dart';

abstract class SplitRepository {
  Future<void> saveSplits(String nestId, String expenseId, List<SplitModel> splits);
  Stream<List<SplitModel>> streamSplits(String nestId, String expenseId);
  Future<List<SplitModel>> getSplits(String nestId, String expenseId);
}
