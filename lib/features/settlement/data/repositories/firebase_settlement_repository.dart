import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:splitnest/features/groups/domain/calculators/cycle_calculator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../members/domain/repositories/member_repository.dart';
import '../../../expenses/domain/repositories/expenses_repository.dart';
import '../../domain/repositories/settlement_repository.dart';
import '../../domain/models/settlement.dart';
import '../../domain/models/balance.dart';
import '../../../balances/domain/calculators/balance_calculator.dart';
import '../../../members/domain/models/member_model.dart';
import '../../../expenses/domain/models/expense.dart';
import '../../../../features/chat/data/services/system_message_service.dart';

class FirebaseSettlementRepository implements SettlementRepository {
  final MemberRepository _memberRepository;
  final ExpensesRepository _expensesRepository;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseSettlementRepository(this._memberRepository, this._expensesRepository);

  @override
  Future<List<Settlement>> getSettlements(String groupId) async {
    final snap = await _firestore
        .collection('nests')
        .doc(groupId)
        .collection('settlements')
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((doc) => Settlement.fromMap(doc.data())).toList();
  }

  @override
  Stream<List<Settlement>> streamSettlements(String groupId) {
    return _firestore
        .collection('nests')
        .doc(groupId)
        .collection('settlements')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => Settlement.fromMap(doc.data())).toList());
  }

  @override
  Future<List<Balance>> getBalances(String groupId) async {
    final currentUserId = _auth.currentUser?.uid;
    final members = await _memberRepository.streamMembers(groupId).first;
    final expenses = await _expensesRepository.streamExpenses(groupId).first;
    final settlements = await getSettlements(groupId);
    return BalanceCalculator.calculateSimplifiedBalances(
      groupId: groupId,
      members: members,
      expenses: expenses,
      settlements: settlements,
      currentUserId: currentUserId,
    );
  }

  @override
  Stream<List<Balance>> streamBalances(String groupId) {
    final controller = StreamController<List<Balance>>();
    final currentUserId = _auth.currentUser?.uid;

    List<MemberModel>? lastMembers;
    List<Expense>? lastExpenses;
    List<Settlement>? lastSettlements;

    StreamSubscription? membersSub;
    StreamSubscription? expensesSub;
    StreamSubscription? settlementsSub;

    void update() {
      if (lastMembers != null && lastExpenses != null && lastSettlements != null) {
        try {
          final balances = BalanceCalculator.calculateSimplifiedBalances(
            groupId: groupId,
            members: lastMembers!,
            expenses: lastExpenses!,
            settlements: lastSettlements!,
            currentUserId: currentUserId,
          );
          if (!controller.isClosed) controller.add(balances);
        } catch (e, stack) {
          if (!controller.isClosed) controller.addError(e, stack);
        }
      }
    }

    membersSub = _memberRepository.streamMembers(groupId).listen(
      (m) { lastMembers = m; update(); },
      onError: (err) { if (!controller.isClosed) controller.addError(err); },
    );
    expensesSub = _expensesRepository.streamExpenses(groupId).listen(
      (e) { lastExpenses = e; update(); },
      onError: (err) { if (!controller.isClosed) controller.addError(err); },
    );
    settlementsSub = streamSettlements(groupId).listen(
      (s) { lastSettlements = s; update(); },
      onError: (err) { if (!controller.isClosed) controller.addError(err); },
    );

    controller.onCancel = () {
      membersSub?.cancel();
      expensesSub?.cancel();
      settlementsSub?.cancel();
      controller.close();
    };

    return controller.stream;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // createSettlement — per-split settle (from split detail screen)
  // ───────────────────────────────────────────────────────────────────────────
  @override
  Future<Settlement> createSettlement({
    required String groupId,
    required String expenseId,
    required String splitId,
    required double amount,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final nestRef = _firestore.collection('nests').doc(groupId);
    final expenseRef = nestRef.collection('expenses').doc(expenseId);
    final splitRef = expenseRef.collection('splits').doc(splitId);

    final splitDoc = await splitRef.get();
    if (!splitDoc.exists) throw Exception('Split does not exist');
    final splitData = splitDoc.data()!;

    final paidBy = splitData['paidBy'] as String;
    final memberId = splitData['memberId'] as String? ?? splitData['userId'] as String;
    
    // Both the person who owes (memberId) and the person who paid (paidBy) can settle.
    if (user.uid != paidBy && user.uid != memberId) {
      throw Exception('Only the payer or receiver can confirm this settlement.');
    }

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

    final expensesSnap = await nestRef
        .collection('expenses')
        .where('date', isGreaterThanOrEqualTo: bounds.start.millisecondsSinceEpoch)
        .where('date', isLessThan: bounds.end.millisecondsSinceEpoch)
        .get();
    final settlementsSnap = await nestRef
        .collection('settlements')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(bounds.start))
        .where('createdAt', isLessThan: Timestamp.fromDate(bounds.end))
        .get();

    final payerId = memberId;
    final receiverId = paidBy;
    final payerName = splitData['memberName'] as String? ?? 'Someone';
    final receiverName = splitData['paidByName'] as String? ?? 'Someone';
    final pendingAmount = (splitData['pendingAmount'] as num?)?.toDouble() ?? 0.0;

    if (pendingAmount <= 0) throw Exception('This split is already fully settled.');

    final actualAmount = amount > pendingAmount ? pendingAmount : amount;
    final newSettlementDocRef = nestRef.collection('settlements').doc();

    final settlement = Settlement(
      id: newSettlementDocRef.id,
      groupId: groupId,
      expenseId: expenseId,
      splitId: splitId,
      payerId: payerId,
      receiverId: receiverId,
      amount: actualAmount,
      status: 'completed',
      createdBy: user.uid,
      createdAt: DateTime.now(),
      payerName: payerName,
      receiverName: receiverName,
    );

    await _firestore.runTransaction((transaction) async {
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
              nestId: groupId,
              messageText: SystemMessageService.cycleCompleted(start: cycleStartDate, end: cycleEndDate),
            );
          }
        } else {
          needsNewCycle = true;
        }
      }

      final splitDocTx = await transaction.get(splitRef);
      if (!splitDocTx.exists) throw Exception('Split does not exist');
      final currentSplitData = splitDocTx.data()!;
      final currentPending = (currentSplitData['pendingAmount'] as num?)?.toDouble() ?? 0.0;
      final currentSettled = (currentSplitData['settledAmount'] as num?)?.toDouble() ?? 0.0;

      if (currentPending <= 0) throw Exception('This split is already fully settled.');

      final txActualAmount = amount > currentPending ? currentPending : amount;
      final newPending = currentPending - txActualAmount;
      final newSettled = currentSettled + txActualAmount;
      final status = newPending <= 0.01 ? 'completed' : 'pending';

      transaction.update(splitRef, {
        'pendingAmount': newPending <= 0.01 ? 0.0 : newPending,
        'settledAmount': newSettled,
        'status': status,
        'isSettled': status == 'completed',
        'updatedAt': FieldValue.serverTimestamp(),
        if (status == 'completed') 'settledAt': FieldValue.serverTimestamp(),
      });

      final expenseDocTx = await transaction.get(expenseRef);
      if (expenseDocTx.exists) {
        final expenseData = expenseDocTx.data()!;
        final rawSplits = expenseData['splits'] as List<dynamic>? ?? [];
        final splitIndex = rawSplits.indexWhere((s) =>
            s['splitId'] == splitId || s['memberId'] == splitId || s['userId'] == splitId);
        if (splitIndex != -1) {
          final splitMap = Map<String, dynamic>.from(rawSplits[splitIndex]);
          splitMap['pendingAmount'] = newPending <= 0.01 ? 0.0 : newPending;
          splitMap['settledAmount'] = newSettled;
          splitMap['status'] = status;
          splitMap['isSettled'] = status == 'completed';
          if (status == 'completed') splitMap['settledAt'] = FieldValue.serverTimestamp();
          final newSplits = List<dynamic>.from(rawSplits);
          newSplits[splitIndex] = splitMap;
          transaction.update(expenseRef, {'splits': newSplits});
        }
      }

      final List<Map<String, dynamic>> allExpenses = expensesSnap.docs.map((d) => d.data()).toList();
      final List<Map<String, dynamic>> allSettlements = settlementsSnap.docs.map((d) => d.data()).toList();
      final newSettlementMap = {...settlement.toMap(), 'createdAt': Timestamp.now()};
      allSettlements.add(newSettlementMap);
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
      if (needsNewCycle) cycleData['createdAt'] = FieldValue.serverTimestamp();
      if (needsNewCycle) transaction.update(nestRef, {'currentCycleId': cycleId});

      transaction.set(newSettlementDocRef, {
        ...settlement.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      final isPartialPayment = txActualAmount < currentPending;
      final timelineRef = nestRef.collection('timeline').doc();
      transaction.set(timelineRef, {
        'type': isPartialPayment ? 'settlement_partial' : 'settlement_recorded',
        'title': isPartialPayment ? 'Partial Payment' : 'Settlement Recorded',
        'description': isPartialPayment
            ? '$payerName paid ₹${txActualAmount.toStringAsFixed(0)} partially to $receiverName'
            : '$payerName fully settled ₹${txActualAmount.toStringAsFixed(0)} with $receiverName',
        'amount': txActualAmount,
        'userId': payerId,
        'userName': payerName,
        'expenseId': expenseId,
        'settlementId': newSettlementDocRef.id,
        'memberId': payerId,
        'icon': isPartialPayment ? 'payments' : 'check_circle',
        'createdAt': FieldValue.serverTimestamp(),
      });

      SystemMessageService.writeInTransaction(
        transaction: transaction,
        nestId: groupId,
        messageText: SystemMessageService.settlementCompleted(
          fromName: payerName,
          toName: receiverName,
          amount: txActualAmount,
        ),
      );

      transaction.set(nestRef.collection('Cycle').doc(cycleId), cycleData, SetOptions(merge: true));
    });

    return settlement;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // settleDebt — settle all pending debt between debtor and creditor.
  // Uses a WriteBatch (not a Transaction) to avoid Firestore transaction
  // read-order violations that cause [cloud_firestore/unknown] null errors.
  // ───────────────────────────────────────────────────────────────────────────
  @override
  Future<void> settleDebt({
    required String groupId,
    required String debtorId,
    required String creditorId,
    required double amount,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final resolvedCreditorId = creditorId == 'user_me' ? user.uid : creditorId;
    final resolvedDebtorId = debtorId == 'user_me' ? user.uid : debtorId;

    if (user.uid != resolvedCreditorId && user.uid != resolvedDebtorId) {
      throw Exception('Only the payer or receiver can confirm this settlement.');
    }

    final nestRef = _firestore.collection('nests').doc(groupId);

    // ── Step 1: Pre-fetch everything we need ─────────────────────────────────
    final nestDoc = await nestRef.get();
    if (!nestDoc.exists) throw Exception('Nest does not exist');
    final nestData = nestDoc.data()!;
    final cycleId = nestData['currentCycleId'] as String?;
    final oldNestSettled = (nestData['totalSettled'] as num?)?.toDouble() ?? 0.0;

    final expensesSnap = await nestRef.collection('expenses').get();

    final debtorMemberDoc = await nestRef.collection('members').doc(resolvedDebtorId).get();
    final creditorMemberDoc = await nestRef.collection('members').doc(resolvedCreditorId).get();
    final debtorName = (debtorMemberDoc.data()?['fullName'] as String?) ?? 'Payer';
    final creditorName = (creditorMemberDoc.data()?['fullName'] as String?) ?? 'Receiver';

    DocumentSnapshot<Map<String, dynamic>>? cycleDoc;
    if (cycleId != null && cycleId.isNotEmpty) {
      cycleDoc = await nestRef.collection('Cycle').doc(cycleId).get();
    }

    // ── Step 2: Find eligible splits ─────────────────────────────────────────
    // A split is eligible when:
    //   - split.userId (or memberId) == resolvedDebtorId  (person who owes)
    //   - paidBy (split-level or expense-level) == resolvedCreditorId  (person owed)
    //   - pendingAmount > 0
    final List<Map<String, dynamic>> splitsToProcess = [];

    for (final expDoc in expensesSnap.docs) {
      final expData = expDoc.data();
      final rawSplits = expData['splits'] as List<dynamic>? ?? [];
      final expPaidBy = (expData['paidBy'] ?? expData['paidByUserId'] ?? '').toString();

      for (int i = 0; i < rawSplits.length; i++) {
        final s = rawSplits[i];
        if (s == null || s is! Map) continue;

        final splitUserId = (s['userId'] ?? s['memberId'] ?? '').toString().trim();
        if (splitUserId.isEmpty || splitUserId == resolvedCreditorId) continue;

        final sPaidByRaw = (s['paidBy'] ?? s['receivedBy'] ?? '').toString().trim();
        final splitPaidBy = sPaidByRaw.isEmpty ? expPaidBy : sPaidByRaw;
        if (splitPaidBy.isEmpty) continue;

        final pendingAmt = (s['pendingAmount'] as num?)?.toDouble() ?? 0.0;

        if (splitUserId == resolvedDebtorId &&
            splitPaidBy == resolvedCreditorId &&
            pendingAmt > 0.01) {
          splitsToProcess.add({
            'expenseId': expDoc.id,
            'arrayIdx': i,
            'memberDocId': splitUserId,
            'date': (expData['date'] as num?) ?? 0,
            'pendingAmount': pendingAmt,
            'settledAmount': (s['settledAmount'] as num?)?.toDouble() ?? 0.0,
            'memberName': (s['memberName'] as String?) ?? debtorName,
            'paidByName': (s['paidByName'] as String?) ?? creditorName,
            'originalArray': rawSplits,
          });
        }
      }
    }

    splitsToProcess.sort((a, b) => (a['date'] as num).compareTo(b['date'] as num));

    if (splitsToProcess.isEmpty) {
      throw Exception(
          'No pending debt found. Please ensure the expense was added with the correct payer and split configuration.');
    }

    // ── Step 3: Compute what gets settled ────────────────────────────────────
    double remaining = amount;
    double totalSettled = 0.0;

    final List<Map<String, dynamic>> processedSplits = [];

    for (final splitInfo in splitsToProcess) {
      if (remaining <= 0.01) break;

      final double pending = splitInfo['pendingAmount'] as double;
      final double settled = splitInfo['settledAmount'] as double;
      final double portion = remaining > pending ? pending : remaining;

      final double newPending = pending - portion;
      final double newSettled = settled + portion;
      final bool isFullySettled = newPending <= 0.01;

      remaining -= portion;
      totalSettled += portion;

      processedSplits.add({
        ...splitInfo,
        'portion': portion,
        'newPending': isFullySettled ? 0.0 : newPending,
        'newSettled': newSettled,
        'isFullySettled': isFullySettled,
      });
    }

    if (totalSettled <= 0.01) {
      throw Exception('Nothing to settle.');
    }

    // ── Step 4: Apply all writes as a WriteBatch ──────────────────────────────
    // WriteBatch has no read-order restrictions — avoids [cloud_firestore/unknown] null
    final batch = _firestore.batch();

    // Track mutated expense arrays to avoid double-writing the same expense
    final Map<String, List<dynamic>> mutatedArrays = {};

    for (final ps in processedSplits) {
      final String expId = ps['expenseId'] as String;
      final int arrayIdx = ps['arrayIdx'] as int;
      final String memberDocId = ps['memberDocId'] as String;
      final double portion = ps['portion'] as double;
      final double newPending = ps['newPending'] as double;
      final double newSettled = ps['newSettled'] as double;
      final bool isFullySettled = ps['isFullySettled'] as bool;

      // 1. Split subcollection doc (set+merge — safe if doc doesn't exist)
      final splitDocRef = nestRef
          .collection('expenses').doc(expId)
          .collection('splits').doc(memberDocId);
      batch.set(splitDocRef, {
        'userId': memberDocId,
        'memberId': memberDocId,
        'pendingAmount': newPending,
        'settledAmount': newSettled,
        'status': isFullySettled ? 'completed' : 'pending',
        'isSettled': isFullySettled,
        'updatedAt': FieldValue.serverTimestamp(),
        if (isFullySettled) 'settledAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2. Splits array inside expense doc
      if (!mutatedArrays.containsKey(expId)) {
        // Clone the original array from the snapshot
        final expSnap = expensesSnap.docs.firstWhere((d) => d.id == expId);
        mutatedArrays[expId] = List<dynamic>.from(expSnap.data()['splits'] ?? []);
      }
      final arr = mutatedArrays[expId]!;
      if (arrayIdx < arr.length) {
        final splitMap = Map<String, dynamic>.from(arr[arrayIdx] as Map);
        splitMap['pendingAmount'] = newPending;
        splitMap['settledAmount'] = newSettled;
        splitMap['status'] = isFullySettled ? 'completed' : 'pending';
        splitMap['isSettled'] = isFullySettled;
        if (isFullySettled) splitMap['settledAt'] = Timestamp.now();
        arr[arrayIdx] = splitMap;
      }

      // 3. Settlement record
      final settlementRef = nestRef.collection('settlements').doc();
      batch.set(settlementRef, {
        'settlementId': settlementRef.id,
        'groupId': groupId,
        'expenseId': expId,
        'splitId': memberDocId,
        'payerId': resolvedDebtorId,
        'receiverId': resolvedCreditorId,
        'payerName': ps['memberName'],
        'receiverName': ps['paidByName'],
        'amount': portion,
        'status': 'completed',
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4. Timeline
      final timelineRef = nestRef.collection('timeline').doc();
      batch.set(timelineRef, {
        'type': isFullySettled ? 'settlement_recorded' : 'settlement_partial',
        'title': isFullySettled ? 'Settlement Recorded' : 'Partial Payment',
        'description': isFullySettled
            ? '${ps['memberName']} fully settled ₹${portion.toStringAsFixed(0)} with ${ps['paidByName']}'
            : '${ps['memberName']} paid ₹${portion.toStringAsFixed(0)} partially to ${ps['paidByName']}',
        'amount': portion,
        'userId': resolvedDebtorId,
        'userName': ps['memberName'],
        'expenseId': expId,
        'settlementId': settlementRef.id,
        'memberId': resolvedDebtorId,
        'icon': isFullySettled ? 'check_circle' : 'payments',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // Write mutated expense arrays
    for (final entry in mutatedArrays.entries) {
      batch.update(nestRef.collection('expenses').doc(entry.key), {
        'splits': entry.value,
      });
    }

    // 5. Nest stats
    batch.update(nestRef, {
      'totalSettled': oldNestSettled + totalSettled,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastActivity': FieldValue.serverTimestamp(),
    });

    // 6. Cycle stats
    if (cycleId != null && cycleId.isNotEmpty && cycleDoc != null && cycleDoc.exists) {
      final cd = cycleDoc.data()!;
      final oldCycleSettled = (cd['totalSettled'] as num?)?.toDouble() ?? 0.0;
      final oldCycleExpenses = (cd['totalExpenses'] as num?)?.toDouble() ?? 0.0;
      final newCycleSettled = oldCycleSettled + totalSettled;
      final newCyclePending = (oldCycleExpenses - newCycleSettled).clamp(0.0, double.infinity);
      final newCyclePct = oldCycleExpenses > 0
          ? (newCycleSettled / oldCycleExpenses).clamp(0.0, 1.0)
          : 1.0;
      batch.update(nestRef.collection('Cycle').doc(cycleId), {
        'totalSettled': newCycleSettled,
        'totalPending': newCyclePending,
        'settledPercentage': newCyclePct,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }


    // 11. Notifications
    final debtorNotifRef = _firestore
        .collection('users').doc(resolvedDebtorId).collection('notifications').doc();
    batch.set(debtorNotifRef, {
      'id': debtorNotifRef.id,
      'title': 'Settlement Paid',
      'description': 'You settled ₹${totalSettled.toStringAsFixed(0)} with $creditorName.',
      'type': 'settlement_paid',
      'groupId': groupId,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    final creditorNotifRef = _firestore
        .collection('users').doc(resolvedCreditorId).collection('notifications').doc();
    batch.set(creditorNotifRef, {
      'id': creditorNotifRef.id,
      'title': 'Settlement Received',
      'description': '$debtorName settled ₹${totalSettled.toStringAsFixed(0)} with you.',
      'type': 'settlement_received',
      'groupId': groupId,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    // 12. Chat system message
    final chatRef = _firestore
        .collection('nests').doc(groupId).collection('messages').doc();
    batch.set(chatRef, {
      'id': chatRef.id,
      'text': '$debtorName settled ₹${totalSettled.toStringAsFixed(0)} with $creditorName. 🤝',
      'senderId': 'system',
      'senderName': 'SplitNest',
      'type': 'system',
      'createdAt': FieldValue.serverTimestamp(),
      'isSystem': true,
    });

    // ── Step 5: Commit batch ──────────────────────────────────────────────────
    await batch.commit();
  }
}
