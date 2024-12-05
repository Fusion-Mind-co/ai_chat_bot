import 'dart:convert';
import 'package:chatbot/payment/payment_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:chatbot/globals.dart';

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

  // sign_up.dartの修正版

  Future<void> signup() async {
    try {
      if (!isEmailValid || !isPasswordValid) {
        setState(() {
          errorMessage = "入力エラーがあります。";
        });
        return;
      }

      // メールアドレスの重複チェック
      final checkEmailUrl = Uri.parse('$serverUrl/check_email');
      print('チェックするURL: $checkEmailUrl'); // URLを確認するためのログ

      final checkResponse = await http.post(
        checkEmailUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': emailController.text,
        }),
      );

      print('サーバーレスポンス: ${checkResponse.statusCode}'); // ステータスコードの確認
      print('レスポンスボディ: ${checkResponse.body}'); // レスポンスの中身を確認

      // メールのチェック処理の結果を確認
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

      // アカウント登録処理
      final signupUrl = Uri.parse('$serverUrl/signup');
      print('サインアップURL: $signupUrl'); // URLを確認するためのログ

      final signupResponse = await http.post(
        signupUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': emailController.text,
          'username': usernameController.text,
          'password': passwordController.text,
          'plan': 'Free', // デフォルトプランを追加
        }),
      );

      print('サインアップレスポンス: ${signupResponse.statusCode}');
      print('サインアップレスポンスボディ: ${signupResponse.body}');

      if (signupResponse.statusCode == 200) {
        // グローバル変数を更新
        globalEmail = emailController.text;
        // 登録成功後、初回フラグをtrueにして支払いページに遷移
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentPage(isInitialAccess: true),
          ),
        );
      } else {
        setState(() {
          try {
            final Map<String, dynamic> responseData =
                json.decode(signupResponse.body);
            errorMessage = responseData['message'];
          } catch (e) {
            errorMessage = "アカウント登録に失敗しました。";
            print('エラーの詳細: $e');
          }
        });
      }
    } catch (e) {
      print('予期せぬエラー: $e');
      setState(() {
        errorMessage = "予期せぬエラーが発生しました。";
      });
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
