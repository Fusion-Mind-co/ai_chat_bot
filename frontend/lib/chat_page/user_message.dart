// user_message.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

Widget user_message(message) {
  return Align(
    alignment: Alignment.centerRight,
    child: Container(
      margin: EdgeInsets.only(left: 30, top: 15, right: 10, bottom: 15),
      padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.greenAccent, // 吹き出しの背景色
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(color: Colors.grey, blurRadius: 5, offset: Offset(2, 3)),
        ],
      ),
      child: MarkdownBody(
        data: message,
        styleSheet: MarkdownStyleSheet(
          p: TextStyle(color: Colors.black, fontSize: 16.0),
        ),
      ),
    ),
  );
}
