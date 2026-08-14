import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseSplit {
  final String splitId;
  final String userId; // memberId
  final String memberName;
  final String paidBy;
  final String paidByName;
  final double originalShare;
  final double settledAmount;
  final double pendingAmount;
  final double amount; // backward compatibility
  final bool isSettled; // backward compatibility
  final String status; // 'pending', 'completed'
  final DateTime? settledAt;
  final DateTime? updatedAt;
  final double? percentage;
  final double? shares;

  const ExpenseSplit({
    this.splitId = '',
    required this.userId,
    this.memberName = 'Someone',
    this.paidBy = '',
    this.paidByName = 'Someone',
    double? originalShare,
    double? settledAmount,
    double? pendingAmount,
    required this.amount,
    this.isSettled = false,
    this.status = 'pending',
    this.settledAt,
    this.updatedAt,
    this.percentage,
    this.shares,
  }) : originalShare = originalShare ?? amount,
       settledAmount = settledAmount ?? 0.0,
       pendingAmount = pendingAmount ?? amount;

  ExpenseSplit copyWith({
    String? splitId,
    String? userId,
    String? memberName,
    String? paidBy,
    String? paidByName,
    double? originalShare,
    double? settledAmount,
    double? pendingAmount,
    double? amount,
    bool? isSettled,
    String? status,
    DateTime? settledAt,
    DateTime? updatedAt,
    double? percentage,
    double? shares,
  }) {
    return ExpenseSplit(
      splitId: splitId ?? this.splitId,
      userId: userId ?? this.userId,
      memberName: memberName ?? this.memberName,
      paidBy: paidBy ?? this.paidBy,
      paidByName: paidByName ?? this.paidByName,
      originalShare: originalShare ?? this.originalShare,
      settledAmount: settledAmount ?? this.settledAmount,
      pendingAmount: pendingAmount ?? this.pendingAmount,
      amount: amount ?? this.amount,
      isSettled: isSettled ?? this.isSettled,
      status: status ?? this.status,
      settledAt: settledAt ?? this.settledAt,
      updatedAt: updatedAt ?? this.updatedAt,
      percentage: percentage ?? this.percentage,
      shares: shares ?? this.shares,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'splitId': splitId,
      'memberId': userId, // DB maps memberId to userId in models
      'userId': userId,
      'memberName': memberName,
      'paidBy': paidBy,
      'paidByName': paidByName,
      'originalShare': originalShare,
      'settledAmount': settledAmount,
      'pendingAmount': pendingAmount,
      'amount': amount,
      'isSettled': isSettled,
      'status': status,
      if (settledAt != null) 'settledAt': Timestamp.fromDate(settledAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (percentage != null) 'percentage': percentage,
      if (shares != null) 'shares': shares,
    };
  }

  factory ExpenseSplit.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final amt = (map['amount'] as num?)?.toDouble() ?? 0.0;
    return ExpenseSplit(
      splitId: map['splitId'] ?? '',
      userId: map['memberId'] ?? map['userId'] ?? '',
      memberName: map['memberName'] ?? 'Someone',
      paidBy: map['paidBy'] ?? '',
      paidByName: map['paidByName'] ?? 'Someone',
      originalShare: (map['originalShare'] as num?)?.toDouble() ?? amt,
      settledAmount: (map['settledAmount'] as num?)?.toDouble() ?? 0.0,
      pendingAmount: (map['pendingAmount'] as num?)?.toDouble() ?? amt,
      amount: amt,
      isSettled: map['isSettled'] ?? false,
      status: map['status'] ?? 'pending',
      settledAt: parseDate(map['settledAt']),
      updatedAt: parseDate(map['updatedAt']),
      percentage: (map['percentage'] as num?)?.toDouble(),
      shares: (map['shares'] as num?)?.toDouble(),
    );
  }
}

class Expense {
  final String id;
  final String title;
  final double amount;
  final String category;
  final String groupId;
  final String paidByUserId; // Maps to paidBy in Firestore
  final String paidByName;
  final List<ExpenseSplit> splits;
  final DateTime date; // Maps to createdAt
  final String splitMethod; // Maps to splitType
  final String? description;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String? imageUrl;

  const Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.groupId,
    required this.paidByUserId,
    this.paidByName = 'Someone',
    required this.splits,
    required this.date,
    required this.splitMethod,
    this.description,
    this.currency = 'INR',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.createdBy = '',
    this.imageUrl,
  }) : createdAt = createdAt ?? date,
       updatedAt = updatedAt ?? date;

  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    String? groupId,
    String? paidByUserId,
    String? paidByName,
    List<ExpenseSplit>? splits,
    DateTime? date,
    String? splitMethod,
    String? description,
    String? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? imageUrl,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      groupId: groupId ?? this.groupId,
      paidByUserId: paidByUserId ?? this.paidByUserId,
      paidByName: paidByName ?? this.paidByName,
      splits: splits ?? this.splits,
      date: date ?? this.date,
      splitMethod: splitMethod ?? this.splitMethod,
      description: description ?? this.description,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'expenseId': id,
      'title': title,
      'amount': amount,
      'category': category,
      'description': description,
      'paidBy': paidByUserId,
      'paidByName': paidByName,
      'splitType': splitMethod,
      'currency': currency,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'imageUrl': imageUrl,
      'splits': splits.map((x) => x.toMap()).toList(),
      // Backward compatibility fields
      'id': id,
      'groupId': groupId,
      'paidByUserId': paidByUserId,
      'date': date.millisecondsSinceEpoch,
      'splitMethod': splitMethod,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map, [String? docId]) {
    final resolvedId = docId ?? map['expenseId'] ?? map['id'] ?? '';
    
    DateTime resolveDateTime(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is Timestamp) return val.toDate();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is String) {
        final parsed = DateTime.tryParse(val);
        if (parsed != null) return parsed;
      }
      return DateTime.now();
    }

    final cDate = resolveDateTime(map['createdAt'] ?? map['date']);
    final uDate = resolveDateTime(map['updatedAt'] ?? map['date']);
    final dDate = resolveDateTime(map['date'] ?? map['createdAt']);

    return Expense(
      id: resolvedId,
      title: map['title'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] ?? 'Other',
      groupId: map['groupId'] ?? '',
      paidByUserId: map['paidBy'] ?? map['paidByUserId'] ?? '',
      paidByName: map['paidByName'] ?? 'Someone',
      splits: List<ExpenseSplit>.from(
        (map['splits'] as List<dynamic>? ?? []).map<ExpenseSplit>(
          (x) => ExpenseSplit.fromMap(x as Map<String, dynamic>),
        ),
      ),
      date: dDate,
      splitMethod: map['splitType'] ?? map['splitMethod'] ?? 'Equal',
      description: map['description'],
      currency: map['currency'] ?? 'INR',
      createdAt: cDate,
      updatedAt: uDate,
      createdBy: map['createdBy'] ?? '',
      imageUrl: map['imageUrl'],
    );
  }
}
