import 'package:chatbot/database/sqlite_database.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:chatbot/globals.dart';
import 'package:chatbot/login_page/google_auth_service.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final storage = FlutterSecureStorage();
  final GoogleAuthService _googleAuthService = GoogleAuthService();

  bool isLoading = true;
  bool isEmailValid = true;
  bool isPasswordValid = true;
  String? errorMessage;
  bool isPasswordObscured = true;
  bool rememberMe = false;
  bool rememberGoogleLogin = false;

  @override
  void initState() {
    super.initState();
    _checkAllLoginStates();
  }

  Future<void> _checkAllLoginStates() async {
    try {
      print('ログイン状態の確認開始');
      
      bool isGoogleLoggedIn = await _googleAuthService.checkLoginState();
      if (isGoogleLoggedIn) {
        print('Googleログイン情報が有効です');
        _navigateToHome();
        return;
      }
      
      await _loadRememberedCredentials();
    } catch (e) {
      print('ログイン状態チェックでエラー: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> initializeDatabase(String email) async {
    try {
      print('データベース初期化開始: $email');
      SQLiteDatabase.resetInstance();
      var bytes = utf8.encode(email);
      global_DB_name = sha256.convert(bytes).toString();
      await SQLiteDatabase.instance.database;
      print('データベース初期化完了');
    } catch (e) {
      print('データベース初期化エラー: $e');
      throw e;
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      print('Googleログイン開始');
      setState(() => errorMessage = null);

      final loginResult = await _googleAuthService.signInWithGoogle(rememberGoogleLogin);
      final googleEmail = await storage.read(key: "google_email");

      if (loginResult && googleEmail != null) {
        print('Googleログイン成功: $googleEmail');
        await initializeDatabase(googleEmail);
        globalEmail = googleEmail;

        if (!rememberGoogleLogin) {
          await storage.write(key: "google_email", value: googleEmail);
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
        print('Googleログイン失敗');
        setState(() => errorMessage = 'Googleログインに失敗しました');
      }
    } catch (e) {
      print('Googleログインでエラー: $e');
      setState(() => errorMessage = 'エラーが発生しました: $e');
    }
  }

  Future<void> _loadRememberedCredentials() async {
    try {
      String? savedEmail = await storage.read(key: "email");
      String? savedPassword = await storage.read(key: "password");
      String? savedDateTime = await storage.read(key: "loginDateTime");

      if (savedEmail != null && savedPassword != null && savedDateTime != null) {
        DateTime? savedDate = DateTime.tryParse(savedDateTime);
        if (savedDate != null) {
          Duration difference = DateTime.now().difference(savedDate);
          if (difference <= LoginExpiration.getLoginExpiration()) {
            setState(() {
              emailController.text = savedEmail;
              passwordController.text = savedPassword;
              rememberMe = true;
            });
            await _attemptAutoLogin(savedEmail, savedPassword);
          } else {
            print('ログイン情報期限切れ');
            await storage.deleteAll();
          }
        }
      }
    } catch (e) {
      print('認証情報読込でエラー: $e');
    }
  }

  Future<void> _attemptAutoLogin(String email, String password) async {
    try {
      final url = Uri.parse('$serverUrl/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        print('自動ログイン成功');
        globalEmail = email;
        await initializeDatabase(email);
        _navigateToHome();
      } else {
        print('自動ログイン失敗');
        setState(() => errorMessage = json.decode(response.body)['message']);
      }
    } catch (e) {
      print('自動ログインでエラー: $e');
    }
  }

  void _navigateToHome() {
    if (globalEmail == null) {
      print('エラー: メールアドレス未設定');
      return;
    }
    Navigator.pushReplacementNamed(context, '/home');
  }

  Future<void> login() async {
    try {
      print('ログイン開始');
      if (!isEmailValid || !isPasswordValid) {
        setState(() => errorMessage = "入力エラーがあります。");
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
        print('ログイン成功');
        setState(() {
          errorMessage = null;
          globalEmail = emailController.text;
        });

        await initializeDatabase(emailController.text);

        if (rememberMe) {
          await storage.write(key: "email", value: emailController.text);
          await storage.write(key: "password", value: passwordController.text);
          await storage.write(key: "loginDateTime", value: DateTime.now().toString());
        } else {
          await storage.deleteAll();
        }

        _navigateToHome();
      } else {
        print('ログイン失敗');
        setState(() => errorMessage = json.decode(response.body)['message']);
      }
    } catch (e) {
      print('ログインでエラー: $e');
      setState(() => errorMessage = "ログイン処理中にエラーが発生しました");
    }
  }

  bool validateEmail(String email) {
    String pattern = r'^[^@]+@[^@]+\.[^@]+$';
    return RegExp(pattern).hasMatch(email) && email.length <= 255;
  }

  bool validatePassword(String password) {
    if (password.length < 8 || password.length > 16) return false;
    return password.contains(RegExp(r'[A-Za-z]')) && 
           password.contains(RegExp(r'\d')) && 
           !password.contains(RegExp(r'\s'));
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
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text('ログイン')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
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
                errorText: isPasswordValid ? null : "パスワードは8〜16文字で、数字と文字を含める必要があります",
                suffixIcon: IconButton(
                  icon: Icon(isPasswordObscured ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => isPasswordObscured = !isPasswordObscured),
                ),
              ),
            ),
            CheckboxListTile(
              title: Text("ログイン情報を記憶する"),
              value: rememberMe,
              onChanged: (value) => setState(() => rememberMe = value ?? false),
            ),
            if (errorMessage != null)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(errorMessage!, style: TextStyle(color: Colors.red)),
              ),
            ElevatedButton(
              onPressed: login,
              child: Text('ログイン'),
            ),
            SizedBox(height: 16),
            _buildGoogleSignInButton(),
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
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/signup'),
              child: Text('アカウント登録はこちら', style: TextStyle(fontSize: 12)),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/forgot_password'),
              child: Text('パスワードを忘れた場合', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
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
              Image.asset('assets/google_logo.png', height: 24),
              SizedBox(width: 12),
              Text('Googleでログイン'),
            ],
          ),
        ),
        CheckboxListTile(
          title: Text("Googleログイン情報を記憶する"),
          value: rememberGoogleLogin,
          onChanged: (value) => setState(() => rememberGoogleLogin = value ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}