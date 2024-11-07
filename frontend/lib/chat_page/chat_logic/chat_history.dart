// chat_history.dart

import 'package:chatbot/globals.dart';
import 'package:chatbot/database/database_interface.dart'; // DatabaseInterfaceをインポート
import 'package:chatbot/database/database_service.dart';
import 'package:chatbot/main.dart'; // DatabaseServiceをインポート

List<Map<String, String>> _chatHistory = [];

// チャット履歴を取得
List<Map<String, String>> getChatHistory() {
  return _chatHistory;
}

// データベースからチャット履歴を取得
Future<void> loadChatHistoryFromDB(int chatId) async {
  final List<Map<String, dynamic>> history = await db.getChatMessages(chatId); // データベースからメッセージを取得
  _chatHistory = history.map((message) {
    return {
      "role": message['is_user'] == 1 ? "user" : "assistant",
      "content": message['is_user'] == 1
          ? "$global_user_name: ${message['content']}"
          : message['content'].toString()
    };
  }).toList();

  _trimChatHistoryIfNeeded(); // トリミングを行う
  print('chatHistory : ${_chatHistory}');
}

// チャット履歴にメッセージを追加
void addMessage(String role, String content) {
  String displayRole = role == "user" ? "user" : role;
  String displayContent = role == "user" ? "$global_user_name: $content" : content;

  _chatHistory.add({"role": displayRole, "content": displayContent});
  _trimChatHistoryIfNeeded(); // トリミングを行う
}

// チャット履歴のトリミング
void _trimChatHistoryIfNeeded() {
  int totalLength = _calculateTotalCharacterCount();
  while (totalLength > chatHistoryMaxLength && _chatHistory.isNotEmpty) {
    _chatHistory.removeAt(0); // 最も古いメッセージを削除
    totalLength = _calculateTotalCharacterCount(); // 再度文字数を計算
  }
}

// 履歴の文字数を計算
int _calculateTotalCharacterCount() {
  return _chatHistory.fold(0, (sum, message) => sum + message['content']!.length);
}

// ユーザーネームを設定
void setUserName(String? global_user_name) {}
