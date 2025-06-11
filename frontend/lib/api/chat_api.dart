import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/chat_session.dart';

class ChatApi {
  static const String baseUrl = 'http://localhost:3000/api/v1/messages';

  /// POST: ユーザーメッセージ送信 & Groq応答を受け取る
  static Future<Map<String, dynamic>> sendMessageWithSession({
    required int chatSessionId,
    required List<Map<String, String>> messages,
    required String model,
  }) async {
    final uri = Uri.parse("http://localhost:3000/api/v1/messages");

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "chat_session_id": chatSessionId,
        "messages": messages,
        "model": model,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to send message: ${response.statusCode}');
    }
  }

  /// GET: チャット履歴の取得（オプションでセッションID指定可能）
  static Future<List<dynamic>> fetchMessages({required int chatSessionId}) async {
    final uri = Uri.parse('$baseUrl?chat_session_id=$chatSessionId');

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch messages');
    }
  }

  static Future<ChatSession?> createSession(String title) async {
    final uri = Uri.parse('http://localhost:3000/api/v1/chat_sessions');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'title': title}),
    );

    if (response.statusCode == 201) {
      final json = jsonDecode(response.body);
      return ChatSession.fromJson(json);
    } else {
      print("セッション作成失敗: ${response.statusCode}");
      return null;
    }
  }

  static Future<void> deleteSession(int sessionId) async {
    final uri = Uri.parse('http://localhost:3000/api/v1/chat_sessions/$sessionId');
    final response = await http.delete(uri);

    if (response.statusCode != 204) {
      throw Exception('セッション削除に失敗しました: ${response.statusCode}');
    }
  }

  static Future<void> renameSession(int sessionId, String newTitle) async {
    final uri = Uri.parse('http://localhost:3000/api/v1/chat_sessions/$sessionId');

    final response = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"title": newTitle}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to rename session: ${response.statusCode}');
    }
  }
}
