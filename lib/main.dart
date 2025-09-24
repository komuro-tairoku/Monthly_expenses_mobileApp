import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'Screen/bottomNavBar.dart';
import 'package:monthly_expenses_mobile_app/Screen/IntroPage.dart';
import 'package:monthly_expenses_mobile_app/Screen/theme.dart';
import 'package:monthly_expenses_mobile_app/Screen/themeProvider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends HookConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quản lý thu chi',
      theme: appTheme.lightTheme,
      darkTheme: appTheme.darkTheme,
      themeMode: appThemeState.isDarkModeEnable
          ? ThemeMode.dark
          : ThemeMode.light,
      home: seenIntro ? const Home() : const IntroPage(),
      routes: {'/home': (context) => const Home()},
    );
  }
}
