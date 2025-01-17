// ai_message.dart
//緑色の吹き出しai_message
import 'package:flutter/material.dart';

Widget ai_message(message) {
  return Align(
    alignment: Alignment.centerLeft,
    child: Container(
      margin: EdgeInsets.only(left: 10, top: 15, right: 30, bottom: 15),
      padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 255, 248, 238), // ユーザーの吹き出しの色
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(color: Colors.grey, blurRadius: 5, offset: Offset(2, 3)),
        ],
      ),
      child: Text(
        message,
        style: TextStyle(color: Colors.black, fontSize: 16.0),
      ),
    ),
  );
}
