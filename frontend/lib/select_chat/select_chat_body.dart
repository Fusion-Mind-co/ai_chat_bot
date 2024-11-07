// select_chat_body.dart

import 'package:flutter/material.dart';
import 'package:chatbot/chat_page/chat_page.dart';
import 'package:chatbot/database/postgreSQL_logic.dart';
import 'package:chatbot/globals.dart';
import 'package:chatbot/database/database_interface.dart'; // DatabaseInterfaceをインポート
import 'package:chatbot/database/database_service.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart'; // cryptoパッケージをインポート

class SelectChat extends StatefulWidget {
  final Function loadingConfig; // コールバックを受け取る
  SelectChat({required this.loadingConfig});

  @override
  SelectChatState createState() => SelectChatState();
}

class SelectChatState extends State<SelectChat> with WidgetsBindingObserver {
  List<Map<String, dynamic>> _selectData = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Observerを追加

    initializeApp(); // 初期化関数を呼び出す
  }

  Future<void> initializeApp() async {
    try {
      // メールアドレスをハッシュ化
      generateDatabaseName();
      print('email = $globalEmail');
      print('global_DB_name = $global_DB_name');

      await db.createDB(); // データベースの初期化
      print('データベース初期化完了');

      await widget.loadingConfig(); // LoadingConfigの完了を待機

      // データベースが初期化された後にチャットデータを取得
      await getSelectChat();
    } catch (e) {
      print('データベース初期化またはチャットデータ取得でエラーが発生しました: $e');
    }
  }

  //=============================2024.10.08作業中===========================

  // メールアドレスをSHA-256でハッシュ化
  void generateDatabaseName() {
    var bytes = utf8.encode(globalEmail!); // メールアドレスをバイト配列に変換
    global_DB_name = sha256.convert(bytes).toString(); // ハッシュ化
  }

  //=============================2024.10.08作業中===========================

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Observerを削除
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      getSelectChat(); // アプリがフォアグラウンドに戻ったときにデータを再取得
    }
  }

  Future<void> getSelectChat() async {
    print('getSelectChat関数 開始');
    final List<Map<String, dynamic>> selectData =
        await db.getAllSelectChat(); // データベースから取得
    setState(() {
      _selectData = selectData;
    });
    print('getSelectChat関数 終了');
  }

  Future<void> newChat() async {
    print('newChat関数');

    try {
      int? newChatId = await db.insertNewChat(); // データベースに新しいチャットを挿入
      print('newChatId: $newChatId'); // デバッグ用

      if (newChatId != null) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              chatId: newChatId,
              loadingConfig: widget.loadingConfig, // コールバックを渡す
            ),
          ),
        );
        getSelectChat(); // 戻ってきたときにデータを再取得
      } else {
        print("新しいチャットの作成に失敗しました");
      }
    } catch (e) {
      print('newChat関数でエラーが発生しました: $e');
    }
  }

  // 並び替えを変更する関数
  void _changeOrder(String newOrder) async {
    print("_changeOrder関数");

    setState(() {
      globalSortOrder = newOrder;
      print("globalSortOrder = $globalSortOrder");

      getSelectChat(); // ソート条件を適用してデータを再取得
    });

    // データベースに新しいソート条件を保存
    await updateUserData(
        'sort_order', {'email': globalEmail, 'sortOrder': globalSortOrder});
  }

  // ソートオプションのテキストを取得する関数
  String _getOrderArrow(String order) {
    switch (order) {
      case 'created_at ASC':
        return '作成日 ↑';
      case 'created_at DESC':
        return '作成日 ↓';
      case 'updated_at ASC':
        return '更新日 ↑';
      case 'updated_at DESC':
        return '更新日 ↓';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            Align(
              alignment: Alignment.center, // 新規チャットボタンを中央に配置
              child: ElevatedButton(
                onPressed: () {
                  newChat();
                },
                child: Text('新規チャット'),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft, // ドロップダウンを左寄せ
              child: Container(
                margin: EdgeInsets.only(left: 16.0), // 画面の端から少し余白を入れる
                child: DropdownButton<String>(
                  value: globalSortOrder,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      _changeOrder(newValue);
                    }
                  },
                  items: <String>[
                    'created_at ASC',
                    'created_at DESC',
                    'updated_at ASC',
                    'updated_at DESC'
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        _getOrderArrow(value),
                        style: TextStyle(fontSize: 10),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _selectData.length,
            itemBuilder: (context, index) {
              final item = _selectData[index];
              return ListTile(
                title: Text(item['title']),
                onTap: () async {
                  if (item['id'] != null) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          chatId: item['id'],
                          loadingConfig: widget.loadingConfig, // コールバックを渡す
                        ),
                      ),
                    );
                  } else {
                    print('IDがnullです: $item');
                  }
                  getSelectChat(); // 戻ってきたときにデータを再取得
                },
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () async {
                    if (item['id'] != null) {
                      print("id = ${item['id']}");
                      await db.deleteChat(item['id']); // データベースからチャットを削除
                      getSelectChat(); // 再取得してUIを更新
                    } else {
                      print('削除できません。IDがnullです: $item');
                    }
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
