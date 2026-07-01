import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:splitnest/features/groups/domain/calculators/cycle_calculator.dart';

void main() {
  group('CycleCalculator Tests', () {
    test('calculateCycleBounds with referenceTime on/after cycleDay', () {
      final bounds = CycleCalculator.calculateCycleBounds(
        cycleDay: 15,
        referenceTime: DateTime(2026, 6, 20), // 20th is after 15th
      );

      expect(bounds.start, DateTime(2026, 6, 15));
      expect(bounds.end, DateTime(2026, 7, 15));
    });

    test('calculateCycleBounds with referenceTime before cycleDay', () {
      final bounds = CycleCalculator.calculateCycleBounds(
        cycleDay: 15,
        referenceTime: DateTime(2026, 6, 10), // 10th is before 15th
      );

      expect(bounds.start, DateTime(2026, 5, 15));
      expect(bounds.end, DateTime(2026, 6, 15));
    });

    test('calculateCycleBounds custom overrides', () {
      final bounds = CycleCalculator.calculateCycleBounds(
        cycleDay: 1,
        customStart: DateTime(2026, 1, 1),
        customEnd: DateTime(2026, 2, 1),
      );

      expect(bounds.start, DateTime(2026, 1, 1));
      expect(bounds.end, DateTime(2026, 2, 1));
    });

    test('computeCycleData correct aggregates', () {
      final start = DateTime(2026, 6, 1);
      final end = DateTime(2026, 7, 1);

      final expenses = [
        {'amount': 150.0},
        {'amount': 50.0},
      ];

      final settlements = [
        {'amount': 100.0},
      ];

      final data = CycleCalculator.computeCycleData(
        cycleId: 'cycle_2026_06',
        cycleStart: start,
        cycleEnd: end,
        expenses: expenses,
        settlements: settlements,
        memberCount: 3,
      );

      expect(data['cycleId'], 'cycle_2026_06');
      expect(data['cycleStartDate'], Timestamp.fromDate(start));
      expect(data['cycleEndDate'], Timestamp.fromDate(end));
      expect(data['totalExpenses'], 200.0);
      expect(data['totalSettled'], 100.0);
      expect(data['totalPending'], 100.0);
      expect(data['totalTransactions'], 3);
      expect(data['memberCount'], 3);
      expect(data['settledPercentage'], 0.5);
    });

    test('computeCycleData with zero expenses handles division by zero', () {
      final start = DateTime(2026, 6, 1);
      final end = DateTime(2026, 7, 1);

      final data = CycleCalculator.computeCycleData(
        cycleId: 'cycle_empty',
        cycleStart: start,
        cycleEnd: end,
        expenses: [],
        settlements: [],
        memberCount: 2,
      );

      expect(data['totalExpenses'], 0.0);
      expect(data['totalSettled'], 0.0);
      expect(data['totalPending'], 0.0);
      expect(data['settledPercentage'], 0.0);
    });
    test('computeCycleData after settlement addition, update, and deletion', () {
      final start = DateTime(2026, 6, 1);
      final end = DateTime(2026, 7, 1);

      final expenses = [
        {'amount': 500.0},
      ];

      // 1. Initial State: No settlements
      var data = CycleCalculator.computeCycleData(
        cycleId: 'cycle_1',
        cycleStart: start,
        cycleEnd: end,
        expenses: expenses,
        settlements: [],
        memberCount: 2,
      );
      expect(data['totalExpenses'], 500.0);
      expect(data['totalSettled'], 0.0);
      expect(data['totalPending'], 500.0);
      expect(data['totalTransactions'], 1);
      expect(data['settledPercentage'], 0.0);

      // 2. Settlement Added: ₹200
      final settlements = [
        {'id': 'set_1', 'amount': 200.0},
      ];
      data = CycleCalculator.computeCycleData(
        cycleId: 'cycle_1',
        cycleStart: start,
        cycleEnd: end,
        expenses: expenses,
        settlements: settlements,
        memberCount: 2,
      );
      expect(data['totalExpenses'], 500.0);
      expect(data['totalSettled'], 200.0);
      expect(data['totalPending'], 300.0);
      expect(data['totalTransactions'], 2);
      expect(data['settledPercentage'], 0.4);

      // 3. Settlement Updated: ₹200 -> ₹400
      settlements[0]['amount'] = 400.0;
      data = CycleCalculator.computeCycleData(
        cycleId: 'cycle_1',
        cycleStart: start,
        cycleEnd: end,
        expenses: expenses,
        settlements: settlements,
        memberCount: 2,
      );
      expect(data['totalExpenses'], 500.0);
      expect(data['totalSettled'], 400.0);
      expect(data['totalPending'], 100.0);
      expect(data['totalTransactions'], 2);
      expect(data['settledPercentage'], 0.8);

      // 4. Settlement Deleted
      settlements.clear();
      data = CycleCalculator.computeCycleData(
        cycleId: 'cycle_1',
        cycleStart: start,
        cycleEnd: end,
        expenses: expenses,
        settlements: settlements,
        memberCount: 2,
      );
      expect(data['totalExpenses'], 500.0);
      expect(data['totalSettled'], 0.0);
      expect(data['totalPending'], 500.0);
      expect(data['totalTransactions'], 1);
      expect(data['settledPercentage'], 0.0);
    });
  });
}
