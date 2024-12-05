import 'package:chatbot/database/sqlite_database.dart';
import 'package:chatbot/payment/payment_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:chatbot/app.dart';
import 'package:chatbot/chat_page/api/api_connect.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:chatbot/globals.dart';
import 'package:chatbot/login_page/forgot_password_page.dart';
import 'package:chatbot/login_page/login_page.dart';
import 'package:chatbot/login_page/sign_up.dart';
import 'package:sqflite/sqflite.dart';

Future<void> main() async {
  print('main関数実行開始');

  // Flutterエンジンを初期化
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 環境変数のロード
    await loadEnvironment();
    print('環境変数ロード完了');

    // SQLiteデータベース初期化
    db = SQLiteDatabase.instance;  // 変更: SQLiteDatabaseのインスタンスを直接取得
    print('SQLiteデータベースが初期化されました');

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