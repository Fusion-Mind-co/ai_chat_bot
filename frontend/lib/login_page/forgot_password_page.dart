// frontend\lib\login_page\forgot_password_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:chatbot/globals.dart';

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final emailController = TextEditingController();
  String? message;

  Future<void> sendResetLink() async {
    print('Future<void> sendResetLink()');
    final url = Uri.parse('$serverUrl/reset_password_request');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': emailController.text}),
    );

    setState(() {
      if (response.statusCode == 200) {
        message = "パスワードリセットのリンクが送信されました。";
      } else {
        message = json.decode(response.body)['message'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('パスワードの再設定')),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          children: [
            SizedBox(height: 25),
            Text(
              'パスワードを再設定するため、アカウントに設定しているアドレスを入力してください',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            SizedBox(height: 10),
            Text(
              '送信後に届いたメールに記載されているURLから、パスワードの再設定を行ってください',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            SizedBox(height: 25),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: "メールアドレス"),
            ),
            ElevatedButton(
              onPressed: sendResetLink,
              child: Text('再設定用メールを送信'),
            ),
            if (message != null)
              Text(message!, style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
