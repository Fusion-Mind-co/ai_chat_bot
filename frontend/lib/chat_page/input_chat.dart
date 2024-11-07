// input_chat.dart

import 'package:flutter/material.dart';
import 'package:chatbot/chat_page/api/api_config.dart';
import 'package:chatbot/chat_page/chat_logic/post_chat.dart';
import 'package:chatbot/chat_page/text_body.dart';
import 'package:chatbot/globals.dart';
import 'package:chatbot/main.dart'; // グローバルな db をインポート

final chatController = TextEditingController();

class InputChat extends StatefulWidget {
  final int chatId;
  final GlobalKey<TextBodyState> textBodyKey;
  final Function loadingConfig; // コールバックを受け取る

  InputChat({
    required this.chatId,
    required this.textBodyKey,
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
    print(
        'globalMaxMonthlyCost = $globalMaxMonthlyCost   globalMonthlyCost = $globalMonthlyCost ');

    // 月間コスト上限のチェック
    if (globalMaxMonthlyCost <= (globalMonthlyCost ?? 0)) {
      setErrorMessage('上限に達しているため利用できません');
      return;
    }

    String inputChat = chatController.text;
    if (inputChat.isEmpty) {
      setErrorMessage("メッセージを入力してください");
      return;
    }

    showLoadingDialog(context);

    try {
      String? gptAnswer = await postChatGPT(inputChat);

      if (gptAnswer != null) {
        //　ユーザーメッセージをデータベースに保存
        int userMessageId =
            await db.postChatDB(widget.chatId, inputChat, true, null);
        //　GPTメッセージをデータベースに保存
        await db.postChatDB(widget.chatId, gptAnswer, false, userMessageId);

        // UIの更新や設定の再読み込み
        widget.textBodyKey.currentState?.loadMessages(widget.chatId);
        widget.loadingConfig();
        chatController.clear();
        await db.updateChatUpdatedAt(widget.chatId);
        setErrorMessage(null); // エラーメッセージをリセット
      } else {
        setErrorMessage('GPTの応答が取得できませんでした');
      }
    } catch (e) {
      setErrorMessage('通信エラーが発生しました');
      print('通信エラーが発生しました: $e'); // 例外の詳細をログに表示
    } finally {
      await updateGlobalMonthlyCost(); // グローバルコストを更新
      hideLoadingDialog(context); // ローディングダイアログを閉じる
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
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
