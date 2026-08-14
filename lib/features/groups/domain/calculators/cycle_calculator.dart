import 'package:cloud_firestore/cloud_firestore.dart';

class CycleCalculator {
  /// Computes the start and end dates for a cycle period based on the nest's cycle day.
  /// Standardizes to local midnight.
  static ({DateTime start, DateTime end}) calculateCycleBounds({
    required int cycleDay,
    DateTime? customStart,
    DateTime? customEnd,
    DateTime? referenceTime,
  }) {
    final ref = referenceTime ?? DateTime.now();

    DateTime clamp(int year, int month, int day) {
      final lastDay = DateTime(year, month + 1, 0).day;
      final clampedDay = day > lastDay ? lastDay : day;
      return DateTime(year, month, clampedDay);
    }

    DateTime start;
    DateTime end;
    if (ref.day >= cycleDay) {
      start = clamp(ref.year, ref.month, cycleDay);
      end = clamp(ref.year, ref.month + 1, cycleDay);
    } else {
      start = clamp(ref.year, ref.month - 1, cycleDay);
      end = clamp(ref.year, ref.month, cycleDay);
    }

    return (
      start: customStart ?? DateTime(start.year, start.month, start.day),
      end: customEnd ?? DateTime(end.year, end.month, end.day),
    );
  }

  /// Calculates Cycle stats from raw list of expenses and settlements.
  static Map<String, dynamic> computeCycleData({
    required String cycleId,
    required DateTime cycleStart,
    required DateTime cycleEnd,
    required List<Map<String, dynamic>> expenses,
    required List<Map<String, dynamic>> settlements,
    required int memberCount,
  }) {
    double totalExpenses = 0.0;
    double totalSelfShares = 0.0;

    for (final exp in expenses) {
      final amt = (exp['amount'] as num?)?.toDouble() ?? 0.0;
      totalExpenses += amt;

      final paidBy = exp['paidByUserId'] ?? exp['paidBy'];
      final splits = exp['splits'] as List<dynamic>?;
      
      if (splits != null && splits.isNotEmpty) {
        for (final split in splits) {
          if (split is Map<String, dynamic>) {
            final splitUserId = split['memberId'] ?? split['userId'];
            if (splitUserId != null && splitUserId == paidBy) {
              totalSelfShares += (split['amount'] as num?)?.toDouble() ?? 0.0;
            }
          }
        }
      } else if (memberCount > 0) {
        totalSelfShares += amt / memberCount;
      }
    }

    double totalSettled = totalSelfShares;
    for (final set in settlements) {
      totalSettled += (set['amount'] as num?)?.toDouble() ?? 0.0;
    }

    final totalPending = (totalExpenses - totalSettled).clamp(0.0, double.infinity);
    final totalTransactions = expenses.length + settlements.length;
    final settledPercentage = totalExpenses > 0
        ? (totalSettled / totalExpenses).clamp(0.0, 1.0)
        : 0.0;

    return {
      'cycleId': cycleId,
      'cycleStartDate': Timestamp.fromDate(cycleStart),
      'cycleEndDate': Timestamp.fromDate(cycleEnd),
      'totalExpenses': totalExpenses,
      'totalSettled': totalSettled,
      'totalPending': totalPending,
      'totalTransactions': totalTransactions,
      'memberCount': memberCount,
      'settledPercentage': settledPercentage,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
