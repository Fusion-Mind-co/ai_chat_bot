// globals.dart

// グローバル化管理
import 'package:chatbot/database/sqlite_database.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

String? global_DB_name;
String? globalEmail;
double? globalMonthlyCost;
String? global_user_name;
String? globalPlan;
double globalMaxMonthlyCost = 0;
String globalSortOrder = 'created_at ASC';
int chatHistoryMaxLength = 1000; // 初期値を設定
int input_text_length = 200;



late SQLiteDatabase db;


// サーバーURLを定義するグローバル変数
String serverUrl = '';

// .envファイルの読み込みとサーバーURLの設定
Future<void> loadEnvironment() async {
  await dotenv.load();
  serverUrl = dotenv.env['SERVER_URL'] ?? 'http://localhost:5000'; // 開発用URL（デフォルト）
  print('serverUrl = $serverUrl');
}


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
  // テスト環境用（分単位）
  static const int testNormalLoginMinutes = 3;    // 通常ログイン: 〇分
  static const int testGoogleLoginMinutes = 3;    // Googleログイン: 〇分

  // 本番環境用（日単位）
  static const int prodNormalLoginDays = 30;     // 通常ログイン: 〇日
  static const int prodGoogleLoginDays = 30;    // Googleログイン: 〇日

  // 現在の環境設定
  static const bool isProduction = false;  // 環境フラグ（false: テスト, true: 本番）

  // 通常ログインの期限を取得
  static Duration getNormalLoginExpiration() {
    if (isProduction) {
      return Duration(days: prodNormalLoginDays);
    } else {
      return Duration(minutes: testNormalLoginMinutes);
    }
  }

  // Googleログインの期限を取得
  static Duration getGoogleLoginExpiration() {
    if (isProduction) {
      return Duration(days: prodGoogleLoginDays);
    } else {
      return Duration(minutes: testGoogleLoginMinutes);
    }
  }

  // 現在の設定を文字列で取得（デバッグ用）
  static String getCurrentSettings() {
    if (isProduction) {
      return '本番環境\n'
          '通常ログイン保持期間: $prodNormalLoginDays日\n'
          'Googleログイン保持期間: $prodGoogleLoginDays日';
    } else {
      return 'テスト環境\n'
          '通常ログイン保持期間: $testNormalLoginMinutes分\n'
          'Googleログイン保持期間: $testGoogleLoginMinutes分';
    }
  }
}


// api_config.dart

// チャットの会話履歴の最大文字数
// 会話のつながりを把握するため

// GPTからの回答の制限トークン数
// 大きすぎるとエラーになる
// 小さすぎると文章が途中で途切れる
int answer_GPT_token_length = 2000;

double Free_max_monthly_cost = 2000; 

double Standard_max_monthly_cost = 25000; 


List<String> GPT_Models = ['gpt-4o-mini' , 'gpt-3.5-turbo' , 'gpt-4o'];

// doubleは小数点を扱える型
// 公式HPより実際のレート

// https://openai.com/api/pricing/

double gpt_4o_mini_in_cost = 0.3;
double gpt_4o_mini_out_cost = 1.2;

double gpt_3_5_turbo_in_cost = 3.0;
double gpt_3_5_turbo_out_cost = 6.0;

double gpt_4o_in_cost = 3.75;
double gpt_4o_out_cost = 15.0;

// 公式サイトで○○トークンあたりのドルの○○で割る数
int divide_value = 1000000;


// GPT応答時タイムアウトエラー時間設定(秒)
int time_out_value = 60;
