// app.dart

import 'dart:convert';
import 'package:chatbot/services/google_auth_service.dart';
import 'package:http/http.dart' as http; // httpパッケージのインポート
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:chatbot/chat_page/chat_logic/chat_history.dart';

import 'package:chatbot/database/postgreSQL_logic.dart';
import 'package:chatbot/globals.dart';
import 'package:chatbot/login_page/login_page.dart';
import 'package:chatbot/select_chat/option_modal.dart';
import 'package:chatbot/select_chat/select_chat_body.dart';
import 'package:chatbot/select_chat/header.dart';

String chatGPT_MODEL = "gpt-4o-mini";

class App extends StatefulWidget {
  @override
  AppState createState() => AppState();
}

class AppState extends State<App> {
  bool _isDarkMode = false;

  final GoogleAuthService _googleAuthService = GoogleAuthService();

  final storage = FlutterSecureStorage(); // 安全なストレージを利用
  TextEditingController userNameController = TextEditingController();
  TextEditingController chatHistoryMaxLengthController =
      TextEditingController();
  TextEditingController inputTextLengthController =
      TextEditingController(); // 新しいコントローラーを追加

  // ユーザー情報のロード
  Future<void> loadAndFetchConfigAndCost() async {
    print('ユーザー情報のロード開始');

    // PostgreSQLからユーザー設定とコストを取得
    final url = Uri.parse('$serverUrl/get/config_and_cost?email=$globalEmail');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      var responseData = jsonDecode(response.body);
      print('サーバーからのレスポンス: $responseData'); // デバッグ用にレスポンス内容を表示

      if (responseData is Map) {
        setState(() {
          // PostgreSQLから取得したデータでグローバル変数を更新
          globalSortOrder = responseData['sortOrder'] ?? 'created_at ASC';
          chatGPT_MODEL = responseData['selectedModel'] ?? 'gpt-4o-mini';
          global_user_name = responseData['user_name'] ?? '';
          chatHistoryMaxLength =
              responseData['chat_history_max_length'] ?? 1000;
          input_text_length = responseData['input_text_length'] ?? 200;
          globalMonthlyCost = responseData['monthly_cost'] ?? 0.0;
          globalPlan = responseData['plan'] ?? 'Free';

          // planに応じてmax_monthly_costを決定
          if (globalPlan == 'Free') {
            globalMaxMonthlyCost = Free_max_monthly_cost;
          } else {
            globalMaxMonthlyCost = Standard_max_monthly_cost;
          }

          // UIコントローラの更新
          chatHistoryMaxLengthController.text = chatHistoryMaxLength.toString();
          inputTextLengthController.text = input_text_length.toString();
          _isDarkMode = responseData['isDarkMode'] ?? false;
        });

        // ロードした内容を表示
        print('ロードした設定:');
        print('  Sort Order: \ $globalSortOrder');
        print('  Model: \ $chatGPT_MODEL');
        print('  User Name: \ $global_user_name');
        print('  Chat History Max Length: \ $chatHistoryMaxLength');
        print('  Input Text Length: \ $input_text_length');
        print('  Monthly Cost: \ $globalMonthlyCost');
        print('  Plan: \ $globalPlan');
        print('  Max Monthly Cost: \ $globalMaxMonthlyCost');
        print('  Dark Mode: \ $_isDarkMode');
      } else {
        print('データの形式が正しくありません');
      }
    } else {
      print('取得失敗');
    }

    print('設定とコストのロード終了');
  }

  //==================================================

  void onModelChange(String newModel) {
    print('onModelChange関数　モデル変更');
    setState(() {
      chatGPT_MODEL = newModel;
    });
    updateUserData(
        'model', {'email': globalEmail, 'selectedModel': chatGPT_MODEL});
    print("chatGPT_MODEL = ${chatGPT_MODEL}");
  }

  void changeInputTextLength(int newLength) {
    if (newLength >= 50) {
      setState(() {
        input_text_length = newLength;
        inputTextLengthController.text = newLength.toString();
      });

      // input_text_lengthが変更された場合、chatHistoryMaxLengthも更新される必要がある
      if (chatHistoryMaxLength < input_text_length) {
        changeChatHistoryMaxLength(input_text_length); // 新しい制約を満たすため更新
      }

      // データベースにアップロード
      updateUserData('input_length',
          {'email': globalEmail, 'input_text_length': input_text_length});
      print('input_text_length = ${input_text_length}');
    } else {
      print('Error: input_text_length must be at least 50');
    }
  }

  void changeChatHistoryMaxLength(int newMaxLength) {
    if (newMaxLength >= input_text_length) {
      setState(() {
        chatHistoryMaxLength = newMaxLength;
        chatHistoryMaxLengthController.text = newMaxLength.toString();
      });

      // データベースにアップロード
      updateUserData('history_length', {
        'email': globalEmail,
        'chat_history_max_length': chatHistoryMaxLength
      });
      print('chat_history_max_length = ${chatHistoryMaxLength}');
    } else {
      print('Error: chatHistoryMaxLength must be at least input_text_length');
    }
  }

  //====================================================================

  //====================================================================

  // ダークモードの切り替え
  void toggleTheme() {
    print('toggleTheme関数起動　ダークモードの切り替え');
    setState(() {
      _isDarkMode = !_isDarkMode;
    });

    updateUserData(
        'darkmode', {'email': globalEmail, 'isDarkMode': _isDarkMode});
    print("ダークモード = ${_isDarkMode}");
  }

  // ユーザーネームの変更
  void changeUserName(String newUserName) {
    print('changeUserName関数起動　ユーザーネームの変更');
    setState(() {
      global_user_name = newUserName;
      userNameController.text = newUserName; // TextEditingControllerを更新
    });
    updateUserData(
        'user_name', {'email': globalEmail, 'user_name': global_user_name});
    print("ユーザーネーム = ${newUserName}");
  }

  //====================================================================

  //====================================================================

  Future<void> logout() async {
    print('ログアウト処理を開始します');
    try {
      // 通常ログインの情報を削除
      await storage.delete(key: "email");
      await storage.delete(key: "password");
      await storage.delete(key: "loginDateTime");

      // Googleログインの情報を削除
      await storage.delete(key: "auth_type");
      await storage.delete(key: "google_email");
      await storage.delete(key: "google_login_datetime");

      // Googleログアウト処理を実行
      await _googleAuthService.signOut();

      // グローバル変数をクリア
      globalEmail = null;
      globalPlan = null;
      globalMonthlyCost = 0.0;
      chatHistoryMaxLength = 1000; // デフォルト値に戻す
      input_text_length = 200; // デフォルト値に戻す

      print('ログアウトが完了しました');

      // ログインページに遷移
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (e) {
      print('ログアウト中にエラーが発生しました: $e');
      // エラーが発生してもユーザーをログインページに遷移させる
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  @override
Widget build(BuildContext context) {
  final themeData = _isDarkMode ? ThemeData.dark() : ThemeData.light();
  
  return MaterialApp(  // Theme widgetではなくMaterialAppを使用
    theme: themeData.copyWith(
      dialogTheme: DialogTheme(
        backgroundColor: themeData.colorScheme.surface,
      ),
    ),
    home: Scaffold(
        appBar: Header(
          context,
          _isDarkMode,
          toggleTheme,
          changeUserName,
          chatHistoryMaxLength,
          chatGPT_MODEL,
          onModelChange,
          changeChatHistoryMaxLength,
          changeInputTextLength,
          input_text_length,
          logout,
        ),
        body: SelectChat(loadingConfig: loadAndFetchConfigAndCost),
      ),
    );
  }
}
