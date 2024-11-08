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
}

// グローバルに管理するデータベースインターフェース
late DatabaseInterface db;

//プラン
Map<String, int> planPrices = {
  'Free': 0,
  'Light': 980,
  'Standard': 1980,
  'Pro': 2980,
  'Expert': 3980,
};

//契約内容
String? nextProcessType; // ユーザーの次のプロセスタイプを保持
DateTime? nextProcessDate; // 次回処理日を保持

// globals.dart に追加
DateTime? globalNextProcessDate;
String? globalNextProcessType;