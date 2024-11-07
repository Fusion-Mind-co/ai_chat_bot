// api_connect.dart

import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:chatbot/globals.dart';

// トークン数を取得する関数
Future<int> fetchTokenCount(String text) async {
  if (serverUrl == null) {
    print('サーバーURLが見つかりません。');
    throw Exception('サーバーURLが見つかりません。');
  }

  print('トークン化リクエスト送信: $text'); // リクエストの内容をログに出力

  try {
    final response = await http.post(
      Uri.parse('$serverUrl/tokenize'), // サーバーURLを使用
      headers: {"Content-Type": "application/json"},
      body: json.encode({'text': text}),
    ).timeout(Duration(seconds: 10)); // タイムアウトを設定

    print('トークン化レスポンス受信: ${response.statusCode}'); // ステータスコードをログに出力

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('トークン数取得成功: ${responseData['tokens']}'); // トークン数をログに出力
      return responseData['tokens'];
    } else {
      print('トークン数取得失敗: ${response.body}'); // エラーメッセージをログに出力
      throw Exception('Failed to load token count');
    }
  } catch (e) {
    print('通信エラー: $e'); // 通信エラーをログに出力
    throw Exception('Failed to load token count');
  }
}

// トークン数を取得するためのメイン関数
Future<int> getToken(String text) async {
  // .envファイルの読み込み


  print('サーバーURL: $serverUrl'); // サーバーURLを確認

  final send_text = text;
  print('送信テキスト: $send_text'); // 送信するテキストをログに出力

  try {
    return await fetchTokenCount(send_text);
  } catch (e) {
    print('トークン取得に失敗しました: $e'); // エラーメッセージをログに出力
    throw e;
  }
}
