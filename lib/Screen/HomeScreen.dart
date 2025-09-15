import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Container(height: 150, color: Theme.of(context).primaryColor),
          Positioned.fill(
            child: Center(
              child: Text(
                'Ghi Chú Thu Chi',
                style: TextStyle(color: Color(0xFFE0E0E0), fontSize: 28),
              ),
            ),
          ),
          Positioned(
            child: IconButton(
              onPressed: () {},
              icon: SvgPicture.asset(
                'assets/icons/menu.svg',
                width: 40,
                color: Color(0xFFE0E0E0),
              ),
            ),
            top: 30,
          ),
          Positioned(
            child: IconButton(
              onPressed: () {},
              icon: SvgPicture.asset(
                'assets/icons/calendar.svg',
                width: 38,
                color: Color(0xFFE0E0E0),
              ),
            ),
            top: 38,
            right: 0,
          ),
        ],
      ),
    );
  }
}
