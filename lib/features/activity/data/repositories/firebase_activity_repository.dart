import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/activity.dart';
import '../../domain/repositories/activity_repository.dart';

class FirebaseActivityRepository implements ActivityRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _timelineRef(String groupId) =>
      _firestore.collection('nests').doc(groupId).collection('timeline');

  @override
  Future<List<Activity>> getGlobalActivities() async {
    // Global feed not backed by Firestore – return empty for now.
    return [];
  }

  @override
  Future<List<Activity>> getGroupActivities(String groupId) async {
    final snap = await _timelineRef(groupId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs
        .map((doc) => Activity.fromMap(doc.data(), doc.id))
        .toList();
  }

  @override
  Stream<List<Activity>> streamGroupActivities(String groupId) {
    return _timelineRef(groupId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Activity.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<void> createActivity(Activity activity) async {
    final docRef = _timelineRef(activity.groupId ?? '').doc();
    await docRef.set({
      ...activity.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
