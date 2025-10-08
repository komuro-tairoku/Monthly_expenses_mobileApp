import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class AppLocalizations {
  final Locale locale;
  Map<String, dynamic> _localizedStrings = const {};

  AppLocalizations(this.locale);

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final loc = Localizations.of<AppLocalizations>(context, AppLocalizations);
    if (loc != null) return loc;
    return AppLocalizations(const Locale('en'));
  }

  Future<bool> load() async {
    final code = locale.languageCode;
    final fallbackCode = 'vi';
    String jsonString;

    try {
      jsonString = await rootBundle.loadString('assets/lang/$code.json');
    } catch (_) {
      jsonString = await rootBundle.loadString(
        'assets/lang/$fallbackCode.json',
      );
    }

    _localizedStrings = json.decode(jsonString) as Map<String, dynamic>;
    return true;
  }

  String t(String key) {
    final parts = key.split('.');
    dynamic value = _localizedStrings;
    for (final p in parts) {
      if (value is Map<String, dynamic> && value.containsKey(p)) {
        value = value[p];
      } else {
        return key;
      }
    }
    return value is String ? value : key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['vi', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
