import 'package:flutter/material.dart';

class User extends StatefulWidget {
  const User({super.key});

  @override
  State<User> createState() => _UserState();
}

class _UserState extends State<User> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('User', style: TextStyle(color: Colors.red, fontSize: 30)),
    );
    ;
  }
}
