import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum representing the available group types for a Nest.
enum GroupType {
  flatmates,
  family,
  travel,
  office,
  friends,
  custom;

  String get displayName {
    switch (this) {
      case GroupType.flatmates:
        return 'Flatmates';
      case GroupType.family:
        return 'Family';
      case GroupType.travel:
        return 'Travel';
      case GroupType.office:
        return 'Office';
      case GroupType.friends:
        return 'Friends';
      case GroupType.custom:
        return 'Custom';
    }
  }

  static GroupType fromString(String value) {
    return GroupType.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => GroupType.custom,
    );
  }
}

/// Enum for member roles within a group.
enum MemberRole {
  admin,
  member;

  String get displayName {
    switch (this) {
      case MemberRole.admin:
        return 'Admin';
      case MemberRole.member:
        return 'Member';
    }
  }
}

/// Represents a member inside a group.
class GroupMember {
  final String id;
  final String name;
  final String email;
  final MemberRole role;
  final DateTime joinedAt;
  final String? photoUrl;

  GroupMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    DateTime? joinedAt,
    this.photoUrl,
  }) : joinedAt = joinedAt ?? DateTime.now();

  GroupMember copyWith({
    String? id,
    String? name,
    String? email,
    MemberRole? role,
    DateTime? joinedAt,
    String? photoUrl,
  }) {
    return GroupMember(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'joinedAt': joinedAt.toIso8601String(),
      'photoUrl': photoUrl,
    };
  }

  factory GroupMember.fromMap(Map<String, dynamic> map) {
    return GroupMember(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: MemberRole.values.firstWhere(
        (e) => e.name == (map['role'] ?? 'member'),
        orElse: () => MemberRole.member,
      ),
      joinedAt: map['joinedAt'] != null
          ? DateTime.parse(map['joinedAt'])
          : DateTime.now(),
      photoUrl: map['photoUrl'],
    );
  }
}

/// Represents the invite method used to add a member.
enum InviteMethod { email, phone, username, inviteCode, shareLink }

/// A pending invite that has not yet been accepted.
class PendingInvite {
  final String value; // email, username, or code
  final InviteMethod method;

  const PendingInvite({required this.value, required this.method});
}

/// The core Group (Nest) domain model, Firestore-ready.
///
/// Firestore document structure:
/// ```
/// groups/{groupId}
/// {
///   groupId, groupName, description, groupType,
///   createdBy, createdAt, memberCount,
///   totalExpenses, totalPending, groupImage
/// }
/// ```
class Group {
  final String id;
  final String name;
  final String description;
  final String? imageUrl;
  final int membersCount;
  final double pendingBalance;
  final String type;
  final String status; // 'Owed', 'You owe', 'Settled'

  // Firestore-specific fields
  final String createdBy;
  final DateTime createdAt;
  final double totalExpenses;
  final double totalPending;
  final double totalSettled;
  final String? groupImage;
  final List<GroupMember> members;
  final String? inviteCode;
  final int settlementCycleDate;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  // Chat summary fields
  final String? lastMessage;
  final String? lastMessageSender;
  final DateTime? lastMessageTime;
  final String? lastMessageType;
  final int? unreadCount;

  Group({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    required this.membersCount,
    required this.pendingBalance,
    required this.type,
    required this.status,
    this.createdBy = '',
    DateTime? createdAt,
    this.totalExpenses = 0.0,
    this.totalPending = 0.0,
    this.totalSettled = 0.0,
    this.groupImage,
    this.members = const [],
    this.inviteCode,
    this.settlementCycleDate = 1,
    this.customStartDate,
    this.customEndDate,
    this.lastMessage,
    this.lastMessageSender,
    this.lastMessageTime,
    this.lastMessageType,
    this.unreadCount,
  }) : createdAt = createdAt ?? DateTime.now();

