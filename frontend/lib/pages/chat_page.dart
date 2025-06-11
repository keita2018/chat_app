import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/chat_session.dart';
import '../api/chat_api.dart';

class ChatPage extends StatefulWidget {
  final int sessionId;

  const ChatPage({super.key, required this.sessionId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<ChatSession> _sessions = [];
  int? _currentSessionId;
  String _currentSessionTitle = '新しいチャット';
  List<Map<String, String>> _chatHistory = [];

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchSessions().then((_) async {
      if (widget.sessionId == 0) {
        final newSession = await ChatApi.createSession("新しいチャット");
        if (newSession != null) {
          setState(() {
            _sessions.insert(0, newSession);
            _currentSessionId = newSession.id;
            _currentSessionTitle = newSession.title;
            _chatHistory = [];
          });
        }
      } else {
        _loadChatHistory(widget.sessionId, _currentSessionTitle);
      }
    });
  }

  Future<void> _fetchSessions() async {
    final response = await http.get(Uri.parse('http://localhost:3000/api/v1/chat_sessions'));

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      setState(() {
        _sessions = jsonList.map((json) => ChatSession.fromJson(json)).toList();
      });
    } else {
      print('セッション取得失敗: ${response.statusCode}');
    }
  }

  Future<void> _loadChatHistory(int sessionId, String sessionTitle) async {
    final response = await http.get(Uri.parse('http://localhost:3000/api/v1/chat_sessions/$sessionId/messages'));

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      setState(() {
        _currentSessionId = sessionId;
        _currentSessionTitle = sessionTitle;
        _chatHistory = jsonList.map((item) => {
          "role": item["role"].toString(),
          "content": item["content"].toString()
        }).toList();
      });

      _scrollToBottom();
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.isEmpty || _currentSessionId == null) return;

    // ユーザーのメッセージを履歴に追加
    setState(() {
      _chatHistory.add({"role": "user", "content": text});
    });

    _controller.clear();

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/v1/messages'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "message": {
            "role": "user",
            "content": text
          },
          "chat_session_id": _currentSessionId
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final assistantMessage = json["assistant"]["content"];

        setState(() {
          _chatHistory.add({"role": "assistant", "content": assistantMessage});
        });

        _scrollToBottom();
      } else {
        setState(() {
          _chatHistory.add({
            "role": "assistant",
            "content": "エラー: ${response.statusCode}"
          });
        });
      }
    } catch (e) {
      setState(() {
        _chatHistory.add({
          "role": "assistant",
          "content": "送信エラー: $e"
        });
      });
    }
  }

  Future<String?> _showRenameDialog(String currentTitle) {
    final controller = TextEditingController(text: currentTitle);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('セッション名を変更'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '新しい名前を入力'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('変更')),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          // 0,
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(child: Text('セッション一覧')),

          // ✅ 新しいチャットを作成するボタン（先頭に追加）
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('新しいチャット'),
            onTap: () async {
              Navigator.pop(context); // Drawer を閉じる
              final newSession = await ChatApi.createSession("新しいチャット");
              if (newSession != null) {
                setState(() {
                  _sessions.insert(0, newSession);
                  _currentSessionId = newSession.id;
                  _currentSessionTitle = newSession.title;
                  _chatHistory = [];
                });
              }
            },
          ),

          // ✅ 既存セッション一覧
          ..._sessions.map((session) {
            final isSelected = session.id == _currentSessionId;
            return ListTile(
              selected: isSelected,
              title: Text(
                session.title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.blue : Colors.black,
                ),
              ),
              onTap: () {
                Navigator.pop(context); // Drawer を閉じる
                _loadChatHistory(session.id, session.title);
              },
              onLongPress: () async {
                final newTitle = await _showRenameDialog(session.title);
                if (newTitle != null && newTitle.trim().isNotEmpty) {
                  try {
                    await ChatApi.renameSession(session.id, newTitle.trim());
                    await _fetchSessions(); // セッション一覧を再取得
                    if (_currentSessionId == session.id) {
                      setState(() {
                        _currentSessionTitle = newTitle.trim();
                      });
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('名前変更に失敗しました: $e')),
                    );
                  }
                }
              },
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('削除確認'),
                      content: Text('セッション「${session.title}」を削除しますか？'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('削除')),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    try {
                      await ChatApi.deleteSession(session.id);
                      setState(() {
                        _sessions.removeWhere((s) => s.id == session.id);
                        if (_currentSessionId == session.id) {
                          _currentSessionId = null;
                          _currentSessionTitle = '新しいチャット';
                          _chatHistory = [];
                        }
                      });
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('削除に失敗しました: $e')),
                      );
                    }
                  }
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildMessageTile(Map<String, String> message) {
    final isUser = message['role'] == 'user';
    // debugPrint('message: ${message['role']}, ${message['content']}');
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue[100] : Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(message['content'] ?? ''),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$_currentSessionTitle'),
      ),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: false,
              itemCount: _chatHistory.length,
              itemBuilder: (context, index) {
                return _buildMessageTile(_chatHistory[index]);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'メッセージを入力'),
                    onSubmitted: (_) {
                      final message = _controller.text.trim();
                      if (message.isNotEmpty) {
                        _controller.clear();
                        _sendMessage(message);
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    final message = _controller.text.trim();
                    if (message.isNotEmpty) {
                      _controller.clear();
                      _sendMessage(message);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
