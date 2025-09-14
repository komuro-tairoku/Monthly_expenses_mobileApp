import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:monthly_expenses_mobile_app/Screen/themeProvider.dart';

class User extends ConsumerWidget {
  const User({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appThemeState = ref.watch(appThemeStateNotifier);
    final themeNotifier = ref.read(appThemeStateNotifier);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        toolbarHeight: 100,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: SizedBox(
              width: 55,
              height: 30,
              child: AnimatedToggleSwitch<bool>.dual(
                current: appThemeState.isDarkModeEnable,
                first: false,
                second: true,
                spacing: 6,
                borderWidth: 2.0,
                height: 30,
                onChanged: (b) => themeNotifier.toggleTheme(b),
                style: ToggleStyle(
                  backgroundColor: Colors.grey[300],
                  indicatorColor: appThemeState.isDarkModeEnable
                      ? Colors.black
                      : Colors.white,
                  borderColor: Colors.transparent,
                  boxShadow: [
                    const BoxShadow(
                      color: Colors.black26,
                      spreadRadius: 0.5,
                      blurRadius: 1,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                styleBuilder: (b) => ToggleStyle(
                  indicatorColor: b ? Colors.black : Colors.yellow[600],
                ),
                iconBuilder: (value) => value
                    ? const Icon(Icons.dark_mode, size: 20)
                    : const Icon(Icons.light_mode, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: const Center(child: Text("Nội dung app")),
    );
  }
}
