import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/wallet_transaction.dart';

class WalletExportService {
  /// Exports all [transactions] to an Excel file and opens the share sheet.
  /// Returns the file path on success, null on failure or if list is empty.
  static Future<String?> exportToExcel(
    List<WalletTransaction> transactions, {
    double? totalIncome,
    double? totalExpense,
    double? balance,
  }) async {
    if (transactions.isEmpty) return null;

    final Excel excel = Excel.createExcel();
    final String sheetName = excel.getDefaultSheet() ?? 'Sheet1';

    // Header row
    excel.appendRow(
      sheetName,
      <CellValue?>[
        TextCellValue('Date'),
        TextCellValue('Type'),
        TextCellValue('Category'),
        TextCellValue('Amount'),
        TextCellValue('Note'),
      ],
    );

    for (final WalletTransaction tx in transactions) {
      excel.appendRow(
        sheetName,
        <CellValue?>[
          TextCellValue(_formatDate(tx.date)),
          TextCellValue(tx.isIncome ? 'Income' : 'Expense'),
          TextCellValue(tx.category?.label ?? '-'),
          DoubleCellValue(tx.isIncome ? tx.amount : -tx.amount),
          TextCellValue(tx.note),
        ],
      );
    }

    // Summary row
    if (totalIncome != null || totalExpense != null || balance != null) {
      excel.appendRow(sheetName, <CellValue?>[null, null, null, null, null]);
      if (totalIncome != null) {
        excel.appendRow(
          sheetName,
          <CellValue?>[
            TextCellValue('Total Income'),
            null,
            null,
            DoubleCellValue(totalIncome),
            null,
          ],
        );
      }
      if (totalExpense != null) {
        excel.appendRow(
          sheetName,
          <CellValue?>[
            TextCellValue('Total Expense'),
            null,
            null,
            DoubleCellValue(-totalExpense),
            null,
          ],
        );
      }
      if (balance != null) {
        excel.appendRow(
          sheetName,
          <CellValue?>[
            TextCellValue('Balance'),
            null,
            null,
            DoubleCellValue(balance),
            null,
          ],
        );
      }
    }

    final List<int>? bytes = excel.encode();
    if (bytes == null) return null;

    final Directory dir = await getTemporaryDirectory();
    final String fileName =
        'smart_wallet_export_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final String path = '${dir.path}/$fileName';
    final File file = File(path);
    await file.writeAsBytes(bytes);

    // ignore: deprecated_member_use
    await Share.shareXFiles(
      <XFile>[XFile(path)],
      subject: 'Smart Wallet Export',
      text: 'Wallet transactions export',
    );

    return path;
  }

  static String _formatDate(DateTime date) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${date.year}-${twoDigits(date.month)}-${twoDigits(date.day)} '
        '${twoDigits(date.hour)}:${twoDigits(date.minute)}';
  }
}
