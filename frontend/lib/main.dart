import 'package:flutter/material.dart';
import 'pages/chat_page.dart'; // ChatPage をインポート

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ChatPage(sessionId: 0), // ここで ChatPage を最初に表示
      debugShowCheckedModeBanner: false,
    );
  }
}
