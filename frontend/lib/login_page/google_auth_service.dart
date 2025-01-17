// google_auth_service.dart
import 'package:chatbot/database/sqlite_database.dart';
import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../globals.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    signInOption: SignInOption.standard,
  );

  final storage = FlutterSecureStorage();

  // ログイン状態をチェックする関数
  Future<bool> checkLoginState() async {
    try {
      final String? savedAuthType = await storage.read(key: "auth_type");
      final String? savedEmail = await storage.read(key: "google_email");
      final String? savedDateTime =
          await storage.read(key: "google_login_datetime");

      if (savedAuthType == "google" &&
          savedEmail != null &&
          savedDateTime != null) {
        final savedDate = DateTime.tryParse(savedDateTime);
        if (savedDate != null) {
          final difference = DateTime.now().difference(savedDate);
          Duration expirationDuration = LoginExpiration.getLoginExpiration();

          if (difference <= expirationDuration) {
            globalEmail = savedEmail;
            await _loadUserConfig(savedEmail);
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      print('ログイン状態チェックでエラー: $e');
      return false;
    }
  }

  Future<bool> signInWithGoogle(bool rememberMe) async {
    try {
      print('Googleログインプロセスを開始します');
      await _googleSignIn.signOut(); // 既存のセッションをクリア

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('ユーザーがログインをキャンセルしました');
        return false;
      }

      final String email = googleUser.email; // メールアドレスを取得
      print('Googleアカウントのメールアドレス: $email');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      print('Google認証が成功しました');

      // サーバーへのリクエスト
      final response = await http.post(
        Uri.parse('$serverUrl/google-login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'access_token': googleAuth.accessToken,
          'email': email,
          'name': googleUser.displayName ?? 'Unknown',
        }),
      );

      if (response.statusCode == 200) {
        print('サーバーログイン成功');
        globalEmail = email;

        // 重要: メールアドレスを必ず保存（rememberMeの値に関わらず）
        await storage.write(key: "google_email", value: email);

        if (rememberMe) {
          print('ログイン情報を永続保存します');
          await storage.write(key: "auth_type", value: "google");
          await storage.write(
              key: "google_login_datetime", value: DateTime.now().toString());
        }

        await _loadUserConfig(email);
        return true;
      } else {
        print('サーバーログイン失敗: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Googleログインエラー: $e');
      return false;
    }
  }

  // ログアウト処理
  Future<void> signOut() async {
    print('Google認証サービスのログアウト開始');
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
        print('Googleアカウントからサインアウト完了');
      } else {
        print('既にGoogleアカウントからサインアウトしています');
      }
    } catch (e) {
      print('Googleサインアウトでエラー: $e');
      // エラーを投げずに処理を続行
    }

    try {
      await storage.delete(key: "auth_type");
      await storage.delete(key: "google_email");
      await storage.delete(key: "google_login_datetime");
      print('Googleログイン情報の削除完了');
    } catch (e) {
      print('ストレージクリアでエラー: $e');
      // エラーを投げずに処理を続行
    }
  }

  Future<void> _loadUserConfig(String email) async {
    try {
      // まずデータベース名を設定
      var bytes = utf8.encode(email);
      global_DB_name = sha256.convert(bytes).toString();
      print('Database name set to: $global_DB_name');

      final response = await http.get(
        Uri.parse('$serverUrl/get/config_and_cost?email=$email'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> config = json.decode(response.body);
        globalMonthlyCost = (config['monthly_cost'] as num).toDouble();
        globalPlan = config['plan'] as String;
        chatHistoryMaxLength = config['chat_history_max_length'] as int;
        input_text_length = config['input_text_length'] as int;

        // データベースの初期化を確実に行う
        await SQLiteDatabase.resetInstance();
        await SQLiteDatabase.instance.database;

        print('User config loaded successfully');
        print('Plan: $globalPlan');
        print('Monthly Cost: $globalMonthlyCost');
        print('Database initialized successfully');
      }
    } catch (e) {
      print('Error loading user config: $e');
      rethrow; // エラーを上位に伝播させる
    }
  }
}
