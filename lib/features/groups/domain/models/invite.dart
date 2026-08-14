enum InviteStatus {
  pending,
  accepted,
  expired,
  revoked;

  String get name {
    switch (this) {
      case InviteStatus.pending:
        return 'pending';
      case InviteStatus.accepted:
        return 'accepted';
      case InviteStatus.expired:
        return 'expired';
      case InviteStatus.revoked:
        return 'revoked';
    }
  }

  static InviteStatus fromString(String value) {
    return InviteStatus.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => InviteStatus.pending,
    );
  }
}

class Invite {
  final String inviteToken;
  final String nestId;
  final String nestName;
  final String inviterUserId;
  final InviteStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? allowedEmail;
  final int? memberCount; // Preview data

  Invite({
    required this.inviteToken,
    required this.nestId,
    required this.nestName,
    required this.inviterUserId,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.allowedEmail,
    this.memberCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'inviteToken': inviteToken,
      'nestId': nestId,
      'nestName': nestName,
      'inviterUserId': inviterUserId,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      if (allowedEmail != null) 'allowedEmail': allowedEmail,
      if (memberCount != null) 'memberCount': memberCount,
    };
  }

  factory Invite.fromMap(Map<String, dynamic> map) {
    return Invite(
      inviteToken: map['inviteToken'] ?? '',
      nestId: map['nestId'] ?? '',
      nestName: map['nestName'] ?? '',
      inviterUserId: map['inviterUserId'] ?? '',
      status: InviteStatus.fromString(map['status'] ?? 'pending'),
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      expiresAt: DateTime.tryParse(map['expiresAt'] ?? '') ?? DateTime.now(),
      allowedEmail: map['allowedEmail'],
      memberCount: map['memberCount'],
    );
  }
}
