import 'package:cloud_firestore/cloud_firestore.dart';

class MemberModel {
  final String id;
  final String fullName;
  final String email;
  final String? profileImage;
  final String role; // 'owner' or 'member'
  final DateTime? joinedAt;
  final String status; // 'active' or 'invited'
  final bool isActive;
  final DateTime? invitedAt;

  const MemberModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.profileImage,
    required this.role,
    this.joinedAt,
    required this.status,
    required this.isActive,
    this.invitedAt,
  });

  MemberModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? profileImage,
    bool clearProfileImage = false,
    String? role,
    DateTime? joinedAt,
    String? status,
    bool? isActive,
    DateTime? invitedAt,
  }) {
    return MemberModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      profileImage: clearProfileImage ? null : (profileImage ?? this.profileImage),
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      invitedAt: invitedAt ?? this.invitedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': id,
      'fullName': fullName,
      'email': email,
      'profileImage': profileImage,
      'role': role,
      'joinedAt': joinedAt != null ? Timestamp.fromDate(joinedAt!) : null,
      'status': status,
      'isActive': isActive,
      'invitedAt': invitedAt != null ? Timestamp.fromDate(invitedAt!) : null,
    };
  }

  factory MemberModel.fromMap(Map<String, dynamic> map, String docId) {
    return MemberModel(
      id: docId,
      fullName: map['fullName'] ?? map['name'] ?? '',
      email: map['email'] ?? '',
      profileImage: map['profileImage'] ?? map['photoUrl'],
      role: map['role'] ?? 'member',
      joinedAt: (map['joinedAt'] as Timestamp?)?.toDate(),
      status: map['status'] ?? 'invited',
      isActive: map['isActive'] ?? false,
      invitedAt: (map['invitedAt'] as Timestamp?)?.toDate(),
    );
  }
}
