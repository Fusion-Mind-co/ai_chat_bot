// chat_page.dart
import 'package:flutter/material.dart';
import 'package:chatbot/chat_page/ai_message.dart';
import 'package:chatbot/chat_page/chat_logic/chat_history.dart';
import 'package:chatbot/chat_page/chat_page_appBar.dart';
import 'package:chatbot/chat_page/input_chat.dart';
import 'package:chatbot/chat_page/text_body.dart';
import 'package:chatbot/database/postgreSQL_logic.dart';
import 'package:chatbot/globals.dart'; // グローバル変数をインポート

class ChatPage extends StatefulWidget {
  final Function loadingConfig; // コールバックを受け取る
  final int chatId;

  ChatPage({required this.chatId, required this.loadingConfig});

  @override
  ChatPageState createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  Map<String, dynamic>? chatData;

  // GlobalKeyを定義
  final GlobalKey<TextBodyState> _textBodyKey = GlobalKey<TextBodyState>();
  final GlobalKey<ChatPageAppbarState> _appBarKey = GlobalKey<ChatPageAppbarState>();

  @override
  void initState() {
    super.initState();
    _initializeChat();
    updateMonthlyCost();
  }

  Future<void> _initializeChat() async {
    if (global_user_name != null) {
      setUserName(global_user_name);
    }
    await _loadChatHistory();
  }

  Future<void> updateMonthlyCost() async {
    double? newCost = await fetchMonthlyCost(); // 非同期処理を完了させる
    if (newCost != null) {
      setState(() {
        globalMonthlyCost = newCost; // グローバル変数を更新
      });
    }
  }

  Future<void> _loadChatHistory() async {
    await loadChatHistoryFromDB(widget.chatId);
    setState(() {});
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: ChatPageAppbar(
          chatId: widget.chatId,
          key: _appBarKey, // GlobalKeyを設定
        ),
        body: Column(
          children: [
            Expanded(
              child: TextBody(chatId: widget.chatId, key: _textBodyKey),
            ),
            InputChat(
              chatId: widget.chatId,
              textBodyKey: _textBodyKey,
              appBarKey: _appBarKey, // AppBarのKeyを渡す
              loadingConfig: widget.loadingConfig,
            ),
          ],
        ),
      ),
    );
  }
}
