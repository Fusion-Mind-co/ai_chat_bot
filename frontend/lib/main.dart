//main.dart
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:chatbot/app.dart';
import 'package:chatbot/chat_page/api/api_connect.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:chatbot/database/database_interface.dart';
import 'package:chatbot/database/database_service.dart';
import 'package:chatbot/database/indexeddb_database.dart';
import 'package:chatbot/database/sqlite_database.dart';
import 'package:chatbot/globals.dart';
import 'package:chatbot/login_page/forgot_password_page.dart';
import 'package:chatbot/login_page/login_page.dart';
import 'package:chatbot/login_page/payment_page.dart';
import 'package:chatbot/login_page/sign_up.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

Future<void> main() async {
  print('main関数実行開始');

  // Flutterエンジンを初期化
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 環境変数のロード → globals.dart
    await loadEnvironment(); // awaitを追加
    print('環境変数ロード完了');

    // データベース初期化を追加
    if (kIsWeb) {
      // ブラウザ版は現在未使用だが、コードは残しておく
      print('ブラウザ版は現在サポートされていません');
    } else {
      // モバイル版のSQLite初期化
      db = DatabaseService.getDatabaseInstance();
      print('モバイル用のSQLiteが初期化されました');
    }

    // Stripe設定
    if (serverUrl.isEmpty) {
      print('エラー: SERVER_URLが読み込めていません');
    } else {
      final publishableKey = dotenv.env['PUBLISHABLE_KEY'];
      if (publishableKey == null || publishableKey.isEmpty) {
        print('エラー: PUBLISHABLE_KEYが読み込めていません');
      } else {
        print('PUBLISHABLE_KEYの読み込み成功: $publishableKey');
        try {
          Stripe.publishableKey = publishableKey;
          await Stripe.instance.applySettings();
          print('Stripe設定の適用に成功しました');
        } catch (e) {
          print('Stripe設定の適用中にエラー: $e');
        }
      }
    }

    // アプリの起動
    runApp(MyApp());
    print('アプリ起動');
  } catch (e) {
    print('初期化中にエラーが発生: $e');
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatGPT bot',
      // テーマ関連の設定は全てAppクラスに移動
      initialRoute: '/',
      routes: {
        '/': (context) => LoginPage(),
        '/home': (context) => App(),
        '/signup': (context) => SignUpPage(),
        '/forgot_password': (context) => ForgotPasswordPage(),
        '/payment': (context) => PaymentPage(isInitialAccess: false),
      },
    );
  }
}