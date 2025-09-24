import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'Screen/bottomNavBar.dart';
import 'Screen/IntroPage.dart';
import 'Screen/theme.dart';
import 'Screen/themeProvider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _loading = true;
  bool _seenIntro = false;

  @override
  void initState() {
    super.initState();
    _checkSeenIntro();
  }

  Future<void> _checkSeenIntro() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("settings")
          .doc("intro")
          .get();

      if (doc.exists && doc.data()?['seenIntro'] == true) {
        setState(() {
          _seenIntro = true;
        });
      }
    } catch (e) {
      print("⚠️ Firestore error: $e");
    }
    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(appThemeStateNotifier);

    if (_loading) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quản lý thu chi',
      theme: appTheme.lightTheme,
      darkTheme: appTheme.darkTheme,
      themeMode: themeState.isDarkModeEnable ? ThemeMode.dark : ThemeMode.light,
      home: _seenIntro ? const Home() : const IntroPage(),
      routes: {'/home': (context) => const Home()},
    );
  }
}
