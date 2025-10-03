import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:hooks_riverpod/legacy.dart';

final appThemeStateNotifier = ChangeNotifierProvider((ref) => AppThemeState());

class AppThemeState extends ChangeNotifier {
  bool isDarkModeEnable = false;
  bool _isInitialized = false;
  Box? _settingsBox;

  bool get isInitialized => _isInitialized;

  AppThemeState() {
    _initTheme();
  }

  Future<void> _initTheme() async {
    try {
      // Mở box nếu chưa mở
      if (!Hive.isBoxOpen('settings')) {
        _settingsBox = await Hive.openBox('settings');
      } else {
        _settingsBox = Hive.box('settings');
      }

      isDarkModeEnable =
          _settingsBox?.get('isDarkModeEnable', defaultValue: false) ?? false;
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Lỗi khởi tạo theme: $e');
      isDarkModeEnable = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  void toggleTheme(bool value) {
    isDarkModeEnable = value;
    _settingsBox?.put('isDarkModeEnable', value);
    notifyListeners();
  }
}
