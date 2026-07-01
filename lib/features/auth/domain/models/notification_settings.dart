class NotificationSettings {
  final String userId;
  final bool expenseAlerts;
  final bool settlementAlerts;
  final bool chatAlerts;
  final bool memberAlerts;
  final bool groupAlerts;

  const NotificationSettings({
    required this.userId,
    this.expenseAlerts = true,
    this.settlementAlerts = true,
    this.chatAlerts = true,
    this.memberAlerts = true,
    this.groupAlerts = true,
  });

  NotificationSettings copyWith({
    String? userId,
    bool? expenseAlerts,
    bool? settlementAlerts,
    bool? chatAlerts,
    bool? memberAlerts,
    bool? groupAlerts,
  }) {
    return NotificationSettings(
      userId: userId ?? this.userId,
      expenseAlerts: expenseAlerts ?? this.expenseAlerts,
      settlementAlerts: settlementAlerts ?? this.settlementAlerts,
      chatAlerts: chatAlerts ?? this.chatAlerts,
      memberAlerts: memberAlerts ?? this.memberAlerts,
      groupAlerts: groupAlerts ?? this.groupAlerts,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'expenseAlerts': expenseAlerts,
      'settlementAlerts': settlementAlerts,
      'chatAlerts': chatAlerts,
      'memberAlerts': memberAlerts,
      'groupAlerts': groupAlerts,
    };
  }

  factory NotificationSettings.fromMap(Map<String, dynamic> map, String defaultUserId) {
    return NotificationSettings(
      userId: map['userId'] ?? defaultUserId,
      expenseAlerts: map['expenseAlerts'] ?? true,
      settlementAlerts: map['settlementAlerts'] ?? true,
      chatAlerts: map['chatAlerts'] ?? true,
      memberAlerts: map['memberAlerts'] ?? true,
      groupAlerts: map['groupAlerts'] ?? true,
    );
  }
}
