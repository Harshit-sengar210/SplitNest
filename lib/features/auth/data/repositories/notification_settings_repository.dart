import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/notification_settings.dart';
import 'firebase_auth_repository.dart';

final notificationSettingsRepositoryProvider = Provider<NotificationSettingsRepository>((ref) {
  return NotificationSettingsRepository(FirebaseFirestore.instance);
});

class NotificationSettingsRepository {
  final FirebaseFirestore _firestore;

  NotificationSettingsRepository(this._firestore);

  Future<NotificationSettings> getSettings(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).collection('settings').doc('notifications').get();
    if (doc.exists && doc.data() != null) {
      return NotificationSettings.fromMap(doc.data()!, userId);
    }
    // Default settings if not found
    return NotificationSettings(userId: userId);
  }

  Future<void> updateSettings(NotificationSettings settings) async {
    await _firestore
        .collection('users')
        .doc(settings.userId)
        .collection('settings')
        .doc('notifications')
        .set(settings.toMap(), SetOptions(merge: true));
  }
}
