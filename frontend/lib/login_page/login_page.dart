import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:chatbot/chat_page/api/api_config.dart';
import 'package:chatbot/globals.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:chatbot/services/google_auth_service.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final storage = FlutterSecureStorage(); // 安全なストレージを利用

  bool isEmailValid = true;
  bool isPasswordValid = true;
  String? errorMessage;
  bool isPasswordObscured = true; // パスワードの表示/非表示を管理する変数
  bool rememberMe = false; // Remember Me の状態を管理

  final Duration loginExpirationLimit = Duration(minutes: time_value);

  // Googleログイン
  final GoogleAuthService _googleAuthService = GoogleAuthService();

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials(); // 初期化時に記憶された情報を読み込む
  }

  // Googleログイン処理

  Future<void> _handleGoogleSignIn() async {
    try {
      setState(() {
        errorMessage = null; // エラーメッセージをクリア
      });

      final success = await _googleAuthService.signInWithGoogle();

      if (success) {
        print('Google sign in successful, navigating to home');
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() {
          errorMessage = 'Googleログインに失敗しました';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'エラーが発生しました: $e';
      });
      print('Google sign in error: $e');
    }
  }

  // Googleログインボタンの追加
  Widget _buildGoogleSignInButton() {
    return ElevatedButton(
      onPressed: _handleGoogleSignIn,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        minimumSize: Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/google_logo.png',
            height: 24,
          ),
          SizedBox(width: 12),
          Text('Googleでログイン'),
        ],
      ),
    );
  }

  // <<<<<ローカルデータ>>>>>
  // 保存された資格情報を読み込む
  Future<void> _loadRememberedCredentials() async {
    print('_loadRememberedCredentials関数　パスワード記憶機能');
    String? savedEmail = await storage.read(key: "email");
    String? savedPassword = await storage.read(key: "password");
    String? savedDateTime = await storage.read(key: "loginDateTime");

    if (savedEmail != null && savedPassword != null && savedDateTime != null) {
      DateTime? savedDate = DateTime.tryParse(savedDateTime);
      if (savedDate != null) {
        // 現在の日時と保存された日時の差分を計算
        Duration difference = DateTime.now().difference(savedDate);

        // リミットを超えていないかチェック
        if (difference <= loginExpirationLimit) {
          setState(() {
            emailController.text = savedEmail;
            passwordController.text = savedPassword;
            rememberMe = true;
          });

          // 自動的にログインを試みる
          _attemptAutoLogin(savedEmail, savedPassword);
        }
      }
    }
  }

// 自動ログインを試みる
  Future<void> _attemptAutoLogin(String email, String password) async {
    print('_attemptAutoLogin関数　自動ログイン');
    final url = Uri.parse('$serverUrl/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    // emailが表示されるかテスト
    print(email);

    if (response.statusCode == 200) {
      // グローバル変数にemailを設定
      globalEmail = email;
      Navigator.pushNamed(context, '/home');
      print('ホーム画面(セレクト画面)に遷移');
    } else {
      setState(() {
        errorMessage = json.decode(response.body)['message'];
      });
    }
  }

  //<<<<<<　→　pyhon　→　postgreSQL >>>>>>

  Future<void> login() async {
    if (!isEmailValid || !isPasswordValid) {
      setState(() {
        errorMessage = "入力エラーがあります。";
      });
      return;
    }

    final url = Uri.parse('$serverUrl/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': emailController.text,
        'password': passwordController.text,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        errorMessage = null;
        // グローバル変数にemailを設定
        globalEmail = emailController.text;
      });

      if (rememberMe) {
        // Remember Me が有効な場合、資格情報と現在の日時を保存
        await storage.write(key: "email", value: emailController.text);
        await storage.write(key: "password", value: passwordController.text);
        await storage.write(
            key: "loginDateTime", value: DateTime.now().toString());
      } else {
        // 無効の場合は保存された資格情報を削除
        await storage.delete(key: "email");
        await storage.delete(key: "password");
        await storage.delete(key: "loginDateTime");
      }

      // emailが表示されるかテスト
      print(emailController.text);

      Navigator.pushNamed(
        context,
        '/home',
      ); // ログイン成功時にホーム画面に遷移
    } else {
      setState(() {
        errorMessage = json.decode(response.body)['message'];
      });
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
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ログイン'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
                controller: passwordController,
                maxLength: 16,
                obscureText: isPasswordObscured, // パスワードの表示/非表示を制御
                decoration: InputDecoration(
                  labelText: "password",
                  errorText:
                      isPasswordValid ? null : "パスワードは4〜16文字で、数字と文字を含める必要があります",
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
              CheckboxListTile(
                title: Text("ログイン情報を記憶する"),
                value: rememberMe,
                onChanged: (bool? value) {
                  setState(() {
                    rememberMe = value ?? false;
                  });
                },
              ),
              SizedBox(height: 26),
              if (errorMessage != null)
                Text(
                  errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: login,
                child: Text('ログイン'),
              ),
              SizedBox(height: 16),
              // Googleログインボタン
              _buildGoogleSignInButton(),

              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('または'),
                  ),
                  Expanded(child: Divider()),
                ],
              ),

              SizedBox(height: 35),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/signup'); // サインアップページに遷移
                },
                child: Text('アカウント登録はこちら', style: TextStyle(fontSize: 12)),
              ),
              SizedBox(height: 26),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(
                      context, '/forgot_password'); // パスワードを忘れた場合のページに遷移
                },
                child: Text('パスワードを忘れた場合', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
