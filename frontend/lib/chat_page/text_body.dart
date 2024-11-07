//text_body.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:chatbot/chat_page/user_message.dart';
import 'package:chatbot/chat_page/ai_message.dart';
import 'package:chatbot/database/database_interface.dart';
import 'package:chatbot/database/database_service.dart';
import 'package:chatbot/globals.dart';

class TextBody extends StatefulWidget {
  final int chatId;
  final Key? key; // keyパラメータを追加

  TextBody({required this.chatId, this.key}) : super(key: key);

  @override
  TextBodyState createState() => TextBodyState();
}

class TextBodyState extends State<TextBody> {
  List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    loadMessages(widget.chatId);
  }

  void _scrollToBottom() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollToEnd();
      }
    });
  }

  void _scrollToEnd() {
    Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (_scrollController.hasClients) {
        double maxScroll = _scrollController.position.maxScrollExtent;
        double currentScroll = _scrollController.position.pixels;

        if (currentScroll < maxScroll) {
          _scrollController.animateTo(
            maxScroll,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          timer.cancel(); // 最後までスクロールしたらタイマーを止める
        }
      }
    });
  }

  Future<void> loadMessages(int chatId) async {
    // データベースからメッセージを取得
    final messages = await db.getChatMessages(chatId);
    setState(() {
      _messages = messages;
    });
    _scrollToBottom(); // メッセージを読み込んだ後にスクロール
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController, // スクロールロジックを使うための設定
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        if (message['is_user'] == 1) {
          return user_message(message['content']);
        } else {
          return ai_message(message['content']);
        }
      },
    );
  }
}
