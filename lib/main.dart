import 'package:flutter/material.dart';
import 'features/chat/chat_page.dart';

void main() {
  runApp(const TalkToApp());
}

class TalkToApp extends StatelessWidget {
  const TalkToApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TalkTo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F7F5),
        fontFamily: 'Pretendard',
      ),
      home: const ChatPage(),
    );
  }
}