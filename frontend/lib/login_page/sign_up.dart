import 'dart:convert';
import 'package:chatbot/login_page/verification_pending_page.dart';
import 'package:chatbot/payment/payment_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:chatbot/globals.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final emailController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  bool isEmailValid = true;
  bool isPasswordValid = true;
  bool isPasswordObscured = true; // パスワードの表示/非表示を管理する変数
  String? errorMessage;

  @override
  void initState() {
    super.initState();

    emailController.addListener(() {
      setState(() {
        isEmailValid = validateEmail(emailController.text);
      });
    });

    passwordController.addListener(() {
      setState(() {
        isPasswordValid = validatePassword(passwordController.text);
      });
    });
  }

  Future<void> signup() async {
    print('signup関数実行');
    final storage = FlutterSecureStorage();

    // スマホのキーボードを隠す
    FocusScope.of(context).unfocus();

    try {
      if (!isEmailValid || !isPasswordValid) {
        setState(() {
          errorMessage = "入力エラーがあります。";
        });
        return;
      }

      // メールアドレスの重複チェック
      print('メールアドレスの重複チェック /check_email');
      final checkEmailUrl = Uri.parse('$serverUrl/check_email');
      final checkResponse = await http.post(
        checkEmailUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': emailController.text,
        }),
      );

      if (checkResponse.statusCode != 200) {
        setState(() {
          try {
            final Map<String, dynamic> responseData =
                json.decode(checkResponse.body);
            errorMessage = responseData['message'];
          } catch (e) {
            errorMessage = "サーバーとの通信に失敗しました。";
            print('エラーの詳細: $e');
          }
        });
        return;
      }

      // 一時的にSecure Storageに保存（24時間の有効期限付き）
      final expireTime =
          DateTime.now().add(Duration(hours: 24)).toIso8601String();
      await storage.write(key: 'temp_email', value: emailController.text);
      await storage.write(key: 'temp_username', value: usernameController.text);
      await storage.write(key: 'temp_password', value: passwordController.text);
      await storage.write(key: 'temp_expire', value: expireTime);

      // メール認証リクエスト送信
      final sendVerificationUrl =
          Uri.parse('$serverUrl/send_verification_email');
      final verificationResponse = await http.post(
        sendVerificationUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': emailController.text,
          'username': usernameController.text,
          'password': passwordController.text, // パスワードも送信
        }),
      );

      if (verificationResponse.statusCode == 200) {
        // 確認画面に遷移
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VerificationPendingPage(
              email: emailController.text,
            ),
          ),
        );
      } else {
        throw Exception('認証メールの送信に失敗しました');
      }
    } catch (e) {
      print('予期せぬエラー: $e');
      setState(() {
        errorMessage = "予期せぬエラーが発生しました。";
      });
      // エラー時は一時保存データを削除
      await storage.delete(key: 'temp_email');
      await storage.delete(key: 'temp_username');
      await storage.delete(key: 'temp_password');
      await storage.delete(key: 'temp_expire');
    }
  }

  // メールアドレスの検証関数
  bool validateEmail(String email) {
    print('メールアドレスの検証');
    String pattern = r'^[^@]+@[^@]+\.[^@]+$';
    RegExp regex = RegExp(pattern);
    return regex.hasMatch(email) && email.length <= 255;
  }

  // パスワードの検証関数
  bool validatePassword(String password) {
    print('パスワードの検証');
    if (password.length < 8 || password.length > 16) {
      return false;
    }

    bool hasLetter = password.contains(RegExp(r'[A-Za-z]'));
    bool hasDigit = password.contains(RegExp(r'\d'));
    bool hasNoSpaces = !password.contains(RegExp(r'\s'));

    return hasLetter && hasDigit && hasNoSpaces;
  }

  @override
  void dispose() {
    emailController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('アカウント 新規作成'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: emailController,
                maxLength: 255,
                decoration: InputDecoration(
                  labelText: "email",
                  errorText: isEmailValid ? null : "無効なメールアドレス",
                ),
              ),
              TextField(
                controller: usernameController,
                maxLength: 255,
                decoration: InputDecoration(
                  labelText: "username",
                ),
              ),
              TextField(
                controller: passwordController,
                maxLength: 16,
                obscureText: isPasswordObscured, // パスワードの表示/非表示を制御
                decoration: InputDecoration(
                  labelText: "password",
                  errorText: isPasswordValid ? null : "パスワードの条件を確認してください",
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordObscured
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        isPasswordObscured = !isPasswordObscured; // 表示/非表示を切り替え
                      });
                    },
                  ),
                ),
              ),
              Text(
                'パスワードの条件 : 「8～16文字」「アルファベットと数字を組み合わせる」「空白は無効」',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
              SizedBox(height: 16),
              if (errorMessage != null)
                Text(
                  errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              ElevatedButton(
                onPressed: signup,
                child: Text('登録'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
