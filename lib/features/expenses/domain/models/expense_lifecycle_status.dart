import 'expense.dart';

class ExpenseLifecycleStatus {
  final Expense expense;
  final double totalAmount;
  final double totalPaid;
  final double remainingAmount;
  final String status; // 'Pending', 'Partial', 'Completed'
  final double progress; // 0.0 to 1.0

  const ExpenseLifecycleStatus({
    required this.expense,
    required this.totalAmount,
    required this.totalPaid,
    required this.remainingAmount,
    required this.status,
    required this.progress,
  });
}
