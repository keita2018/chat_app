import 'package:flutter/material.dart';
import 'chat_page.dart';

class ChatHome extends StatefulWidget {
  const ChatHome({super.key});

  @override
  State<ChatHome> createState() => _ChatHomeState();
}

class _ChatHomeState extends State<ChatHome> {
  int _selectedSessionId = 0;

  final List<Map<String, dynamic>> _sessions = [
    {"id": 0, "title": "新しいチャット"},
    {"id": 1, "title": "セッション1"},
    {"id": 2, "title": "セッション2"},
  ];

  void _selectSession(int id) {
    setState(() {
      _selectedSessionId = id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 左サイドバー
          Container(
            width: 250,
            color: Colors.grey[200],
            child: Column(
              children: [
                const SizedBox(height: 50),
                const Text(
                  'セッション一覧',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _sessions.length,
                    itemBuilder: (context, index) {
                      final session = _sessions[index];
                      return ListTile(
                        selected: session["id"] == _selectedSessionId,
                        title: Text(session["title"]),
                        onTap: () => _selectSession(session["id"]),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // 右チャット画面
          Expanded(
            child: ChatPage(sessionId: _selectedSessionId),
          ),
        ],
      ),
    );
  }
}
