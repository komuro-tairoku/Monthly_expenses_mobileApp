import 'package:flutter/material.dart';
import 'package:monthly_expenses_mobile_app/l10n/app_localizations.dart';

class Chatbox extends StatefulWidget {
  const Chatbox({super.key});

  @override
  State<Chatbox> createState() => _ChatboxState();
}

class _ChatboxState extends State<Chatbox> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        toolbarHeight: 100,
        title: Text(
          AppLocalizations.of(context).t('chatbox.title'),
          style: TextStyle(fontSize: 35),
        ),
        centerTitle: true,
      ),
      body: Center(child: Text('Was coming', style: TextStyle(fontSize: 22))),
    );
  }
}
