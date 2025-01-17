import 'package:flutter/material.dart';
import 'package:chatbot/chat_page/ai_message.dart';
import 'package:chatbot/chat_page/chat_logic/chat_history.dart';
import 'package:chatbot/chat_page/chat_page_appBar.dart';
import 'package:chatbot/chat_page/input_chat.dart';
import 'package:chatbot/chat_page/text_body.dart';
import 'package:chatbot/database/sqlite_database.dart';
import 'package:chatbot/globals.dart';

class ChatPage extends StatefulWidget {
  final Function loadingConfig;
  final int chatId;

  ChatPage({required this.chatId, required this.loadingConfig});

  @override
  ChatPageState createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  final SQLiteDatabase _database = SQLiteDatabase.instance;
  final GlobalKey<TextBodyState> _textBodyKey = GlobalKey<TextBodyState>();
  final GlobalKey<ChatPageAppbarState> _appBarKey =
      GlobalKey<ChatPageAppbarState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void setLoading(bool isLoading) {
    setState(() {
      _isLoading = isLoading;
    });
  }

  Future<void> _initializeChat() async {
    try {
      print('チャットページの初期化開始 - chatId: ${widget.chatId}');
      await _database.database;
      print('データベース接続確認完了');

      await _loadChatHistory();
      print('チャットページの初期化完了');
    } catch (e) {
      print('チャットページの初期化でエラー: $e');
    }
  }

  Future<void> _loadChatHistory() async {
    try {
      print('チャット履歴読込開始 - chatId: ${widget.chatId}');
      await _database.database;
      await ChatHistory.loadFromDB(widget.chatId);
      setState(() {});
      print('チャット履歴読込完了');
    } catch (e) {
      print('チャット履歴読込でエラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: ChatPageAppbar(
            chatId: widget.chatId,
            key: _appBarKey,
          ),
          body: Column(
            children: [
              Expanded(
                child: TextBody(chatId: widget.chatId, key: _textBodyKey),
              ),
              InputChat(
                chatId: widget.chatId,
                textBodyKey: _textBodyKey,
                appBarKey: _appBarKey,
                loadingConfig: setLoading,
              ),
            ],
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black54,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}
