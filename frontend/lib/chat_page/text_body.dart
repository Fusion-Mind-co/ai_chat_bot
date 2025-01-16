import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:chatbot/chat_page/user_message.dart';
import 'package:chatbot/chat_page/ai_message.dart';
import 'package:chatbot/database/sqlite_database.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class TextBody extends StatefulWidget {
  final int chatId;
  final Key? key;

  TextBody({required this.chatId, this.key}) : super(key: key);

  @override
  TextBodyState createState() => TextBodyState();
}

class TextBodyState extends State<TextBody> {
  final SQLiteDatabase _database = SQLiteDatabase.instance;
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    loadMessages(widget.chatId);
  }

  Future<void> loadMessages(int chatId) async {
    try {
      print('メッセージ読込開始 - chatId: $chatId');
      final messages = await _database.getChatMessages(chatId);

      if (mounted) {
        setState(() {
          _messages = messages;
          print('メッセージを更新: ${messages.length}件');
        });
        await Future.delayed(Duration(milliseconds: 100));
        _scrollToBottom();
      }
    } catch (e) {
      print('メッセージ読込でエラー: $e');
    }
  }

  void _scrollToBottom() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void addStreamingMessage(
      Stream<String> messageStream, Function(String) onComplete) {
    var buffer = '';
    print('ストリーミング開始');

    setState(() {
      _messages = List<Map<String, dynamic>>.from(_messages)
        ..add({
          'is_user': 0,
          'content': '',
          'is_streaming': true,
        });
    });

    messageStream.listen(
      (String chunk) {
        if (mounted) {
          setState(() {
            buffer += chunk;
            _messages.last['content'] = buffer;
          });
          _scrollToBottom();
        }
      },
      onError: (error) {
        print('ストリーミングエラー: $error');
        if (mounted) {
          setState(() => _messages.last['is_streaming'] = false);
        }
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
        } else if (message['is_streaming'] == true) {
          return buildStreamingMessage(message['content']);
        } else {
          return ai_message(message['content']);
        }
      },
    );
  }

  Widget buildStreamingMessage(String content) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(left: 10, top: 15, right: 30, bottom: 15),
        padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 255, 248, 238),
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(color: Colors.grey, blurRadius: 5, offset: Offset(2, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              content,
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
}
