import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationWriter {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sends a notification to a specific user.
  /// Used for direct notifications (e.g., personal ledger, settlement, welcome).
  static Future<void> sendToUser({
    required String targetUserId,
    required String title,
    required String description,
    required String type,
    String? relatedItemId,
    String? groupId,
    Transaction? transaction,
  }) async {
    String resolvedUserId = targetUserId;
    if (targetUserId == 'user_me') {
      resolvedUserId = FirebaseAuth.instance.currentUser?.uid ?? targetUserId;
    }

    final docRef = _firestore
        .collection('users')
        .doc(resolvedUserId)
        .collection('notifications')
        .doc();

    final data = {
      'id': docRef.id,
      'title': title,
      'description': description,
      'type': type,
      if (relatedItemId != null) 'relatedItemId': relatedItemId,
      if (groupId != null) 'groupId': groupId,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    };

    if (transaction != null) {
      transaction.set(docRef, data);
    } else {
      await docRef.set(data);
    }
  }

  /// Sends a notification to all members of a group/nest.
  /// Used for group events (e.g., expense added, chat message, new member joined).
  /// Excludes the [excludeUserId] if provided (usually the actor who triggered it).
  static Future<void> sendToGroup({
    required String groupId,
    required String title,
    required String description,
    required String type,
    String? relatedItemId,
    String? excludeUserId,
  }) async {
    try {
      final nestDoc = await _firestore.collection('nests').doc(groupId).get();
      if (!nestDoc.exists) return;

      final List<dynamic> memberIds = nestDoc.data()?['memberIds'] ?? [];
      
      final batch = _firestore.batch();
      for (final String memberId in memberIds) {
        if (excludeUserId != null && memberId == excludeUserId) {
          continue; // Don't notify the person who did the action
        }
        
        final docRef = _firestore
            .collection('users')
            .doc(memberId)
            .collection('notifications')
            .doc();

        batch.set(docRef, {
          'id': docRef.id,
          'title': title,
          'description': description,
          'type': type,
          if (relatedItemId != null) 'relatedItemId': relatedItemId,
          'groupId': groupId,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }

      await batch.commit();
    } catch (e) {
      // Ignore errors for notifications to prevent breaking main flows
    }
  }
}
