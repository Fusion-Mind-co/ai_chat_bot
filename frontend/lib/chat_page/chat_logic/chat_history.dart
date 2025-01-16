import 'package:chatbot/database/sqlite_database.dart';
import 'package:chatbot/globals.dart';

List<Map<String, String>> _chatHistory = [];
final SQLiteDatabase _database = SQLiteDatabase.instance;

List<Map<String, String>> getChatHistory() {
  return _chatHistory;
}

Future<void> loadChatHistoryFromDB(int chatId) async {
  final List<Map<String, dynamic>> history =
      await _database.getChatMessages(chatId);
  _chatHistory = history.map((message) {
    return {
      "role": message['is_user'] == 1 ? "user" : "assistant",
      "content": message['is_user'] == 1
          ? "$global_username: ${message['content']}"
          : message['content'].toString()
    };
  }).toList();

  _trimChatHistoryIfNeeded();
  print('chatHistory : ${_chatHistory}');
}

void addMessage(String role, String content) {
  String displayRole = role == "user" ? "user" : role;
  String displayContent =
      role == "user" ? "$global_username: $content" : content;

  _chatHistory.add({"role": displayRole, "content": displayContent});
  _trimChatHistoryIfNeeded(); // 長さを超えた場合のトリミング
}

void _trimChatHistoryIfNeeded() {
  int totalLength = _calculateTotalCharacterCount();
  while (totalLength > chatHistoryMaxLength && _chatHistory.isNotEmpty) {
    _chatHistory.removeAt(0);
    totalLength = _calculateTotalCharacterCount();
  }
}

int _calculateTotalCharacterCount() {
  return _chatHistory.fold(
      0, (sum, message) => sum + message['content']!.length);
}

void setUserName(String? global_username) {}

List<Map<String, String>> trimChatHistory(
    List<Map<String, String>> history, int maxTokens) {
  int totalTokens = 0;
  List<Map<String, String>> trimmedHistory = [];

  for (int i = history.length - 1; i >= 0; i--) {
    int messageTokens = history[i]["content"]?.length ?? 0; // 文字数を仮のトークン数として計算
    if (totalTokens + messageTokens > maxTokens) break;
    trimmedHistory.insert(0, history[i]);
    totalTokens += messageTokens;
  }

  return trimmedHistory;
}
