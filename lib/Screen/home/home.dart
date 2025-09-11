import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF6B43FF),
        toolbarHeight: 90,
        title: Text(
          "Ghi chú thu chi",
          style: TextStyle(color: Color(0xFFE0E0E0), fontSize: 30),
        ),
        actions: [
          IconButton(
            onPressed: () {
              print("hello world");
            },
            icon: SvgPicture.asset('assets/icons/menu.svg'),
          ),
        ],
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
        ),
      ),
    );
  }
}