  Group copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    int? membersCount,
    double? pendingBalance,
    String? type,
    String? status,
    String? createdBy,
    DateTime? createdAt,
    double? totalExpenses,
    double? totalPending,
    double? totalSettled,
    String? groupImage,
    List<GroupMember>? members,
    String? inviteCode,
    int? settlementCycleDate,
    DateTime? customStartDate,
    DateTime? customEndDate,
    String? lastMessage,
    String? lastMessageSender,
    DateTime? lastMessageTime,
    String? lastMessageType,
    int? unreadCount,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      membersCount: membersCount ?? this.membersCount,
      pendingBalance: pendingBalance ?? this.pendingBalance,
      type: type ?? this.type,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      totalPending: totalPending ?? this.totalPending,
      totalSettled: totalSettled ?? this.totalSettled,
      groupImage: groupImage ?? this.groupImage,
      members: members ?? this.members,
      inviteCode: inviteCode ?? this.inviteCode,
      settlementCycleDate: settlementCycleDate ?? this.settlementCycleDate,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSender: lastMessageSender ?? this.lastMessageSender,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  /// Converts to Firestore document map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupName': name,
      'description': description,
      'imageUrl': imageUrl,
      'memberCount': membersCount,
      'pendingBalance': pendingBalance,
      'groupType': type,
      'status': status,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'totalExpenses': totalExpenses,
      'totalPending': totalPending,
      'totalSettled': totalSettled,
      'groupImage': groupImage,
      'members': members.map((m) => m.toMap()).toList(),
      'inviteCode': inviteCode,
      'settlementCycleDate': settlementCycleDate,
      'customStartDate': customStartDate?.toIso8601String(),
      'customEndDate': customEndDate?.toIso8601String(),
      'lastMessage': lastMessage,
      'lastMessageSender': lastMessageSender,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'lastMessageType': lastMessageType,
      'unreadCount': unreadCount,
    };
  }

  /// Creates a Group from a Firestore document map.
  factory Group.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return Group(
      id: map['id'] ?? '',
      name: map['groupName'] ?? map['name'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'],
      membersCount: map['memberCount'] ?? map['membersCount'] ?? 0,
      pendingBalance: (map['pendingBalance'] as num?)?.toDouble() ?? 0.0,
      type: map['groupType'] ?? map['type'] ?? 'Custom',
      status: map['status'] ?? 'Settled',
      createdBy: map['createdBy'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is Timestamp 
              ? (map['createdAt'] as Timestamp).toDate() 
              : DateTime.parse(map['createdAt']))
          : DateTime.now(),
      totalExpenses: (map['totalExpenses'] as num?)?.toDouble() ?? 0.0,
      totalPending: (map['totalPending'] as num?)?.toDouble() ?? 0.0,
      totalSettled: (map['totalSettled'] as num?)?.toDouble() ?? 0.0,
      groupImage: map['groupImage'],
      members: (map['members'] as List<dynamic>?)
              ?.map((m) => GroupMember.fromMap(m as Map<String, dynamic>))
              .toList() ??
          const [],
      inviteCode: map['inviteCode'],
      settlementCycleDate: map['settlementCycleDate'] ?? 1,
      customStartDate: map['customStartDate'] != null
          ? (map['customStartDate'] is Timestamp 
              ? (map['customStartDate'] as Timestamp).toDate() 
              : DateTime.parse(map['customStartDate']))
          : null,
      customEndDate: map['customEndDate'] != null
          ? (map['customEndDate'] is Timestamp 
              ? (map['customEndDate'] as Timestamp).toDate() 
              : DateTime.parse(map['customEndDate']))
          : null,
      lastMessage: map['lastMessage'],
      lastMessageSender: map['lastMessageSender'],
      lastMessageTime: parseDate(map['lastMessageTime']),
      lastMessageType: map['lastMessageType'],
      unreadCount: map['unreadCount'] != null ? (map['unreadCount'] as num).toInt() : null,
    );
  }
}
