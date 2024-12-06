//text_body.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:chatbot/chat_page/user_message.dart';
import 'package:chatbot/chat_page/ai_message.dart';
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
  String _currentStreamingMessage = '';
  bool _isStreaming = false;
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
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> loadMessages(int chatId) async {
    // データベースからメッセージを取得
    final messages = await db.getChatMessages(chatId);
    if (mounted) {
      setState(() {
        _messages = messages;
      });
      // 少し遅延を入れてスクロール
      await Future.delayed(Duration(milliseconds: 100));
      _scrollToBottom();
    }
  }

  // ストリーミングメッセージを追加するメソッド
  void addStreamingMessage(
      Stream<String> messageStream, Function(String) onComplete) {
    var buffer = '';
    print('ストリーミング開始');

    // 既存のメッセージを保持
    final currentMessages = List<Map<String, dynamic>>.from(_messages);

    setState(() {
      _messages = [
        ...currentMessages,
        {
          'is_user': 0,
          'content': '',
          'is_streaming': true,
        }
      ];
    });

    messageStream.listen(
      (String chunk) {
        print('チャンク受信: $chunk');
        setState(() {
          buffer += chunk;
          _messages.last['content'] = buffer;
        });
        _scrollToBottom();
      },
      onError: (error) {
        print('ストリーミングエラー: $error');
        setState(() {
          _messages.last['is_streaming'] = false;
        });
      },
      onDone: () {
        print('ストリーミング完了: $buffer');
        if (mounted) {
          setState(() {
            _messages.last['is_streaming'] = false;
            _messages.last['content'] = buffer;
          });
          onComplete(buffer);
        }
      },
      cancelOnError: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        if (message['is_user'] == 1) {
          return user_message(message['content']);
        } else {
          // ストリーミング中のメッセージの場合
          if (message['is_streaming'] == true) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Container(
                margin:
                    EdgeInsets.only(left: 10, top: 15, right: 30, bottom: 15),
                padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 255, 248, 238),
                  borderRadius: BorderRadius.circular(15.0),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey,
                        blurRadius: 5,
                        offset: Offset(2, 3)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message['content'],
                      style: TextStyle(color: Colors.black, fontSize: 16.0),
                    ),
                    SizedBox(height: 8),
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return ai_message(message['content']);
        }
      },
    );
  }
}
