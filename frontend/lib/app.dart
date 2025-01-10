// app.dart
import 'dart:convert';
import 'package:chatbot/database/postgreSQL_logic.dart';
import 'package:chatbot/database/sqlite_database.dart';
import 'package:chatbot/login_page/google_auth_service.dart';
import 'package:chatbot/socket_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:chatbot/globals.dart';
import 'package:chatbot/login_page/login_page.dart';
import 'package:chatbot/select_chat/select_chat_body.dart';
import 'package:chatbot/select_chat/header.dart';
import 'package:provider/provider.dart';
import 'theme/theme_provider.dart';

class App extends StatefulWidget {
  @override
  AppState createState() => AppState();
}

class AppState extends State<App> {
  static AppState? instance;
  bool _isDarkMode = false;
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  final storage = FlutterSecureStorage();
  final userNameController = TextEditingController();
  final chatHistoryMaxLengthController = TextEditingController();
  final inputTextLengthController = TextEditingController();

  @override
  void initState() {
    super.initState();
    instance = this;
    SocketService.initSocket();
  }

  @override
  void dispose() {
    if (instance == this) instance = null;
    SocketService.dispose();
    super.dispose();
  }

  static Future<void> refreshState() async {
    if (instance != null) {
      await instance!.loadAndFetchConfigAndCost();
    }
  }

  Future<void> loadAndFetchConfigAndCost() async {
    try {
      print('ユーザー設定の読込開始');
      final url =
          Uri.parse('$serverUrl/get/config_and_cost?email=$globalEmail');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data is Map) {
          setState(() {
            globalSortOrder = data['sortOrder'] ?? 'created_at ASC';
            globalSelectedModel = data['selectedModel'] ?? 'gpt-3.5-turbo';
            global_username = data['username'] ?? '';
            chatHistoryMaxLength = data['chat_history_max_length'] ?? 1000;
            input_text_length = data['input_text_length'] ?? 200;
            globalMonthlyCost = data['monthly_cost'] ?? 0.0;
            globalPlan = data['plan'] ?? 'Free';
            Provider.of<ThemeProvider>(context, listen: false)
                .setThemeMode(data['isDarkMode'] ?? false);
          });
          print('ユーザー設定を更新しました');
        }
      }
    } catch (e) {
      print('ユーザー設定の読込でエラー: $e');
    }
  }

  void onModelChange(String newModel) async {
    try {
      print('モデル変更: $newModel');
      setState(() => globalSelectedModel = newModel);
      await updateUserData('model',
          {'email': globalEmail, 'selectedModel': globalSelectedModel});
    } catch (e) {
      print('モデル変更でエラー: $e');
    }
  }

  Future<void> logout() async {
    try {
      print('ログアウト開始');

      // データベースのクリーンアップ
      print('データベースのクリーンアップ開始');
      SQLiteDatabase.resetInstance();
      print('データベースのクリーンアップ完了');

      // グローバル変数をリセット
      globalEmail = null;
      globalPlan = 'Free';
      globalSelectedModel = 'gpt-3.5-turbo';
      globalMonthlyCost = 0.0;
      chatHistoryMaxLength = 1000;
      input_text_length = 200;
      global_DB_name = null;

      // ストレージをクリア
      print('ストレージのクリア開始');
      await storage.delete(key: "email");
      await storage.delete(key: "password");
      await storage.delete(key: "loginDateTime");
      await storage.delete(key: "auth_type");
      await storage.delete(key: "google_email");
      await storage.delete(key: "google_login_datetime");
      print('ストレージのクリア完了');

      // Googleログアウト
      print('Googleログアウト開始');
      await _googleAuthService.signOut();
      print('Googleログアウト完了');

      print('ログアウト完了');
    } catch (e) {
      print('ログアウトでエラー: $e');
    } finally {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  void toggleTheme() {
    try {
      print('テーマ切替開始');
      setState(() => _isDarkMode = !_isDarkMode);
      updateUserData(
          'darkmode', {'email': globalEmail, 'isDarkMode': _isDarkMode});
    } catch (e) {
      print('テーマ切替でエラー: $e');
    }
  }

  void changeUserName(String newUserName) {
    try {
      print('ユーザー名変更開始');
      setState(() {
        global_username = newUserName;
        userNameController.text = newUserName;
      });
      updateUserData(
          'username', {'email': globalEmail, 'username': global_username});
    } catch (e) {
      print('ユーザー名変更でエラー: $e');
    }
  }

  void changeInputTextLength(int newLength) {
    try {
      if (newLength >= 50) {
        print('入力文字数変更開始');
        setState(() {
          input_text_length = newLength;
          inputTextLengthController.text = newLength.toString();
        });

        if (chatHistoryMaxLength < input_text_length) {
          changeChatHistoryMaxLength(input_text_length);
        }

        updateUserData('input_length',
            {'email': globalEmail, 'input_text_length': input_text_length});
      }
    } catch (e) {
      print('入力文字数変更でエラー: $e');
    }
  }

  void changeChatHistoryMaxLength(int newMaxLength) {
    try {
      if (newMaxLength >= input_text_length) {
        print('チャット履歴長変更開始');
        setState(() {
          chatHistoryMaxLength = newMaxLength;
          chatHistoryMaxLengthController.text = newMaxLength.toString();
        });

        updateUserData('history_length', {
          'email': globalEmail,
          'chat_history_max_length': chatHistoryMaxLength
        });
      }
    } catch (e) {
      print('チャット履歴長変更でエラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(
        context,
        changeUserName,
        onModelChange,
        logout,
      ),
      body: SelectChat(loadingConfig: loadAndFetchConfigAndCost),
    );
  }
}
