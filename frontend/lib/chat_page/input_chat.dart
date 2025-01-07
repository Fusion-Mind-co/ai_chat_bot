// input_chat.dart

import 'package:chatbot/chat_page/chat_page_appBar.dart';
import 'package:flutter/material.dart';
import 'package:chatbot/chat_page/chat_logic/post_chat.dart';
import 'package:chatbot/chat_page/text_body.dart';
import 'package:chatbot/globals.dart';
import 'package:chatbot/main.dart';

final chatController = TextEditingController();

class InputChat extends StatefulWidget {
  final int chatId;
  final GlobalKey<TextBodyState> textBodyKey;
  final GlobalKey<ChatPageAppbarState> appBarKey;
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

  Future<void> getInputChat() async {
    print('getInputChat() 開始');

    // キーボードを隠す
    FocusScope.of(context).unfocus();

    String inputChat = chatController.text;
    if (inputChat.isEmpty) {
      setErrorMessage("メッセージを入力してください");
      return;
    }

    try {
      // チャットが初回かつタイトルが初期値かチェック
      final chatData = await db.getSelectChatById(widget.chatId);
      final messages = await db.getChatMessages(widget.chatId);
      bool isFirstChat = messages.isEmpty;
      bool isDefaultTitle = chatData?['title'] == "新しいchat";

      // 入力フィールドをクリアして、ローディング状態を解除
      chatController.clear();
      setErrorMessage(null);

      // ユーザーメッセージをデータベースに保存し、UIに即時反映
      int userMessageId =
          await db.postChatDB(widget.chatId, inputChat, true, null);
      widget.textBodyKey.currentState?.loadMessages(widget.chatId);

      try {
        // ストリーミングレスポンスを取得
        Stream<String> gptStream = await postChatGPTStream(inputChat);

        // テキストボディにストリーミングメッセージを追加
        widget.textBodyKey.currentState?.addStreamingMessage(
          gptStream,
          (String completeMessage) async {
            // メッセージ完了時の処理
            await db.postChatDB(
                widget.chatId, completeMessage, false, userMessageId);

            // 初回チャットの場合のタイトル生成
            if (isFirstChat && isDefaultTitle) {
              String newTitle = await generateChatTitle(inputChat);
              await db.updateChatTitle(newTitle, widget.chatId);
              widget.appBarKey.currentState?.updateTitleText(newTitle);
            }

            await db.updateChatUpdatedAt(widget.chatId);
            widget.loadingConfig();
          },
        );
      } catch (e) {
        print('GPTストリーミングエラー: $e');
        setErrorMessage('GPTの応答が取得できませんでした');
      }
    } catch (e) {
      setErrorMessage('通信エラーが発生しました');
      print('通信エラーが発生しました: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.0),
          child: TextField(
            controller: chatController,
            maxLength: input_text_length,
            maxLines: null,
            decoration: InputDecoration(
              filled: true,
              labelText: _errorMessage ?? 'メッセージを入力してください',
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
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
          style: TextStyle(fontSize: 10), // サイズのみ指定
          textAlign: TextAlign.center,
        )
      ],
    );
  }
}
