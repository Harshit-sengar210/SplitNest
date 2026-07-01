/// An immutable snapshot of a completed billing cycle for a single nest.
class CycleReport {
  final String id;
  final String groupId;
  final DateTime cycleStart;
  final DateTime cycleEnd;
  final double totalExpenses;
  final double totalSettled;
  final double totalPending;
  final int totalTransactions;
  final int memberCount;
  final DateTime archivedAt;

  const CycleReport({
    required this.id,
    required this.groupId,
    required this.cycleStart,
    required this.cycleEnd,
    required this.totalExpenses,
    required this.totalSettled,
    required this.totalPending,
    required this.totalTransactions,
    required this.memberCount,
    required this.archivedAt,
  });

  /// What fraction of expenses were settled (0.0 – 1.0).
  double get settledPercent =>
      totalExpenses > 0 ? (totalSettled / totalExpenses).clamp(0.0, 1.0) : 0.0;

  Map<String, dynamic> toMap() => {
        'id': id,
        'groupId': groupId,
        'cycleStart': cycleStart.toIso8601String(),
        'cycleEnd': cycleEnd.toIso8601String(),
        'totalExpenses': totalExpenses,
        'totalSettled': totalSettled,
        'totalPending': totalPending,
        'totalTransactions': totalTransactions,
        'memberCount': memberCount,
        'archivedAt': archivedAt.toIso8601String(),
      };

  factory CycleReport.fromMap(Map<String, dynamic> map) => CycleReport(
        id: map['id'] ?? '',
        groupId: map['groupId'] ?? '',
        cycleStart: DateTime.parse(map['cycleStart']),
        cycleEnd: DateTime.parse(map['cycleEnd']),
        totalExpenses: (map['totalExpenses'] as num?)?.toDouble() ?? 0,
        totalSettled: (map['totalSettled'] as num?)?.toDouble() ?? 0,
        totalPending: (map['totalPending'] as num?)?.toDouble() ?? 0,
        totalTransactions: map['totalTransactions'] ?? 0,
        memberCount: map['memberCount'] ?? 0,
        archivedAt: DateTime.parse(map['archivedAt']),
      );
}
