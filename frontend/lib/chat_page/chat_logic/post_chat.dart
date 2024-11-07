// post_chat.dart

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:chatbot/app.dart';
import 'package:chatbot/chat_page/api/api_config.dart';
import 'package:chatbot/chat_page/api/api_connect.dart';
import 'package:chatbot/chat_page/api/cost_logic.dart';
import 'dart:convert';
import 'package:chatbot/chat_page/chat_logic/chat_history.dart';


Future<String?> postChatGPT(String text) async {
  print("postChatGPT関数");
  
  final myToken = dotenv.get('MY_TOKEN');

  var url = Uri.https(
    "api.openai.com",
    "/v1/chat/completions",
  );

  try {
    addMessage("user", text);
    final chatHistory = getChatHistory();
    print('postChatGPT: チャット履歴取得完了: $chatHistory'); // デバッグポイント

    final requestBody = json.encode({
      "model": chatGPT_MODEL,
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
      CostManagement(userTokenCount, GPTtokenCount, chatGPT_MODEL,
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
