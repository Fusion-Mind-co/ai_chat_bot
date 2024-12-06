// input_chat.dart

import 'package:chatbot/chat_page/chat_page_appBar.dart';
import 'package:flutter/material.dart';
import 'package:chatbot/chat_page/chat_logic/post_chat.dart';
import 'package:chatbot/chat_page/text_body.dart';
import 'package:chatbot/globals.dart';
import 'package:chatbot/main.dart'; // グローバルな db をインポート

final chatController = TextEditingController();

class InputChat extends StatefulWidget {
  final int chatId;
  final GlobalKey<TextBodyState> textBodyKey;
  final GlobalKey<ChatPageAppbarState> appBarKey; // AppBarのKeyを追加
  final Function loadingConfig;

  InputChat({
    required this.chatId,
    required this.textBodyKey,
    required this.appBarKey, // 追加
    required this.loadingConfig,
  });

  @override
  _InputChatState createState() => _InputChatState();
}

class _InputChatState extends State<InputChat> {
  String? _errorMessage;

  // エラーメッセージの表示を管理するメソッド
  void setErrorMessage(String? errorMessage) {
    setState(() {
      _errorMessage = errorMessage;
    });
  }

  //==============ローディングくるくるアニメーション関数========================
  void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Loading..."),
            ],
          ),
        );
      },
    );
  }

  void hideLoadingDialog(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop(); // ダイアログを閉じる
  }
  //========================================================================


  Future<void> getInputChat() async {
    print('getInputChat() 開始');

    String inputChat = chatController.text;
    if (inputChat.isEmpty) {
      setErrorMessage("メッセージを入力してください");
      return;
    }

    showLoadingDialog(context);

    try {
      final chatData = await db.getSelectChatById(widget.chatId);
      final messages = await db.getChatMessages(widget.chatId);
      bool isFirstChat = messages.isEmpty;
      bool isDefaultTitle = chatData?['title'] == "新しいchat";

      String? gptAnswer = await postChatGPT(inputChat);

      if (gptAnswer != null) {
        int userMessageId = await db.postChatDB(widget.chatId, inputChat, true, null);
        await db.postChatDB(widget.chatId, gptAnswer, false, userMessageId);

        // 初回チャットでデフォルトタイトルの場合、タイトルを自動生成し即時反映
        if (isFirstChat && isDefaultTitle) {
          String newTitle = await generateChatTitle(inputChat);
          await db.updateChatTitle(newTitle, widget.chatId);
          // AppBarのタイトルを更新
          widget.appBarKey.currentState?.updateTitleText(newTitle);
        }

        widget.textBodyKey.currentState?.loadMessages(widget.chatId);
        widget.loadingConfig();
        chatController.clear();
        await db.updateChatUpdatedAt(widget.chatId);
        setErrorMessage(null);
      } else {
        setErrorMessage('GPTの応答が取得できませんでした');
      }
    } catch (e) {
      setErrorMessage('通信エラーが発生しました');
      print('通信エラーが発生しました: $e');
    } finally {
      hideLoadingDialog(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          // パディングを追加
          padding: EdgeInsets.symmetric(horizontal: 10.0), // 左右に16.0のパディング
          child: TextField(
            controller: chatController,
            maxLength: input_text_length,
            maxLines: null,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black54
                  : Colors.white,
              labelText: _errorMessage ?? 'メッセージを入力してください',
              labelStyle: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white60
                    : Colors.black54,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white30
                      : Colors.black26,
                ),
                borderRadius: BorderRadius.circular(20.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 2.0,
                ),
                borderRadius: BorderRadius.circular(20.0),
              ),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            getInputChat();
          },
          child: Text('送信'),
        ),
        Text(
          'この応答には誤りが含まれる可能性があります。',
          style: TextStyle(fontSize: 10, color: Colors.grey),
          textAlign: TextAlign.center,
        )
      ],
    );
  }

  updateGlobalMonthlyCost() {} // グローバルコストの更新メソッド
}
