import 'package:flutter/cupertino.dart';
import 'package:hooks_riverpod/legacy.dart';

final appThemeStateNotifier = ChangeNotifierProvider((ref) => AppThemeState());

class AppThemeState extends ChangeNotifier {
  var isDarkModeEnable = false;

  AppThemeState() {
    final box = Hive.box('settings');
    isDarkModeEnable = box.get('isDarkModeEnable', defaultValue: false) as bool;
  }
  void toggleTheme(bool value) {
    isDarkModeEnable = value;
    Hive.box('settings').put('isDarkModeEnable', value);
    notifyListeners();
  }
}
