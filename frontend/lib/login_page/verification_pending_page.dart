// lib/login_page/verification_pending_page.dart
import 'dart:convert';
import 'package:chatbot/globals.dart';
import 'package:flutter/material.dart';
import 'package:chatbot/socket_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class VerificationPendingPage extends StatefulWidget {
  final String email;

  const VerificationPendingPage({
    Key? key,
    required this.email,
  }) : super(key: key);

  @override
  State<VerificationPendingPage> createState() =>
      _VerificationPendingPageState();
}

class _VerificationPendingPageState extends State<VerificationPendingPage> {
  final storage = FlutterSecureStorage(); // storage を定義

  @override
  void initState() {
    super.initState();
    // WebSocket接続の初期化のみ
    SocketService.initSocket();
    // 登録完了の通知リスナーを追加
    SocketService.addRegistrationCompleteListener(_handleRegistrationComplete);
  }

  @override
  void dispose() {
    SocketService.removeRegistrationCompleteListener(
        _handleRegistrationComplete);
    super.dispose();
  }

  void _handleRegistrationComplete(dynamic data) async {
    if (data['email'] == widget.email && data['status'] == 'success') {
      try {
        print('Registration complete notification received');

        // 一時保存したパスワードを取得
        final password = await storage.read(key: 'temp_password');
        if (password == null) {
          print('Temp password not found');
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(
                '/login', (Route<dynamic> route) => false);
          }
          return;
        }

        // ログイン処理
        final loginUrl = Uri.parse('$serverUrl/login');
        print('Attempting auto login...');
        final response = await http.post(
          loginUrl,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'email': widget.email,
            'password': password,
          }),
        );

        if (response.statusCode == 200) {
          print('Auto login successful');
          globalEmail = widget.email;
          await storage.deleteAll();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('登録が完了しました'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pushNamedAndRemoveUntil(
                '/home', (Route<dynamic> route) => false);
          }
        } else {
          throw Exception('ログインに失敗しました');
        }
      } catch (e) {
        print('Error: $e');
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
              '/login', (Route<dynamic> route) => false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('メール認証'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.mark_email_unread,
              size: 64,
              color: Colors.blue,
            ),
            SizedBox(height: 24),
            Text(
              '認証メールを送信しました',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              '${widget.email}に認証メールを送信しました。\nメール内のリンクをクリックして、登録を完了してください。',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: Text('ログイン画面に戻る'),
            ),
          ],
        ),
      ),
    );
  }
}
