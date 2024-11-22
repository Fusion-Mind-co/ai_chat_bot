// google_auth_service.dart
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../globals.dart';
import 'package:chatbot/chat_page/api/api_config.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    signInOption: SignInOption.standard,
  );

  Future<bool> signInWithGoogle() async {
    try {
      print('Starting Google Sign In...');

      // 既存のサインインを明示的にサインアウト
      await _googleSignIn.signOut();

      // 新規サインイン
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('User cancelled sign in');
        return false;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      print('Authentication successful');

      // バックエンド(Flask)に認証情報を送信
      final response = await http.post(
        Uri.parse('$serverUrl/google-login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'access_token': googleAuth.accessToken,
          'email': googleUser.email,
          'name': googleUser.displayName ?? 'Unknown',
        }),
      );

      print('Backend response status: ${response.statusCode}');
      print('Backend response body: ${response.body}');

      if (response.statusCode == 200) {
        globalEmail = googleUser.email;
        await _loadUserConfig(googleUser.email);
        return true;
      }

      return false;
    } catch (e) {
      print('Google Sign-In Error: $e');
      return false;
    }
  }

  // ユーザー設定を取得する関数を分離
  Future<void> _loadUserConfig(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$serverUrl/get/config_and_cost?email=$email'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> config = json.decode(response.body);

        // グローバル変数を更新
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
