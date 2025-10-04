import 'package:hive_flutter/hive_flutter.dart';
import '../db/transaction.dart';

class HiveHelper {
  static Box<TransactionModel>? _transactionBox;
  static Box? _settingsBox;

  /// Lấy transaction box, tự động mở nếu chưa mở
  static Future<Box<TransactionModel>> getTransactionBox() async {
    if (_transactionBox != null && _transactionBox!.isOpen) {
      return _transactionBox!;
    }

    _transactionBox = await Hive.openBox<TransactionModel>('transactions');
    return _transactionBox!;
  }

  /// Optional: normalize existing transaction entries to ensure correct types.
  /// Call this once (for example during app startup) if you suspect legacy
  /// entries have wrong field types stored in Hive.
  static Future<void> normalizeTransactionData() async {
    final box = await getTransactionBox();
    final keys = box.keys.toList();
    for (var key in keys) {
      try {
        final value = box.get(key);
        if (value == null) continue;

        // Defensive coercion in case some fields were stored with incorrect types.
        // Use dynamic access so the analyzer doesn't assume concrete types here.
        bool changed = false;
        final id = (value as dynamic).id?.toString() ?? '';
        if (id != value.id) {
          value.id = id;
          changed = true;
        }

        final category = (value as dynamic).category?.toString() ?? '';
        if (category != value.category) {
          value.category = category;
          changed = true;
        }

        // amount might have been stored as int or String in legacy data; read as dynamic
        final dynamic rawAmount = (value as dynamic).amount;
        double amount = 0.0;
        if (rawAmount is num)
          amount = rawAmount.toDouble();
        else if (rawAmount is String)
          amount = double.tryParse(rawAmount) ?? 0.0;
        if (amount != value.amount) {
          value.amount = amount;
          changed = true;
        }

        final note = (value as dynamic).note?.toString() ?? '';
        if (note != value.note) {
          value.note = note;
          changed = true;
        }

        // date / isIncome / isSynced are non-nullable in the model; if some legacy
        // records are invalid, we resave other corrected fields above.
        if (changed) await value.save();
      } catch (e) {
        // ignore individual record failures
      }
    }
  }

  /// Lấy settings box, tự động mở nếu chưa mở
  static Future<Box> getSettingsBox() async {
    if (_settingsBox != null && _settingsBox!.isOpen) {
      return _settingsBox!;
    }

    _settingsBox = await Hive.openBox('settings');
    return _settingsBox!;
  }

  /// Kiểm tra xem transaction box đã mở chưa
  static bool isTransactionBoxOpen() {
    return _transactionBox != null && _transactionBox!.isOpen;
  }

  /// Đóng tất cả boxes (nếu cần)
  static Future<void> closeAll() async {
    await _transactionBox?.close();
    await _settingsBox?.close();
    _transactionBox = null;
    _settingsBox = null;
  }
}
