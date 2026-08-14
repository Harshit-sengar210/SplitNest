import 'package:cloud_firestore/cloud_firestore.dart';

class LedgerTransaction {
  final String transactionId;
  final String userId;
  final String title;
  final String description;
  final double amount;
  final String type; // 'expense', 'income', 'lend', 'borrow'
  final String categoryId;
  final String categoryName;
  final String paymentMethod;
  final DateTime date;
  final String? attachmentUrl;
  final String? personName;
  final String? personUserId;
  final String status; // 'pending', 'completed'
  final DateTime createdAt;
  final DateTime updatedAt;
  final String source; // 'personal' or 'group'

  const LedgerTransaction({
    required this.transactionId,
    required this.userId,
    required this.title,
    required this.description,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.categoryName,
    required this.paymentMethod,
    required this.date,
    this.attachmentUrl,
    this.personName,
    this.personUserId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.source = 'personal',
  });

  LedgerTransaction copyWith({
    String? transactionId,
    String? userId,
    String? title,
    String? description,
    double? amount,
    String? type,
    String? categoryId,
    String? categoryName,
    String? paymentMethod,
    DateTime? date,
    String? attachmentUrl,
    String? personName,
    String? personUserId,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? source,
  }) {
    return LedgerTransaction(
      transactionId: transactionId ?? this.transactionId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      date: date ?? this.date,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      personName: personName ?? this.personName,
      personUserId: personUserId ?? this.personUserId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      source: source ?? this.source,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'transactionId': transactionId,
      'userId': userId,
      'title': title,
      'description': description,
      'amount': amount,
      'type': type,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'paymentMethod': paymentMethod,
      'date': Timestamp.fromDate(date),
      'attachmentUrl': attachmentUrl,
      'personName': personName,
      'personUserId': personUserId,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'source': source,
    };
  }

  factory LedgerTransaction.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is Timestamp) return val.toDate();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is String) {
        final p = DateTime.tryParse(val);
        if (p != null) return p;
      }
      return DateTime.now();
    }

    return LedgerTransaction(
      transactionId: docId ?? map['transactionId'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      type: map['type'] ?? 'expense',
      categoryId: map['categoryId'] ?? '',
      categoryName: map['categoryName'] ?? '',
      paymentMethod: map['paymentMethod'] ?? '',
      date: parseDate(map['date']),
      attachmentUrl: map['attachmentUrl'],
      personName: map['personName'],
      personUserId: map['personUserId'],
      status: map['status'] ?? 'pending',
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
      source: map['source'] ?? 'group',
    );
  }
}
