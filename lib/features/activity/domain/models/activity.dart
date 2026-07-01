import 'package:cloud_firestore/cloud_firestore.dart';

class Activity {
  final String id;
  final String type;
  final String title;
  final String description;
  final double? amount;
  final String userId;
  final String userName;
  final String? expenseId;
  final String? settlementId;
  final String? memberId;
  final String icon;
  final DateTime createdAt;

  // Backward-compatibility getters
  String get activityType => type;
  String get actorId => userId;
  String? get actorName => userName.isEmpty ? null : userName;
  String? get relatedId => expenseId;

  // Backward compatibility fields stored in the class
  final String? groupId;
  final String? groupName;

  const Activity({
    required this.id,
    String? type,
    String? activityType,
    required this.title,
    required this.description,
    this.amount,
    String? userId,
    String? actorId,
    String? userName,
    String? actorName,
    String? expenseId,
    String? relatedId,
    this.settlementId,
    this.memberId,
    String? icon,
    required this.createdAt,
    this.groupId,
    this.groupName,
  }) : type = type ?? activityType ?? 'expense_added',
       userId = userId ?? actorId ?? '',
       userName = userName ?? actorName ?? '',
       expenseId = expenseId ?? relatedId,
       icon = icon ?? 'receipt';

  Activity copyWith({
    String? id,
    String? type,
    String? title,
    String? description,
    double? amount,
    String? userId,
    String? userName,
    String? expenseId,
    String? settlementId,
    String? memberId,
    String? icon,
    DateTime? createdAt,
    String? groupId,
    String? groupName,
  }) {
    return Activity(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      expenseId: expenseId ?? this.expenseId,
      settlementId: settlementId ?? this.settlementId,
      memberId: memberId ?? this.memberId,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'activityId': id,
      'type': type,
      'title': title,
      'description': description,
      'amount': amount,
      'userId': userId,
      'userName': userName,
      'expenseId': expenseId,
      'settlementId': settlementId,
      'memberId': memberId,
      'icon': icon,
      'createdAt': Timestamp.fromDate(createdAt),
      if (groupId != null) 'groupId': groupId,
      if (groupName != null) 'groupName': groupName,
    };
  }

  factory Activity.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parseCreatedAt(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return Activity(
      id: docId ?? map['activityId'] ?? map['id'] ?? '',
      type: map['type'] ?? map['activityType'] ?? 'expense_added',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] as num?)?.toDouble(),
      userId: map['userId'] ?? map['actorId'] ?? '',
      userName: map['userName'] ?? map['actorName'] ?? '',
      expenseId: map['expenseId'] ?? map['relatedId'],
      settlementId: map['settlementId'],
      memberId: map['memberId'],
      icon: map['icon'] ?? 'receipt',
      createdAt: parseCreatedAt(map['createdAt']),
      groupId: map['groupId'],
      groupName: map['groupName'],
    );
  }
}
