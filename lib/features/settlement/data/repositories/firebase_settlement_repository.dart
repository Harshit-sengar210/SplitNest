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

    membersSub = _memberRepository.streamMembers(groupId).listen(
      (m) {
        lastMembers = m;
        update();
      },
      onError: (err) {
        if (!controller.isClosed) controller.addError(err);
      },
    );

    expensesSub = _expensesRepository.streamExpenses(groupId).listen(
      (e) {
        lastExpenses = e;
        update();
      },
      onError: (err) {
        if (!controller.isClosed) controller.addError(err);
      },
    );

    settlementsSub = streamSettlements(groupId).listen(
      (s) {
        lastSettlements = s;
        update();
      },
      onError: (err) {
        if (!controller.isClosed) controller.addError(err);
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
    
    // 1. READS OUTSIDE TRANSACTION:
    final splitDoc = await splitRef.get();
    if (!splitDoc.exists) throw Exception('Split does not exist');
    final splitData = splitDoc.data()!;
    
    final paidBy = splitData['paidBy'] as String;
    if (user.uid != paidBy) {
      throw Exception('Only the receiver can confirm this settlement.');
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

    final expensesSnap = await nestRef.collection('expenses')
        .where('date', isGreaterThanOrEqualTo: bounds.start.millisecondsSinceEpoch)
        .where('date', isLessThan: bounds.end.millisecondsSinceEpoch)
        .get();
    final settlementsSnap = await nestRef.collection('settlements')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(bounds.start))
        .where('createdAt', isLessThan: Timestamp.fromDate(bounds.end))
        .get();
    
    final memberId = splitData['memberId'] as String;
    final payerId = memberId;
    final receiverId = paidBy;
    final payerName = splitData['memberName'] as String? ?? 'Someone';
    final receiverName = splitData['paidByName'] as String? ?? 'Someone';
    final pendingAmount = (splitData['pendingAmount'] as num?)?.toDouble() ?? 0.0;
    
    if (pendingAmount <= 0) {
      throw Exception('This split is already fully settled.');
    }
    
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

      // Re-read split to ensure consistency
      final splitDocTx = await transaction.get(splitRef);
      if (!splitDocTx.exists) throw Exception('Split does not exist');
      final currentSplitData = splitDocTx.data()!;
      final currentPending = (currentSplitData['pendingAmount'] as num?)?.toDouble() ?? 0.0;
      final currentSettled = (currentSplitData['settledAmount'] as num?)?.toDouble() ?? 0.0;
      
      if (currentPending <= 0) {
        throw Exception('This split is already fully settled.');
      }
      
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
      
      // Fetch Expense to update its array as well (backward compatibility)
      final expenseDocTx = await transaction.get(expenseRef);
      if (expenseDocTx.exists) {
        final expenseData = expenseDocTx.data()!;
        final rawSplits = expenseData['splits'] as List<dynamic>? ?? [];
        final splitIndex = rawSplits.indexWhere((s) => s['splitId'] == splitId || s['memberId'] == splitId || s['userId'] == splitId);
        
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
      final newSettlementMap = {
        ...settlement.toMap(),
        'createdAt': Timestamp.now(),
      };
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
      if (needsNewCycle) {
        cycleData['createdAt'] = FieldValue.serverTimestamp();
      }

      if (needsNewCycle) {
        transaction.update(nestRef, {'currentCycleId': cycleId});
      }
      
      // Write the new settlement document
      transaction.set(newSettlementDocRef, {
        ...settlement.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Write timeline event
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

      // System chat message
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

  @override
  Future<void> settleDebt({
    required String groupId,
    required String debtorId,
    required String creditorId,
    required double amount,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    // Resolve user IDs if mock strings like 'user_me' are passed
    final resolvedCreditorId = creditorId == 'user_me' ? user.uid : creditorId;
    final resolvedDebtorId = debtorId == 'user_me' ? user.uid : debtorId;

    if (user.uid != resolvedCreditorId) {
      throw Exception('Only the receiver can confirm this settlement.');
    }

    final nestRef = _firestore.collection('nests').doc(groupId);

    final expensesSnap = await nestRef.collection('expenses').get();
    
    final debtorTxsSnap = await _firestore
        .collection('users')
        .doc(resolvedDebtorId)
        .collection('ledger')
        .doc('transactions')
        .collection('transactions')
        .get();

    final creditorTxsSnap = await _firestore
        .collection('users')
        .doc(resolvedCreditorId)
        .collection('ledger')
        .doc('transactions')
        .collection('transactions')
        .get();

    await _firestore.runTransaction((transaction) async {
      // 1. Fetch Nest Doc
      final nestDoc = await transaction.get(nestRef);
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
      
      // Resolve member names
      final debtorMemberSnap = await transaction.get(nestRef.collection('members').doc(resolvedDebtorId));
      final creditorMemberSnap = await transaction.get(nestRef.collection('members').doc(resolvedCreditorId));
      final debtorName = debtorMemberSnap.exists ? (debtorMemberSnap.data()?['fullName'] ?? 'Debtor') : 'Debtor';
      final creditorName = creditorMemberSnap.exists ? (creditorMemberSnap.data()?['fullName'] ?? 'Creditor') : 'Creditor';

      // Find unpaid splits belonging to that debtor
      final List<Map<String, dynamic>> targetSplitsToProcess = [];
      for (final expDoc in expensesSnap.docs) {
        final expData = expDoc.data();
        final rawSplits = expData['splits'] as List<dynamic>? ?? [];
        for (final s in rawSplits) {
          final splitUserId = s['userId'] ?? s['memberId'] ?? '';
          final splitPaidBy = s['paidBy'] ?? s['receivedBy'] ?? '';
          final pendingAmt = (s['pendingAmount'] as num?)?.toDouble() ?? 0.0;
          if (splitUserId == resolvedDebtorId && splitPaidBy == resolvedCreditorId && pendingAmt > 0.01) {
            targetSplitsToProcess.add({
              'expenseId': expDoc.id,
              'splitId': s['splitId'] ?? s['memberId'] ?? '',
              'date': expData['date'] ?? 0,
              'pendingAmount': pendingAmt,
              'settledAmount': (s['settledAmount'] as num?)?.toDouble() ?? 0.0,
              'memberName': s['memberName'] ?? debtorName,
              'paidByName': s['paidByName'] ?? creditorName,
            });
          }
        }
      }

      // Sort splits by date (FIFO)
      targetSplitsToProcess.sort((a, b) => (a['date'] as num).compareTo(b['date'] as num));

      if (targetSplitsToProcess.isEmpty) {
        throw Exception('No pending debt found between these members.');
      }

      double remaining = amount;
      double totalSettledThisTime = 0.0;

      for (final splitInfo in targetSplitsToProcess) {
        if (remaining <= 0.01) break;
        final double pending = splitInfo['pendingAmount'];
        final double portion = remaining > pending ? pending : remaining;

        final String expId = splitInfo['expenseId'];
        final String splitId = splitInfo['splitId'];
        final double oldSettled = splitInfo['settledAmount'];

        final double newPending = pending - portion;
        final double newSettled = oldSettled + portion;
        final String status = newPending <= 0.01 ? 'completed' : 'pending';

        totalSettledThisTime += portion;
        remaining -= portion;

        // Update split subcollection doc
        final splitDocRef = nestRef.collection('expenses').doc(expId).collection('splits').doc(splitId);
        transaction.update(splitDocRef, {
          'pendingAmount': newPending <= 0.01 ? 0.0 : newPending,
          'settledAmount': newSettled,
          'status': status,
          'isSettled': status == 'completed',
          'updatedAt': FieldValue.serverTimestamp(),
          if (status == 'completed') 'settledAt': FieldValue.serverTimestamp(),
        });

        // Update splits array inside expense doc
        final expDocRef = nestRef.collection('expenses').doc(expId);
        final expDocSnap = await transaction.get(expDocRef);
        if (expDocSnap.exists) {
          final expData = expDocSnap.data()!;
          final splitsList = List<dynamic>.from(expData['splits'] ?? []);
          final idx = splitsList.indexWhere((s) => s['splitId'] == splitId || s['memberId'] == splitId);
          if (idx != -1) {
            final splitMap = Map<String, dynamic>.from(splitsList[idx]);
            splitMap['pendingAmount'] = newPending <= 0.01 ? 0.0 : newPending;
            splitMap['settledAmount'] = newSettled;
            splitMap['status'] = status;
            splitMap['isSettled'] = status == 'completed';
            if (status == 'completed') splitMap['settledAt'] = FieldValue.serverTimestamp();
            splitsList[idx] = splitMap;
            transaction.update(expDocRef, {'splits': splitsList});
          }
        }

        // Create settlement document under nest
        final newSettlementDocRef = nestRef.collection('settlements').doc();
        transaction.set(newSettlementDocRef, {
          'settlementId': newSettlementDocRef.id,
          'groupId': groupId,
          'expenseId': expId,
          'splitId': splitId,
          'payerId': resolvedDebtorId,
          'receiverId': resolvedCreditorId,
          'amount': portion,
          'status': 'completed',
          'createdBy': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'payerName': splitInfo['memberName'],
          'receiverName': splitInfo['paidByName'],
        });

        // Write Nest timeline event
        final timelineRef = nestRef.collection('timeline').doc();
        transaction.set(timelineRef, {
          'type': portion < pending ? 'settlement_partial' : 'settlement_recorded',
          'title': portion < pending ? 'Partial Payment' : 'Settlement Recorded',
          'description': portion < pending
              ? '${splitInfo['memberName']} paid ₹${portion.toStringAsFixed(0)} partially to ${splitInfo['paidByName']}'
              : '${splitInfo['memberName']} fully settled ₹${portion.toStringAsFixed(0)} with ${splitInfo['paidByName']}',
          'amount': portion,
          'userId': resolvedDebtorId,
          'userName': splitInfo['memberName'],
          'expenseId': expId,
          'settlementId': newSettlementDocRef.id,
          'memberId': resolvedDebtorId,
          'icon': portion < pending ? 'payments' : 'check_circle',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (totalSettledThisTime <= 0) return;

      // Update parent Nest document stats (totalExpense and totalSettled)
      final double oldNestSettled = (nestData['totalSettled'] as num?)?.toDouble() ?? 0.0;
      transaction.update(nestRef, {
        'totalSettled': oldNestSettled + totalSettledThisTime,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastActivity': FieldValue.serverTimestamp(),
      });

      // Recalculate Cycle stats and update active Cycle document
      String? cycleId = nestData['currentCycleId'] as String?;
      if (cycleId != null) {
        final cycleDocRef = nestRef.collection('Cycle').doc(cycleId);
        final cycleSnap = await transaction.get(cycleDocRef);
        if (cycleSnap.exists) {
          final cycleData = cycleSnap.data()!;
          final double oldCycleExpenses = (cycleData['totalExpenses'] as num?)?.toDouble() ?? 0.0;
          final double oldCycleSettled = (cycleData['totalSettled'] as num?)?.toDouble() ?? 0.0;
          final double newCycleSettled = oldCycleSettled + totalSettledThisTime;
          final double newCyclePending = oldCycleExpenses - newCycleSettled;
          final double newCyclePct = oldCycleExpenses > 0 ? (newCycleSettled / oldCycleExpenses).clamp(0.0, 1.0) : 1.0;

          transaction.update(cycleDocRef, {
            'totalSettled': newCycleSettled,
            'totalPending': newCyclePending < 0.01 ? 0.0 : newCyclePending,
            'settledPercentage': newCyclePct,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // Log Personal Ledger transactions for debtor and creditor
      final double txAmount = totalSettledThisTime;
      
      // Debtor (Payer) ledger transaction: borrow reduction (negative amount)
      final debtorTxRef = _firestore.collection('users').doc(resolvedDebtorId).collection('ledger').doc('transactions').collection('transactions').doc();
      transaction.set(debtorTxRef, {
        'transactionId': debtorTxRef.id,
        'userId': resolvedDebtorId,
        'title': 'Repayment to $creditorName',
        'description': 'Repaid debt inside Nest "${nestData['name']}"',
        'amount': -txAmount,
        'type': 'borrow',
        'categoryId': 'repayment',
        'categoryName': 'Repayment',
        'paymentMethod': 'transfer',
        'date': Timestamp.now(),
        'personName': creditorName,
        'personUserId': resolvedCreditorId,
        'status': 'completed',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Creditor (Receiver) ledger transaction: lend reduction (negative amount)
      final creditorTxRef = _firestore.collection('users').doc(resolvedCreditorId).collection('ledger').doc('transactions').collection('transactions').doc();
      transaction.set(creditorTxRef, {
        'transactionId': creditorTxRef.id,
        'userId': resolvedCreditorId,
        'title': 'Repayment from $debtorName',
        'description': 'Received repayment inside Nest "${nestData['name']}"',
        'amount': -txAmount,
        'type': 'lend',
        'categoryId': 'repayment',
        'categoryName': 'Repayment',
        'paymentMethod': 'transfer',
        'date': Timestamp.now(),
        'personName': debtorName,
        'personUserId': resolvedDebtorId,
        'status': 'completed',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Recalculate Ledger Summary for Debtor
      double debtorIncome = 0.0;
      double debtorExpense = 0.0;
      double debtorLend = 0.0;
      double debtorBorrow = 0.0;
      for (final doc in debtorTxsSnap.docs) {
        final data = doc.data();
        final amt = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final type = (data['type'] as String? ?? '').toLowerCase();
        if (type == 'income') debtorIncome += amt;
        else if (type == 'expense') debtorExpense += amt;
        else if (type == 'lend') debtorLend += amt;
        else if (type == 'borrow') debtorBorrow += amt;
      }
      // Add the new transaction in recalculation (since FieldValue.serverTimestamp / batch set isn't in query results yet)
      debtorBorrow += -txAmount; 
      
      transaction.set(_firestore.collection('users').doc(resolvedDebtorId).collection('ledger').doc('summary'), {
        'totalIncome': debtorIncome,
        'totalExpense': debtorExpense,
        'totalLend': debtorLend,
        'totalBorrow': debtorBorrow,
        'netBalance': debtorIncome - debtorExpense + debtorLend - debtorBorrow,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Recalculate Ledger Summary for Creditor
      double creditorIncome = 0.0;
      double creditorExpense = 0.0;
      double creditorLend = 0.0;
      double creditorBorrow = 0.0;
      for (final doc in creditorTxsSnap.docs) {
        final data = doc.data();
        final amt = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final type = (data['type'] as String? ?? '').toLowerCase();
        if (type == 'income') creditorIncome += amt;
        else if (type == 'expense') creditorExpense += amt;
        else if (type == 'lend') creditorLend += amt;
        else if (type == 'borrow') creditorBorrow += amt;
      }
      // Add the new transaction in recalculation
      creditorLend += -txAmount;

      transaction.set(_firestore.collection('users').doc(resolvedCreditorId).collection('ledger').doc('summary'), {
        'totalIncome': creditorIncome,
        'totalExpense': creditorExpense,
        'totalLend': creditorLend,
        'totalBorrow': creditorBorrow,
        'netBalance': creditorIncome - creditorExpense + creditorLend - creditorBorrow,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log notifications to both users' notifications collection
      final debtorNotifRef = _firestore.collection('users').doc(resolvedDebtorId).collection('notifications').doc();
      transaction.set(debtorNotifRef, {
        'id': debtorNotifRef.id,
        'title': 'Settlement Paid',
        'description': 'You settled ₹${txAmount.toStringAsFixed(0)} with $creditorName.',
        'type': 'settlement_paid',
        'groupId': groupId,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      final creditorNotifRef = _firestore.collection('users').doc(resolvedCreditorId).collection('notifications').doc();
      transaction.set(creditorNotifRef, {
        'id': creditorNotifRef.id,
        'title': 'Settlement Received',
        'description': '$debtorName settled ₹${txAmount.toStringAsFixed(0)} with you.',
        'type': 'settlement_received',
        'groupId': groupId,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // Chat system message
      SystemMessageService.writeInTransaction(
        transaction: transaction,
        nestId: groupId,
        messageText: SystemMessageService.settlementCompleted(
          fromName: debtorName,
          toName: creditorName,
          amount: txAmount,
        ),
      );
    });
  }
}
