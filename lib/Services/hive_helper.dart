import 'package:hive_flutter/hive_flutter.dart';
import '../db/transaction.dart';

class HiveHelper {
  //luu transaction -> transaction model
  static Box<TransactionModel>? _transactionBox;
  static Box? _settingsBox;

  //luu giao dich vao Hive
  static Future<Box<TransactionModel>> getTransactionBox() async {
    if (_transactionBox != null && _transactionBox!.isOpen) {
      return _transactionBox!;
    }

    _transactionBox = await Hive.openBox<TransactionModel>('transactions');
    return _transactionBox!;
  }

  static Future<void> normalizeTransactionData() async {
    final box = await getTransactionBox();
    final keys = box.keys.toList();
    for (var key in keys) {
      try {
        final value = box.get(key);
        if (value == null) continue;

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

        if (changed) await value.save();
      } catch (e) {}
    }
  }

  //luu seenIntro, theme
  static Future<Box> getSettingsBox() async {
    if (_settingsBox != null && _settingsBox!.isOpen) {
      return _settingsBox!;
    }

    _settingsBox = await Hive.openBox('settings');
    return _settingsBox!;
  }

  static bool isTransactionBoxOpen() {
    return _transactionBox != null && _transactionBox!.isOpen;
  }

  static Future<void> closeAll() async {
    await _transactionBox?.close();
    await _settingsBox?.close();
    _transactionBox = null;
    _settingsBox = null;
  }
}
