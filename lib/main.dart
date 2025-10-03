import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'firebase_options.dart';
import './db/transaction.dart';
import './Services/syncService.dart';
import 'Screen/IntroPage.dart';
import 'Screen/loginScreen.dart';
import 'Screen/bottomNavBar.dart';
import 'Screen/theme.dart';
import 'Screen/themeProvider.dart';
import 'Services/hiveHelper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Hive.initFlutter();
  Hive.registerAdapter(TransactionModelAdapter());

  SyncService.start();

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
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAppState();
  }

  Future<void> _checkAppState() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.isAnonymous) {
        _isLoggedIn = true;

        final doc = await FirebaseFirestore.instance
            .collection("settings")
            .doc(user.uid)
            .get();
        if (doc.exists && (doc.data()?['seenIntro'] == true)) {
          _seenIntro = true;
        }
      } else {
        // Lazy open settings box qua HiveHelper
        final box = await HiveHelper.getSettingsBox();
        _seenIntro = box.get('seenIntro', defaultValue: false);
      }
    } catch (e) {
      debugPrint("⚠️ Firestore error: $e");
      _seenIntro = false;
      _isLoggedIn = false;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appThemeState = ref.watch(appThemeStateNotifier);

    // Đợi cả app state và theme đều khởi tạo xong
    if (_loading || !appThemeState.isInitialized) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    Widget homePage;
    if (_isLoggedIn) {
      homePage = const Home();
    } else {
      homePage = _seenIntro ? const LoginScreen() : const IntroPage();
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quản lý thu chi',
      theme: appTheme.lightTheme,
      darkTheme: appTheme.darkTheme,
      themeMode: appThemeState.isDarkModeEnable
          ? ThemeMode.dark
          : ThemeMode.light,
      home: homePage,
      routes: {
        '/intro': (context) => const IntroPage(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const Home(),
      },
    );
  }
}
