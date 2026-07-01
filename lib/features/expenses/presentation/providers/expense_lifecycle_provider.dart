import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/expense_lifecycle_status.dart';
import '../../domain/calculators/expense_lifecycle_calculator.dart';
import 'expenses_provider.dart';
import '../../../settlement/presentation/providers/settlement_provider.dart';
import '../../../members/presentation/providers/member_providers.dart';

final expenseLifecycleProvider = StreamProvider.family<List<ExpenseLifecycleStatus>, String>((ref, nestId) async* {
  // Watch all three streams to ensure real-time updates when any collection changes
  final expensesAsync = ref.watch(nestExpensesStreamProvider(nestId));
  final settlementsAsync = ref.watch(groupSettlementsProvider(nestId));
  final membersAsync = ref.watch(nestMembersStreamProvider(nestId));

  // If any are still loading and don't have data, yield empty/wait
  if (!expensesAsync.hasValue || !settlementsAsync.hasValue || !membersAsync.hasValue) {
    yield [];
    return;
  }

  final expenses = expensesAsync.value ?? [];
  final settlements = settlementsAsync.value ?? [];
  final members = membersAsync.value ?? [];

  // Calculate the lifecycle status for all expenses
  final statuses = ExpenseLifecycleCalculator.calculate(
    expenses: expenses,
    settlements: settlements,
    members: members,
  );

  yield statuses;
});
