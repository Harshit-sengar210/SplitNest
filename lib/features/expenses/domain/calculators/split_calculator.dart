import '../models/split_model.dart';

class SplitCalculator {
  static List<SplitModel> calculateEqual({
    required double totalAmount,
    required List<({String id, String name})> selectedMembers,
  }) {
    if (selectedMembers.isEmpty) return [];
    final share = totalAmount / selectedMembers.length;
    final pct = 100.0 / selectedMembers.length;
    return selectedMembers.map((m) {
      return SplitModel(
        memberId: m.id,
        memberName: m.name,
        amount: double.parse(share.toStringAsFixed(2)),
        percentage: double.parse(pct.toStringAsFixed(2)),
        shares: 1.0,
        status: 'pending',
        createdAt: DateTime.now(),
      );
    }).toList();
  }

  static List<SplitModel> calculateExact({
    required double totalAmount,
    required List<({String id, String name, double amount})> memberAmounts,
  }) {
    if (memberAmounts.isEmpty) return [];
    return memberAmounts.map((m) {
      final pct = totalAmount > 0 ? (m.amount / totalAmount) * 100.0 : 0.0;
      return SplitModel(
        memberId: m.id,
        memberName: m.name,
        amount: double.parse(m.amount.toStringAsFixed(2)),
        percentage: double.parse(pct.toStringAsFixed(2)),
        shares: 0.0,
        status: 'pending',
        createdAt: DateTime.now(),
      );
    }).toList();
  }

  static List<SplitModel> calculatePercentage({
    required double totalAmount,
    required List<({String id, String name, double percentage})> memberPercentages,
  }) {
    if (memberPercentages.isEmpty) return [];
    return memberPercentages.map((m) {
      final share = (m.percentage / 100.0) * totalAmount;
      return SplitModel(
        memberId: m.id,
        memberName: m.name,
        amount: double.parse(share.toStringAsFixed(2)),
        percentage: double.parse(m.percentage.toStringAsFixed(2)),
        shares: 0.0,
        status: 'pending',
        createdAt: DateTime.now(),
      );
    }).toList();
  }

  static List<SplitModel> calculateShares({
    required double totalAmount,
    required List<({String id, String name, double shares})> memberShares,
  }) {
    if (memberShares.isEmpty) return [];
    final totalShares = memberShares.fold<double>(0, (sum, m) => sum + m.shares);
    return memberShares.map((m) {
      final shareAmount = totalShares > 0 ? (m.shares / totalShares) * totalAmount : 0.0;
      final pct = totalShares > 0 ? (m.shares / totalShares) * 100.0 : 0.0;
      return SplitModel(
        memberId: m.id,
        memberName: m.name,
        amount: double.parse(shareAmount.toStringAsFixed(2)),
        percentage: double.parse(pct.toStringAsFixed(2)),
        shares: m.shares,
        status: 'pending',
        createdAt: DateTime.now(),
      );
    }).toList();
  }
}
