import 'package:cloud_firestore/cloud_firestore.dart';

class LedgerSummary {
  final double totalIncome;
  final double totalExpense;
  final double totalLend;
  final double totalBorrow;
  final double netBalance;
  final DateTime updatedAt;

  const LedgerSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.totalLend,
    required this.totalBorrow,
    required this.netBalance,
    required this.updatedAt,
  });

  LedgerSummary copyWith({
    double? totalIncome,
    double? totalExpense,
    double? totalLend,
    double? totalBorrow,
    double? netBalance,
    DateTime? updatedAt,
  }) {
    return LedgerSummary(
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      totalLend: totalLend ?? this.totalLend,
      totalBorrow: totalBorrow ?? this.totalBorrow,
      netBalance: netBalance ?? this.netBalance,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'totalLend': totalLend,
      'totalBorrow': totalBorrow,
      'netBalance': netBalance,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory LedgerSummary.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is Timestamp) return val.toDate();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is String) {
        final p = DateTime.tryParse(val);
        if (p != null) return p;
      }
      return DateTime.now();
    }

    return LedgerSummary(
      totalIncome: (map['totalIncome'] as num?)?.toDouble() ?? 0.0,
      totalExpense: (map['totalExpense'] as num?)?.toDouble() ?? 0.0,
      totalLend: (map['totalLend'] as num?)?.toDouble() ?? 0.0,
      totalBorrow: (map['totalBorrow'] as num?)?.toDouble() ?? 0.0,
      netBalance: (map['netBalance'] as num?)?.toDouble() ?? 0.0,
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  factory LedgerSummary.zero() {
    return LedgerSummary(
      totalIncome: 0.0,
      totalExpense: 0.0,
      totalLend: 0.0,
      totalBorrow: 0.0,
      netBalance: 0.0,
      updatedAt: DateTime.now(),
    );
  }
}
