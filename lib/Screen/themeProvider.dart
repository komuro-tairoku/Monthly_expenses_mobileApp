import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/legacy.dart';

final appThemeStateNotifier = ChangeNotifierProvider<AppThemeState>(
  (ref) => AppThemeState(),
);

class AppThemeState extends ChangeNotifier {
  var isDarkModeEnable = false;

  AppThemeState() {
    _loadThemeFromFirebase();
  }

  /// Lấy theme từ Firestore
  Future<void> _loadThemeFromFirebase() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("settings")
          .doc("theme")
          .get();

      if (doc.exists) {
        isDarkModeEnable = doc.data()?['isDarkModeEnable'] ?? false;
        notifyListeners();
      }
    } catch (e) {
      print("⚠️ Firestore error when loading theme: $e");
    }
  }

  Future<void> toggleTheme(bool value) async {
    isDarkModeEnable = value;
    notifyListeners();

    try {
      await FirebaseFirestore.instance.collection("settings").doc("theme").set({
        "isDarkModeEnable": value,
      });
    } catch (e) {
      print("⚠️ Firestore error when saving theme: $e");
    }
  }
}
