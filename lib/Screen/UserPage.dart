import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'themeProvider.dart';

class UserPage extends ConsumerStatefulWidget {
  const UserPage({super.key});

  @override
  ConsumerState<UserPage> createState() => _UserPageState();
}

class _UserPageState extends ConsumerState<UserPage> {
  File? _avatarImage;
  String? _avatarUrl;
  final ImagePicker _picker = ImagePicker();
  final double circleSize = 150;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();
      if (doc.exists) {
        setState(() {
          _avatarUrl = doc.data()?["avatarUrl"] as String?;
        });
      }
    } catch (e) {
      debugPrint("⚠️ Firestore error (load avatar): $e");
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final storageRef = FirebaseStorage.instance
          .ref()
          .child("avatars")
          .child("$uid${p.extension(picked.path)}");

      await storageRef.putFile(File(picked.path));
      final downloadUrl = await storageRef.getDownloadURL();

      // Save avatar URL to Firestore
      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "avatarUrl": downloadUrl,
      }, SetOptions(merge: true));

      setState(() {
        _avatarImage = File(picked.path);
        _avatarUrl = downloadUrl;
      });
    } catch (e) {
      debugPrint("⚠️ Error picking/uploading image: $e");
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
              // Header with theme switch
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
                      crossAxisAlignment: CrossAxisAlignment.center,
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

          // Avatar
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
                      : (_avatarUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  _avatarUrl!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.deepPurple,
                              )),
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
