import 'package:cloud_firestore/cloud_firestore.dart';

class Settlement {
  final String id; // maps to settlementId
  final String groupId;
  final String expenseId;
  final String splitId;
  final String payerId;
  final String receiverId;
  final double amount;
  final String status;
  final String createdBy;
  final DateTime createdAt;

  // UI convenience helper fields (nullable or default)
  final String? payerName;
  final String? receiverName;

  const Settlement({
    required this.id,
    required this.groupId,
    required this.expenseId,
    required this.splitId,
    required this.payerId,
    required this.receiverId,
    required this.amount,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    this.payerName,
    this.receiverName,
  });

  Settlement copyWith({
    String? id,
    String? groupId,
    String? expenseId,
    String? splitId,
    String? payerId,
    String? receiverId,
    double? amount,
    String? status,
    String? createdBy,
    DateTime? createdAt,
    String? payerName,
    String? receiverName,
  }) {
    return Settlement(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      expenseId: expenseId ?? this.expenseId,
      splitId: splitId ?? this.splitId,
      payerId: payerId ?? this.payerId,
      receiverId: receiverId ?? this.receiverId,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      payerName: payerName ?? this.payerName,
      receiverName: receiverName ?? this.receiverName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'settlementId': id,
      'groupId': groupId,
      'expenseId': expenseId,
      'splitId': splitId,
      'payerId': payerId,
      'receiverId': receiverId,
      'amount': amount,
      'status': status,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'payerName': payerName,
      'receiverName': receiverName,
    };
  }

  factory Settlement.fromMap(Map<String, dynamic> map) {
    return Settlement(
      id: map['settlementId'] ?? map['id'] ?? '',
      groupId: map['groupId'] ?? '',
      expenseId: map['expenseId'] ?? '',
      splitId: map['splitId'] ?? '',
      payerId: map['payerId'] ?? map['paidBy'] ?? map['fromUserId'] ?? '',
      receiverId: map['receiverId'] ?? map['receivedBy'] ?? map['toUserId'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'completed',
      createdBy: map['createdBy'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is Timestamp
              ? (map['createdAt'] as Timestamp).toDate()
              : DateTime.parse(map['createdAt'].toString()))
          : (map['timestamp'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'])
              : DateTime.now()),
      payerName: map['payerName'] ?? map['fromUserName'] ?? map['paidByName'],
      receiverName: map['receiverName'] ?? map['toUserName'] ?? map['receivedByName'],
    );
  }
}
