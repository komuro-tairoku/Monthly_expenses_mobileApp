import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'themeProvider.dart';

@HiveType(typeId: 1)
class UserProfile extends HiveObject {
  @HiveField(0)
  String? avatarPath;

  UserProfile({this.avatarPath});
}

class UserPage extends ConsumerStatefulWidget {
  const UserPage({super.key});

  @override
  ConsumerState<UserPage> createState() => _UserPageState();
}

class _UserPageState extends ConsumerState<UserPage> {
  File? _avatarImage;
  final ImagePicker _picker = ImagePicker();
  final double circleSize = 150;

  Box<UserProfile>? _userBox;

  @override
  void initState() {
    super.initState();
    _initUserData();
  }

  Future<void> _initUserData() async {
    _userBox = await Hive.openBox<UserProfile>('users');

    final userProfile = _userBox!.get('profile');
    if (userProfile != null && userProfile.avatarPath != null) {
      final file = File(userProfile.avatarPath!);
      if (file.existsSync()) {
        setState(() {
          _avatarImage = file;
        });
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

      final oldPath = _userBox!.get('profile')?.avatarPath;
      if (oldPath != null && File(oldPath).existsSync()) {
        try {
          File(oldPath).deleteSync();
        } catch (_) {}
      }

      final profile = UserProfile(avatarPath: savedImage.path);
      await _userBox!.put('profile', profile);

      setState(() {
        _avatarImage = savedImage;
      });
    } catch (e) {
      debugPrint("⚠️ Error picking image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      child: Consumer(
                        builder: (context, ref, _) {
                          final appThemeState = ref.watch(
                            appThemeStateNotifier,
                          );
                          final themeNotifier = ref.read(
                            appThemeStateNotifier.notifier,
                          );

                          return AnimatedToggleSwitch<bool>.dual(
                            current: appThemeState.isDarkModeEnable,
                            first: false,
                            second: true,
                            spacing: 6,
                            borderWidth: 2.0,
                            height: 30,
                            onChanged: (b) => themeNotifier.toggleTheme(b),
                            iconBuilder: (value) => value
                                ? const Icon(Icons.dark_mode, size: 20)
                                : const Icon(Icons.light_mode, size: 20),
                            styleBuilder: (b) => ToggleStyle(
                              backgroundColor: Colors.grey[300],
                              indicatorColor: b ? Colors.black : Colors.yellow,
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
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: 100),
                    Text(
                      "Profile",
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
                            "Account",
                            style: Theme.of(context).textTheme.bodyMedium!
                                .copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 21),
                          _buildItem(context, Icons.person, "Edit profile"),
                          _buildItem(context, Icons.security, "Bảo mật"),
                          _buildItem(context, Icons.notifications, "Thông báo"),
                          _buildItem(context, Icons.lock, "Riêng tư"),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset('assets/icons/crown.svg', width: 25),
                        const SizedBox(width: 6),
                        const Text('Nạp'),
                        const SizedBox(width: 4),
                        const Text(
                          'VIP',
                          style: TextStyle(
                            fontSize: 23,
                            color: Color(0xFFFFB743),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('để sử dụng full chức năng'),
                      ],
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
                  ),
                  child: _avatarImage != null
                      ? ClipOval(
                          child: Image.file(_avatarImage!, fit: BoxFit.cover),
                        )
                      : const Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.deepPurple,
                        ),
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
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Icon(icon, size: 22, color: const Color(0xFF6B43FF)),
        const SizedBox(width: 12),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 17),
        ),
      ],
    ),
  );
}
