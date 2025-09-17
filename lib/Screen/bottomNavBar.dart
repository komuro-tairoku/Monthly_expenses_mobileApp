import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'HomeScreen.dart';
import 'Statement.dart';
import 'Budget.dart';
import 'User.dart';
import 'bottomSheet.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;
  static final List<Widget> _screens = [
    const HomeScreen(),
    Statement(),
    const Budget(),
    const User(),
  ];
  void _onItemTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      body: _screens[_selectedIndex],

      bottomNavigationBar: BottomAppBar(
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              buildNavBarItem(CupertinoIcons.house_alt_fill, 'Home', 0),
              buildNavBarItem(CupertinoIcons.chart_pie_fill, 'Báo cáo', 1),
              SizedBox(width: 25),
              buildNavBarItem(
                CupertinoIcons.money_dollar_circle_fill,
                'Ngân sách',
                2,
              ),
              buildNavBarItem(CupertinoIcons.person_fill, 'User', 3),
            ],
          ),
        ),
      ),
      floatingActionButton: RawMaterialButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) {
              return const bottomSheet();
            },
          );
        },
        shape: const CircleBorder(),
        fillColor: Colors.white,
        elevation: 10,
        child: SvgPicture.asset(
          'assets/icons/add.svg',
          width: 60,
          height: 60,
          color: const Color(0xFF6B43FF),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget buildNavBarItem(IconData icon, String label, int index) {
    final bool isSlected = _selectedIndex == index;
    return InkWell(
      onTap: () => _onItemTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: _selectedIndex == index
                ? Color(0xFF6B43FF)
                : Color(0xFF828282),
          ),
          Text(label),
        ],
      ),
    );
  }
}
