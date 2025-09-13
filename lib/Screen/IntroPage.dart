import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      pages: [
        PageViewModel(
          titleWidget: Text(
            "Chào mừng đến với",
            style: TextStyle(
              color: Color(0xFF6B43FF),
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          bodyWidget: Text(
            "Ứng dụng quản lý chi tiêu",
            style: TextStyle(fontSize: 25),
          ),
          image: Center(
            child: Icon(
              Icons.monetization_on_rounded,
              size: 100,
              color: Color(0xFFD4AF37),
            ),
          ),
        ),
        PageViewModel(
          titleWidget: Text(
            "Nơi bạn có thể",
            style: TextStyle(
              color: Color(0xFF6B43FF),
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          bodyWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "• Ghi lại chi tiêu nhanh chóng",
                style: TextStyle(fontSize: 25),
              ),
              Text("• Xem báo cáo trực quan", style: TextStyle(fontSize: 25)),
              Text(
                "• Đặt ngân sách thông minh",
                style: TextStyle(fontSize: 25),
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
          titleWidget: Text(
            "Giao diện thân thiện",
            style: TextStyle(
              color: Color(0xFF6B43FF),
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          bodyWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text("• Dễ dàng sử dụng", style: TextStyle(fontSize: 25)),
              Text(
                "• Thiết kế tối giản, trực quan",
                style: TextStyle(fontSize: 25),
              ),
              Text("• Hỗ trợ đa nền tảng", style: TextStyle(fontSize: 25)),
              Text("• Trải nghiệm mượt mà", style: TextStyle(fontSize: 25)),
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
      ],
      done: const Text(
        "Done",
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF6B43FF),
          fontSize: 25,
        ),
      ),
      onDone: () {
        // Khi bấm Done -> chuyển trang
        Navigator.of(context).pushReplacementNamed('/home');
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
