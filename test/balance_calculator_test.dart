import 'package:flutter_test/flutter_test.dart';
import 'package:splitnest/features/balances/domain/calculators/balance_calculator.dart';
import 'package:splitnest/features/balances/domain/models/member_balance.dart';
import 'package:splitnest/features/members/domain/models/member_model.dart';
import 'package:splitnest/features/expenses/domain/models/expense.dart';
import 'package:splitnest/features/settlement/domain/models/settlement.dart';
import 'package:splitnest/features/settlement/domain/models/balance.dart';
import 'package:splitnest/core/utils/mock_database.dart';

void main() {
  group('BalanceCalculator Tests', () {
    final memberA = MemberModel(
      id: 'user_a',
      fullName: 'Alice',
      email: 'alice@example.com',
      role: 'owner',
      status: 'active',
      isActive: true,
    );

    final memberB = MemberModel(
      id: 'user_b',
      fullName: 'Bob',
      email: 'bob@example.com',
      role: 'member',
      status: 'active',
      isActive: true,
    );

    final memberC = MemberModel(
      id: 'user_c',
      fullName: 'Charlie',
      email: 'charlie@example.com',
      role: 'member',
      status: 'active',
      isActive: true,
    );

    final members = [memberA, memberB, memberC];

    test('Zero expenses results in zero balances for all members', () {
      final results = BalanceCalculator.calculate(
        members: members,
        expenses: [],
      );

      expect(results.length, 3);
      for (final b in results) {
        expect(b.paid, 0.0);
        expect(b.owes, 0.0);
        expect(b.balance, 0.0);
      }
    });

    test('Single payer, equal split among all members', () {
      final expense = Expense(
        id: 'exp_1',
        title: 'Dinner',
        amount: 120.0,
        category: 'Food',
        groupId: 'nest_1',
        paidByUserId: 'user_a',
        paidByName: 'Alice',
        splits: [], // Empty splits represents equal split among all nest members
        date: DateTime.now(),
        splitMethod: 'Equal',
      );

      final results = BalanceCalculator.calculate(
        members: members,
        expenses: [expense],
      );

      // Alice (user_a)
      final balanceA = results.firstWhere((r) => r.memberId == 'user_a');
      expect(balanceA.paid, 120.0);
      expect(balanceA.owes, 40.0);
      expect(balanceA.balance, 80.0);

      // Bob (user_b)
      final balanceB = results.firstWhere((r) => r.memberId == 'user_b');
      expect(balanceB.paid, 0.0);
      expect(balanceB.owes, 40.0);
      expect(balanceB.balance, -40.0);

      // Charlie (user_c)
      final balanceC = results.firstWhere((r) => r.memberId == 'user_c');
      expect(balanceC.paid, 0.0);
      expect(balanceC.owes, 40.0);
      expect(balanceC.balance, -40.0);
    });

    test('Multiple expenses and varying payers', () {
      final expense1 = Expense(
        id: 'exp_1',
        title: 'Rent',
        amount: 120.0,
        category: 'Utilities',
        groupId: 'nest_1',
        paidByUserId: 'user_a',
        paidByName: 'Alice',
        splits: [
          const ExpenseSplit(userId: 'user_a', amount: 40.0),
          const ExpenseSplit(userId: 'user_b', amount: 40.0),
          const ExpenseSplit(userId: 'user_c', amount: 40.0),
        ],
        date: DateTime.now(),
        splitMethod: 'Equal',
      );

      final expense2 = Expense(
        id: 'exp_2',
        title: 'Drinks',
        amount: 60.0,
        category: 'Party',
        groupId: 'nest_1',
        paidByUserId: 'user_b',
        paidByName: 'Bob',
        splits: [
          const ExpenseSplit(userId: 'user_b', amount: 30.0),
          const ExpenseSplit(userId: 'user_c', amount: 30.0),
        ],
        date: DateTime.now(),
        splitMethod: 'Equal',
      );

      final results = BalanceCalculator.calculate(
        members: members,
        expenses: [expense1, expense2],
      );

      // Alice (user_a): paid 120, owes 40 (from exp1) => net +80
      final balanceA = results.firstWhere((r) => r.memberId == 'user_a');
      expect(balanceA.paid, 120.0);
      expect(balanceA.owes, 40.0);
      expect(balanceA.balance, 80.0);

      // Bob (user_b): paid 60, owes 40 (from exp1) + 30 (from exp2) = 70 => net -10
      final balanceB = results.firstWhere((r) => r.memberId == 'user_b');
      expect(balanceB.paid, 60.0);
      expect(balanceB.owes, 70.0);
      expect(balanceB.balance, -10.0);

      // Charlie (user_c): paid 0, owes 40 (from exp1) + 30 (from exp2) = 70 => net -70
      final balanceC = results.firstWhere((r) => r.memberId == 'user_c');
      expect(balanceC.paid, 0.0);
      expect(balanceC.owes, 70.0);
      expect(balanceC.balance, -70.0);
    });

    test('Payer not participating in the split (buying gift for others)', () {
      final expense = Expense(
        id: 'exp_1',
        title: 'Gift for Bob & Charlie',
        amount: 100.0,
        category: 'Other',
        groupId: 'nest_1',
        paidByUserId: 'user_a',
        paidByName: 'Alice',
        splits: [
          const ExpenseSplit(userId: 'user_b', amount: 50.0),
          const ExpenseSplit(userId: 'user_c', amount: 50.0),
        ],
        date: DateTime.now(),
        splitMethod: 'Equal',
      );

      final results = BalanceCalculator.calculate(
        members: members,
        expenses: [expense],
      );

      // Alice (user_a): paid 100, owes 0 => net +100
      final balanceA = results.firstWhere((r) => r.memberId == 'user_a');
      expect(balanceA.paid, 100.0);
      expect(balanceA.owes, 0.0);
      expect(balanceA.balance, 100.0);

      // Bob (user_b): paid 0, owes 50 => net -50
      final balanceB = results.firstWhere((r) => r.memberId == 'user_b');
      expect(balanceB.paid, 0.0);
      expect(balanceB.owes, 50.0);
      expect(balanceB.balance, -50.0);

      // Charlie (user_c): paid 0, owes 50 => net -50
      final balanceC = results.firstWhere((r) => r.memberId == 'user_c');
      expect(balanceC.paid, 0.0);
      expect(balanceC.owes, 50.0);
      expect(balanceC.balance, -50.0);
    });

    test('User A pays ₹1000 equally for A and B -> User B pays ₹600 equally for A and B -> Settlement updates correctly', () {
      final expense1 = Expense(
        id: 'exp_1',
        title: 'Expense 1',
        amount: 1000.0,
        category: 'Other',
        groupId: 'nest_1',
        paidByUserId: 'user_a',
        paidByName: 'Alice',
        splits: [
          const ExpenseSplit(userId: 'user_a', amount: 500.0),
          const ExpenseSplit(userId: 'user_b', amount: 500.0),
        ],
        date: DateTime.now(),
        splitMethod: 'Equal',
      );

      // Scenario 1: User A pays ₹1000 equally for A and B -> A should be owed ₹500
      var results = BalanceCalculator.calculate(
        members: members,
        expenses: [expense1],
      );

      var balanceA = results.firstWhere((r) => r.memberId == 'user_a');
      var balanceB = results.firstWhere((r) => r.memberId == 'user_b');
      expect(balanceA.paid, 1000.0);
      expect(balanceA.owes, 500.0);
      expect(balanceA.balance, 500.0);
      expect(balanceB.paid, 0.0);
      expect(balanceB.owes, 500.0);
      expect(balanceB.balance, -500.0);

      // Scenario 2: User B pays ₹600 equally for A and B -> balances update correctly
      final expense2 = Expense(
        id: 'exp_2',
        title: 'Expense 2',
        amount: 600.0,
        category: 'Other',
        groupId: 'nest_1',
        paidByUserId: 'user_b',
        paidByName: 'Bob',
        splits: [
          const ExpenseSplit(userId: 'user_a', amount: 300.0),
          const ExpenseSplit(userId: 'user_b', amount: 300.0),
        ],
        date: DateTime.now(),
        splitMethod: 'Equal',
      );

      results = BalanceCalculator.calculate(
        members: members,
        expenses: [expense1, expense2],
      );

      balanceA = results.firstWhere((r) => r.memberId == 'user_a');
      balanceB = results.firstWhere((r) => r.memberId == 'user_b');
      // Alice paid 1000, owes 500 + 300 = 800 => net +200
      expect(balanceA.paid, 1000.0);
      expect(balanceA.owes, 800.0);
      expect(balanceA.balance, 200.0);
      // Bob paid 600, owes 500 + 300 = 800 => net -200
      expect(balanceB.paid, 600.0);
      expect(balanceB.owes, 800.0);
      expect(balanceB.balance, -200.0);

      // Scenario 3: Creating a settlement instantly updates balances (B settles 200 to A)
      final settlement = Settlement(
        id: 'settle_1',
        groupId: 'nest_1',
        expenseId: 'exp_2',
        splitId: 'split_b',
        payerId: 'user_b',
        receiverId: 'user_a',
        amount: 200.0,
        status: 'completed',
        createdBy: 'user_b',
        createdAt: DateTime.now(),
      );

      results = BalanceCalculator.calculate(
        members: members,
        expenses: [expense1, expense2],
        settlements: [settlement],
      );

      balanceA = results.firstWhere((r) => r.memberId == 'user_a');
      balanceB = results.firstWhere((r) => r.memberId == 'user_b');
      // Alice: paid 1000, owes 800 (from expenses) + 200 (received settlement) = 1000 => net 0
      expect(balanceA.paid, 1000.0);
      expect(balanceA.owes, 1000.0);
      expect(balanceA.balance, 0.0);
      // Bob: paid 600 + 200 (sent settlement) = 800, owes 800 (from expenses) => net 0
      expect(balanceB.paid, 800.0);
      expect(balanceB.owes, 800.0);
      expect(balanceB.balance, 0.0);
    });

    test('Various Split Methods (Percentage, Shares, Exact Amount) test', () {
      final expensePct = Expense(
        id: 'exp_pct',
        title: 'Percentage Split',
        amount: 200.0,
        category: 'Other',
        groupId: 'nest_1',
        paidByUserId: 'user_a',
        splits: [
          const ExpenseSplit(userId: 'user_a', amount: 0.0, percentage: 30.0),
          const ExpenseSplit(userId: 'user_b', amount: 0.0, percentage: 70.0),
        ],
        date: DateTime.now(),
        splitMethod: 'Percentage',
      );

      var results = BalanceCalculator.calculate(
        members: members,
        expenses: [expensePct],
      );

      var balanceA = results.firstWhere((r) => r.memberId == 'user_a');
      var balanceB = results.firstWhere((r) => r.memberId == 'user_b');
      // Alice owes 30% of 200 = 60. Paid 200. Net = +140.
      expect(balanceA.paid, 200.0);
      expect(balanceA.owes, 60.0);
      expect(balanceA.balance, 140.0);
      // Bob owes 70% of 200 = 140. Paid 0. Net = -140.
      expect(balanceB.paid, 0.0);
      expect(balanceB.owes, 140.0);
      expect(balanceB.balance, -140.0);

      final expenseShares = Expense(
        id: 'exp_shares',
        title: 'Shares Split',
        amount: 300.0,
        category: 'Other',
        groupId: 'nest_1',
        paidByUserId: 'user_b',
        splits: [
          const ExpenseSplit(userId: 'user_a', amount: 0.0, shares: 1.0),
          const ExpenseSplit(userId: 'user_b', amount: 0.0, shares: 2.0),
        ],
        date: DateTime.now(),
        splitMethod: 'Shares',
      );

      results = BalanceCalculator.calculate(
        members: members,
        expenses: [expenseShares],
      );

      balanceA = results.firstWhere((r) => r.memberId == 'user_a');
      balanceB = results.firstWhere((r) => r.memberId == 'user_b');
      // Alice owes 1/(1+2) = 1/3 of 300 = 100. Paid 0. Net = -100.
      expect(balanceA.paid, 0.0);
      expect(balanceA.owes, 100.0);
      expect(balanceA.balance, -100.0);
      // Bob owes 2/3 of 300 = 200. Paid 300. Net = +100.
      expect(balanceB.paid, 300.0);
      expect(balanceB.owes, 200.0);
      expect(balanceB.balance, 100.0);
    });

    test('calculateSimplifiedBalances dynamically simplified debts correctly', () {
      final expense = Expense(
        id: 'exp_1',
        title: 'Expense 1',
        amount: 1000.0,
        category: 'Other',
        groupId: 'nest_1',
        paidByUserId: 'user_a',
        splits: [
          const ExpenseSplit(userId: 'user_a', amount: 500.0),
          const ExpenseSplit(userId: 'user_b', amount: 500.0),
        ],
        date: DateTime.now(),
        splitMethod: 'Equal',
      );

      final settlements = [
        Settlement(
          id: 'settle_1',
          groupId: 'nest_1',
          expenseId: 'exp_1',
          splitId: 'split_b',
          payerId: 'user_b',
          receiverId: 'user_a',
          amount: 300.0,
          status: 'completed',
          createdBy: 'user_b',
          createdAt: DateTime.now(),
        )
      ];

      final balances = BalanceCalculator.calculateSimplifiedBalances(
        groupId: 'nest_1',
        members: members,
        expenses: [expense],
        settlements: settlements,
        currentUserId: 'user_a',
      );

      expect(balances.length, 1);
      final b = balances.first;
      expect(b.fromUserId, 'user_b');
      expect(b.toUserId, 'user_me');
      expect(b.amount, 200.0); // 500 - 300 = 200
    });

    test('FIFO split settlement status updates (partial and full payment)', () {
      final expense = Expense(
        id: 'exp_1',
        title: 'Dinner',
        amount: 1000.0,
        category: 'Food',
        groupId: 'nest_1',
        paidByUserId: 'user_a',
        splits: [
          const ExpenseSplit(userId: 'user_a', amount: 500.0),
          const ExpenseSplit(userId: 'user_b', amount: 500.0, status: 'pending', isSettled: false),
        ],
        date: DateTime.now(),
        splitMethod: 'Equal',
      );

      final db = MockDatabase();
      db.expenses.clear();
      db.settlements.clear();
      db.balances.clear();

      db.expenses.add(expense);

      // Verify initial split is pending
      expect(db.expenses.first.splits[1].status, 'pending');
      expect(db.expenses.first.splits[1].isSettled, false);

      // Bob settles 20 (partial payment)
      db.settleUp('nest_1', 'user_b', 'user_a', 20.0);

      // Verify split is still pending
      expect(db.expenses.first.splits[1].status, 'pending');
      expect(db.expenses.first.splits[1].isSettled, false);

      // Bob settles remaining 480 (full payment)
      db.settleUp('nest_1', 'user_b', 'user_a', 480.0);

      // Verify split is now completed and settled
      expect(db.expenses.first.splits[1].status, 'completed');
      expect(db.expenses.first.splits[1].isSettled, true);
    });
  });
}
