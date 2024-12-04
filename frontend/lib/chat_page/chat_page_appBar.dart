// chat_page_appBar.dart

import 'package:flutter/material.dart';
import 'package:chatbot/app.dart';
import 'package:chatbot/globals.dart'; // グローバル変数をインポート
import 'package:chatbot/main.dart'; // DatabaseServiceをインポート

class ChatPageAppbar extends StatefulWidget implements PreferredSizeWidget {
  final int chatId;

  ChatPageAppbar({required this.chatId});

  @override
  ChatPageAppbarState createState() => ChatPageAppbarState();

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

class ChatPageAppbarState extends State<ChatPageAppbar> {
  bool _hasError = false;
  TextEditingController _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadChatTitle();
  }

  Future<void> _loadChatTitle() async {
    final data = await db.getSelectChatById(widget.chatId); // データベースからチャットタイトルを取得
    if (data != null) {
      setState(() {
        _titleController.text = data['title'] ?? '';
      });
    }
  }

  Future<void> updateTitle(String title) async {
    if (title.isEmpty) {
      setState(() {
        _hasError = true;
      });
      return;
    }

    setState(() {
      _hasError = false;
    });

    if (_titleController.text != null) {
      await db.updateChatTitle(title, widget.chatId); // データベースにタイトルを更新
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: TextField(
        controller: _titleController,
        decoration: InputDecoration(
          labelText: _hasError ? 'エラー: タイトルを入力してください' : '${chatGPT_MODEL}  ${globalMonthlyCost?.toInt() ?? 0}/${globalMaxMonthlyCost?.toInt() ?? 0}',
          labelStyle: TextStyle(
            color: _hasError ? Colors.red : null,
          ),
          contentPadding: EdgeInsets.only(bottom: 8.0, top: 16.0),
          border: InputBorder.none,
        ),
        style: TextStyle(
          color: _hasError
              ? Colors.red
              : Theme.of(context).textTheme.bodyLarge?.color ?? const Color.fromARGB(255, 120, 120, 120),
        ),
        onChanged: (value) {
          updateTitle(value);
        },
      ),
    );
  }
}
