import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  Future<void> _saveSeenIntro() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      user = (await FirebaseAuth.instance.signInAnonymously()).user;
    }

    await FirebaseFirestore.instance.collection('settings').doc(user!.uid).set({
      'seenIntro': true,
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      pages: [
        PageViewModel(
          titleWidget: const Text(
            "Chào mừng đến với",
            style: TextStyle(
              color: Color(0xFF6B43FF),
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          bodyWidget: Text(
            "Ứng dụng quản lý chi tiêu",
            style: Theme.of(
              context,
            ).textTheme.bodyMedium!.copyWith(fontSize: 25),
          ),
          image: const Center(
            child: Icon(
              Icons.monetization_on_rounded,
              size: 150,
              color: Color.fromARGB(255, 232, 192, 63),
            ),
          ),
        ),
        PageViewModel(
          titleWidget: const Text(
            "Nơi bạn có thể",
            style: TextStyle(
              color: Color(0xFF6B43FF),
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          bodyWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "• Ghi lại chi tiêu nhanh chóng",
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium!.copyWith(fontSize: 25),
              ),
              Text(
                "• Xem báo cáo trực quan",
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium!.copyWith(fontSize: 25),
              ),
              Text(
                "• Đặt ngân sách thông minh",
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium!.copyWith(fontSize: 25),
              ),
            ],
          ),
          image: Center(
            child: SvgPicture.asset(
              'assets/icons/columnChart.svg',
              width: 150,
              height: 150,
            ),
          ),
        ),
        PageViewModel(
          titleWidget: const Text(
            "Giao diện thân thiện",
            style: TextStyle(
              color: Color(0xFF6B43FF),
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          bodyWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "• Dễ dàng sử dụng",
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium!.copyWith(fontSize: 25),
              ),
              Text(
                "• Thiết kế tối giản, trực quan",
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium!.copyWith(fontSize: 25),
              ),
              Text(
                "• Hỗ trợ đa nền tảng",
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium!.copyWith(fontSize: 25),
              ),
              Text(
                "• Trải nghiệm mượt mà",
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium!.copyWith(fontSize: 25),
              ),
            ],
          ),
          image: Center(
            child: SvgPicture.asset(
              'assets/icons/seedIcon.svg',
              width: 150,
              height: 150,
            ),
          ),
        ),
        PageViewModel(
          titleWidget: const Text(
            "Bạn đã sẵn sàng?",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6B43FF),
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          bodyWidget: Text.rich(
            TextSpan(
              text: "Ấn ",
              style: Theme.of(
                context,
              ).textTheme.bodyMedium!.copyWith(fontSize: 25),
              children: [
                const TextSpan(
                  text: "tiếp tục",
                  style: TextStyle(
                    color: Color(0xFF6B43FF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: " để bắt đầu trải nghiệm",
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium!.copyWith(fontSize: 25),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          image: Center(
            child: Icon(
              Icons.download_done_rounded,
              size: 150,
              color: Colors.green[400],
            ),
          ),
        ),
      ],
      done: const Text(
        "Tiếp tục",
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF6B43FF),
          fontSize: 25,
        ),
      ),
      onDone: () async {
        await _saveSeenIntro();
        if (context.mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      },
      showSkipButton: true,
      skip: const Text(
        "Skip",
        style: TextStyle(fontSize: 25, color: Color(0xFF6B43FF)),
      ),
      next: const Icon(Icons.arrow_forward, color: Color(0xFF6B43FF), size: 30),
    );
  }
}
