import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/app_notification.dart';

final notificationsStreamProvider = StreamProvider<List<AppNotification>>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final userId = authState.user?.id;
  if (userId == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
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
  final list = ref.watch(notificationsStreamProvider).value ?? [];
  return list.where((n) {
    return n.type != 'payment_received' &&
           n.type != 'settlement_received' &&
           n.type != 'settlement_paid';
  }).toList();
});
