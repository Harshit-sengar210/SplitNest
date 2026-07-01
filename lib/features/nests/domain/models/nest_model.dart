import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NestModel {
  final String nestId;
  final String name;
  final String description;
  final String? coverImage;
  final String category;
  final String currency;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String inviteCode;
  final int memberCount;
  final double totalExpense;
  final double totalSettled;
  final String? currentCycleId;
  final DateTime? lastActivity;
  final bool isArchived;
  final List<String> memberIds;

  const NestModel({
    required this.nestId,
    required this.name,
    required this.description,
    this.coverImage,
    required this.category,
    this.currency = 'INR',
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
    required this.inviteCode,
    this.memberCount = 1,
    this.totalExpense = 0.0,
    this.totalSettled = 0.0,
    this.currentCycleId,
    this.lastActivity,
    this.isArchived = false,
    this.memberIds = const [],
  });

  NestModel copyWith({
    String? nestId,
    String? name,
    String? description,
    String? coverImage,
    bool clearCoverImage = false,
    String? category,
    String? currency,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? inviteCode,
    int? memberCount,
    double? totalExpense,
    double? totalSettled,
    String? currentCycleId,
    bool clearCurrentCycleId = false,
    DateTime? lastActivity,
    bool? isArchived,
    List<String>? memberIds,
  }) {
    return NestModel(
      nestId: nestId ?? this.nestId,
      name: name ?? this.name,
      description: description ?? this.description,
      coverImage: clearCoverImage ? null : (coverImage ?? this.coverImage),
      category: category ?? this.category,
      currency: currency ?? this.currency,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      inviteCode: inviteCode ?? this.inviteCode,
      memberCount: memberCount ?? this.memberCount,
      totalExpense: totalExpense ?? this.totalExpense,
      totalSettled: totalSettled ?? this.totalSettled,
      currentCycleId: clearCurrentCycleId ? null : (currentCycleId ?? this.currentCycleId),
      lastActivity: lastActivity ?? this.lastActivity,
      isArchived: isArchived ?? this.isArchived,
      memberIds: memberIds ?? this.memberIds,
    );
  }

  factory NestModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return NestModel.fromMap(data, doc.id);
  }

  factory NestModel.fromMap(Map<String, dynamic> map, String docId) {
    final memberIdsRaw = map['memberIds'] as List<dynamic>?;
    return NestModel(
      nestId: docId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      coverImage: map['coverImage'],
      category: map['category'] ?? '',
      currency: map['currency'] ?? 'INR',
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      inviteCode: map['inviteCode'] ?? '',
      memberCount: map['memberCount'] ?? 1,
      totalExpense: (map['totalExpense'] as num?)?.toDouble() ?? 0.0,
      totalSettled: (map['totalSettled'] as num?)?.toDouble() ?? 0.0,
      currentCycleId: map['currentCycleId'],
      lastActivity: (map['lastActivity'] as Timestamp?)?.toDate(),
      isArchived: map['isArchived'] ?? false,
      memberIds: memberIdsRaw != null ? List<String>.from(memberIdsRaw) : [map['createdBy'] ?? ''],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'coverImage': coverImage,
      'category': category,
      'currency': currency,
      'createdBy': createdBy,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(), // Always updated to server timestamp on write
      'inviteCode': inviteCode,
      'memberCount': memberCount,
      'totalExpense': totalExpense,
      'totalSettled': totalSettled,
      'currentCycleId': currentCycleId,
      'lastActivity': FieldValue.serverTimestamp(), // Always updated to server timestamp on write
      'isArchived': isArchived,
      'memberIds': memberIds,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NestModel &&
        other.nestId == nestId &&
        other.name == name &&
        other.description == description &&
        other.coverImage == coverImage &&
        other.category == category &&
        other.currency == currency &&
        other.createdBy == createdBy &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.inviteCode == inviteCode &&
        other.memberCount == memberCount &&
        other.totalExpense == totalExpense &&
        other.totalSettled == totalSettled &&
        other.currentCycleId == currentCycleId &&
        other.lastActivity == lastActivity &&
        other.isArchived == isArchived &&
        listEquals(other.memberIds, memberIds);
  }

  @override
  int get hashCode {
    return Object.hashAll([
      nestId,
      name,
      description,
      coverImage,
      category,
      currency,
      createdBy,
      createdAt,
      updatedAt,
      inviteCode,
      memberCount,
      totalExpense,
      totalSettled,
      currentCycleId,
      lastActivity,
      isArchived,
      Object.hashAll(memberIds),
    ]);
  }
}
