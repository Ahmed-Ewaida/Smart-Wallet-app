import 'package:flutter/material.dart';

/// Categories explain what each amount of money is:
/// - Income: source of money (e.g. this amount is Salary, Gift, Business).
/// - Expense: where money went (e.g. spent on Food, Transport, Bills).
enum TransactionCategory {
  // Income — source of money (this amount is from...)
  salary('Salary', Icons.work, true),
  business('Business', Icons.store, true),
  investment('Investment', Icons.trending_up, true),
  gift('Gift', Icons.card_giftcard, true),
  otherIncome('Other', Icons.more_horiz, true),

  // Expense — use of money (this amount went to...)
  food('Food', Icons.restaurant, false),
  transport('Transport', Icons.directions_car, false),
  shopping('Shopping', Icons.shopping_bag, false),
  bills('Bills', Icons.receipt_long, false),
  entertainment('Entertainment', Icons.movie, false),
  health('Health', Icons.medical_services, false),
  education('Education', Icons.school, false),
  otherExpense('Other', Icons.more_horiz, false);

  const TransactionCategory(this.label, this.icon, this.isIncome);

  final String label;
  final IconData icon;
  final bool isIncome;

  static List<TransactionCategory> forType(bool isIncome) {
    return values.where((TransactionCategory c) => c.isIncome == isIncome).toList();
  }

  static TransactionCategory fromString(String? value) {
    if (value == null || value.isEmpty) {
      return otherExpense;
    }
    return TransactionCategory.values.firstWhere(
      (TransactionCategory c) => c.name == value,
      orElse: () => otherExpense,
    );
  }
}
