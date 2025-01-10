//  select_chat_body.dart

import 'package:chatbot/app.dart';
import 'package:chatbot/database/postgreSQL_logic.dart';
import 'package:chatbot/database/sqlite_database.dart';
import 'package:chatbot/socket_service.dart';
import 'package:flutter/material.dart';
import 'package:chatbot/chat_page/chat_page.dart';
import 'package:chatbot/globals.dart';

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
    SocketService.addStatusUpdateListener(_handleStatusUpdate);
  }

  @override
  void dispose() {
    SocketService.removeStatusUpdateListener(_handleStatusUpdate);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _handleStatusUpdate(dynamic data) async {
    if (data['email'] == globalEmail && mounted) {
      print('SelectChat: ユーザー状態の更新を検知');
      try {
        await AppState.refreshState();
        await getSelectChat();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('設定が更新されました'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        print('状態更新でエラー: $e');
      }
    }
  }

  Future<void> initializeApp() async {
    try {
      print('SelectChat初期化開始');
      if (globalEmail == null) {
        throw Exception('メールアドレスが設定されていません');
      }
      await _database.database;
      await widget.loadingConfig();
      await getSelectChat();
      print('SelectChat初期化完了');
    } catch (e) {
      print('SelectChat初期化でエラー: $e');
      throw e;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      getSelectChat();
    }
  }

  Future<void> getSelectChat() async {
    try {
      print('チャット一覧の取得開始');
      final List<Map<String, dynamic>> selectData = await _database.getAllSelectChat();
      if (mounted) {
        setState(() {
          _selectData = selectData;
          print('チャット一覧を更新: ${selectData.length}件');
        });
      }
    } catch (e) {
      print('チャット一覧の取得でエラー: $e');
    }
  }

  Future<void> newChat() async {
    try {
      print('新規チャット作成開始');
      int? newChatId = await _database.insertNewChat();
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
        await getSelectChat();
      }
    } catch (e) {
      print('新規チャット作成でエラー: $e');
    }
  }

  void _changeOrder(String newOrder) async {
    try {
      print('ソート順変更: $newOrder');
      setState(() {
        globalSortOrder = newOrder;
        getSelectChat();
      });
      await updateUserData('sort_order', {
        'email': globalEmail,
        'sortOrder': globalSortOrder
      });
    } catch (e) {
      print('ソート順変更でエラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 20),
        Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                onPressed: () => newChat(),
                child: Text('新規チャット'),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                margin: EdgeInsets.only(left: 16.0),
                child: DropdownButton<String>(
                  value: globalSortOrder,
                  onChanged: (newValue) => _changeOrder(newValue!),
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
        SizedBox(height: 20),
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
                    getSelectChat();
                  }
                },
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () => _showEditDialog(item),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _showDeleteDialog(item),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _getOrderArrow(String order) {
    switch (order) {
      case 'created_at ASC': return '作成日 ↑';
      case 'created_at DESC': return '作成日 ↓';
      case 'updated_at ASC': return '更新日 ↑';
      case 'updated_at DESC': return '更新日 ↓';
      default: return '';
    }
  }

  void _showEditDialog(Map<String, dynamic> item) {
    final titleController = TextEditingController(text: item['title']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('タイトルの編集'),
        content: TextField(
          controller: titleController,
          decoration: InputDecoration(
            hintText: 'チャットタイトルを入力',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            child: Text('キャンセル'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('保存'),
            onPressed: () async {
              if (item['id'] != null && titleController.text.isNotEmpty) {
                await _database.updateChatTitle(titleController.text, item['id']);
                getSelectChat();
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('削除の確認'),
        content: Text('${item['title']}を削除しますか？'),
        actions: [
          TextButton(
            child: Text('戻る'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text(
              '削除',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onPressed: () async {
              if (item['id'] != null) {
                await _database.deleteChat(item['id']);
                getSelectChat();
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}