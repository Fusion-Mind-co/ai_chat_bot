// header.dart

import 'package:flutter/material.dart';
import 'package:chatbot/app.dart';
import 'package:chatbot/select_chat/option_modal.dart';
import 'package:chatbot/globals.dart'; // グローバル変数をインポート

AppBar Header(
  BuildContext context,
  bool isDarkMode,
  Function toggleTheme,
  Function changeUserName,
  Function onModelChange,
  Function logout,
) {
  return AppBar(
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ChatGPT bot',
          style: TextStyle(
            fontSize: 20,
            color: const Color.fromARGB(255, 113, 113, 113),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "${globalPlan}",
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color.fromARGB(255, 113, 113, 113),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "${globalSelectedModel}", // selectedModelの代わりにグローバル変数を使用
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color.fromARGB(255, 113, 113, 113),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
    leading: IconButton(
      icon: Icon(Icons.menu),
      onPressed: () {
        CustomModal.show(
          context,
          isDarkMode,
          toggleTheme,
          changeUserName,
          onModelChange,
          logout,
        );
      },
    ),
    actions: <Widget>[
      IconButton(
        icon: Icon(Icons.logout),
        onPressed: () {
          logout();
        },
      ),
    ],
  );
}
