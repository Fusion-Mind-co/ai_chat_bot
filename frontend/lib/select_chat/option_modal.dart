// option_modal.dart

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

    final ThemeData parentTheme =
        isDarkMode ? ThemeData.dark() : ThemeData.light();

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        bool currentMode = isDarkMode; // 現在のモードを保持

        return StatefulBuilder(
          // Themeの外側にStatefulBuilderを移動
          builder: (context, setState) {
            final ThemeData parentTheme =
                currentMode ? ThemeData.dark() : ThemeData.light();

            return Theme(
              data: parentTheme,
              child: AlertDialog(
                // themeではなくparentThemeを使用
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
                      Text(
                        '利用状況: ${globalMonthlyCost?.toInt() ?? 0} / ${globalMaxMonthlyCost.toInt()} pt',
                        style: TextStyle(
                          fontSize: 14,
                          color: parentTheme.textTheme.bodyMedium?.color,
                        ),
                      ),
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
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            currentMode = !currentMode; // モードを更新
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
                      Text(
                        'GPTモデル切替',
                        style: TextStyle(
                            color: parentTheme.textTheme.bodyMedium?.color),
                      ),
                      DropdownButton<String>(
                        value: selectedModel,
                        dropdownColor: parentTheme.dialogBackgroundColor,
                        style: TextStyle(
                            color: parentTheme.textTheme.bodyMedium?.color),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            onModelChange(newValue);
                          }
                          Navigator.of(context).pop();
                        },
                        items: GPT_Models.map<DropdownMenuItem<String>>(
                            (String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: chatHistoryMaxLengthController,
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                  color:
                                      parentTheme.textTheme.bodyMedium?.color),
                              onChanged: (value) {
                                int? newLength = int.tryParse(value);
                                if (newLength != null) {
                                  setState(() {
                                    if (newLength < inputTextLength) {
                                      errorMessage =
                                          '最大履歴文字数は入力テキストの長さ以上である必要があります';
                                    } else {
                                      errorMessage = null;
                                      changeChatHistoryMaxLength(newLength);
                                    }
                                  });
                                }
                              },
                              decoration: InputDecoration(
                                labelText: '履歴送信の文字数上限',
                                labelStyle: TextStyle(
                                    color: parentTheme
                                        .textTheme.bodyMedium?.color),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: parentTheme.dividerColor),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: parentTheme.primaryColor),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.help_outline,
                                color: parentTheme.iconTheme.color),
                            onPressed: () {
                              _showDescriptionModal(
                                  context, isDarkMode); // isDarkModeを渡す
                            },
                          ),
                        ],
                      ),
                      TextField(
                        controller: inputTextLengthController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                            color: parentTheme.textTheme.bodyMedium?.color),
                        onChanged: (value) {
                          int? newLength = int.tryParse(value);
                          if (newLength != null) {
                            setState(() {
                              if (newLength < 50) {
                                errorMessage = '入力テキストの長さは50文字以上である必要があります';
                              } else if (newLength > maxLength) {
                                errorMessage = '入力テキストの長さは最大履歴文字数以下である必要があります';
                              } else {
                                errorMessage = null;
                                changeInputTextLength(newLength);
                              }
                            });
                          }
                        },
                        decoration: InputDecoration(
                          labelText: '入力文字数上限',
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

  static Future<void> _showDescriptionModal(
      BuildContext context, bool isDarkMode) {
    final ThemeData parentTheme =
        isDarkMode ? ThemeData.dark() : ThemeData.light();

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Theme(
          data: parentTheme,
          child: AlertDialog(
            // StatefulBuilderは不要です（この画面では状態管理が不要なため）
            backgroundColor: parentTheme.colorScheme.surface,
            title: Text(
              '履歴を送信する際の文字数の上限とは？', // タイトルを修正（'オプション設定'ではなく）
              style: parentTheme.textTheme.titleLarge,
            ),
            content: Text(
              'ChatGPTはメッセージを送信する際、'
              '現在のメッセージに加え、過去のメッセージも'
              '同時に送信する仕組みになっています。\n\n'
              '「履歴を送信する際の文字数の上限」とは、ユーザーとChatGPTの'
              '過去のやり取りを含むすべてのメッセージの合計文字数'
              'を指します。\n\n'
              '履歴文字数が多いほど、ChatGPTは会話の文脈を'
              'より深く理解できますが、その分コストが増加します。\n\n'
              'また、ChatGPTは、送信されたメッセージの範囲内でしか'
              '会話の文脈を理解できないため、履歴に含まれない内容は'
              '考慮されません。',
              style: TextStyle(
                fontSize: 12,
                color: parentTheme.textTheme.bodyMedium?.color,
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
  }
}
