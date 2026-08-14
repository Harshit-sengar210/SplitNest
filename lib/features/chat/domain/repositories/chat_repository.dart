import '../../domain/models/message.dart';

abstract class ChatRepository {
  Stream<List<Message>> getMessagesStream(String groupId);
  Future<void> sendMessage(Message message);
  Future<void> editMessage(String groupId, String messageId, String newText);
  Future<void> deleteMessage(String groupId, String messageId);
}
