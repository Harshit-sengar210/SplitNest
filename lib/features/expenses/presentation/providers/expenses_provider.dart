import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/expense.dart';
import '../../domain/repositories/expenses_repository.dart';
import '../../data/repositories/firebase_expenses_repository.dart';
import '../../data/services/expenses_service.dart';
import '../../../../core/providers/database_provider.dart';

final expensesServiceProvider = Provider<ExpensesService>((ref) {
  return ExpensesService();
});

final expensesRepositoryProvider = Provider<ExpensesRepository>((ref) {
  final service = ref.watch(expensesServiceProvider);
  return FirebaseExpensesRepository(service);
});

class ExpensesState {
  final List<Expense> expenses;
  final bool isLoading;
  final String? errorMessage;

  const ExpensesState({
    this.expenses = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  ExpensesState copyWith({
    List<Expense>? expenses,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ExpensesState(
      expenses: expenses ?? this.expenses,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class ExpensesNotifier extends StateNotifier<ExpensesState> {
  final ExpensesRepository _repository;

  ExpensesNotifier(this._repository) : super(const ExpensesState());

  Future<void> loadExpenses(String groupId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final expenses = await _repository.getExpenses(groupId);
      state = state.copyWith(isLoading: false, expenses: expenses);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

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
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final newExpense = await _repository.createExpense(
        title: title,
        amount: amount,
        category: category,
        groupId: groupId,
        paidByUserId: paidByUserId,
        splits: splits,
        splitMethod: splitMethod,
        description: description,
        currency: currency,
        paidByName: paidByName,
      );
      
      final rawList = [newExpense, ...state.expenses];
      final uniqueExpenses = <Expense>[];
      final seenIds = <String>{};
      for (final e in rawList) {
        if (seenIds.add(e.id)) {
          uniqueExpenses.add(e);
        }
      }
      state = state.copyWith(isLoading: false, expenses: uniqueExpenses);
      
      return newExpense;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> deleteExpense(String id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.deleteExpense(id);
      final updatedList = state.expenses.where((e) => e.id != id).toList();
      state = state.copyWith(isLoading: false, expenses: updatedList);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final expensesProvider = StateNotifierProvider.family<ExpensesNotifier, ExpensesState, String>((ref, groupId) {
  final repository = ref.watch(expensesRepositoryProvider);
  final notifier = ExpensesNotifier(repository);
  notifier.loadExpenses(groupId);
  ref.listen(databaseChangeProvider, (previous, next) {
    notifier.loadExpenses(groupId);
  });
  return notifier;
});

final nestExpensesStreamProvider = StreamProvider.family<List<Expense>, String>((ref, groupId) {
  final repository = ref.watch(expensesRepositoryProvider);
  return repository.streamExpenses(groupId);
});

final singleExpenseStreamProvider = StreamProvider.family<Expense, ({String groupId, String expenseId})>((ref, arg) {
  final repository = ref.watch(expensesRepositoryProvider);
  return repository.streamExpenseById(arg.groupId, arg.expenseId);
});
