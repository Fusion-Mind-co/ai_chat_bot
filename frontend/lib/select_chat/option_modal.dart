// option_modal.dart

import 'package:chatbot/app.dart';
import 'package:chatbot/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:chatbot/globals.dart';

class CustomModal {
  static Future<void> show(
    BuildContext context,
    Function changeUserName,
    Function onModelChange,
    Function logout,
  ) async {
    TextEditingController userNameController =
        TextEditingController(text: global_username);

    String? errorMessage;

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final themeProvider = Provider.of<ThemeProvider>(context);

            List<String> availableModels =
                globalPlan == 'Standard' ? GPT_Models : ['gpt-3.5-turbo'];

            return AlertDialog(
              title: Text('オプション設定'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('$globalEmail'),
                    Text('現在のプラン: $globalPlan'),
                    SizedBox(height: 20),

                    // AIモデル選択
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AIモデル選択',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (globalPlan != 'Standard')
                          Text(
                            '※ モデル選択はStandardプランのみ利用可能です',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                            ),
                          ),
                        DropdownButton<String>(
                          value: globalSelectedModel,
                          isExpanded: true,
                          onChanged: globalPlan == 'Standard'
                              ? (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      globalSelectedModel = newValue;
                                    });
                                    onModelChange(newValue);
                                  }
                                }
                              : null,
                          items: availableModels
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    TextField(
                      onChanged: (value) {
                        changeUserName(value);
                      },
                      controller: userNameController,
                      decoration: InputDecoration(
                        labelText: 'ユーザー名',
                      ),
                    ),
                    SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: () {
                        themeProvider.toggleTheme();
                      },
                      child: Text('ライト/ダークモード切替'),
                    ),
                    SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.pushNamed(context, '/payment');
                      },
                      child: Text('プラン選択 (お支払いページ)'),
                    ),

                    if (errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          errorMessage!,
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('閉じる'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
