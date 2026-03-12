import 'package:flutter/material.dart';
import '../controllers/theme_controller.dart';
import '../controllers/wallet_controller.dart';
import '../models/transaction_category.dart';
import '../models/wallet_transaction.dart';
import '../services/wallet_export_service.dart';

class SmartWalletHomePage extends StatefulWidget {
  const SmartWalletHomePage({super.key, this.themeController});

  final ThemeController? themeController;

  @override
  State<SmartWalletHomePage> createState() => _SmartWalletHomePageState();
}

class _SmartWalletHomePageState extends State<SmartWalletHomePage> {
  late final WalletController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WalletController()
      ..addListener(_onControllerChanged)
      ..loadTransactions();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _addTransactionSheet({required bool isIncome}) async {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController noteController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    TransactionCategory selectedCategory = TransactionCategory.forType(isIncome).first;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        final EdgeInsets viewInsets = MediaQuery.of(ctx).viewInsets;
        final List<TransactionCategory> categories =
            TransactionCategory.forType(isIncome);

        return StatefulBuilder(
          builder: (BuildContext context, void Function(void Function()) setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: viewInsets.bottom + 20,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        isIncome ? 'Add Income' : 'Add Expense',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isIncome
                          ? 'What is this money? (e.g. Salary, Gift)'
                          : 'What did you spend on? (e.g. Food, Transport)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Category',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categories.map((TransactionCategory cat) {
                        final bool selected = cat == selectedCategory;
                        return ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(cat.icon, size: 18, color: selected ? Colors.white : null),
                              const SizedBox(width: 6),
                              Text(cat.label),
                            ],
                          ),
                          selected: selected,
                          onSelected: (bool value) {
                            if (value) {
                              setState(() => selectedCategory = cat);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixText: '\u20B9 ',
                        border: OutlineInputBorder(),
                      ),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an amount';
                        }
                        final double? parsed =
                            double.tryParse(value.replaceAll(',', ''));
                        if (parsed == null || parsed <= 0) {
                          return 'Enter a valid amount greater than 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'Note (optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          final double amount = double.parse(
                            amountController.text.replaceAll(',', ''),
                          );
                          final String note = noteController.text.trim();

                          await _controller.addTransaction(
                            amount: amount,
                            isIncome: isIncome,
                            note: note,
                            category: selectedCategory,
                          );

                          if (context.mounted) {
                            Navigator.of(ctx).pop();
                          }
                        },
                        child: Text(isIncome ? 'Save Income' : 'Save Expense'),
                      ),
                    ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteTransaction(WalletTransaction tx) async {
    await _controller.deleteTransaction(tx.id);
  }

  String _formatDate(DateTime date) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final String day = twoDigits(date.day);
    final String month = twoDigits(date.month);
    final String year = date.year.toString();
    final String hour = twoDigits(date.hour);
    final String minute = twoDigits(date.minute);
    return '$day/$month/$year  $hour:$minute';
  }

  void _showThemeMenu() {
    final ThemeController? tc = widget.themeController;
    if (tc == null) return;
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Theme',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Brightness',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 8),
                SegmentedButton<ThemeMode>(
                  segments: const <ButtonSegment<ThemeMode>>[
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode),
                      label: Text('Light'),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode),
                      label: Text('Dark'),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto),
                      label: Text('System'),
                    ),
                  ],
                  selected: <ThemeMode>{tc.mode},
                  onSelectionChanged: (Set<ThemeMode> selected) {
                    tc.setMode(selected.first);
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'Style',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 8),
                SegmentedButton<AppThemeVariant>(
                  segments: const <ButtonSegment<AppThemeVariant>>[
                    ButtonSegment<AppThemeVariant>(
                      value: AppThemeVariant.defaultTheme,
                      label: Text('Default'),
                    ),
                    ButtonSegment<AppThemeVariant>(
                      value: AppThemeVariant.custom,
                      label: Text('Custom'),
                    ),
                    ButtonSegment<AppThemeVariant>(
                      value: AppThemeVariant.random,
                      label: Text('Random'),
                    ),
                  ],
                  selected: <AppThemeVariant>{tc.variant},
                  onSelectionChanged: (Set<AppThemeVariant> selected) {
                    tc.setVariant(selected.first);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showBillsAndDebtsMenu() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (BuildContext context, ScrollController scrollController) {
            return Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        'Bills and debts',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          FilledButton.icon(
                            onPressed: _controller.transactions.isEmpty
                                ? null
                                : () async {
                                    final String? path =
                                        await WalletExportService.exportToExcel(
                                      _controller.transactions,
                                      totalIncome: _controller.totalIncome,
                                      totalExpense: _controller.totalExpense,
                                      balance: _controller.balance,
                                    );
                                    if (path != null && ctx.mounted) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        const SnackBar(
                                          content: Text('Export shared'),
                                        ),
                                      );
                                    } else if (_controller.transactions.isEmpty && ctx.mounted) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        const SnackBar(
                                          content: Text('No data to export'),
                                        ),
                                      );
                                    }
                                  },
                            icon: const Icon(Icons.table_chart, size: 20),
                            label: const Text('Export Excel'),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            icon: const Icon(Icons.close),
                            tooltip: 'Close',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: <Widget>[
                      _buildDebtsSection(ctx),
                      const SizedBox(height: 20),
                      _buildBillsSection(ctx),
                      const SizedBox(height: 20),
                      _buildAllTransactionsSection(ctx),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDebtsSection(BuildContext sheetContext) {
    final double debt = _controller.totalDebt;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(sheetContext).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Debts (total you owe)',
                style: Theme.of(sheetContext).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '\u20B9 ${debt.toStringAsFixed(2)}',
                style: Theme.of(sheetContext).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: debt > 0 ? Colors.red.shade700 : null,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Set the total amount you owe. This is shown in your current balance as "Available".',
            style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _showSetDebtDialog(sheetContext),
            icon: const Icon(Icons.edit, size: 18),
            label: Text(debt > 0 ? 'Update debt' : 'Add debt'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSetDebtDialog(BuildContext context) async {
    final TextEditingController controller = TextEditingController(
      text: _controller.totalDebt > 0 ? _controller.totalDebt.toStringAsFixed(2) : '',
    );
    await showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Total debt'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount you owe (\u20B9)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final double? value = double.tryParse(
                  controller.text.replaceAll(',', '').trim(),
                );
                await _controller.setTotalDebt(value ?? 0);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBillsSection(BuildContext sheetContext) {
    final List<WalletTransaction> bills = _controller.billsTransactions;
    final double total = _controller.billsTotal;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(sheetContext).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Bills',
                style: Theme.of(sheetContext).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '\u20B9 ${total.toStringAsFixed(2)}',
                style: Theme.of(sheetContext).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Expenses in Bills category. Add expenses and choose "Bills" to track here.',
            style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          if (bills.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'No bills yet',
                style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
            )
          else
            ...bills.map(
              (WalletTransaction tx) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.receipt_long, color: Colors.orange.shade700),
                title: Text(
                  tx.note.isEmpty ? 'Bill' : tx.note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(_formatDate(tx.date), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                trailing: Text(
                  '-\u20B9 ${tx.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAllTransactionsSection(BuildContext sheetContext) {
    if (_controller.transactions.isEmpty) {
      return Text(
        'No transactions yet. Add income or expenses from the home screen.',
        style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'All transactions',
          style: Theme.of(sheetContext).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        ..._controller.transactions.map(
          (WalletTransaction tx) {
            final Color color = tx.isIncome
                ? const Color(0xFF16A34A)
                : const Color(0xFFDC2626);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(sheetContext).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: tx.isIncome
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFFEE2E2),
                    child: Icon(
                      tx.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                      color: color,
                    ),
                  ),
                  title: Text(
                    tx.note.isEmpty
                        ? (tx.category?.label ?? (tx.isIncome ? 'Income' : 'Expense'))
                        : tx.note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    [if (tx.category != null) tx.category!.label, _formatDate(tx.date)].join(' • '),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  trailing: Text(
                    '${tx.isIncome ? '+' : '-'}\u20B9 ${tx.amount.toStringAsFixed(2)}',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Wallet'),
        centerTitle: true,
        actions: <Widget>[
          if (widget.themeController != null)
            IconButton(
              onPressed: _showThemeMenu,
              icon: Icon(
                Theme.of(context).brightness == Brightness.dark
                    ? Icons.dark_mode
                    : Icons.light_mode,
              ),
              tooltip: 'Theme',
            ),
          IconButton(
            onPressed: _showBillsAndDebtsMenu,
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Bills and debts',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              _buildBalanceCard(),
              const SizedBox(height: 12),
              _buildCategoryBreakdown(),
              const SizedBox(height: 16),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _addTransactionSheet(isIncome: false),
                  icon: const Icon(Icons.remove_circle_outline,
                      color: Colors.red),
                  label: const Text('Add Expense'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _addTransactionSheet(isIncome: true),
                  icon:
                      const Icon(Icons.add_circle_outline, color: Colors.white),
                  label: const Text('Add Income'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    final double balance = _controller.balance;
    final double bills = _controller.billsTotal;
    final double debts = _controller.totalDebt;
    final double available = _controller.availableBalance;
    final bool positive = balance >= 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF2563EB), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Current Balance',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '\u20B9 ${balance.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (bills > 0 || debts > 0) ...<Widget>[
            const SizedBox(height: 12),
            if (bills > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'Bills',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                    Text(
                      '\u20B9 ${bills.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            if (debts > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'Debts',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                    Text(
                      '\u20B9 ${debts.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            if (bills > 0 || debts > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'Available',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      '\u20B9 ${available.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    positive ? Icons.trending_up : Icons.trending_down,
                    color: positive
                        ? const Color(0xFFBBF7D0)
                        : const Color(0xFFFCA5A5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    positive ? 'You are on track' : 'Spending more than income',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    final Map<TransactionCategory, double> expenseByCat =
        _controller.expenseByCategory;
    final Map<TransactionCategory, double> incomeByCat =
        _controller.incomeByCategory;
    final bool hasAny = expenseByCat.isNotEmpty || incomeByCat.isNotEmpty;

    if (!hasAny) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Your money by category',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Where your money came from & where it went',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          if (incomeByCat.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              'Money from (income source)',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            ...incomeByCat.entries.map(
              (MapEntry<TransactionCategory, double> e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: <Widget>[
                    Icon(e.key.icon, size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        e.key.label,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      '\u20B9 ${e.value.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (expenseByCat.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              'Money spent on (expense)',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            ...expenseByCat.entries.map(
              (MapEntry<TransactionCategory, double> e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: <Widget>[
                    Icon(e.key.icon, size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        e.key.label,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      '\u20B9 ${e.value.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade700,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.transactions.isEmpty) {
      return _buildEmptyState();
    }

    return _buildTransactionList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 72,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'No transactions yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start by adding your income or daily expenses.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    final List<WalletTransaction> transactions = _controller.transactions;

    return ListView.separated(
      itemCount: transactions.length,
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int index) {
        final WalletTransaction tx = transactions[index];
        final Color color =
            tx.isIncome ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

        return Dismissible(
          key: ValueKey<String>(tx.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.red.shade400,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => _deleteTransaction(tx),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: tx.isIncome
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFFEE2E2),
                child: Icon(
                  tx.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                  color: color,
                ),
              ),
              title: Text(
                tx.note.isEmpty
                    ? (tx.category?.label ?? (tx.isIncome ? 'Income' : 'Expense'))
                    : tx.note,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                [
                  if (tx.category != null) tx.category!.label,
                  _formatDate(tx.date),
                ].join(' • '),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    '${tx.isIncome ? '+' : '-'}\u20B9 ${tx.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

