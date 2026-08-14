import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/app_notification.dart';

import 'package:firebase_auth/firebase_auth.dart';

final notificationsStreamProvider = StreamProvider<List<AppNotification>>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final userId = authState.user?.id;
  if (userId == null) return const Stream.empty();

  String resolvedUserId = userId;
  if (userId == 'user_me') {
    resolvedUserId = FirebaseAuth.instance.currentUser?.uid ?? userId;
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(resolvedUserId)
      .collection('notifications')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      DateTime parseDate(dynamic val) {
        if (val == null) return DateTime.now();
        if (val is Timestamp) return val.toDate();
        if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
        return DateTime.now();
      }
      return AppNotification(
        id: doc.id,
        title: data['title'] ?? '',
        description: data['description'] ?? '',
        type: data['type'] ?? 'system_update',
        relatedItemId: data['relatedItemId'],
        groupId: data['groupId'],
        timestamp: parseDate(data['timestamp'] ?? data['createdAt']),
        isRead: data['isRead'] ?? false,
      );
    }).toList();
  });
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifsAsync = ref.watch(notificationsStreamProvider);
  return notifsAsync.value?.where((n) => !n.isRead).length ?? 0;
});

final notificationsProvider = Provider<List<AppNotification>>((ref) {
  return ref.watch(notificationsStreamProvider).value ?? [];
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return NotificationService(userId: authState.user?.id);
});

class NotificationService {
  final String? userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  NotificationService({required this.userId});

  String _resolveUserId() {
    if (userId == 'user_me') {
      return FirebaseAuth.instance.currentUser?.uid ?? userId!;
    }
    return userId!;
  }

  Future<void> markAsRead(String notificationId) async {
    if (userId == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(_resolveUserId())
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    if (userId == null) return;
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_resolveUserId())
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    if (userId == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(_resolveUserId())
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }
}
