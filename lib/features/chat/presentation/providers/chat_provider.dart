import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../data/repositories/firebase_chat_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Real-time message stream — Firestore snapshots() is the single source of truth
// ─────────────────────────────────────────────────────────────────────────────
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return FirebaseChatRepository();
});

final chatMessagesProvider = StreamProvider.family<List<Message>, String>((ref, groupId) {
  final repository = ref.watch(chatRepositoryProvider);
  // Riverpod disposes the stream subscription automatically when the provider
  // is no longer watched (screen popped / widget disposed).
  return repository.getMessagesStream(groupId);
});

// ─────────────────────────────────────────────────────────────────────────────
// Send message
// ─────────────────────────────────────────────────────────────────────────────
class ChatSendState {
  final bool isSending;
  final String? error;

  const ChatSendState({this.isSending = false, this.error});
}

class ChatSendNotifier extends StateNotifier<ChatSendState> {
  final Ref ref;

  // Hard lock — prevents a second send from starting while one is in flight.
  // This is the server-side duplicate guard; the UI disables the button too.
  bool _isBusy = false;

  ChatSendNotifier(this.ref) : super(const ChatSendState());

  /// Returns `true` on success, `false` on failure or if already sending.
  Future<bool> sendMessage(Message message) async {
    if (_isBusy) return false; // duplicate prevention
    _isBusy = true;
    state = const ChatSendState(isSending: true);
    try {
      final repository = ref.read(chatRepositoryProvider);
      await repository.sendMessage(message);
      state = const ChatSendState(isSending: false);
      return true;
    } catch (e) {
      state = ChatSendState(isSending: false, error: e.toString());
      return false;
    } finally {
      _isBusy = false;
    }
  }
}

final chatSendProvider = StateNotifierProvider<ChatSendNotifier, ChatSendState>((ref) {
  return ChatSendNotifier(ref);
});

// ─────────────────────────────────────────────────────────────────────────────
// Edit message — updates Firestore; stream rebuilds UI automatically
// ─────────────────────────────────────────────────────────────────────────────
class ChatEditDeleteNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  ChatEditDeleteNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<void> editMessage(
      String groupId, String messageId, String newText) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(chatRepositoryProvider).editMessage(groupId, messageId, newText);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteMessage(String groupId, String messageId) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(chatRepositoryProvider).deleteMessage(groupId, messageId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final chatEditDeleteProvider =
    StateNotifierProvider<ChatEditDeleteNotifier, AsyncValue<void>>((ref) {
  return ChatEditDeleteNotifier(ref);
});
