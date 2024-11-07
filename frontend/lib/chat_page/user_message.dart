// user_message.dart
//緑色の吹き出しウィジェット
import 'package:flutter/material.dart';

//【右寄せ黄緑吹き出し】
Widget user_message(message) {
  return Align(
    alignment: Alignment.centerRight,
    child: Container(
      margin: EdgeInsets.only(left: 30, top: 15, right: 10, bottom: 15),
      padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.greenAccent, // ユーザーの吹き出しの色
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