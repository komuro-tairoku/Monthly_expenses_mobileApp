import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:monthly_expenses_mobile_app/Screen/loginScreen.dart';
import 'firebase_options.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'Screen/bottomNavBar.dart';
import 'Screen/IntroPage.dart';
import 'Screen/theme.dart';
import 'Screen/themeProvider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import './db/transaction.dart' as localdb;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  User? user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    await FirebaseAuth.instance.signInAnonymously();
  }
  await Hive.initFlutter();
  Hive.registerAdapter(localdb.TransactionAdapter());
  await Hive.openBox<localdb.Transaction>('transactions_v2');
  await Hive.openBox('settings');

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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _loading = false);
        return;
      }
      final doc = await FirebaseFirestore.instance
          .collection("settings")
          .doc(user.uid)
          .get();

      if (doc.exists && (doc.data()?['seenIntro'] == true)) {
        _seenIntro = true;
      }
    } catch (e) {
      debugPrint("⚠️ Firestore error: $e");
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appThemeState = ref.watch(appThemeStateNotifier);

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
      themeMode: appThemeState.isDarkModeEnable
          ? ThemeMode.dark
          : ThemeMode.light,
      home: _seenIntro ? const Home() : const IntroPage(),
      routes: {'/home': (context) => const Home()},
    );
  }
}
