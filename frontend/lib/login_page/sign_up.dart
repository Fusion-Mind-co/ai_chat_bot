import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:chatbot/globals.dart';
import 'payment_page.dart'; // PaymentPageのインポート

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
    if (!isEmailValid || !isPasswordValid) {
      setState(() {
        errorMessage = "入力エラーがあります。";
      });
      return;
    }

    // まずメールアドレスの重複チェック
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
        final Map<String, dynamic> responseData =
            json.decode(checkResponse.body);
        errorMessage = responseData['message'];
      });
      return;
    }

    // アカウント登録処理
    final signupUrl = Uri.parse('$serverUrl/signup');
    final signupResponse = await http.post(
      signupUrl,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': emailController.text,
        'username': usernameController.text,
        'password': passwordController.text,
        'payment_status': false // 初期支払いステータス
      }),
    );

    if (signupResponse.statusCode == 200) {
      // グローバル変数を更新
      globalEmail = emailController.text;

      // 登録成功後、支払いページに遷移
      Navigator.pushNamed(context, '/payment');
    }
  }

  // メールアドレスの検証関数
  bool validateEmail(String email) {
    String pattern = r'^[^@]+@[^@]+\.[^@]+$';
    RegExp regex = RegExp(pattern);
    return regex.hasMatch(email) && email.length <= 255;
  }

  // パスワードの検証関数
  bool validatePassword(String password) {
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
                child: Text('次へ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
