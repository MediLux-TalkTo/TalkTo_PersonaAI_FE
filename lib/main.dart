import 'package:flutter/material.dart';

import 'core/network/api_client.dart';
import 'features/auth/data/auth_api.dart';
import 'features/chat/chat_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final token = await AuthApi().login(
      identifier: 'admin@talkto.local',
      password: 'Admin1234!',
    );

    ApiClient.setToken(token);
    debugPrint('LOGIN SUCCESS');
  } catch (e) {
    debugPrint('LOGIN ERROR: $e');
  }

  runApp(const TalkToApp());
}

class TalkToApp extends StatelessWidget {
  const TalkToApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ChatPage(),
    );
  }
}
