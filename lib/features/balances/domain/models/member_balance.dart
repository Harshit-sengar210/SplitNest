class MemberBalance {
  final String memberId;
  final String memberName;
  final double paid;
  final double owes;
  final double balance;
  final String? photoUrl;

  const MemberBalance({
    required this.memberId,
    required this.memberName,
    required this.paid,
    required this.owes,
    required this.balance,
    this.photoUrl,
  });

  MemberBalance copyWith({
    String? memberId,
    String? memberName,
    double? paid,
    double? owes,
    double? balance,
    String? photoUrl,
  }) {
    return MemberBalance(
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      paid: paid ?? this.paid,
      owes: owes ?? this.owes,
      balance: balance ?? this.balance,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'memberName': memberName,
      'paid': paid,
      'owes': owes,
      'balance': balance,
      'photoUrl': photoUrl,
    };
  }

  factory MemberBalance.fromMap(Map<String, dynamic> map) {
    return MemberBalance(
      memberId: map['memberId'] ?? '',
      memberName: map['memberName'] ?? '',
      paid: (map['paid'] as num?)?.toDouble() ?? 0.0,
      owes: (map['owes'] as num?)?.toDouble() ?? 0.0,
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      photoUrl: map['photoUrl'],
    );
  }
}
