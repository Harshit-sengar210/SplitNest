import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../features/expenses/domain/models/expense.dart';

class Message {
  final String messageId;
  final String groupId;
  final String senderId;
  final String senderName;
  final String? senderPhoto;
  final String message;
  final String messageType; // 'text', 'image', 'system'
  final DateTime createdAt;
  final DateTime? editedAt;
  final bool isEdited;
  final bool isDeleted;

  // Compatibility fields
  final Expense? expenseDetails;

  // Compatibility getters
  String get id => messageId;
  String get text => message;
  DateTime get timestamp => createdAt;
  String? get imageUrl => messageType == 'image' ? message : null;
  bool get isRead => true; // Compatibility check

  Message({
    String? messageId,
    required this.groupId,
    required this.senderId,
    required this.senderName,
    this.senderPhoto,
    String? message,
    String? messageType,
    DateTime? createdAt,
    this.editedAt,
    this.isEdited = false,
    this.isDeleted = false,
    this.expenseDetails,
    // Legacy support parameters:
    String? id,
    String? text,
    DateTime? timestamp,
    String? imageUrl,
  })  : messageId = messageId ?? id ?? '',
        message = message ?? text ?? imageUrl ?? '',
        messageType = messageType ?? (imageUrl != null ? 'image' : 'text'),
        createdAt = createdAt ?? timestamp ?? DateTime.now();

  Message copyWith({
    String? messageId,
    String? groupId,
    String? senderId,
    String? senderName,
    String? senderPhoto,
    String? message,
    String? messageType,
    DateTime? createdAt,
    DateTime? editedAt,
    bool? isEdited,
    bool? isDeleted,
    Expense? expenseDetails,
    // Legacy support:
    String? id,
    String? text,
    DateTime? timestamp,
    String? imageUrl,
  }) {
    return Message(
      messageId: messageId ?? id ?? this.messageId,
      groupId: groupId ?? this.groupId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderPhoto: senderPhoto ?? this.senderPhoto,
      message: message ?? text ?? (imageUrl != null ? imageUrl : this.message),
      messageType: messageType ?? (imageUrl != null ? 'image' : this.messageType),
      createdAt: createdAt ?? timestamp ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      expenseDetails: expenseDetails ?? this.expenseDetails,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'groupId': groupId,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhoto': senderPhoto,
      'message': message,
      'messageType': messageType,
      'createdAt': Timestamp.fromDate(createdAt),
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'isEdited': isEdited,
      'isDeleted': isDeleted,
      'expenseDetails': expenseDetails?.toMap(),
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return Message(
      messageId: map['messageId'] ?? map['id'] ?? '',
      groupId: map['groupId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderPhoto: map['senderPhoto'] ?? map['photoUrl'],
      message: map['message'] ?? map['text'] ?? '',
      messageType: map['messageType'] ?? (map['imageUrl'] != null ? 'image' : 'text'),
      createdAt: parseDate(map['createdAt'] ?? map['timestamp']),
      editedAt: map['editedAt'] != null ? parseDate(map['editedAt']) : null,
      isEdited: map['isEdited'] ?? false,
      isDeleted: map['isDeleted'] ?? false,
      expenseDetails: map['expenseDetails'] != null ? Expense.fromMap(map['expenseDetails']) : null,
    );
  }
}
