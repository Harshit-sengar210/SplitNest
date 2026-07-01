import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../domain/models/message.dart';
import '../../../../core/utils/mock_database.dart';
import 'firebase_chat_repository.dart';

abstract class ChatRepository {
  Stream<List<Message>> getMessagesStream(String groupId);
  Future<void> sendMessage(Message message);
  Future<void> editMessage(String groupId, String messageId, String newText);
  Future<void> deleteMessage(String groupId, String messageId);
}

class MockChatRepository implements ChatRepository {
  final Map<String, List<Message>> _messages = {};
  final Map<String, StreamController<List<Message>>> _controllers = {};

  @override
  Stream<List<Message>> getMessagesStream(String groupId) {
    if (!_controllers.containsKey(groupId)) {
      _controllers[groupId] = StreamController<List<Message>>.broadcast();
    }
    
    if (!_messages.containsKey(groupId)) {
      _messages[groupId] = [
        Message(
          messageId: 'msg_1',
          groupId: groupId,
          senderId: 'user_sarah',
          senderName: 'Sarah',
          message: 'Awesome, thanks! I\'ll add the wifi bill later today.',
          messageType: 'text',
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        Message(
          messageId: 'msg_sys_exp',
          groupId: groupId,
          senderId: 'system',
          senderName: 'System',
          message: 'Expense added: Grocery Shopping - \$120.00',
          messageType: 'system',
          createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
        ),
        Message(
          messageId: 'msg_2',
          groupId: groupId,
          senderId: 'user_me',
          senderName: 'You',
          message: 'Hey everyone, I just created the group for our expenses!',
          messageType: 'text',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        Message(
          messageId: 'msg_sys_joined',
          groupId: groupId,
          senderId: 'system',
          senderName: 'System',
          message: 'Papa joined the nest',
          messageType: 'system',
          createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
        ),
        Message(
          messageId: 'msg_yesterday_1',
          groupId: groupId,
          senderId: 'user_sarah',
          senderName: 'Sarah',
          message: 'Is anyone going to get groceries today?',
          messageType: 'text',
          createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
        ),
        Message(
          messageId: 'msg_sys_added',
          groupId: groupId,
          senderId: 'system',
          senderName: 'System',
          message: 'Harshit added Naresh',
          messageType: 'system',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        Message(
          messageId: 'msg_older_1',
          groupId: groupId,
          senderId: 'user_sarah',
          senderName: 'Sarah',
          message: 'Hello everyone! Excited to use SplitNest!',
          messageType: 'text',
          createdAt: DateTime.now().subtract(const Duration(days: 3, hours: 1)),
        ),
      ];
    }
    
    // Yield the initial state immediately when someone listens
    Future.microtask(() {
      if (_controllers[groupId]?.isClosed == false) {
        _controllers[groupId]!.add(List.from(_messages[groupId]!));
      }
    });

    return _controllers[groupId]!.stream;
  }

  @override
  Future<void> sendMessage(Message message) async {
    final groupId = message.groupId;
    if (!_messages.containsKey(groupId)) {
      _messages[groupId] = [];
    }
    if (!_controllers.containsKey(groupId)) {
      _controllers[groupId] = StreamController<List<Message>>.broadcast();
    }

    // Optimistic UI update: instantly add the message locally and broadcast
    _messages[groupId]!.insert(0, message);
    _controllers[groupId]!.add(List.from(_messages[groupId]!));

    // Add Notification
    String groupName = 'Group';
    try {
      final grp = MockDatabase().groups.firstWhere((g) => g.id == groupId);
      groupName = grp.name;
    } catch (_) {}

    MockDatabase().addNotification(
      title: 'New message in $groupName',
      description: '${message.senderName}: ${message.text}',
      type: 'chat_message',
      groupId: groupId,
      relatedItemId: message.id,
    );

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> editMessage(
      String groupId, String messageId, String newText) async {
    final msgs = _messages[groupId];
    if (msgs == null) return;
    final idx = msgs.indexWhere((m) => m.messageId == messageId);
    if (idx == -1) return;
    msgs[idx] = msgs[idx].copyWith(
      message: newText,
      isEdited: true,
      editedAt: DateTime.now(),
    );
    _controllers[groupId]?.add(List.from(msgs));
  }

  @override
  Future<void> deleteMessage(String groupId, String messageId) async {
    final msgs = _messages[groupId];
    if (msgs == null) return;
    final idx = msgs.indexWhere((m) => m.messageId == messageId);
    if (idx == -1) return;
    msgs[idx] = msgs[idx].copyWith(isDeleted: true);
    _controllers[groupId]?.add(List.from(msgs));
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  try {
    if (Firebase.apps.isNotEmpty) {
      return FirebaseChatRepository();
    }
  } catch (_) {}
  return MockChatRepository();
});
