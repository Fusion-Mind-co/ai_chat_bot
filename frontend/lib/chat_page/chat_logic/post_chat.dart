// post_chat.dart

import 'package:chatbot/globals.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:chatbot/app.dart';
import 'package:chatbot/chat_page/api/api_connect.dart';
import 'package:chatbot/chat_page/api/cost_logic.dart';
import 'dart:convert';
import 'package:chatbot/chat_page/chat_logic/chat_history.dart';
import 'dart:async';

Future<Stream<String>> postChatGPTStream(String text) async {
  print("postChatGPTStream関数");

  var url = Uri.https("api.openai.com", "/v1/chat/completions");
  final client = http.Client();
  final streamController = StreamController<String>();

  try {
    addMessage("user", text);
    final chatHistory = getChatHistory();

    final requestBody = json.encode({
      "model": globalSelectedModel,
      "messages": chatHistory,
      "max_tokens": answer_GPT_token_length,
      "stream": true,
    });

    final request = http.Request('POST', url);
    request.headers.addAll({
      "Content-Type": "application/json",
      "Authorization": "Bearer $myToken",
      "Accept": "text/event-stream",
    });
    request.body = requestBody;

    final response = await client.send(request);
    print('レスポンスステータス: ${response.statusCode}');

    if (response.statusCode == 200) {
      String fullMessage = '';

      response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (String line) async {
          if (line.startsWith('data: ') && line != 'data: [DONE]') {
            try {
              final data = json.decode(line.substring(6));
              final content = data['choices'][0]['delta']['content'] ?? '';
              if (content.isNotEmpty) {
                print('コンテンツ追加: $content');
                fullMessage += content;
                streamController.add(content);
              }
            } catch (e) {
              print('JSONパースエラー: $e');
            }
          } else if (line == 'data: [DONE]') {
            print('ストリーム完了');
            print('完全なメッセージ: $fullMessage');
            addMessage("assistant", fullMessage);
            await Future.delayed(Duration(milliseconds: 100)); // 遅延を追加
            await streamController.close();
          }
        },
        onDone: () {
          client.close();
        },
        onError: (error) {
          print('ストリームエラー: $error');
          streamController.addError(error);
          client.close();
        },
        cancelOnError: false,
      );

      return streamController.stream;
    } else {
      throw Exception('APIリクエストエラー: ${response.statusCode}');
    }
  } catch (e) {
    print('通信エラー: $e');
    streamController.addError(e);
    await streamController.close();
    client.close();
    rethrow;
  }
}

Future<String?> postChatGPT(String text) async {
  print("postChatGPT関数");

  var url = Uri.https(
    "api.openai.com",
    "/v1/chat/completions",
  );

  try {
    addMessage("user", text);
    final chatHistory = getChatHistory();
    print('postChatGPT: チャット履歴取得完了: $chatHistory'); // デバッグポイント

    final requestBody = json.encode({
      "model": globalSelectedModel,
      "messages": chatHistory,
      "max_tokens": answer_GPT_token_length,
    });

    print('リクエストボディ: $requestBody'); // デバッグポイント

    //ユーザーが投げた「履歴込みメッセージ(chatHistory)」のトークン数を計算
    String combinedMessages =
        chatHistory.map((message) => message['content']).join(' ');

    int userTokenCount = await getToken(combinedMessages);
    print('ユーザーが投げたトークン数: $userTokenCount'); // デバッグポイント

    final response = await http
        .post(
          url,
          body: requestBody,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $myToken"
          },
        )
        .timeout(Duration(seconds: time_out_value))
        .catchError((error) {
          print('HTTPリクエストエラー: $error');
          print('time_out_value: $time_out_value');
        });

    print('postChatGPT: レスポンス受信: ${response.statusCode}');

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      String answer = data['choices'][0]['message']['content'];
      print('postChatGPT: GPTからの回答: $answer'); // デバッグポイント

      int GPTtokenCount = await getToken(answer);
      print('GPTからの回答トークン数: $GPTtokenCount'); // デバッグポイント

      int user_text_length = combinedMessages.length;
      int gpt_text_length = answer.length;
      CostManagement(userTokenCount, GPTtokenCount, globalSelectedModel,
          user_text_length, gpt_text_length);

      addMessage("assistant", answer);
      return answer;
    } else {
      print('サーバーエラー: ${response.statusCode}'); // デバッグポイント
      return null; // エラーが発生した場合はnullを返す
    }
  } catch (e) {
    print('通信エラー: $e'); // デバッグポイント
    return null;
  }
}

// chatタイトルをaiで生成する関数

Future<String> generateChatTitle(String firstMessage) async {
  var url = Uri.https("api.openai.com", "/v1/chat/completions");

  try {
    final requestBody = json.encode({
      "model": "gpt-3.5-turbo",
      "messages": [
        {
          "role": "system",
          "content": "チャット内容から適切なタイトルを20文字以内で生成してください。余計な説明は不要です。"
        },
        {"role": "user", "content": "以下のチャット内容のタイトルを生成してください：\n$firstMessage"}
      ],
      "max_tokens": 50,
    });

    final response = await http
        .post(
          url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $myToken"
          },
          body: requestBody,
        )
        .timeout(Duration(seconds: time_out_value));

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      String title = data['choices'][0]['message']['content'];
      return title.trim();
    } else {
      print('タイトル生成エラー: ${response.statusCode}');
      return "新しいchat";
    }
  } catch (e) {
    print('タイトル生成でエラーが発生: $e');
    return "新しいchat";
  }
}
