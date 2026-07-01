import '../models/activity.dart';

abstract class ActivityRepository {
  Future<List<Activity>> getGlobalActivities();
  
  Future<List<Activity>> getGroupActivities(String groupId);
  Stream<List<Activity>> streamGroupActivities(String groupId);
  
  Future<void> createActivity(Activity activity);
}
