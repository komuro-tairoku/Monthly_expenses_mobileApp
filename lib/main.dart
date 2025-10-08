import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'firebase_options.dart';
import './db/transaction.dart';
import './Services/sync_service.dart';
import 'Screen/intro_page.dart';
import 'Screen/login_screen.dart';
import 'Screen/bottom_nav_bar.dart';
import 'Screen/theme.dart';
import 'Screen/theme_provider.dart';
import 'Services/hive_helper.dart';
import 'l10n/app_localizations.dart';
import 'l10n/locale_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Hive.initFlutter();
  Hive.registerAdapter(TransactionModelAdapter());

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
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await _checkAppState();

      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.isAnonymous) {
        SyncService.start();
      }
    } catch (e) {
      debugPrint("Error during initialization: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _checkAppState() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.isAnonymous) {
        _isLoggedIn = true;

        final doc = await FirebaseFirestore.instance
            .collection("settings")
            .doc(user.uid)
            .get()
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                debugPrint("Firestore timeout, using default value");
                return FirebaseFirestore.instance
                    .collection("settings")
                    .doc(user.uid)
                    .get();
              },
            );

        if (doc.exists && (doc.data()?['seenIntro'] == true)) {
          _seenIntro = true;
        }
      } else {
        final box = await HiveHelper.getSettingsBox();
        _seenIntro = box.get('seenIntro', defaultValue: false);
      }
    } catch (e) {
      debugPrint("Error checking app state: $e");
      _seenIntro = false;
      _isLoggedIn = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appThemeState = ref.watch(appThemeStateNotifier);
    final appLocaleState = ref.watch(appLocaleStateNotifier);

    Widget app = Builder(
      builder: (context) {
        final media = MediaQuery.of(context);
        final maxTextScale = media.textScaleFactor.clamp(1.0, 1.0);

        if (_loading ||
            !appThemeState.isInitialized ||
            !appLocaleState.isInitialized) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: appLocaleState.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('vi'), Locale('es'), Locale('en')],
            home: Scaffold(
              body: Center(
                child: MediaQuery(
                  data: media.copyWith(textScaleFactor: maxTextScale),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFF6B43FF)),
                      const SizedBox(height: 16),
                      FittedBox(
                        child: Text(
                          'Đang khởi động...',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
          locale: appLocaleState.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('vi'), Locale('es'), Locale('en')],
          onGenerateTitle: (ctx) => AppLocalizations.of(ctx).t('app.title'),
          theme: appTheme.lightTheme,
          darkTheme: appTheme.darkTheme,
          themeMode: appThemeState.isDarkModeEnable
              ? ThemeMode.dark
              : ThemeMode.light,
          home: MediaQuery(
            data: media.copyWith(textScaleFactor: maxTextScale),
            child: homePage,
          ),
          routes: {
            '/intro': (context) => const IntroPage(),
            '/login': (context) => const LoginScreen(),
            '/home': (context) => const Home(),
          },
        );
      },
    );

    return app;
  }

  @override
  void dispose() {
    SyncService.stop();
    super.dispose();
  }
}
