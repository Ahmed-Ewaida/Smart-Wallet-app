import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/transaction_category.dart';
import '../models/wallet_transaction.dart';

const String storageKey = 'smart_wallet_transactions_v1';
const String debtStorageKey = 'smart_wallet_total_debt';

class WalletController extends ChangeNotifier {
  List<WalletTransaction> _transactions = <WalletTransaction>[];
  double _totalDebt = 0;
  bool _isLoading = true;

  List<WalletTransaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  double get totalDebt => _totalDebt;

  double get balance {
    return _transactions.fold<double>(
      0,
      (double sum, WalletTransaction t) =>
          sum + (t.isIncome ? t.amount : -t.amount),
    );
  }

  /// Balance minus debts (available after bills/debts).
  double get availableBalance => balance - _totalDebt;

  /// Total of expenses in Bills category.
  double get billsTotal =>
      _transactions
          .where((WalletTransaction t) =>
              !t.isIncome && t.category == TransactionCategory.bills)
          .fold<double>(0, (double sum, WalletTransaction t) => sum + t.amount);

  /// Transactions that are bills (expense, category Bills).
  List<WalletTransaction> get billsTransactions =>
      _transactions
          .where((WalletTransaction t) =>
              !t.isIncome && t.category == TransactionCategory.bills)
          .toList();

  /// Total income across all transactions.
  double get totalIncome =>
      _transactions.where((WalletTransaction t) => t.isIncome).fold<double>(
            0,
            (double sum, WalletTransaction t) => sum + t.amount,
          );

  /// Total expenses across all transactions.
  double get totalExpense =>
      _transactions.where((WalletTransaction t) => !t.isIncome).fold<double>(
            0,
            (double sum, WalletTransaction t) => sum + t.amount,
          );

  /// Amount per category for expenses (explains where money goes).
  Map<TransactionCategory, double> get expenseByCategory {
    final Map<TransactionCategory, double> map =
        <TransactionCategory, double>{};
    for (final WalletTransaction t in _transactions) {
      if (!t.isIncome) {
        final TransactionCategory cat =
            t.category ?? TransactionCategory.otherExpense;
        map[cat] = (map[cat] ?? 0) + t.amount;
      }
    }
    return map;
  }

  /// Amount per category for income (explains where money comes from).
  Map<TransactionCategory, double> get incomeByCategory {
    final Map<TransactionCategory, double> map =
        <TransactionCategory, double>{};
    for (final WalletTransaction t in _transactions) {
      if (t.isIncome) {
        final TransactionCategory cat =
            t.category ?? TransactionCategory.otherIncome;
        map[cat] = (map[cat] ?? 0) + t.amount;
      }
    }
    return map;
  }

  Future<void> loadTransactions() async {
    _isLoading = true;
    notifyListeners();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(storageKey);
    _totalDebt = (prefs.getDouble(debtStorageKey)) ?? 0;

    if (raw == null) {
      _transactions = <WalletTransaction>[];
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final List<dynamic> decoded = json.decode(raw) as List<dynamic>;
      _transactions = decoded
          .map(
            (dynamic e) =>
                WalletTransaction.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      _transactions = <WalletTransaction>[];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setTotalDebt(double value) async {
    _totalDebt = value < 0 ? 0 : value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(debtStorageKey, _totalDebt);
    notifyListeners();
  }

  Future<void> _saveTransactions() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String raw = json.encode(
      _transactions.map((WalletTransaction t) => t.toJson()).toList(),
    );
    await prefs.setString(storageKey, raw);
  }

  Future<void> addTransaction({
    required double amount,
    required bool isIncome,
    String? note,
    TransactionCategory? category,
  }) async {
    TransactionCategory resolvedCategory = category ??
        (isIncome ? TransactionCategory.otherIncome : TransactionCategory.otherExpense);
    // Ensure category type matches transaction type (fix mismatch e.g. expense with income category)
    if (resolvedCategory.isIncome != isIncome) {
      resolvedCategory = isIncome
          ? TransactionCategory.otherIncome
          : TransactionCategory.otherExpense;
    }
    final WalletTransaction tx = WalletTransaction(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      amount: amount,
      note: (note ?? '').trim(),
      date: DateTime.now(),
      isIncome: isIncome,
      category: resolvedCategory,
    );

    _transactions = <WalletTransaction>[tx, ..._transactions];
    notifyListeners();
    await _saveTransactions();
  }

  Future<void> deleteTransaction(String id) async {
    _transactions =
        _transactions.where((WalletTransaction t) => t.id != id).toList();
    notifyListeners();
    await _saveTransactions();
  }
}

