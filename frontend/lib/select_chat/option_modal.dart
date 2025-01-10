// option_modal.dart

import 'package:chatbot/app.dart';
import 'package:chatbot/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:chatbot/globals.dart';

class CustomModal {
  static Future<void> show(
    BuildContext context,
    Function changeUserName,
    Function onModelChange,
    Function logout,
  ) {
    // asyncを削除
    TextEditingController userNameController =
        TextEditingController(text: global_username);

    String? errorMessage;

    return showGeneralDialog<void>(
      // 型パラメータを追加
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) => Container(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        var curve = Curves.easeInOutCubic;
        var curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );

        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(
            opacity:
                Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
            child: AlertDialog(
              title: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('オプション設定'),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () {
                        Navigator.of(context).pop(); // モーダルを閉じる
                      },
                    ),
                  ),
                ],
              ),
              content: StatefulBuilder(
                builder: (context, setState) {
                  final themeProvider = Provider.of<ThemeProvider>(context);
                  List<String> availableModels =
                      globalPlan == 'Standard' ? GPT_Models : ['gpt-3.5-turbo'];

                  // プランに応じてモデルを自動調整
                  if (!availableModels.contains(globalSelectedModel)) {
                    globalSelectedModel = 'gpt-3.5-turbo'; // デフォルトモデルに設定
                  }

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('$globalEmail'),
                        Text('現在のプラン: $globalPlan'),
                        SizedBox(height: 20),

                        // 以下は既存のUI要素
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
                                  .map<DropdownMenuItem<String>>(
                                      (String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),

                        // その他の既存のコンテンツ
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
                        SizedBox(height: 20),

                        ElevatedButton(
                          onPressed: () {
                            logout();
                            Navigator.of(context).pop();
                          },
                          child: Text('ログアウト'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
      barrierDismissible: true,
      barrierLabel: '',
      // モーダルを表示した時の後ろの画面の暗くする率
      barrierColor: Colors.black.withOpacity(0.2),
      transitionDuration: const Duration(milliseconds: 750),
    );
  }
}
