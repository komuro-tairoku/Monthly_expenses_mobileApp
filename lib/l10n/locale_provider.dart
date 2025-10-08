import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hooks_riverpod/legacy.dart';

final appLocaleStateNotifier = ChangeNotifierProvider(
  (ref) => AppLocaleState(),
);

class AppLocaleState extends ChangeNotifier {
  Locale _locale = const Locale('vi');
  Locale get locale => _locale;
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  Box? _settingsBox;

  AppLocaleState() {
    _initLocale();
  }

  Future<void> _initLocale() async {
    try {
      if (!Hive.isBoxOpen('settings')) {
        _settingsBox = await Hive.openBox('settings');
      } else {
        _settingsBox = Hive.box('settings');
      }

      final String code =
          _settingsBox?.get('localeCode', defaultValue: 'vi') ?? 'vi';
      _locale = Locale(code);
      _isInitialized = true;
      notifyListeners();
    } catch (_) {
      _locale = const Locale('vi');
      _isInitialized = true;
      notifyListeners();
    }
  }

  void setLocale(Locale locale) {
    _locale = locale;
    _settingsBox?.put('localeCode', locale.languageCode);
    notifyListeners();
  }
}
