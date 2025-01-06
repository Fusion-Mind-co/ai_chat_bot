// header.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chatbot/theme_provider.dart';
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
                  ),
                ),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "${globalSelectedModel}",
                  style: TextStyle(
                    fontSize: 12,
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
        final themeProvider =
            Provider.of<ThemeProvider>(context, listen: false);
        CustomModal.show(
          context,
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
