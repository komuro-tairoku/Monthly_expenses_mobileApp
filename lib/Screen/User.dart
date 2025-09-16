// user_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:monthly_expenses_mobile_app/Screen/themeProvider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:animated_toggle_switch/animated_toggle_switch.dart';

class User extends ConsumerStatefulWidget {
  const User({super.key});

  @override
  ConsumerState<User> createState() => _UserState();
}

class _UserState extends ConsumerState<User> {
  File? _avatarImage;
  final ImagePicker _picker = ImagePicker();
  final double circleSize = 150;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  void _loadAvatar() {
    final box = Hive.box('settings');
    final String? path = box.get('avatarPath') as String?;
    if (path != null && path.isNotEmpty) {
      final f = File(path);
      if (f.existsSync()) {
        _avatarImage = f;
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;

      final appDir = await getApplicationDocumentsDirectory();
      final fileName =
          'avatar_${DateTime.now().millisecondsSinceEpoch}${p.extension(picked.path)}';
      final savedImage = await File(
        picked.path,
      ).copy('${appDir.path}/$fileName');

      Hive.box('settings').put('avatarPath', savedImage.path);

      setState(() {
        _avatarImage = savedImage;
      });
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appThemeState = ref.watch(appThemeStateNotifier);
    final themeNotifier = ref.read(appThemeStateNotifier);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                height: 150,
                color: Theme.of(context).primaryColor,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
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
                          boxShadow: const [
                            BoxShadow(
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
                ),
              ),

              // Body
              Expanded(
                child: Column(
                  children: [
                    SizedBox(height: 100),
                    Text(
                      "User",
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium!.copyWith(fontSize: 25),
                    ),
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Acount",
                            style: Theme.of(context).textTheme.bodyMedium!
                                .copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          SizedBox(height: 21),
                          _buildItem(context, Icons.person, "Edit profile"),
                          _buildItem(context, Icons.security, "Security"),
                          _buildItem(
                            context,
                            Icons.notifications,
                            "Notifications",
                          ),
                          _buildItem(context, Icons.lock, "Privacy"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          Positioned(
            top: 90,
            left: MediaQuery.of(context).size.width / 2 - (circleSize / 2),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: circleSize,
                  height: circleSize,
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                    image: _avatarImage != null
                        ? DecorationImage(
                            image: FileImage(_avatarImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _avatarImage == null
                      ? const Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.deepPurple,
                        )
                      : null,
                ),

                Positioned(
                  bottom: -4,
                  right: -4,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.add_a_photo,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildItem(BuildContext context, IconData icon, String text) {
  return Padding(
    padding: EdgeInsetsGeometry.symmetric(vertical: 8),
    child: Row(
      children: [
        Icon(icon, size: 22, color: Color(0xFF6B43FF)),
        const SizedBox(width: 12),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 17),
        ),
      ],
    ),
  );
}
