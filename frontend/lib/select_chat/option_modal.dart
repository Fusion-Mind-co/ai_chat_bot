// option_modal.dart

import 'package:chatbot/app.dart';
import 'package:flutter/material.dart';
import 'package:chatbot/globals.dart';

class CustomModal {
  static Future<void> show(
    BuildContext context,
    bool isDarkMode,
    Function toggleTheme,
    Function changeUserName,
    int maxLength,
    String selectedModel,
    Function onModelChange,
    Function changeChatHistoryMaxLength,
    Function changeInputTextLength,
    int inputTextLength,
    Function logout,
  ) async {
    TextEditingController userNameController =
        TextEditingController(text: global_user_name);

    TextEditingController chatHistoryMaxLengthController =
        TextEditingController(text: maxLength.toString());

    TextEditingController inputTextLengthController =
        TextEditingController(text: inputTextLength.toString());

    String? errorMessage;
    String currentModel = selectedModel;

    final ThemeData parentTheme =
        isDarkMode ? ThemeData.dark() : ThemeData.light();

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        bool currentMode = isDarkMode;

        return StatefulBuilder(
          builder: (context, setState) {
            final ThemeData parentTheme =
                currentMode ? ThemeData.dark() : ThemeData.light();

            if (globalPlan == 'Free' && currentModel != 'gpt-3.5-turbo') {
              currentModel = 'gpt-3.5-turbo';
              onModelChange(currentModel);
            }

            List<String> availableModels =
                globalPlan == 'Standard' ? GPT_Models : ['gpt-3.5-turbo'];

            return Theme(
              data: parentTheme,
              // 以下略
              child: AlertDialog(
                backgroundColor: parentTheme.colorScheme.surface,
                title: Text(
                  'オプション設定',
                  style: parentTheme.textTheme.titleLarge,
                ),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('$globalEmail',
                          style: parentTheme.textTheme.bodyMedium),
                      Text(
                        '現在のプラン: $globalPlan',
                        style: TextStyle(
                          fontSize: 14,
                          color: parentTheme.textTheme.bodyMedium?.color,
                        ),
                      ),
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
                              color: parentTheme.textTheme.bodyMedium?.color,
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
                            value: currentModel,
                            isExpanded: true,
                            onChanged: globalPlan == 'Standard'
                                ? (String? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        currentModel = newValue;
                                        chatGPT_MODEL = newValue;
                                      });
                                      onModelChange(newValue);
                                    }
                                  }
                                : null,
                            items: availableModels
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                  style: TextStyle(
                                    color:
                                        parentTheme.textTheme.bodyMedium?.color,
                                  ),
                                ),
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
                        style: TextStyle(
                            color: parentTheme.textTheme.bodyMedium?.color),
                        decoration: InputDecoration(
                          labelText: 'ユーザー名',
                          labelStyle: TextStyle(
                              color: parentTheme.textTheme.bodyMedium?.color),
                          enabledBorder: UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: parentTheme.dividerColor),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: parentTheme.primaryColor),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),

                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            currentMode = !currentMode;
                          });
                          toggleTheme();
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor:
                              parentTheme.textTheme.bodyMedium?.color,
                          backgroundColor:
                              parentTheme.buttonTheme.colorScheme?.background,
                        ),
                        child: Text('ライト/ダークモード切替'),
                      ),
                      SizedBox(height: 20),

                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.pushNamed(context, '/payment');
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor:
                              parentTheme.textTheme.bodyMedium?.color,
                          backgroundColor:
                              parentTheme.buttonTheme.colorScheme?.background,
                        ),
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
                    child: Text(
                      '閉じる',
                      style: TextStyle(color: parentTheme.primaryColor),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
