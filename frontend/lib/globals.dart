// globals.dart

// グローバル化管理
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:chatbot/database/database_interface.dart'; // kIsWebを使うために必要

String? global_DB_name;
String? globalEmail;
double? globalMonthlyCost;
String? global_user_name;
String? globalPlan;
double globalMaxMonthlyCost = 0;
String globalSortOrder = 'created_at ASC';
int chatHistoryMaxLength = 1000; // 初期値を設定
int input_text_length = 200;






// サーバーURLを定義するグローバル変数
String serverUrl = '';

// .envファイルの読み込みとサーバーURLの設定
Future<void> loadEnvironment() async {
  await dotenv.load();
  serverUrl = dotenv.env['SERVER_URL'] ?? 'http://localhost:5000'; // 開発用URL（デフォルト）
  print('serverUrl = $serverUrl');
}

// グローバルに管理するデータベースインターフェース
late DatabaseInterface db;

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
