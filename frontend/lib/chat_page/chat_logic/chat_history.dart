// chat_history.dart

import 'package:chatbot/database/sqlite_database.dart';
import 'package:chatbot/globals.dart';

class ChatMessage {
  final String role;
  final String content;
  final bool isUser;

  ChatMessage({
    required this.role,
    required this.content,
    required this.isUser,
  });

  Map<String, dynamic> toOpenAIFormat() {
    return {
      "role": isUser ? "user" : "assistant",
      "content": isUser ? "$global_username: $content" : content,
    };
  }

  Map<String, dynamic> toGeminiFormat() {
    return {
      "parts": [{"text": isUser ? "$global_username: $content" : content}],
      "role": isUser ? "user" : "model"
    };
  }
}

class ChatHistory {
  static final ChatHistory _instance = ChatHistory._internal();
  factory ChatHistory() => _instance;
  ChatHistory._internal();

  static ChatHistory get instance => _instance;

  final List<ChatMessage> _messages = [];
  final SQLiteDatabase _database = SQLiteDatabase.instance;

  List<ChatMessage> get messages => List.unmodifiable(_messages);

  static Future<void> loadFromDB(int chatId) async {
    await _instance._loadFromDB(chatId);
  }

  Future<void> _loadFromDB(int chatId) async {
    final List<Map<String, dynamic>> history = 
        await _database.getChatMessages(chatId);
    
    _messages.clear();
    _messages.addAll(history.map((message) => ChatMessage(
      role: message['is_user'] == 1 ? "user" : "assistant",
      content: message['content'].toString(),
      isUser: message['is_user'] == 1,
    )));

    _trimIfNeeded();
  }

  static void addMessage(String role, String content) {
    _instance._addMessage(role, content);
  }

  void _addMessage(String role, String content) {
    bool isUser = role == "user";
    _messages.add(ChatMessage(
      role: role,
      content: content,
      isUser: isUser,
    ));
    _trimIfNeeded();
  }

  void _trimIfNeeded() {
    int totalLength = _calculateTotalLength();
    while (totalLength > chatHistoryMaxLength && _messages.isNotEmpty) {
      _messages.removeAt(0);
      totalLength = _calculateTotalLength();
    }
  }

  int _calculateTotalLength() {
    return _messages.fold(0, (sum, msg) => sum + msg.content.length);
  }

  static List<Map<String, dynamic>> getFormattedHistory({required bool isGemini}) {
    return _instance._getFormattedHistory(isGemini);
  }

  List<Map<String, dynamic>> _getFormattedHistory(bool isGemini) {
    if (_messages.isEmpty) return [];

    final maxMessages = 10; // 履歴の最大メッセージ数を制限
    final startIdx = _messages.length > maxMessages ? 
        _messages.length - maxMessages : 0;
    
    return _messages
        .sublist(startIdx)
        .map((msg) => isGemini ? msg.toGeminiFormat() : msg.toOpenAIFormat())
        .toList();
  }
}