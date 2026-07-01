import '../../domain/models/activity.dart';
import '../../domain/repositories/activity_repository.dart';
import '../../../../core/utils/mock_database.dart';

class MockActivityRepository implements ActivityRepository {
  final MockDatabase _db = MockDatabase();

  @override
  Future<List<Activity>> getGlobalActivities() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.from(_db.activities);
  }

  @override
  Future<List<Activity>> getGroupActivities(String groupId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _db.activities.where((a) => a.groupId == groupId).toList();
  }

  @override
  Stream<List<Activity>> streamGroupActivities(String groupId) {
    return _db.changeStream.map((_) =>
        _db.activities.where((a) => a.groupId == groupId).toList());
  }

  @override
  Future<void> createActivity(Activity activity) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _db.activities.insert(0, activity);
    _db.triggerChange();
  }
}
