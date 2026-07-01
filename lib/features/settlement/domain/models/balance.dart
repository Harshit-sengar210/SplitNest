class Balance {
  final String groupId;
  final String fromUserId;
  final String toUserId;
  final double amount;
  final DateTime updatedAt;

  const Balance({
    required this.groupId,
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
    required this.updatedAt,
  });

  Balance copyWith({
    String? groupId,
    String? fromUserId,
    String? toUserId,
    double? amount,
    DateTime? updatedAt,
  }) {
    return Balance(
      groupId: groupId ?? this.groupId,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      amount: amount ?? this.amount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'amount': amount,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Balance.fromMap(Map<String, dynamic> map) {
    return Balance(
      groupId: map['groupId'] ?? '',
      fromUserId: map['fromUserId'] ?? '',
      toUserId: map['toUserId'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }
}
