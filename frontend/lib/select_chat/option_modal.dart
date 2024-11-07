// option_modal.dart

import 'package:flutter/material.dart';
import 'package:chatbot/chat_page/api/api_config.dart';
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

    String? errorMessage; // エラーメッセージを管理する変数

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('オプション設定'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('$globalEmail'),
                    Text(
                      '現在のプラン: $globalPlan',
                      style: TextStyle(fontSize: 14),
                    ),
                    Text(
                      '利用状況: ${globalMonthlyCost?.toInt() ?? 0} / ${globalMaxMonthlyCost.toInt()} pt',
                      style: TextStyle(fontSize: 14),
                    ),
                    TextField(
                      onChanged: (value) {
                        changeUserName(value);
                      },
                      controller: userNameController,
                      decoration: InputDecoration(labelText: 'ユーザー名'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        toggleTheme();
                      },
                      child: Text('ライト/ダークモード切替'),
                    ),
                    SizedBox(height: 20),
                    Text('GPTモデル切替'),
                    DropdownButton<String>(
                      value: selectedModel,
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
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.help_outline, color: Colors.grey),
                          onPressed: () {
                            _showDescriptionModal(context);
                          },
                        ),
                      ],
                    ),
                    TextField(
                      controller: inputTextLengthController,
                      keyboardType: TextInputType.number,
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
                      ),
                    ),
                    SizedBox(height: 20),
                    
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // 現在のモーダルを閉じる
                        Navigator.pushNamed(
                            context, '/payment'); // PaymentPageへ遷移
                      },
                      child: Text('プラン選択 (お支払いページ)'),
                    ),

                    // エラーメッセージの表示（既存のコード）
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

  // 「履歴最大文字数」についての説明を表示するモーダルを表示する関数
  static void _showDescriptionModal(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('履歴を送信する際の文字数の上限とは？'),
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
            style: TextStyle(fontSize: 12),
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
  }
}
