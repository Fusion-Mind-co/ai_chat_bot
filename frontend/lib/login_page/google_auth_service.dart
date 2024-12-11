// google_auth_service.dart
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
          Duration expirationDuration =
              LoginExpiration.getLoginExpiration();

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
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('ユーザーがログインをキャンセルしました');
        return false;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      print('Google認証が成功しました');

      final response = await http.post(
        Uri.parse('$serverUrl/google-login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'access_token': googleAuth.accessToken,
          'email': googleUser.email,
          'name': googleUser.displayName ?? 'Unknown',
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        globalEmail = googleUser.email;

        if (rememberMe) {
          print('ログイン情報を保存します');
          await storage.write(key: "auth_type", value: "google");
          await storage.write(key: "google_email", value: googleUser.email);
          await storage.write(
              key: "google_login_datetime", value: DateTime.now().toString());
        } else {
          print('ログイン情報は保存しません');
          await storage.delete(key: "auth_type");
          await storage.delete(key: "google_email");
          await storage.delete(key: "google_login_datetime");
        }

        await _loadUserConfig(googleUser.email);
        print('ログインメッセージ: ${responseData['message']}');
        return true;
      }

      return false;
    } catch (e) {
      print('Googleログインエラー: $e');
      return false;
    }
  }

  // ログアウト処理
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await storage.delete(key: "auth_type");
      await storage.delete(key: "google_email");
      await storage.delete(key: "google_login_datetime");
      globalEmail = null;
    } catch (e) {
      print('Sign out error: $e');
    }
  }

  Future<void> _loadUserConfig(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$serverUrl/get/config_and_cost?email=$email'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> config = json.decode(response.body);
        globalMonthlyCost = (config['monthly_cost'] as num).toDouble();
        globalPlan = config['plan'] as String;
        chatHistoryMaxLength = config['chat_history_max_length'] as int;
        input_text_length = config['input_text_length'] as int;

        print('User config loaded successfully');
        print('Plan: $globalPlan');
        print('Monthly Cost: $globalMonthlyCost');
      }
    } catch (e) {
      print('Error loading user config: $e');
    }
  }
}
