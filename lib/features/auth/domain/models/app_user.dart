class AppUser {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? username;
  final String? phone;
  final String? bio;
  final String? activeNestId;
  final bool isAdmin;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.username,
    this.phone,
    this.bio,
    this.activeNestId,
    this.isAdmin = false,
    required this.createdAt,
    this.updatedAt,
  });

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? username,
    String? phone,
    String? bio,
    String? activeNestId,
    bool clearActiveNestId = false,
    bool? isAdmin,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      activeNestId: clearActiveNestId ? null : (activeNestId ?? this.activeNestId),
      isAdmin: isAdmin ?? this.isAdmin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': id,
      'email': email,
      'fullName': displayName,
      'profileImage': photoUrl,
      'username': username,
      'phone': phone,
      'bio': bio,
      'activeNestId': activeNestId,
      'isAdmin': isAdmin,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': (updatedAt ?? createdAt).toIso8601String(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['userId'] ?? map['id'] ?? '',
      email: map['email'] ?? '',
      displayName: map['fullName'] ?? map['displayName'] ?? '',
      photoUrl: map['profileImage'] ?? map['photoUrl'],
      username: map['username'],
      phone: map['phone'],
      bio: map['bio'],
      activeNestId: map['activeNestId'],
      isAdmin: map['isAdmin'] == true,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
    );
  }
}
