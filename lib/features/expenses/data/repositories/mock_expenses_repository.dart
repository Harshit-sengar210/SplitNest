import '../../domain/models/expense.dart';
import '../../domain/repositories/expenses_repository.dart';
import '../../../../core/utils/mock_database.dart';

class MockExpensesRepository implements ExpensesRepository {
  final MockDatabase _db = MockDatabase();

  @override
  Future<List<Expense>> getExpenses(String groupId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _db.expenses.where((e) => e.groupId == groupId).toList();
  }

  @override
  Future<Expense> getExpenseById(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _db.expenses.firstWhere(
      (e) => e.id == id,
      orElse: () => throw Exception('Expense not found'),
    );
  }

  @override
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
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    final newExpense = Expense(
      id: 'exp_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      amount: amount,
      category: category,
      groupId: groupId,
      paidByUserId: paidByUserId,
      paidByName: paidByName ?? 'Someone',
      splits: splits,
      date: DateTime.now(),
      splitMethod: splitMethod,
      description: description,
      currency: currency ?? 'INR',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: 'user_me',
    );
    
    _db.addExpense(newExpense);
    return newExpense;
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _db.updateExpense(expense);
  }

  @override
  Future<void> deleteExpense(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _db.deleteExpense(id);
  }

  @override
  Stream<List<Expense>> streamExpenses(String groupId) {
    return Stream.value(_db.expenses.where((e) => e.groupId == groupId).toList());
  }

  @override
  Stream<Expense> streamExpenseById(String groupId, String expenseId) {
    return Stream.value(
      _db.expenses.firstWhere(
        (e) => e.id == expenseId,
        orElse: () => throw Exception('Expense not found'),
      ),
    );
  }
}
