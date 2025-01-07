// header.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chatbot/theme/theme_provider.dart';
import 'package:chatbot/app.dart';
import 'package:chatbot/select_chat/option_modal.dart';
import 'package:chatbot/globals.dart';

AppBar Header(
  BuildContext context,
  Function changeUserName,
  Function onModelChange,
  Function logout,
) {
  return AppBar(
    toolbarHeight: kToolbarHeight, // AppBarのデフォルト高さ
    title: Center(
      child: Text(
        '$globalSelectedModel  /  $globalPlan',
        style: TextStyle(
          fontSize: 20,
        ),
      ),
    ),
    leading: Container(
      margin: EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        onPressed: () {
          final themeProvider =
              Provider.of<ThemeProvider>(context, listen: false);
          CustomModal.show(
            context,
            changeUserName,
            onModelChange,
            logout,
          );
        },
        child: Center(
          // Centerで縦方向のオーバーフローを防ぐ
          child: Column(
            mainAxisSize: MainAxisSize.min, // 子要素を最小限の高さに調整
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.menu, size: 20), // アイコンのサイズを調整
              SizedBox(height: 1.0), // テキストとアイコンの間にスペースを追加
              FittedBox(
                fit: BoxFit.scaleDown, // テキストが収まりきらない場合縮小
                child: Text(
                  'メニュー',
                  style: TextStyle(fontSize: 8),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}


