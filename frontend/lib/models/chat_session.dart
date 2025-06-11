
class ChatSession {
  final int id;
  final String title;
  final DateTime createdAt;

  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'],
      title: json['title'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'created_at': createdAt.toIso8601String(),
    };
  }
}