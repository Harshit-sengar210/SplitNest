import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:splitnest/features/groups/domain/calculators/cycle_calculator.dart';
import 'package:splitnest/features/chat/data/services/system_message_service.dart';

class ExpensesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> streamExpenses(String nestId) {
    return _firestore
        .collection('nests')
        .doc(nestId)
        .collection('expenses')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamExpenseById(
      String nestId, String expenseId) {
    return _firestore
        .collection('nests')
        .doc(nestId)
        .collection('expenses')
        .doc(expenseId)
        .snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getExpenseById(
      String nestId, String expenseId) {
    return _firestore
        .collection('nests')
        .doc(nestId)
        .collection('expenses')
        .doc(expenseId)
        .get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getExpenses(String nestId) {
    return _firestore
        .collection('nests')
        .doc(nestId)
        .collection('expenses')
        .orderBy('createdAt', descending: true)
        .get();
  }

  /// Convenience helper – returns a new auto-ID doc ref in the timeline sub-collection.
  DocumentReference<Map<String, dynamic>> _newTimelineRef(String nestId) =>
      _firestore
          .collection('nests')
          .doc(nestId)
          .collection('timeline')
          .doc();

  Future<void> createExpense({
    required String nestId,
    required String expenseId,
    required Map<String, dynamic> expenseData,
    required double amount,
    required List<Map<String, dynamic>> splitsData,
    // Optional timeline context
    String? actorUserId,
    String? actorUserName,
    String? expenseTitle,
  }) async {
    final nestRef = _firestore.collection('nests').doc(nestId);
    final expenseRef = nestRef.collection('expenses').doc(expenseId);
    final timelineRef = _newTimelineRef(nestId);

    // 1. READS OUTSIDE TRANSACTION:
    final nestDoc = await nestRef.get();
    if (!nestDoc.exists) throw Exception('Nest does not exist');

    final nestData = nestDoc.data()!;
    final cycleDay = nestData['settlementCycleDate'] as int? ?? 1;
    final DateTime? customStart = nestData['customStartDate'] != null 
        ? (nestData['customStartDate'] as Timestamp).toDate() 
        : null;
    final DateTime? customEnd = nestData['customEndDate'] != null 
        ? (nestData['customEndDate'] as Timestamp).toDate() 
        : null;

    final bounds = CycleCalculator.calculateCycleBounds(
      cycleDay: cycleDay,
      customStart: customStart,
      customEnd: customEnd,
    );

    final expensesSnap = await nestRef.collection('expenses')
        .where('date', isGreaterThanOrEqualTo: bounds.start.millisecondsSinceEpoch)
        .where('date', isLessThan: bounds.end.millisecondsSinceEpoch)
        .get();
    final settlementsSnap = await nestRef.collection('settlements')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(bounds.start))
        .where('createdAt', isLessThan: Timestamp.fromDate(bounds.end))
        .get();

    // Query FIFO collections outside the transaction:
    final payerId = expenseData['paidBy'] as String;
    final settlementsSnapFIFO = await nestRef.collection('settlements')
        .where('receivedBy', isEqualTo: payerId)
        .get();
    final expensesSnapFIFO = await nestRef.collection('expenses')
        .where('paidBy', isEqualTo: payerId)
        .get();

    final debtorIds = splitsData
        .map((s) => s['memberId'] as String)
        .where((id) => id != payerId)
        .toList();

    await _firestore.runTransaction((transaction) async {
      // 2. READS INSIDE TRANSACTION:
      final nestDocTx = await transaction.get(nestRef);
      if (!nestDocTx.exists) throw Exception('Nest does not exist');

      final nestDataTx = nestDocTx.data()!;
      String? cycleId = nestDataTx['currentCycleId'] as String?;
      bool needsNewCycle = cycleId == null;
      if (cycleId != null) {
        final cycleDoc = await transaction.get(nestRef.collection('Cycle').doc(cycleId));
        if (cycleDoc.exists) {
          final cycleEndDate = (cycleDoc.data()!['cycleEndDate'] as Timestamp).toDate();
          if (DateTime.now().isAfter(cycleEndDate)) {
            needsNewCycle = true;
            final cycleStartDate = (cycleDoc.data()!['cycleStartDate'] as Timestamp).toDate();
            SystemMessageService.writeInTransaction(
              transaction: transaction,
              nestId: nestId,
              messageText: SystemMessageService.cycleCompleted(start: cycleStartDate, end: cycleEndDate),
            );
          }
        } else {
          needsNewCycle = true;
        }
      }

      // 3. IN-MEMORY CALCULATION:
      final List<Map<String, dynamic>> allExpenses = expensesSnap.docs.map((d) => d.data()).toList();
      allExpenses.add(expenseData);

      final List<Map<String, dynamic>> allSettlements = settlementsSnap.docs.map((d) => d.data()).toList();
      final memberCount = (nestDataTx['memberIds'] as List<dynamic>?)?.length ?? 0;

      if (needsNewCycle) {
        cycleId = 'cycle_${bounds.start.year}_${bounds.start.month.toString().padLeft(2, '0')}_${DateTime.now().millisecondsSinceEpoch}';
      }

      final cycleData = CycleCalculator.computeCycleData(
        cycleId: cycleId!,
        cycleStart: bounds.start,
        cycleEnd: bounds.end,
        expenses: allExpenses,
        settlements: allSettlements,
        memberCount: memberCount,
      );
      if (needsNewCycle) {
        cycleData['createdAt'] = FieldValue.serverTimestamp();
      }

      // 4. WRITES:
      if (needsNewCycle) {
        transaction.update(nestRef, {'currentCycleId': cycleId});
      }

      transaction.set(expenseRef, expenseData);

      for (final split in splitsData) {
        final memberId = split['memberId'] as String;
        final splitId = _firestore.collection('nests').doc(nestId).collection('expenses').doc(expenseId).collection('splits').doc().id;
        
        final newSplit = {
          ...split,
          'splitId': splitId,
          'memberId': memberId,
          'userId': memberId,
          'paidBy': expenseData['paidBy'],
          'paidByName': expenseData['paidByName'],
          'originalShare': split['amount'],
          'settledAmount': 0.0,
          'pendingAmount': split['amount'],
          'status': 'pending',
          'updatedAt': FieldValue.serverTimestamp(),
          'memberName': split['memberName'] ?? 'Someone',
        };
        transaction.set(expenseRef.collection('splits').doc(memberId), newSplit);
      }

      // Execute FIFO allocations on splits
      final List<Map<String, dynamic>> allSettlementsFIFO =
          settlementsSnapFIFO.docs.map((d) => d.data()).toList();
      final List<Map<String, dynamic>> allExpensesFIFO =
          expensesSnapFIFO.docs.map((d) => d.data()).toList();
      allExpensesFIFO.add(expenseData);

      _reallocateFIFO(
        nestId: nestId,
        payerId: payerId,
        debtorIds: debtorIds,
        allSettlements: allSettlementsFIFO,
        allExpenses: allExpensesFIFO,
        transaction: transaction,
      );

      final double current = (nestDataTx['totalExpense'] as num?)?.toDouble() ?? 0.0;
      transaction.update(nestRef, {
        'totalExpense': current + amount,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastActivity': FieldValue.serverTimestamp(),
      });

      // ── Timeline event ──────────────────────────────────────────────────────
      transaction.set(timelineRef, {
        'type': 'expense_added',
        'title': expenseTitle ?? 'Expense Added',
        'description':
            '${actorUserName ?? 'Someone'} added an expense of ₹${amount.toStringAsFixed(0)}',
        'amount': amount,
        'userId': actorUserId ?? '',
        'userName': actorUserName ?? '',
        'expenseId': expenseId,
        'settlementId': null,
        'memberId': null,
        'icon': 'receipt',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ── System chat message ─────────────────────────────────────────────────
      SystemMessageService.writeInTransaction(
        transaction: transaction,
        nestId: nestId,
        messageText: SystemMessageService.expenseAdded(
          actorName: actorUserName ?? 'Someone',
          expenseTitle: expenseTitle ?? 'Expense',
          amount: amount,
        ),
      );

      transaction.set(nestRef.collection('Cycle').doc(cycleId), cycleData, SetOptions(merge: true));
    });
  }

  Future<void> updateExpense({
    required String nestId,
    required String expenseId,
    required Map<String, dynamic> expenseData,
    required double oldAmount,
    required double newAmount,
    required List<Map<String, dynamic>> splitsData,
    // Optional timeline context
    String? actorUserId,
    String? actorUserName,
    String? expenseTitle,
  }) async {
    final nestRef = _firestore.collection('nests').doc(nestId);
    final expenseRef = nestRef.collection('expenses').doc(expenseId);
    final timelineRef = _newTimelineRef(nestId);

    // 1. READS OUTSIDE TRANSACTION:
    final nestDoc = await nestRef.get();
    if (!nestDoc.exists) throw Exception('Nest does not exist');

    final nestData = nestDoc.data()!;
    final cycleDay = nestData['settlementCycleDate'] as int? ?? 1;
    final DateTime? customStart = nestData['customStartDate'] != null 
        ? (nestData['customStartDate'] as Timestamp).toDate() 
        : null;
    final DateTime? customEnd = nestData['customEndDate'] != null 
        ? (nestData['customEndDate'] as Timestamp).toDate() 
        : null;

    final bounds = CycleCalculator.calculateCycleBounds(
      cycleDay: cycleDay,
      customStart: customStart,
      customEnd: customEnd,
    );

    final expensesSnap = await nestRef.collection('expenses')
        .where('date', isGreaterThanOrEqualTo: bounds.start.millisecondsSinceEpoch)
        .where('date', isLessThan: bounds.end.millisecondsSinceEpoch)
        .get();
    final settlementsSnap = await nestRef.collection('settlements')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(bounds.start))
        .where('createdAt', isLessThan: Timestamp.fromDate(bounds.end))
        .get();

    // Query all existing splits in the sub-collection to delete them
    final oldSplitsSnap = await expenseRef.collection('splits').get();

    // Query FIFO collections outside the transaction:
    final payerId = expenseData['paidBy'] as String;
    final settlementsSnapFIFO = await nestRef.collection('settlements')
        .where('receivedBy', isEqualTo: payerId)
        .get();
    final expensesSnapFIFO = await nestRef.collection('expenses')
        .where('paidBy', isEqualTo: payerId)
        .get();

    final debtorIds = splitsData
        .map((s) => s['memberId'] as String)
        .where((id) => id != payerId)
        .toList();

    await _firestore.runTransaction((transaction) async {
      // 2. READS INSIDE TRANSACTION:
      final nestDocTx = await transaction.get(nestRef);
      if (!nestDocTx.exists) throw Exception('Nest does not exist');

      final nestDataTx = nestDocTx.data()!;
      String? cycleId = nestDataTx['currentCycleId'] as String?;
      bool needsNewCycle = cycleId == null;
      if (cycleId != null) {
        final cycleDoc = await transaction.get(nestRef.collection('Cycle').doc(cycleId));
        if (cycleDoc.exists) {
          final cycleEndDate = (cycleDoc.data()!['cycleEndDate'] as Timestamp).toDate();
          if (DateTime.now().isAfter(cycleEndDate)) {
            needsNewCycle = true;
            final cycleStartDate = (cycleDoc.data()!['cycleStartDate'] as Timestamp).toDate();
            SystemMessageService.writeInTransaction(
              transaction: transaction,
              nestId: nestId,
              messageText: SystemMessageService.cycleCompleted(start: cycleStartDate, end: cycleEndDate),
            );
          }
        } else {
          needsNewCycle = true;
        }
      }

      // 3. IN-MEMORY CALCULATION:
      final List<Map<String, dynamic>> allExpenses = expensesSnap.docs.map((d) => d.data()).toList();
      final idx = allExpenses.indexWhere((e) => e['expenseId'] == expenseId);
      if (idx != -1) {
        allExpenses[idx] = expenseData;
      } else {
        allExpenses.add(expenseData);
      }

      final List<Map<String, dynamic>> allSettlements = settlementsSnap.docs.map((d) => d.data()).toList();
      final memberCount = (nestDataTx['memberIds'] as List<dynamic>?)?.length ?? 0;

      if (needsNewCycle) {
        cycleId = 'cycle_${bounds.start.year}_${bounds.start.month.toString().padLeft(2, '0')}_${DateTime.now().millisecondsSinceEpoch}';
      }

      final cycleData = CycleCalculator.computeCycleData(
        cycleId: cycleId!,
        cycleStart: bounds.start,
        cycleEnd: bounds.end,
        expenses: allExpenses,
        settlements: allSettlements,
        memberCount: memberCount,
      );
      if (needsNewCycle) {
        cycleData['createdAt'] = FieldValue.serverTimestamp();
      }

      // 4. WRITES:
      if (needsNewCycle) {
        transaction.update(nestRef, {'currentCycleId': cycleId});
      }

      // Delete old split subcollection docs
      for (final doc in oldSplitsSnap.docs) {
        transaction.delete(doc.reference);
      }

      // Set new split subcollection docs
      for (final split in splitsData) {
        final memberId = split['memberId'] as String;
        final splitId = _firestore.collection('nests').doc(nestId).collection('expenses').doc(expenseId).collection('splits').doc().id;
        
        final newSplit = {
          ...split,
          'splitId': splitId,
          'memberId': memberId,
          'userId': memberId,
          'paidBy': expenseData['paidBy'],
          'paidByName': expenseData['paidByName'],
          'originalShare': split['amount'],
          'settledAmount': 0.0,
          'pendingAmount': split['amount'],
          'status': 'pending',
          'updatedAt': FieldValue.serverTimestamp(),
          'memberName': split['memberName'] ?? 'Someone',
        };
        transaction.set(expenseRef.collection('splits').doc(memberId), newSplit);
      }

      transaction.update(expenseRef, expenseData);

      // Execute FIFO allocations on splits
      final List<Map<String, dynamic>> allSettlementsFIFO =
          settlementsSnapFIFO.docs.map((d) => d.data()).toList();
      final List<Map<String, dynamic>> allExpensesFIFO =
          expensesSnapFIFO.docs.map((d) => d.data()).toList();

      final eIdx = allExpensesFIFO.indexWhere((e) => e['expenseId'] == expenseId);
      if (eIdx != -1) {
        allExpensesFIFO[eIdx] = expenseData;
      } else {
        allExpensesFIFO.add(expenseData);
      }

      _reallocateFIFO(
        nestId: nestId,
        payerId: payerId,
        debtorIds: debtorIds,
        allSettlements: allSettlementsFIFO,
        allExpenses: allExpensesFIFO,
        transaction: transaction,
      );

      final double current = (nestDataTx['totalExpense'] as num?)?.toDouble() ?? 0.0;
      transaction.update(nestRef, {
        'totalExpense': current - oldAmount + newAmount,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastActivity': FieldValue.serverTimestamp(),
      });

      // ── Timeline event ──────────────────────────────────────────────────────
      transaction.set(timelineRef, {
        'type': 'expense_updated',
        'title': expenseTitle ?? 'Expense Updated',
        'description':
            '${actorUserName ?? 'Someone'} edited an expense to ₹${newAmount.toStringAsFixed(0)}',
        'amount': newAmount,
        'userId': actorUserId ?? '',
        'userName': actorUserName ?? '',
        'expenseId': expenseId,
        'settlementId': null,
        'memberId': null,
        'icon': 'edit',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ── System chat message ─────────────────────────────────────────────────
      SystemMessageService.writeInTransaction(
        transaction: transaction,
        nestId: nestId,
        messageText: SystemMessageService.expenseUpdated(
          actorName: actorUserName ?? 'Someone',
          expenseTitle: expenseTitle ?? 'Expense',
          newAmount: newAmount,
        ),
      );

      transaction.set(nestRef.collection('Cycle').doc(cycleId), cycleData, SetOptions(merge: true));
    });
  }

  Future<void> deleteExpense({
    required String nestId,
    required String expenseId,
    required double amount,
    // Optional timeline context
    String? actorUserId,
    String? actorUserName,
    String? expenseTitle,
  }) async {
    final nestRef = _firestore.collection('nests').doc(nestId);
    final expenseRef = nestRef.collection('expenses').doc(expenseId);
    final timelineRef = _newTimelineRef(nestId);

    // 1. READS OUTSIDE TRANSACTION:
    final nestDoc = await nestRef.get();
    if (!nestDoc.exists) throw Exception('Nest does not exist');

    final nestData = nestDoc.data()!;
    final cycleDay = nestData['settlementCycleDate'] as int? ?? 1;
    final DateTime? customStart = nestData['customStartDate'] != null 
        ? (nestData['customStartDate'] as Timestamp).toDate() 
        : null;
    final DateTime? customEnd = nestData['customEndDate'] != null 
        ? (nestData['customEndDate'] as Timestamp).toDate() 
        : null;

    final bounds = CycleCalculator.calculateCycleBounds(
      cycleDay: cycleDay,
      customStart: customStart,
      customEnd: customEnd,
    );

    final expensesSnap = await nestRef.collection('expenses')
        .where('date', isGreaterThanOrEqualTo: bounds.start.millisecondsSinceEpoch)
        .where('date', isLessThan: bounds.end.millisecondsSinceEpoch)
        .get();
    final settlementsSnap = await nestRef.collection('settlements')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(bounds.start))
        .where('createdAt', isLessThan: Timestamp.fromDate(bounds.end))
        .get();

    // Query the old splits subcollection to delete them
    final oldSplitsSnap = await expenseRef.collection('splits').get();

    // Query current expense doc to find payer and debtor IDs
    final targetExpenseDoc = await expenseRef.get();
    if (!targetExpenseDoc.exists) return; // Already deleted or doesn't exist
    final targetExpenseData = targetExpenseDoc.data()!;
    final payerId = targetExpenseData['paidBy'] as String;
    final rawSplits = targetExpenseData['splits'] as List<dynamic>? ?? [];
    final debtorIds = rawSplits
        .map((s) => s['userId'] as String)
        .where((id) => id != payerId)
        .toList();

    // Query FIFO collections outside the transaction:
    final settlementsSnapFIFO = await nestRef.collection('settlements')
        .where('receivedBy', isEqualTo: payerId)
        .get();
    final expensesSnapFIFO = await nestRef.collection('expenses')
        .where('paidBy', isEqualTo: payerId)
        .get();

    await _firestore.runTransaction((transaction) async {
      // 2. READS INSIDE TRANSACTION:
      final nestDocTx = await transaction.get(nestRef);
      if (!nestDocTx.exists) throw Exception('Nest does not exist');

      final nestDataTx = nestDocTx.data()!;
      String? cycleId = nestDataTx['currentCycleId'] as String?;
      bool needsNewCycle = cycleId == null;
      if (cycleId != null) {
        final cycleDoc = await transaction.get(nestRef.collection('Cycle').doc(cycleId));
        if (cycleDoc.exists) {
          final cycleEndDate = (cycleDoc.data()!['cycleEndDate'] as Timestamp).toDate();
          if (DateTime.now().isAfter(cycleEndDate)) {
            needsNewCycle = true;
            final cycleStartDate = (cycleDoc.data()!['cycleStartDate'] as Timestamp).toDate();
            SystemMessageService.writeInTransaction(
              transaction: transaction,
              nestId: nestId,
              messageText: SystemMessageService.cycleCompleted(start: cycleStartDate, end: cycleEndDate),
            );
          }
        } else {
          needsNewCycle = true;
        }
      }

      // 3. IN-MEMORY CALCULATION:
      final List<Map<String, dynamic>> allExpenses = expensesSnap.docs.map((d) => d.data()).toList();
      allExpenses.removeWhere((e) => e['expenseId'] == expenseId);

      final List<Map<String, dynamic>> allSettlements = settlementsSnap.docs.map((d) => d.data()).toList();
      final memberCount = (nestDataTx['memberIds'] as List<dynamic>?)?.length ?? 0;

      if (needsNewCycle) {
        cycleId = 'cycle_${bounds.start.year}_${bounds.start.month.toString().padLeft(2, '0')}_${DateTime.now().millisecondsSinceEpoch}';
      }

      final cycleData = CycleCalculator.computeCycleData(
        cycleId: cycleId!,
        cycleStart: bounds.start,
        cycleEnd: bounds.end,
        expenses: allExpenses,
        settlements: allSettlements,
        memberCount: memberCount,
      );
      if (needsNewCycle) {
        cycleData['createdAt'] = FieldValue.serverTimestamp();
      }

      // 4. WRITES:
      if (needsNewCycle) {
        transaction.update(nestRef, {'currentCycleId': cycleId});
      }

      // Delete subcollection split docs
      for (final doc in oldSplitsSnap.docs) {
        transaction.delete(doc.reference);
      }

      transaction.delete(expenseRef);

      // Execute FIFO allocations on remaining splits (omitting the deleted expense)
      final List<Map<String, dynamic>> allSettlementsFIFO =
          settlementsSnapFIFO.docs.map((d) => d.data()).toList();
      final List<Map<String, dynamic>> allExpensesFIFO =
          expensesSnapFIFO.docs.map((d) => d.data()).toList();
      allExpensesFIFO.removeWhere((e) => e['expenseId'] == expenseId);

      _reallocateFIFO(
        nestId: nestId,
        payerId: payerId,
        debtorIds: debtorIds,
        allSettlements: allSettlementsFIFO,
        allExpenses: allExpensesFIFO,
        transaction: transaction,
      );

      final double current = (nestDataTx['totalExpense'] as num?)?.toDouble() ?? 0.0;
      transaction.update(nestRef, {
        'totalExpense': (current - amount).clamp(0.0, double.infinity),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastActivity': FieldValue.serverTimestamp(),
      });

      // ── Timeline event ──────────────────────────────────────────────────────
      transaction.set(timelineRef, {
        'type': 'expense_deleted',
        'title': 'Expense Deleted',
        'description':
            '${actorUserName ?? 'Someone'} deleted an expense of ₹${amount.toStringAsFixed(0)}',
        'amount': amount,
        'userId': actorUserId ?? '',
        'userName': actorUserName ?? '',
        'expenseId': expenseId,
        'settlementId': null,
        'memberId': null,
        'icon': 'delete',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ── System chat message ─────────────────────────────────────────────────
      SystemMessageService.writeInTransaction(
        transaction: transaction,
        nestId: nestId,
        messageText: SystemMessageService.expenseDeleted(
          actorName: actorUserName ?? 'Someone',
          expenseTitle: expenseTitle ?? 'Expense',
        ),
      );

      transaction.set(nestRef.collection('Cycle').doc(cycleId), cycleData, SetOptions(merge: true));
    });
  }

  void _reallocateFIFO({
    required String nestId,
    required String payerId,
    required List<String> debtorIds,
    required List<Map<String, dynamic>> allSettlements,
    required List<Map<String, dynamic>> allExpenses,
    required Transaction transaction,
  }) {
    for (final debtorId in debtorIds) {
      if (debtorId == payerId) continue;

      // Sum all settlements from debtorId to payerId
      double totalSettledAmount = 0.0;
      for (final set in allSettlements) {
        if (set['paidBy'] == debtorId && set['receivedBy'] == payerId) {
          totalSettledAmount += (set['amount'] as num?)?.toDouble() ?? 0.0;
        }
      }

      // Gather expenses paid by payerId where debtorId is in splits list
      final List<Map<String, dynamic>> debtorExpenses = [];
      for (final exp in allExpenses) {
        if (exp['paidBy'] == payerId) {
          final splits = exp['splits'] as List<dynamic>? ?? [];
          final hasDebtor = splits.any((s) => (s['userId'] ?? s['memberId']) == debtorId);
          if (hasDebtor) {
            debtorExpenses.add(exp);
          }
        }
      }

      // Sort expenses by date (ascending)
      debtorExpenses.sort((a, b) {
        final aTime = a['date'] ?? a['createdAt'] ?? 0;
        final bTime = b['date'] ?? b['createdAt'] ?? 0;
        final aVal = aTime is Timestamp 
            ? aTime.millisecondsSinceEpoch 
            : (aTime is int ? aTime : 0);
        final bVal = bTime is Timestamp 
            ? bTime.millisecondsSinceEpoch 
            : (bTime is int ? bTime : 0);
        return aVal.compareTo(bVal);
      });

      double remainingToSettle = totalSettledAmount;
      for (final exp in debtorExpenses) {
        final expenseId = exp['expenseId'] ?? exp['id'] as String;
        final splits = List<dynamic>.from(exp['splits'] as List<dynamic>? ?? []);

        final splitIndex = splits.indexWhere((s) => (s['userId'] ?? s['memberId']) == debtorId);
        if (splitIndex == -1) continue;

        final splitMap = Map<String, dynamic>.from(splits[splitIndex]);
        final splitAmount = (splitMap['amount'] as num?)?.toDouble() ?? 0.0;

        final double allocated = remainingToSettle >= splitAmount ? splitAmount : remainingToSettle;
        remainingToSettle -= allocated;

        final isFullySettled = (allocated >= splitAmount - 0.01);

        splitMap['status'] = isFullySettled ? 'completed' : 'pending';
        splitMap['isSettled'] = isFullySettled;
        splitMap['settledAt'] = isFullySettled ? FieldValue.serverTimestamp() : null;

        splits[splitIndex] = splitMap;
        exp['splits'] = splits;

        // Update the subcollection split document
        final splitDocRef = _firestore
            .collection('nests')
            .doc(nestId)
            .collection('expenses')
            .doc(expenseId)
            .collection('splits')
            .doc(debtorId);

        transaction.set(splitDocRef, {
          'status': isFullySettled ? 'completed' : 'pending',
          'isSettled': isFullySettled,
          'settledAt': isFullySettled ? FieldValue.serverTimestamp() : null,
        }, SetOptions(merge: true));

        // Update parent doc splits list
        final expDocRef = _firestore
            .collection('nests')
            .doc(nestId)
            .collection('expenses')
            .doc(expenseId);
        
        transaction.update(expDocRef, {'splits': splits});
      }
    }
  }
}
