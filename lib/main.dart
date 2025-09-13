import 'package:flutter/material.dart';
import 'package:monthly_expenses_mobile_app/Screen/IntroPage.dart';
import 'Screen/bottomNavBar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quản lý thu chi',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const IntroPage(),
      routes: {'/home': (context) => const Home()},
    );
  }
}
