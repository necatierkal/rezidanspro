import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  final int contactUserId;
  final String contactName;

  const ChatScreen({super.key, required this.contactUserId, required this.contactName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(contactName)),
      body: const Center(
        child: Text('Özel Mesajlaşma'),
      ),
    );
  }
}
