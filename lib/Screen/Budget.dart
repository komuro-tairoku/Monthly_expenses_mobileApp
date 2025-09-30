import 'package:flutter/material.dart';

class Budget extends StatefulWidget {
  const Budget({super.key});

  @override
  State<Budget> createState() => _BudgetState();
}

class _BudgetState extends State<Budget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        toolbarHeight: 100,
        title: Text('Ngân sách', style: TextStyle(fontSize: 35)),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          'Tính năng sẽ ra mắt trong tương lai ^^',
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
    ;
  }
}
