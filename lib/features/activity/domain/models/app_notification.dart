class AppNotification {
  final String id;
  final String title;
  final String description;
  final String type; // e.g. expense_added, expense_updated, expense_deleted, settlement_received, settlement_paid, payment_request, payment_received, nest_created, nest_updated, member_joined, member_removed, chat_message, receipt_scanned, system_update
  final String? relatedItemId;
  final String? groupId;
  final DateTime timestamp;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.relatedItemId,
    this.groupId,
    required this.timestamp,
    this.isRead = false,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? description,
    String? type,
    String? relatedItemId,
    String? groupId,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      relatedItemId: relatedItemId ?? this.relatedItemId,
      groupId: groupId ?? this.groupId,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}
