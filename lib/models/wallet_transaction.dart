import 'transaction_category.dart';

class WalletTransaction {
  WalletTransaction({
    required this.id,
    required this.amount,
    required this.note,
    required this.date,
    required this.isIncome,
    this.category,
  });

  final String id;
  final double amount;
  final String note;
  final DateTime date;
  final bool isIncome;
  final TransactionCategory? category;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'amount': amount,
        'note': note,
        'date': date.toIso8601String(),
        'isIncome': isIncome,
        'category': category?.name,
      };

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      note: (json['note'] as String?) ?? '',
      date: DateTime.parse(json['date'] as String),
      isIncome: json['isIncome'] as bool,
      category: json['category'] != null
          ? TransactionCategory.fromString(json['category'] as String?)
          : null,
    );
  }
}

