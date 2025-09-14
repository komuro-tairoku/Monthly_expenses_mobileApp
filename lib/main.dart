import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:monthly_expenses_mobile_app/Screen/IntroPage.dart';
import 'package:monthly_expenses_mobile_app/Screen/theme.dart';
import 'package:monthly_expenses_mobile_app/Screen/themeProvider.dart';
import 'Screen/bottomNavBar.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends HookConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appThemeState = ref.watch(appThemeStateNotifier);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quản lý thu chi',
      theme: appTheme.lightTheme,
      darkTheme: appTheme.darkTheme,
      themeMode: appThemeState.isDarkModeEnable
          ? ThemeMode.dark
          : ThemeMode.light,
      home: const IntroPage(),
      routes: {'/home': (context) => const Home()},
    );
  }
}
