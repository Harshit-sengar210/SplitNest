import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:splitnest/features/groups/domain/calculators/cycle_calculator.dart';
import 'package:splitnest/features/chat/data/services/system_message_service.dart';

class MembersService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> streamMembers(String nestId) {
    return _firestore
        .collection('nests')
        .doc(nestId)
        .collection('members')
        .snapshots();
  }

  /// Returns a new auto-ID doc ref for the timeline sub-collection.
  DocumentReference<Map<String, dynamic>> _newTimelineRef(String nestId) =>
      _firestore
          .collection('nests')
          .doc(nestId)
          .collection('timeline')
          .doc();

  Future<void> addMember(
    String nestId,
    String memberId,
    Map<String, dynamic> memberData,
  ) async {
    final nestRef = _firestore.collection('nests').doc(nestId);
    final memberRef = nestRef.collection('members').doc(memberId);
    final timelineRef = _newTimelineRef(nestId);

    final memberName =
        memberData['fullName'] ?? memberData['name'] ?? 'Someone';

    // 1. READS OUTSIDE TRANSACTION:
    final nestDoc = await nestRef.get();
    if (!nestDoc.exists) throw Exception('Nest not found');

    final data = nestDoc.data()!;
    final List<String> memberIds =
        List<String>.from(data['memberIds'] ?? []);
    if (!memberIds.contains(memberId)) {
      memberIds.add(memberId);
    }

    final cycleDay = data['settlementCycleDate'] as int? ?? 1;
    final DateTime? customStart = data['customStartDate'] != null 
        ? (data['customStartDate'] as Timestamp).toDate() 
        : null;
    final DateTime? customEnd = data['customEndDate'] != null 
        ? (data['customEndDate'] as Timestamp).toDate() 
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

    await _firestore.runTransaction((transaction) async {
      // 2. READS INSIDE TRANSACTION:
      final nestDocTx = await transaction.get(nestRef);
      if (!nestDocTx.exists) throw Exception('Nest not found');

      final dataTx = nestDocTx.data()!;
      String? cycleId = dataTx['currentCycleId'] as String?;
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
      final List<Map<String, dynamic>> allSettlements = settlementsSnap.docs.map((d) => d.data()).toList();
      final memberCount = memberIds.length;

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
        transaction.update(nestRef, {
          'memberIds': memberIds,
          'memberCount': memberIds.length,
          'currentCycleId': cycleId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        transaction.update(nestRef, {
          'memberIds': memberIds,
          'memberCount': memberIds.length,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      transaction.set(memberRef, memberData);

      // ── Timeline event ──────────────────────────────────────────────────────
      transaction.set(timelineRef, {
        'type': 'member_joined',
        'title': 'Member Joined',
        'description': '$memberName joined the nest',
        'amount': null,
        'userId': memberId,
        'userName': memberName,
        'expenseId': null,
        'settlementId': null,
        'memberId': memberId,
        'icon': 'person_add',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ── System chat message ─────────────────────────────────────────────────
      SystemMessageService.writeInTransaction(
        transaction: transaction,
        nestId: nestId,
        messageText: SystemMessageService.memberJoined(memberName),
      );

      transaction.set(nestRef.collection('Cycle').doc(cycleId), cycleData, SetOptions(merge: true));
    });
  }

  Future<void> updateMemberRole(
      String nestId, String memberId, String role) async {
    await _firestore
        .collection('nests')
        .doc(nestId)
        .collection('members')
        .doc(memberId)
        .update({'role': role});
  }

  Future<void> removeMember(
    String nestId,
    String memberId, {
    String? memberName,
  }) async {
    final nestRef = _firestore.collection('nests').doc(nestId);
    final memberRef = nestRef.collection('members').doc(memberId);
    final timelineRef = _newTimelineRef(nestId);

    // Resolve name if not provided
    String resolvedName = memberName ?? 'Someone';
    if (memberName == null) {
      final snap = await memberRef.get();
      if (snap.exists) {
        resolvedName =
            snap.data()?['fullName'] ?? snap.data()?['name'] ?? 'Someone';
      }
    }

    // 1. READS OUTSIDE TRANSACTION:
    final nestDoc = await nestRef.get();
    if (!nestDoc.exists) throw Exception('Nest not found');

    final data = nestDoc.data()!;
    final List<String> memberIds =
        List<String>.from(data['memberIds'] ?? []);
    memberIds.remove(memberId);

    final cycleDay = data['settlementCycleDate'] as int? ?? 1;
    final DateTime? customStart = data['customStartDate'] != null 
        ? (data['customStartDate'] as Timestamp).toDate() 
        : null;
    final DateTime? customEnd = data['customEndDate'] != null 
        ? (data['customEndDate'] as Timestamp).toDate() 
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

    await _firestore.runTransaction((transaction) async {
      // 2. READS INSIDE TRANSACTION:
      final nestDocTx = await transaction.get(nestRef);
      if (!nestDocTx.exists) throw Exception('Nest not found');

      final dataTx = nestDocTx.data()!;
      String? cycleId = dataTx['currentCycleId'] as String?;
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
      final List<Map<String, dynamic>> allSettlements = settlementsSnap.docs.map((d) => d.data()).toList();
      final memberCount = memberIds.length;

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
        transaction.update(nestRef, {
          'memberIds': memberIds,
          'memberCount': memberIds.length,
          'currentCycleId': cycleId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        transaction.update(nestRef, {
          'memberIds': memberIds,
          'memberCount': memberIds.length,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      transaction.delete(memberRef);

      // ── Timeline event ──────────────────────────────────────────────────────
      transaction.set(timelineRef, {
        'type': 'member_left',
        'title': 'Member Left',
        'description': '$resolvedName left the nest',
        'amount': null,
        'userId': memberId,
        'userName': resolvedName,
        'expenseId': null,
        'settlementId': null,
        'memberId': memberId,
        'icon': 'person_remove',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ── System chat message ─────────────────────────────────────────────────
      SystemMessageService.writeInTransaction(
        transaction: transaction,
        nestId: nestId,
        messageText: SystemMessageService.memberLeft(resolvedName),
      );

      transaction.set(nestRef.collection('Cycle').doc(cycleId), cycleData, SetOptions(merge: true));
    });
  }
}
