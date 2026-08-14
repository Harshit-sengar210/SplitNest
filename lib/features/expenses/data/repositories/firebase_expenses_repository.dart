import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/expense.dart';
import '../../domain/repositories/expenses_repository.dart';
import '../services/expenses_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/split_model.dart';
import '../../domain/calculators/split_calculator.dart';
import '../../../activity/data/services/notification_writer.dart';

class FirebaseExpensesRepository implements ExpensesRepository {
  final ExpensesService _service;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FirebaseExpensesRepository(this._service);

  @override
  Future<List<Expense>> getExpenses(String groupId) async {
    final snapshot = await _service.getExpenses(groupId);
    return snapshot.docs.map((doc) => Expense.fromMap(doc.data(), doc.id)).toList();
  }

  @override
  Future<Expense> getExpenseById(String id) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final groupId = userDoc.data()?['activeNestId'];
    if (groupId == null) throw Exception('No active nest');
    
    final doc = await _service.getExpenseById(groupId, id);
    if (!doc.exists) throw Exception('Expense not found');
    return Expense.fromMap(doc.data()!, doc.id);
  }

  @override
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
    String? imageUrl,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    final docRef = FirebaseFirestore.instance.collection('nests').doc(groupId).collection('expenses').doc();
    final expenseId = docRef.id;

    // Resolve paidByName if not provided
    String resolvedPaidByName = paidByName ?? '';
    if (resolvedPaidByName.isEmpty) {
      final actualPaidBy = paidByUserId == 'user_me' ? currentUser.uid : paidByUserId;
      final memberDoc = await FirebaseFirestore.instance
          .collection('nests')
          .doc(groupId)
          .collection('members')
          .doc(actualPaidBy)
          .get();
      if (memberDoc.exists) {
        resolvedPaidByName = memberDoc.data()?['fullName'] ?? memberDoc.data()?['name'] ?? '';
      }
      if (resolvedPaidByName.isEmpty) {
        resolvedPaidByName = currentUser.displayName ?? currentUser.email?.split('@').first ?? 'Someone';
      }
    }

    // Helper to resolve a member's name
    Future<String> resolveMemberName(String id) async {
      if (id == 'user_me' || id == currentUser.uid) {
        return currentUser.displayName ?? currentUser.email?.split('@').first ?? 'You';
      }
      final memberDoc = await FirebaseFirestore.instance
          .collection('nests')
          .doc(groupId)
          .collection('members')
          .doc(id)
          .get();
      if (memberDoc.exists) {
        return memberDoc.data()?['fullName'] ?? memberDoc.data()?['name'] ?? '';
      }
      return 'Member';
    }

    // Generate SplitModels using SplitCalculator
    final List<SplitModel> splitModels = [];
    if (splitMethod == 'Equal') {
      final List<({String id, String name})> selectedMembers = [];
      for (final split in splits) {
        final mId = split.userId == 'user_me' ? currentUser.uid : split.userId;
        final mName = split.memberName != 'Someone' && split.memberName.isNotEmpty ? split.memberName : await resolveMemberName(mId);
        selectedMembers.add((id: mId, name: mName));
      }
      splitModels.addAll(
        SplitCalculator.calculateEqual(
          totalAmount: amount,
          selectedMembers: selectedMembers,
        ),
      );
    } else if (splitMethod == 'Percentage' || splitMethod == 'Percentage Split') {
      final List<({String id, String name, double percentage})> memberPercentages = [];
      for (final split in splits) {
        final mId = split.userId == 'user_me' ? currentUser.uid : split.userId;
        final mName = split.memberName != 'Someone' && split.memberName.isNotEmpty ? split.memberName : await resolveMemberName(mId);
        final double pct = split.percentage ?? (amount > 0 ? (split.amount / amount) * 100.0 : 0.0);
        memberPercentages.add((id: mId, name: mName, percentage: pct));
      }
      splitModels.addAll(
        SplitCalculator.calculatePercentage(
          totalAmount: amount,
          memberPercentages: memberPercentages,
        ),
      );
    } else if (splitMethod == 'Shares' || splitMethod == 'Share Split') {
      final List<({String id, String name, double shares})> memberShares = [];
      for (final split in splits) {
        final mId = split.userId == 'user_me' ? currentUser.uid : split.userId;
        final mName = split.memberName != 'Someone' && split.memberName.isNotEmpty ? split.memberName : await resolveMemberName(mId);
        final double sh = split.shares ?? 1.0;
        memberShares.add((id: mId, name: mName, shares: sh));
      }
      splitModels.addAll(
        SplitCalculator.calculateShares(
          totalAmount: amount,
          memberShares: memberShares,
        ),
      );
    } else {
      // Exact Amount
      final List<({String id, String name, double amount})> memberAmounts = [];
      for (final split in splits) {
        final mId = split.userId == 'user_me' ? currentUser.uid : split.userId;
        final mName = split.memberName != 'Someone' && split.memberName.isNotEmpty ? split.memberName : await resolveMemberName(mId);
        memberAmounts.add((id: mId, name: mName, amount: split.amount));
      }
      splitModels.addAll(
        SplitCalculator.calculateExact(
          totalAmount: amount,
          memberAmounts: memberAmounts,
        ),
      );
    }

    final splitsData = splitModels.map((s) => s.toMap()).toList();

    final data = {
      'expenseId': expenseId,
      'title': title,
      'amount': amount,
      'category': category,
      'description': description,
      'paidBy': paidByUserId == 'user_me' ? currentUser.uid : paidByUserId,
      'paidByName': resolvedPaidByName,
      'splitType': splitMethod,
      'currency': currency ?? 'INR',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': currentUser.uid,
      'imageUrl': imageUrl,
      'splits': splits.map((x) {
        final m = x.toMap();
        if (m['memberId'] == 'user_me') m['memberId'] = currentUser.uid;
        if (m['userId'] == 'user_me') m['userId'] = currentUser.uid;
        if (m['paidBy'] == 'user_me') m['paidBy'] = currentUser.uid;
        
        final actualPaidBy = paidByUserId == 'user_me' ? currentUser.uid : paidByUserId;
        final isSelfShare = m['memberId'] == actualPaidBy;
        
        m['settledAmount'] = isSelfShare ? m['amount'] : 0.0;
        m['pendingAmount'] = isSelfShare ? 0.0 : m['amount'];
        m['status'] = isSelfShare ? 'completed' : 'pending';
        
        return m;
      }).toList(),
      // Backward compatibility fields
      'id': expenseId,
      'groupId': groupId,
      'paidByUserId': paidByUserId == 'user_me' ? currentUser.uid : paidByUserId,
      'date': DateTime.now().millisecondsSinceEpoch,
      'splitMethod': splitMethod,
    };

    await _service.createExpense(
      nestId: groupId,
      expenseId: expenseId,
      expenseData: data,
      amount: amount,
      splitsData: splitsData,
      actorUserId: currentUser.uid,
      actorUserName: resolvedPaidByName,
      expenseTitle: title,
    );

    NotificationWriter.sendToGroup(
      groupId: groupId,
      title: 'New Expense Added',
      description: '$resolvedPaidByName added a new expense: $title',
      type: 'expense_added',
      relatedItemId: expenseId,
    );

    return Expense(
      id: expenseId,
      title: title,
      amount: amount,
      category: category,
      groupId: groupId,
      paidByUserId: paidByUserId == 'user_me' ? currentUser.uid : paidByUserId,
      paidByName: resolvedPaidByName,
      splits: splits,
      date: DateTime.now(),
      splitMethod: splitMethod,
      description: description,
      currency: currency ?? 'INR',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: currentUser.uid,
      imageUrl: imageUrl,
    );
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final oldDoc = await _service.getExpenseById(expense.groupId, expense.id);
    if (!oldDoc.exists) throw Exception('Expense not found');
    final oldExpense = Expense.fromMap(oldDoc.data()!, oldDoc.id);

    final data = expense.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    
    // Sanitize user_me
    if (data['paidBy'] == 'user_me') data['paidBy'] = user.uid;
    if (data['paidByUserId'] == 'user_me') data['paidByUserId'] = user.uid;
    data['splits'] = expense.splits.map((x) {
      final m = x.toMap();
      if (m['memberId'] == 'user_me') m['memberId'] = user.uid;
      if (m['userId'] == 'user_me') m['userId'] = user.uid;
      if (m['paidBy'] == 'user_me') m['paidBy'] = user.uid;
      return m;
    }).toList();

    // Helper to resolve a member's name
    Future<String> resolveMemberName(String id) async {
      if (id == 'user_me' || id == user.uid) {
        return user.displayName ?? user.email?.split('@').first ?? 'You';
      }
      final memberDoc = await FirebaseFirestore.instance
          .collection('nests')
          .doc(expense.groupId)
          .collection('members')
          .doc(id)
          .get();
      if (memberDoc.exists) {
        return memberDoc.data()?['fullName'] ?? memberDoc.data()?['name'] ?? '';
      }
      return 'Member';
    }

    final List<Map<String, dynamic>> splitsData = [];
    for (final split in expense.splits) {
      final mId = split.userId == 'user_me' ? user.uid : split.userId;
      final mName = split.memberName != 'Someone' && split.memberName.isNotEmpty ? split.memberName : await resolveMemberName(mId);
      splitsData.add({
        'memberId': mId,
        'memberName': mName,
        'amount': split.amount,
        'percentage': split.percentage ?? 0.0,
        'shares': split.shares ?? 0.0,
        'status': split.status,
        'createdAt': FieldValue.serverTimestamp(),
        'isSettled': split.isSettled,
        if (split.settledAt != null) 'settledAt': Timestamp.fromDate(split.settledAt!),
      });
    }

    await _service.updateExpense(
      nestId: expense.groupId,
      expenseId: expense.id,
      expenseData: data,
      oldAmount: oldExpense.amount,
      newAmount: expense.amount,
      splitsData: splitsData,
      actorUserId: user.uid,
      actorUserName: user.displayName ?? user.email?.split('@').first ?? 'Someone',
      expenseTitle: expense.title,
    );

    NotificationWriter.sendToGroup(
      groupId: expense.groupId,
      title: 'Expense Updated',
      description: '${user.displayName ?? "Someone"} updated the expense: ${expense.title}',
      type: 'expense_updated',
      relatedItemId: expense.id,
    );
  }

  @override
  Future<void> deleteExpense(String id) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final groupId = userDoc.data()?['activeNestId'];
    if (groupId == null) throw Exception('No active nest');

    final doc = await _service.getExpenseById(groupId, id);
    if (!doc.exists) return;
    
    final oldExpense = Expense.fromMap(doc.data()!, doc.id);

    await _service.deleteExpense(
      nestId: groupId,
      expenseId: id,
      amount: oldExpense.amount,
      actorUserId: user.uid,
      actorUserName: user.displayName ?? user.email?.split('@').first ?? 'Someone',
      expenseTitle: oldExpense.title,
    );

    NotificationWriter.sendToGroup(
      groupId: groupId,
      title: 'Expense Deleted',
      description: '${user.displayName ?? "Someone"} deleted the expense: ${oldExpense.title}',
      type: 'expense_deleted',
      relatedItemId: id,
    );
  }

  @override
  Stream<List<Expense>> streamExpenses(String groupId) {
    return _service.streamExpenses(groupId).map((snapshot) {
      return snapshot.docs.map((doc) => Expense.fromMap(doc.data(), doc.id)).toList();
    });
  }

  @override
  Stream<Expense> streamExpenseById(String groupId, String expenseId) {
    return _service.streamExpenseById(groupId, expenseId).map((doc) {
      if (!doc.exists) throw Exception('Expense not found');
      return Expense.fromMap(doc.data()!, doc.id);
    });
  }
}
