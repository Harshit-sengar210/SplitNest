import '../../../members/domain/models/member_model.dart';
import '../../../expenses/domain/models/expense.dart';
import '../../../settlement/domain/models/settlement.dart';
import '../../../settlement/domain/models/balance.dart';
import '../models/member_balance.dart';

class BalanceCalculator {
  static double _round(double value) {
    return double.parse(value.toStringAsFixed(2));
  }

  static List<MemberBalance> calculate({
    required List<MemberModel> members,
    required List<Expense> expenses,
    List<Settlement> settlements = const [],
    String? currentUserId,
  }) {
    String norm(String id) {
      if (currentUserId != null) {
        if (id == 'user_me') return currentUserId;
      }
      return id;
    }

    final Map<String, double> paidMap = {};
    final Map<String, double> owesMap = {};

    for (final member in members) {
      final normalizedId = norm(member.id);
      paidMap[normalizedId] = 0.0;
      owesMap[normalizedId] = 0.0;
    }

    double getSplitAmount(Expense expense, ExpenseSplit split, List<ExpenseSplit> allSplits) {
      if (split.amount > 0.01) return split.amount;
      if (expense.splitMethod == 'Percentage' || expense.splitMethod == 'Percentage Split') {
        final pct = split.percentage ?? 0.0;
        return expense.amount * (pct / 100.0);
      } else if (expense.splitMethod == 'Shares' || expense.splitMethod == 'Share Split') {
        final totalShares = allSplits.fold(0.0, (sum, s) => sum + (s.shares ?? 0.0));
        if (totalShares <= 0) return 0.0;
        final sh = split.shares ?? 0.0;
        return expense.amount * (sh / totalShares);
      } else {
        return split.amount;
      }
    }

    for (final expense in expenses) {
      final payerId = norm(expense.paidByUserId);
      if (paidMap.containsKey(payerId)) {
        paidMap[payerId] = paidMap[payerId]! + expense.amount;
      }

      final expenseSplits = expense.splits.isEmpty
          ? members.map((m) => ExpenseSplit(
              userId: m.id,
              amount: expense.amount / members.length,
            )).toList()
          : expense.splits;

      for (final split in expenseSplits) {
        final splitUserId = norm(split.userId);
        if (owesMap.containsKey(splitUserId)) {
          final amt = getSplitAmount(expense, split, expenseSplits);
          owesMap[splitUserId] = owesMap[splitUserId]! + amt;
        }
      }
    }

    // Apply settlements on the fly
    for (final settlement in settlements) {
      final payerId = norm(settlement.payerId);
      final receiverId = norm(settlement.receiverId);

      if (paidMap.containsKey(payerId)) {
        paidMap[payerId] = paidMap[payerId]! + settlement.amount;
      }
      if (owesMap.containsKey(receiverId)) {
        owesMap[receiverId] = owesMap[receiverId]! + settlement.amount;
      }
    }

    final List<MemberBalance> list = [];
    for (final m in members) {
      final normalizedId = norm(m.id);
      final paid = _round(paidMap[normalizedId] ?? 0.0);
      final owes = _round(owesMap[normalizedId] ?? 0.0);
      final balance = _round(paid - owes);

      list.add(MemberBalance(
        memberId: m.id,
        memberName: m.fullName,
        paid: paid,
        owes: owes,
        balance: balance,
        photoUrl: m.profileImage,
      ));
    }

    return list;
  }

  static List<Balance> calculateSimplifiedBalances({
    required String groupId,
    required List<MemberModel> members,
    required List<Expense> expenses,
    required List<Settlement> settlements,
    String? currentUserId,
  }) {
    String norm(String id) {
      if (currentUserId != null) {
        if (id == 'user_me') return currentUserId;
      }
      return id;
    }

    String denorm(String id) {
      if (currentUserId != null && id == currentUserId) {
        return 'user_me';
      }
      return id;
    }

    final Map<String, Map<String, double>> netOwed = {};

    void addDebt(String debtor, String creditor, double amount) {
      final d = norm(debtor);
      final c = norm(creditor);
      if (d == c) return;

      netOwed.putIfAbsent(d, () => {});
      netOwed[d]![c] = (netOwed[d]![c] ?? 0.0) + amount;
    }

    double getSplitAmount(Expense expense, ExpenseSplit split, List<ExpenseSplit> allSplits) {
      if (split.amount > 0.01) return split.amount;
      if (expense.splitMethod == 'Percentage' || expense.splitMethod == 'Percentage Split') {
        final pct = split.percentage ?? 0.0;
        return expense.amount * (pct / 100.0);
      } else if (expense.splitMethod == 'Shares' || expense.splitMethod == 'Share Split') {
        final totalShares = allSplits.fold(0.0, (sum, s) => sum + (s.shares ?? 0.0));
        if (totalShares <= 0) return 0.0;
        final sh = split.shares ?? 0.0;
        return expense.amount * (sh / totalShares);
      } else {
        return split.amount;
      }
    }

    for (final expense in expenses) {
      final payer = norm(expense.paidByUserId);
      final expenseSplits = expense.splits.isEmpty
          ? members.map((m) => ExpenseSplit(
              userId: m.id,
              amount: expense.amount / members.length,
            )).toList()
          : expense.splits;

      for (final split in expenseSplits) {
        final amt = getSplitAmount(expense, split, expenseSplits);
        addDebt(split.userId, payer, amt);
      }
    }

    // Subtract settlements on the fly
    for (final settlement in settlements) {
      final payer = norm(settlement.payerId);
      final receiver = norm(settlement.receiverId);
      if (payer == receiver) continue;

      if (netOwed[payer]?.containsKey(receiver) == true) {
        netOwed[payer]![receiver] = netOwed[payer]![receiver]! - settlement.amount;
      } else {
        addDebt(receiver, payer, settlement.amount);
      }
    }

    final memberIds = members.map((m) => norm(m.id)).toSet().toList();
    final List<Balance> simplified = [];

    for (int i = 0; i < memberIds.length; i++) {
      for (int j = i + 1; j < memberIds.length; j++) {
        final u1 = memberIds[i];
        final u2 = memberIds[j];

        final owes1to2 = netOwed[u1]?[u2] ?? 0.0;
        final owes2to1 = netOwed[u2]?[u1] ?? 0.0;

        if (owes1to2 > owes2to1) {
          final diff = _round(owes1to2 - owes2to1);
          if (diff > 0.01) {
            simplified.add(Balance(
              groupId: groupId,
              fromUserId: denorm(u1),
              toUserId: denorm(u2),
              amount: diff,
              updatedAt: DateTime.now(),
            ));
          }
        } else if (owes2to1 > owes1to2) {
          final diff = _round(owes2to1 - owes1to2);
          if (diff > 0.01) {
            simplified.add(Balance(
              groupId: groupId,
              fromUserId: denorm(u2),
              toUserId: denorm(u1),
              amount: diff,
              updatedAt: DateTime.now(),
            ));
          }
        }
      }
    }

    return simplified;
  }
}
