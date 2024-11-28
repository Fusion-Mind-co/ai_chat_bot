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
  final storage = FlutterSecureStorage();
  final GoogleAuthService _googleAuthService = GoogleAuthService();

  bool isLoading = true; // ローディング状態を管理
  bool isEmailValid = true;
  bool isPasswordValid = true;
  String? errorMessage;
  bool isPasswordObscured = true;
  bool rememberMe = false;
  bool rememberGoogleLogin = false; // Google用のRememberMe状態

  @override
  void initState() {
    super.initState();
    _checkAllLoginStates(); // 初期化時にすべてのログイン状態をチェック
  }

  // すべてのログイン状態をチェック
  Future<void> _checkAllLoginStates() async {
    print('ログイン状態の確認を開始します');
    try {
      // Googleログインの状態をチェック
      bool isGoogleLoggedIn = await _googleAuthService.checkLoginState();
      if (isGoogleLoggedIn) {
        print('Googleログイン情報が有効です - ホーム画面に遷移します');
        _navigateToHome();
        return;
      }
      print('Googleログイン情報が見つからないか、期限切れです');

      // 通常ログインの状態をチェック
      await _loadRememberedCredentials();
    } catch (e) {
      print('ログイン状態チェック中にエラーが発生しました: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      setState(() {
        errorMessage = null;
      });

      print('Googleログインを開始します');
      final success = await _googleAuthService
          .signInWithGoogle(rememberGoogleLogin); // rememberGoogleLoginを渡す

      if (success) {
        print('Googleログインが成功しました');
        if (rememberGoogleLogin) {
          print('Googleログイン情報を保存します');
        } else {
          print('Googleログイン情報は保存しません');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ログインしました'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        await Future.delayed(Duration(milliseconds: 500));
        _navigateToHome();
      } else {
        print('Googleログインが失敗しました');
        setState(() {
          errorMessage = 'Googleログインに失敗しました';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Googleログインに失敗しました'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Googleログイン処理中にエラーが発生しました: $e');
      setState(() {
        errorMessage = 'エラーが発生しました: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('エラーが発生しました'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildGoogleSignInButton() {
    return Column(
      children: [
        ElevatedButton(
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
        ),
        CheckboxListTile(
          title: Text("Googleログイン情報を記憶する"),
          value: rememberGoogleLogin,
          onChanged: (bool? value) {
            setState(() {
              rememberGoogleLogin = value ?? false;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Future<void> _loadRememberedCredentials() async {
    print('保存されたログイン情報を確認しています');
    String? savedEmail = await storage.read(key: "email");
    String? savedPassword = await storage.read(key: "password");
    String? savedDateTime = await storage.read(key: "loginDateTime");

    if (savedEmail != null && savedPassword != null && savedDateTime != null) {
      DateTime? savedDate = DateTime.tryParse(savedDateTime);
      if (savedDate != null) {
        Duration difference = DateTime.now().difference(savedDate);
        Duration expirationDuration =
            LoginExpiration.getNormalLoginExpiration();

        print('現在の${LoginExpiration.isProduction ? "本番" : "テスト"}環境設定:');
        print(LoginExpiration.getCurrentSettings());

        if (difference <= expirationDuration) {
          print('ログイン情報が有効期限内です');
          setState(() {
            emailController.text = savedEmail;
            passwordController.text = savedPassword;
            rememberMe = true;
          });

          await _attemptAutoLogin(savedEmail, savedPassword);
        } else {
          print('ログイン情報の有効期限が切れています');
          // 期限切れの情報を削除
          await storage.delete(key: "email");
          await storage.delete(key: "password");
          await storage.delete(key: "loginDateTime");
        }
      }
    }
  }

  Future<void> _attemptAutoLogin(String email, String password) async {
    print('自動ログインを試行します');
    final url = Uri.parse('$serverUrl/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    print('ログイン試行中のメールアドレス: $email');

    if (response.statusCode == 200) {
      print('自動ログインが成功しました');
      globalEmail = email;
      _navigateToHome();
    } else {
      print('自動ログインが失敗しました');
      setState(() {
        errorMessage = json.decode(response.body)['message'];
      });
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  Future<void> login() async {
    print('手動ログインを開始します');
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
      print('ログインが成功しました');
      setState(() {
        errorMessage = null;
        globalEmail = emailController.text;
      });

      if (rememberMe) {
        print('ログイン情報を保存します');
        await storage.write(key: "email", value: emailController.text);
        await storage.write(key: "password", value: passwordController.text);
        await storage.write(
            key: "loginDateTime", value: DateTime.now().toString());
      } else {
        print('保存されたログイン情報を削除します');
        await storage.delete(key: "email");
        await storage.delete(key: "password");
        await storage.delete(key: "loginDateTime");
      }

      _navigateToHome();
    } else {
      print('ログインが失敗しました');
      setState(() {
        errorMessage = json.decode(response.body)['message'];
      });
    }
  }

  bool validateEmail(String email) {
    String pattern = r'^[^@]+@[^@]+\.[^@]+$';
    RegExp regex = RegExp(pattern);
    return regex.hasMatch(email) && email.length <= 255;
  }

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
    if (isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
                obscureText: isPasswordObscured,
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
                        isPasswordObscured = !isPasswordObscured;
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
                  Navigator.pushNamed(context, '/signup');
                },
                child: Text('アカウント登録はこちら', style: TextStyle(fontSize: 12)),
              ),
              SizedBox(height: 26),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/forgot_password');
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
