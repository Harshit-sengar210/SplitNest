import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../members/domain/repositories/member_repository.dart';
import '../../../expenses/domain/repositories/expenses_repository.dart';
import '../../../settlement/domain/repositories/settlement_repository.dart';
import '../../../settlement/domain/models/settlement.dart';
import '../../domain/repositories/balance_repository.dart';
import '../../domain/models/member_balance.dart';
import '../../domain/calculators/balance_calculator.dart';
import '../../../members/domain/models/member_model.dart';
import '../../../expenses/domain/models/expense.dart';

class FirebaseBalanceRepository implements BalanceRepository {
  final MemberRepository _memberRepository;
  final ExpensesRepository _expensesRepository;
  final SettlementRepository _settlementRepository;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FirebaseBalanceRepository(
    this._memberRepository,
    this._expensesRepository,
    this._settlementRepository,
  );

  @override
  Future<List<MemberBalance>> calculateBalances(String nestId) async {
    final currentUserId = _auth.currentUser?.uid;
    final members = await _memberRepository.streamMembers(nestId).first;
    final expenses = await _expensesRepository.streamExpenses(nestId).first;
    final settlements = await _settlementRepository.getSettlements(nestId);

    final balances = BalanceCalculator.calculate(
      members: members,
      expenses: expenses,
      settlements: settlements,
      currentUserId: currentUserId,
    );
    balances.sort((a, b) => b.balance.compareTo(a.balance));
    return balances;
  }

  @override
  Stream<List<MemberBalance>> streamBalances(String nestId) {
    final currentUserId = _auth.currentUser?.uid;
    final controller = StreamController<List<MemberBalance>>();

    List<MemberModel>? lastMembers;
    List<Expense>? lastExpenses;
    List<Settlement>? lastSettlements;
    StreamSubscription? membersSub;
    StreamSubscription? expensesSub;
    StreamSubscription? settlementsSub;

    void update() {
      if (lastMembers != null && lastExpenses != null && lastSettlements != null) {
        try {
          final balances = BalanceCalculator.calculate(
            members: lastMembers!,
            expenses: lastExpenses!,
            settlements: lastSettlements!,
            currentUserId: currentUserId,
          );
          balances.sort((a, b) => b.balance.compareTo(a.balance));
          if (!controller.isClosed) {
            controller.add(balances);
          }
        } catch (e, stack) {
          if (!controller.isClosed) {
            controller.addError(e, stack);
          }
        }
      }
    }

    membersSub = _memberRepository.streamMembers(nestId).listen(
      (m) {
        lastMembers = m;
        update();
      },
      onError: (err) {
        if (!controller.isClosed) {
          controller.addError(err);
        }
      },
    );

    expensesSub = _expensesRepository.streamExpenses(nestId).listen(
      (e) {
        lastExpenses = e;
        update();
      },
      onError: (err) {
        if (!controller.isClosed) {
          controller.addError(err);
        }
      },
    );

    settlementsSub = _settlementRepository.streamSettlements(nestId).listen(
      (s) {
        lastSettlements = s;
        update();
      },
      onError: (err) {
        if (!controller.isClosed) {
          controller.addError(err);
        }
      },
    );

    controller.onCancel = () {
      membersSub?.cancel();
      expensesSub?.cancel();
      settlementsSub?.cancel();
      controller.close();
    };

    return controller.stream;
  }
}
