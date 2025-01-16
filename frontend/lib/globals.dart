// globals.dart

import 'dart:convert';
import 'package:chatbot/database/sqlite_database.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:chatbot/database/postgreSQL_logic.dart';  
import 'package:chatbot/app.dart';  
import 'package:http/http.dart' as http;


String? global_DB_name;
String? globalEmail;
double? globalMonthlyCost;
String? global_username;
String? globalPlan;
double globalMaxMonthlyCost = 0;
String globalSortOrder = 'created_at ASC';
String globalSelectedModel = 'gpt-3.5-turbo';
int chatHistoryMaxLength = 0; 
int input_text_length = 0;

late SQLiteDatabase db;





List<Map<String, String>> chatHistory = [];


// ⓵.envファイルからサーバーURLの読み込み===============================================


// サーバーURLを定義するグローバル変数
String serverUrl = '';
Future<void> loadEnvironment() async {
  await dotenv.load();
  serverUrl = dotenv.env['SERVER_URL'] ?? 'http://localhost:5000'; // 開発用URL（デフォルト）
  print('serverUrl = $serverUrl');
}


// ⓶バックエンドからセキュアな値を取得===============================================

String googleClientId = '';
String myToken = '';
String Gemini_api_key = '';
int loginValue = 0;
String loginUnit = '';

// main.dart main()関数内で呼び出し

Future<void> loadBackendConfig() async {
  print('バックエンドからキーを読み込み');
  final url = Uri.parse('$serverUrl/api/get-secret-config');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final Map<String, dynamic> config = json.decode(response.body);
    googleClientId = config['GOOGLE_CLIENT_ID'];
    myToken = config['MY_TOKEN'];
    Gemini_api_key = config['GEMINI_API_KEY'];
    loginValue = int.parse(config['LOGIN_VALUE']);
    loginUnit = config['LOGIN_UNIT'];
    print('設定が正常に読み込まれました');
    print(Gemini_api_key);
  } else {
    print('設定の読み込みに失敗しました: ${response.statusCode}');
  }
}


// ================================================================================

                                // 編集中

// ================================================================================

// モデルがどちらのAIモデルの系統かを判別する関数

bool isGeminiModel(String model) {
  return model.toLowerCase().contains('gemini');
}

bool isOpenAIModel(String model) {
  return model.toLowerCase().contains('gpt');
}

// ================================================================================

                                // 編集中

// ================================================================================


//プラン
Map<String, int> planPrices = {
  'Free': 0,
  'Standard': 1950,
};

//契約内容
String? nextProcessType; // ユーザーの次のプロセスタイプを保持
DateTime? nextProcessDate; // 次回処理日を保持

// globals.dart に追加
DateTime? globalNextProcessDate;
String? globalNextProcessType;


// ログイン記憶保持期間の設定
class LoginExpiration {
  static Duration getLoginExpiration() {
    // グローバル変数を使用
    if (loginValue > 0 && loginUnit.isNotEmpty) {
      switch (loginUnit) {
        case 'minutes': return Duration(minutes: loginValue);
        case 'hours': return Duration(hours: loginValue);
        case 'days': return Duration(days: loginValue);
        default: return Duration(days: 7); // デフォルト値
      }
    }
    return Duration(days: 7); // 値が取得できない場合のデフォルト値
  }
}


// api_config.dart

// チャットの会話履歴の最大文字数
// 会話のつながりを把握するため

// GPTからの回答の制限トークン数
// 大きすぎるとエラーになる
// 小さすぎると文章が途中で途切れる
int answer_GPT_token_length = 2000;


List<String> AI_Models = ['gpt-4o-mini' , 'gpt-3.5-turbo' , 'gpt-4o','gemini-1.5-flash','gemini-1.5-pro'];

// doubleは小数点を扱える型
// 公式HPより実際のレート

// https://openai.com/api/pricing/

double gpt_4o_mini_in_cost = 0.3;
double gpt_4o_mini_out_cost = 1.2;

double gpt_3_5_turbo_in_cost = 3.0;
double gpt_3_5_turbo_out_cost = 6.0;

double gpt_4o_in_cost = 3.75;
double gpt_4o_out_cost = 15.0;


// GPT応答時タイムアウトエラー時間設定(秒)
int time_out_value = 60;
