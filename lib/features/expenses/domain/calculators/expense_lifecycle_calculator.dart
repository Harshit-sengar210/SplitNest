import '../../../members/domain/models/member_model.dart';
import '../../domain/models/expense.dart';
import '../../../settlement/domain/models/settlement.dart';
import '../models/expense_lifecycle_status.dart';

class ExpenseLifecycleCalculator {
  static List<ExpenseLifecycleStatus> calculate({
    required List<Expense> expenses,
    required List<Settlement> settlements,
    required List<MemberModel> members,
  }) {
    // 1. Group settlements by (paidBy, receivedBy) to calculate total settled balance available
    final Map<String, Map<String, double>> settledBalance = {};

    void addSettlementBalance(String paidBy, String receivedBy, double amount) {
      settledBalance.putIfAbsent(paidBy, () => {});
      settledBalance[paidBy]!.putIfAbsent(receivedBy, () => 0.0);
      settledBalance[paidBy]![receivedBy] = settledBalance[paidBy]![receivedBy]! + amount;
    }

    for (final settlement in settlements) {
      addSettlementBalance(settlement.paidBy, settlement.receivedBy, settlement.amount);
    }

    // 2. Sort expenses chronologically (FIFO order)
    final sortedExpenses = List<Expense>.from(expenses)
      ..sort((a, b) => a.date.compareTo(b.date));

    final List<ExpenseLifecycleStatus> results = [];

    // 3. Process each expense
    for (final expense in sortedExpenses) {
      final String payerId = expense.paidByUserId;
      final double totalAmount = expense.amount;

      // Determine the precise split amounts for each participant
      final Map<String, double> splitAmounts = {};
      
      if (expense.splits.isEmpty) {
        // Equal split among all nest members
        final int count = members.length;
        if (count > 0) {
          final double share = totalAmount / count;
          for (final m in members) {
            splitAmounts[m.id] = share;
          }
        }
      } else {
        // We have explicit splits, but let's recompute/extract the amount
        // because the UI depends on exact amounts per split
        final method = expense.splitMethod.toLowerCase();
        if (method.contains('equal')) {
          final int count = expense.splits.length;
          if (count > 0) {
            final double share = totalAmount / count;
            for (final split in expense.splits) {
              splitAmounts[split.userId] = share;
            }
          }
        } else if (method.contains('exact')) {
          for (final split in expense.splits) {
            splitAmounts[split.userId] = split.amount;
          }
        } else if (method.contains('percentage')) {
          for (final split in expense.splits) {
            final pct = split.percentage ?? 0.0;
            splitAmounts[split.userId] = (pct / 100) * totalAmount;
          }
        } else if (method.contains('shares')) {
          double totalShares = 0.0;
          for (final split in expense.splits) {
            totalShares += split.shares ?? 0.0;
          }
          if (totalShares > 0) {
            for (final split in expense.splits) {
              final sh = split.shares ?? 0.0;
              splitAmounts[split.userId] = (sh / totalShares) * totalAmount;
            }
          }
        }
      }

      // 4. Calculate total paid for this specific expense
      // The payer has inherently "paid" their own share.
      double totalPaid = splitAmounts[payerId] ?? 0.0;

      // For every other participant, check if they have settled balance with the payer
      for (final entry in splitAmounts.entries) {
        final String participantId = entry.key;
        final double owedAmount = entry.value;

        if (participantId == payerId) continue; // Handled above

        if (owedAmount > 0.001) {
          final double availableBalance = settledBalance[participantId]?[payerId] ?? 0.0;
          
          if (availableBalance > 0) {
            // Allocate up to owedAmount from the available balance
            final double allocated = availableBalance >= owedAmount ? owedAmount : availableBalance;
            
            // Deduct from available balance
            settledBalance[participantId]![payerId] = availableBalance - allocated;
            
            // Add to total paid for this expense
            totalPaid += allocated;
          }
        }
      }

      // Handle precision issues
      if (totalPaid > totalAmount) totalPaid = totalAmount;

      final double remainingAmount = totalAmount - totalPaid;
      
      String status = 'Pending';
      if (totalPaid >= totalAmount - 0.01) {
        status = 'Completed';
      } else if (totalPaid > 0.01) {
        status = 'Partial';
      }

      double progress = totalAmount > 0 ? totalPaid / totalAmount : 1.0;
      if (progress > 1.0) progress = 1.0;
      if (progress < 0.0) progress = 0.0;

      results.add(
        ExpenseLifecycleStatus(
          expense: expense,
          totalAmount: totalAmount,
          totalPaid: totalPaid,
          remainingAmount: remainingAmount,
          status: status,
          progress: progress,
        )
      );
    }

    // The UI should show newest first, so we reverse the chronological list
    return results.reversed.toList();
  }
}
