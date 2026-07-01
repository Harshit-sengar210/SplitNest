import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/message.dart';
import 'mock_chat_repository.dart';

class FirebaseChatRepository implements ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  @override
  Stream<List<Message>> getMessagesStream(String groupId) {
    final currentUser = _firebaseAuth.currentUser;
    return _firestore
        .collection('nests')
        .doc(groupId)
        .collection('Chats')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        if (!data.containsKey('messageId')) {
          data['messageId'] = doc.id;
        }
        
        // Map real Firebase UID to 'user_me' for the current logged-in user
        final rawSenderId = data['senderId'] ?? '';
        if (currentUser != null && rawSenderId == currentUser.uid) {
          data['senderId'] = 'user_me';
        }
        
        return Message.fromMap(data);
      }).toList();
    });
  }

  @override
  Future<void> sendMessage(Message message) async {
    final currentUser = _firebaseAuth.currentUser;
    final realSenderId = (message.senderId == 'user_me' && currentUser != null)
        ? currentUser.uid
        : message.senderId;

    // Always resolve the sender's display name and photo from Firebase Auth
    // so the stored data is always accurate even if the client passed stale values.
    String senderName = message.senderName;
    String? senderPhoto = message.senderPhoto;
    if (currentUser != null && (senderName == 'You' || senderName.isEmpty)) {
      senderName = currentUser.displayName ??
          currentUser.email?.split('@').first ??
          'User';
      senderPhoto = currentUser.photoURL;
    }

    // ── Always use a Firestore-generated document ID ────────────────────────
    // This guarantees uniqueness even if the user taps Send multiple times
    // rapidly. Each call produces a distinct ref; the _isBusy guard in the
    // notifier is a second safety layer.
    final chatsCollection = _firestore
        .collection('nests')
        .doc(message.groupId)
        .collection('Chats');

    final messageRef = chatsCollection.doc(); // auto-generated ID
    final generatedId = messageRef.id;

    final nestRef = _firestore.collection('nests').doc(message.groupId);

    // Build the payload — use FieldValue.serverTimestamp() for createdAt so
    // ordering is always accurate regardless of client clock drift.
    final now = DateTime.now();
    final Map<String, dynamic> messageData = {
      'messageId': generatedId,
      'groupId': message.groupId,
      'senderId': realSenderId,
      'senderName': senderName,
      'senderPhoto': senderPhoto,
      'message': message.message,
      'messageType': message.messageType,
      'createdAt': FieldValue.serverTimestamp(),
      'editedAt': null,
      'isEdited': false,
      'isDeleted': false,
    };

    // Derive the lastMessage preview text
    String lastMessageText = message.message;
    if (message.messageType == 'image') {
      lastMessageText = '📷 Photo';
    } else if (message.messageType == 'system') {
      lastMessageText = message.message;
    }

    final Map<String, dynamic> nestUpdate = {
      'lastMessage': lastMessageText,
      'lastMessageSender': senderName,
      'lastMessageTime': Timestamp.fromDate(now),
      'lastMessageType': message.messageType,
    };

    // ── Atomic batch write ───────────────────────────────────────────────────
    final batch = _firestore.batch();
    batch.set(messageRef, messageData);   // 1. message document
    batch.update(nestRef, nestUpdate);    // 2. nest metadata
    await batch.commit();                 // both or neither
  }

  @override
  Future<void> editMessage(
      String groupId, String messageId, String newText) async {
    await _firestore
        .collection('nests')
        .doc(groupId)
        .collection('Chats')
        .doc(messageId)
        .update({
      'message': newText,
      'isEdited': true,
      'editedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  @override
  Future<void> deleteMessage(String groupId, String messageId) async {
    // Soft-delete: keeps the document so stream listeners see the update
    await _firestore
        .collection('nests')
        .doc(groupId)
        .collection('Chats')
        .doc(messageId)
        .update({
      'isDeleted': true,
    });
  }
}
