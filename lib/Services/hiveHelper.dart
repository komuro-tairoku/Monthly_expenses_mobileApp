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
