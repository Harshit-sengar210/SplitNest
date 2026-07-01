class CycleStats {
  final String groupId;
  final DateTime cycleStart;
  final DateTime cycleEnd;
  final double totalExpenses;
  final double totalSettled;
  final double totalPending;
  final int totalTransactions;
  final int memberCount;

  const CycleStats({
    required this.groupId,
    required this.cycleStart,
    required this.cycleEnd,
    required this.totalExpenses,
    required this.totalSettled,
    required this.totalPending,
    required this.totalTransactions,
    required this.memberCount,
  });

  /// Settled percentage, clamped [0, 1].
  double get settledPercent =>
      totalExpenses > 0 ? (totalSettled / totalExpenses).clamp(0.0, 1.0) : 0.0;

  CycleStats copyWith({
    String? groupId,
    DateTime? cycleStart,
    DateTime? cycleEnd,
    double? totalExpenses,
    double? totalSettled,
    double? totalPending,
    int? totalTransactions,
    int? memberCount,
  }) {
    return CycleStats(
      groupId: groupId ?? this.groupId,
      cycleStart: cycleStart ?? this.cycleStart,
      cycleEnd: cycleEnd ?? this.cycleEnd,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      totalSettled: totalSettled ?? this.totalSettled,
      totalPending: totalPending ?? this.totalPending,
      totalTransactions: totalTransactions ?? this.totalTransactions,
      memberCount: memberCount ?? this.memberCount,
    );
  }
}
