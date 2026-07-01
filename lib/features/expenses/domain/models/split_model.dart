import 'package:cloud_firestore/cloud_firestore.dart';

class SplitModel {
  final String memberId;
  final String memberName;
  final double amount;
  final double percentage;
  final double shares;
  final String status; // 'pending', 'completed'
  final DateTime createdAt;
  final bool isSettled;
  final DateTime? settledAt;

  const SplitModel({
    required this.memberId,
    required this.memberName,
    required this.amount,
    required this.percentage,
    required this.shares,
    required this.status,
    required this.createdAt,
    this.isSettled = false,
    this.settledAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'memberName': memberName,
      'amount': amount,
      'percentage': percentage,
      'shares': shares,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'isSettled': isSettled,
      if (settledAt != null) 'settledAt': Timestamp.fromDate(settledAt!),
    };
  }

  factory SplitModel.fromMap(Map<String, dynamic> map) {
    DateTime? parseSettledAt(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return SplitModel(
      memberId: map['memberId'] ?? '',
      memberName: map['memberName'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      percentage: (map['percentage'] as num?)?.toDouble() ?? 0.0,
      shares: (map['shares'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isSettled: map['isSettled'] ?? false,
      settledAt: parseSettledAt(map['settledAt']),
    );
  }
}
