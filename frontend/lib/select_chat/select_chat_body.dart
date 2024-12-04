import 'package:chatbot/database/sqlite_database.dart';
import 'package:flutter/material.dart';
import 'package:chatbot/chat_page/chat_page.dart';
import 'package:chatbot/database/postgreSQL_logic.dart';
import 'package:chatbot/globals.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class SelectChat extends StatefulWidget {
  final Function loadingConfig;
  SelectChat({required this.loadingConfig});

  @override
  SelectChatState createState() => SelectChatState();
}

class SelectChatState extends State<SelectChat> with WidgetsBindingObserver {
  List<Map<String, dynamic>> _selectData = [];
  final SQLiteDatabase _database = SQLiteDatabase.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initializeApp();
  }

  Future<void> initializeApp() async {
    try {
      generateDatabaseName();
      print('email = $globalEmail');
      print('global_DB_name = $global_DB_name');

      await _database.database; // データベースの初期化を待機
      print('データベース初期化完了');

      await widget.loadingConfig();

      await getSelectChat();
    } catch (e) {
      print('データベース初期化またはチャットデータ取得でエラーが発生しました: $e');
    }
  }

  void generateDatabaseName() {
    var bytes = utf8.encode(globalEmail!);
    global_DB_name = sha256.convert(bytes).toString();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      getSelectChat();
    }
  }

  Future<void> getSelectChat() async {
    print('getSelectChat関数 開始');
    final List<Map<String, dynamic>> selectData = 
        await _database.getAllSelectChat();
    setState(() {
      _selectData = selectData;
    });
    print('getSelectChat関数 終了');
  }

  Future<void> newChat() async {
    print('newChat関数');

    try {
      int? newChatId = await _database.insertNewChat();
      print('newChatId: $newChatId');

      if (newChatId != null) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              chatId: newChatId,
              loadingConfig: widget.loadingConfig,
            ),
          ),
        );
        getSelectChat();
      } else {
        print("新しいチャットの作成に失敗しました");
      }
    } catch (e) {
      print('newChat関数でエラーが発生しました: $e');
    }
  }

  void _changeOrder(String newOrder) async {
    print("_changeOrder関数");

    setState(() {
      globalSortOrder = newOrder;
      print("globalSortOrder = $globalSortOrder");

      getSelectChat();
    });

    await updateUserData(
        'sort_order', {'email': globalEmail, 'sortOrder': globalSortOrder});
  }

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
              alignment: Alignment.center,
              child: ElevatedButton(
                onPressed: () {
                  newChat();
                },
                child: Text('新規チャット'),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                margin: EdgeInsets.only(left: 16.0),
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
                          loadingConfig: widget.loadingConfig,
                        ),
                      ),
                    );
                  } else {
                    print('IDがnullです: $item');
                  }
                  getSelectChat();
                },
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () async {
                    if (item['id'] != null) {
                      print("id = ${item['id']}");
                      await _database.deleteChat(item['id']);
                      getSelectChat();
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