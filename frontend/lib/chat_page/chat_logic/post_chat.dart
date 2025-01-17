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

// ＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝

// ChatGPTのポストロジック
// (ストリーミング対応)

// ＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝
Future<Stream<String>> postChatGPTStream(String text) async {
  print("postChatGPTStream関数");

  var url = Uri.https("api.openai.com", "/v1/chat/completions");
  final client = http.Client();
  final streamController = StreamController<String>();

  try {
    ChatHistory.addMessage("user", text);
    final messages = ChatHistory.getFormattedHistory(isGemini: false);

    final requestBody = json.encode({
      "model": globalSelectedModel,
      "messages": messages,
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
            ChatHistory.addMessage("assistant", fullMessage);
            await Future.delayed(Duration(milliseconds: 100));
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

// ＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝

// Geminiのポストロジック

// ＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝

Future<Map<String, dynamic>> postGemini(String input) async {
  try {
    // Gemini用のフォーマットで履歴を取得
    final formattedHistory = ChatHistory.getFormattedHistory(isGemini: true);
    
    // 現在のメッセージを追加
    formattedHistory.add({
      "parts": [{"text": "$global_username: $input"}],
      "role": "user"
    });

    // リクエストボディの構築
    final requestBody = json.encode({
      "contents": formattedHistory,
      "generationConfig": {
        "temperature": 0.7,
        "maxOutputTokens": answer_GPT_token_length,
      }
    });

    // APIリクエスト送信
    final response = await http.post(
      Uri.https('generativelanguage.googleapis.com',
          '/v1beta/models/$globalSelectedModel:generateContent'),
      headers: {
        "Content-Type": "application/json",
        "x-goog-api-key": Gemini_api_key,
      },
      body: requestBody,
    );

    // レスポンス処理
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final generatedText = data["candidates"][0]["content"]["parts"][0]["text"];
      return {"status": "success", "response": generatedText};
    } else {
      print('Gemini APIエラー: ${response.statusCode} - ${response.body}');
      throw Exception('APIエラー: ${response.statusCode}');
    }
  } catch (e) {
    print('Gemini処理エラー: $e');
    throw e;
  }
}

// トリミング関数
List<Map<String, dynamic>> trimChatHistory(
    List<Map<String, dynamic>> history, int maxTokens) {
  int currentTokens = 0;
  List<Map<String, dynamic>> trimmedHistory = [];

  for (var message in history.reversed) {
    int messageTokens = message["content"].length; // トークン数の概算
    if (currentTokens + messageTokens > maxTokens) break;
    trimmedHistory.insert(0, message); // 最新のメッセージから追加
    currentTokens += messageTokens;
  }

  return trimmedHistory;
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
