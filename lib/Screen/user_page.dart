import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:monthly_expenses_mobile_app/l10n/app_localizations.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import 'theme_provider.dart';
import 'login_screen.dart';
import '../l10n/locale_provider.dart';

class UserPage extends ConsumerStatefulWidget {
  const UserPage({super.key});

  @override
  ConsumerState<UserPage> createState() => _UserPageState();
}

class _UserPageState extends ConsumerState<UserPage> {
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
    final String? path = box.get('avatarPath');
    if (path != null && path.isNotEmpty) {
      final file = File(path);
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

      final oldPath = Hive.box('settings').get('avatarPath');
      if (oldPath != null && File(oldPath).existsSync()) {
        try {
          File(oldPath).deleteSync();
        } catch (_) {}
      }

      Hive.box('settings').put('avatarPath', savedImage.path);

      setState(() {
        _avatarImage = savedImage;
      });
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Đăng xuất thành công")));
      }
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  void _showReportDialog(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final user = FirebaseAuth.instance.currentUser;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context).t('common.report'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).t("report.title"),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(
                    context,
                  ).t("report.input_title"),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).t("report.detail"),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(
                    context,
                  ).t("report.input_detail"),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context).t("report.cancel"),
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty ||
                  descriptionController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context).t("report.fill_all"),
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              // Construct email
              final String yourEmail = 'bosscyrus12yahoo@gmail.com';
              final String subject = Uri.encodeComponent(
                'Bug Report: ${titleController.text}',
              );
              final String body = Uri.encodeComponent(
                'User: ${user?.email ?? "Unknown"}\n'
                'User Name: ${user?.displayName ?? "N/A"}\n'
                'Date: ${DateTime.now()}\n\n'
                'Title: ${titleController.text}\n\n'
                'Description:\n${descriptionController.text}',
              );

              final Uri emailUri = Uri.parse(
                'mailto:$yourEmail?subject=$subject&body=$body',
              );

              try {
                final bool launched = await launchUrl(
                  emailUri,
                  mode: LaunchMode.externalApplication,
                );
                if (!launched && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Không thể mở ứng dụng email'),
                    ),
                  );
                }
              } catch (e) {
                debugPrint('Error launching email: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B43FF),
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context).t("report.send")),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final localeState = ref.watch(appLocaleStateNotifier);
    final localeNotifier = ref.read(appLocaleStateNotifier.notifier);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                height: 150,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6B43FF), Color(0xFF8B5FFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6B43FF).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
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

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              AnimatedToggleSwitch<bool>.dual(
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
                                  indicatorColor: b
                                      ? Colors.black
                                      : Colors.yellow,
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
                              ),
                            ],
                          );
                        },
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
                      user?.displayName ?? user?.email ?? "User",
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
                          _buildItem(
                            context,
                            Icons.security,
                            AppLocalizations.of(context).t('common.security'),
                          ),
                          _buildItem(
                            context,
                            Icons.notifications,
                            AppLocalizations.of(
                              context,
                            ).t('common.notification'),
                          ),
                          _buildItem(
                            context,
                            Icons.lock,
                            AppLocalizations.of(context).t('common.private'),
                          ),
                          GestureDetector(
                            onTap: () => _showReportDialog(context),
                            child: _buildItem(
                              context,
                              Icons.report,
                              AppLocalizations.of(context).t('common.report'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Dropdown chọn ngôn ngữ
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceVariant.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outline.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.language,
                                  size: 20,
                                  color: Color(0xFF6B43FF),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: localeState.locale.languageCode,
                                      isExpanded: true,
                                      icon: Icon(
                                        Icons.keyboard_arrow_down,
                                        size: 20,
                                        color: Color(0xFF6B43FF),
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      dropdownColor: Theme.of(
                                        context,
                                      ).colorScheme.surface,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .copyWith(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'vi',
                                          child: Text('Tiếng Việt'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'en',
                                          child: Text('English'),
                                        ),
                                      ],
                                      onChanged: (code) {
                                        if (code == null) return;
                                        localeNotifier.setLocale(Locale(code));
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 21),
                          GestureDetector(
                            onTap: () => _signOut(context),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.logout,
                                  size: 22,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  ).t('common.logout'),
                                  style: Theme.of(context).textTheme.bodyMedium!
                                      .copyWith(
                                        fontSize: 17,
                                        color: Colors.red,
                                      ),
                                ),
                              ],
                            ),
                          ),
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
                  child: ClipOval(
                    child: _avatarImage != null
                        ? Image.file(_avatarImage!, fit: BoxFit.cover)
                        : (user?.photoURL != null
                              ? Image.network(
                                  user!.photoURL!,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.deepPurple,
                                )),
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
