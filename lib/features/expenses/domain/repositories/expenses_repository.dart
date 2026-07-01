import '../models/expense.dart';

abstract class ExpensesRepository {
  Future<List<Expense>> getExpenses(String groupId);
  Future<Expense> getExpenseById(String id);
  Future<Expense> createExpense({
    required String title,
    required double amount,
    required String category,
    required String groupId,
    required String paidByUserId,
    required List<ExpenseSplit> splits,
    required String splitMethod,
    String? description,
    String? currency,
    String? paidByName,
  });
  Future<void> updateExpense(Expense expense);
  Future<void> deleteExpense(String id);
  
  Stream<List<Expense>> streamExpenses(String groupId);
  Stream<Expense> streamExpenseById(String groupId, String expenseId);
}
