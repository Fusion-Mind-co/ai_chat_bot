//indexeddb_database.dart

import 'package:idb_shim/idb.dart';
import 'package:idb_shim/idb_browser.dart';
import 'package:chatbot/globals.dart';
import 'database_interface.dart';

class IndexedDBDatabase implements DatabaseInterface {
  Database? db;

  // データベースの初期化
  @override
  Future<void> createDB() async {
    var idbFactory = getIdbFactory();
    if (idbFactory != null) {
      try {
        db = await idbFactory.open(global_DB_name!, version: 1,
            onUpgradeNeeded: (e) {
          var db = e.database;
          print("IndexedDBデータベース ${global_DB_name} を作成しました");

          var chatStore =
              db.createObjectStore('chat', keyPath: 'id', autoIncrement: true);
          chatStore.createIndex('chat_id', 'chat_id', unique: false);

          var selectChatStore = db.createObjectStore('select_chat',
              keyPath: 'id', autoIncrement: true);
          selectChatStore.createIndex('created_at', 'created_at',
              unique: false);
          selectChatStore.createIndex('updated_at', 'updated_at',
              unique: false);

          var costDataStore = db.createObjectStore('cost_data',
              keyPath: 'id', autoIncrement: true);
          costDataStore.createIndex('timestamp', 'timestamp', unique: false);
        });

        print("IndexedDBデータベース ${global_DB_name} を開きました");
      } catch (e) {
        print('IndexedDBデータベースの作成またはオープンに失敗しました: $e');
      }
    } else {
      print('このプラットフォームではIndexedDBがサポートされていません');
    }
  }

  // chatテーブルからチャットメッセージを取得
  @override
  Future<List<Map<String, dynamic>>> getChatMessages(int chatId) async {
    print('getChatMessages 関数');
    print('chatId ⁼ $chatId');

    var txn = db!.transaction('chat', idbModeReadOnly);
    var store = txn.objectStore('chat');

    // chat_id に基づいてメッセージを取得する
    var index = store.index('chat_id');
    var result = await index.getAll(chatId);
    await txn.completed;

    return result != null
        ? result.map((item) => item as Map<String, dynamic>).toList()
        : [];
  }

  // chatテーブルに新しいチャットメッセージを追加
  @override
  Future<int> postChatDB(int chatId, String inputChat, bool isUserMessage,
      int? responseToMessageId) async {
    print(
        'postChatDB 関数 chatId = $chatId inputChat = $inputChat isUserMessage = $isUserMessage');

    var txn = db!.transaction('chat', idbModeReadWrite);
    var store = txn.objectStore('chat');

    var key = await store.put({
      'chat_id': chatId,
      'content': inputChat,
      'timestamp': DateTime.now().toString(),
      'is_user': isUserMessage ? 1 : 0,
      'response_to_message_id': responseToMessageId,
    });
    await txn.completed;

    print('postChatDB completed');
    return key as int;
  }

// select_chatテーブルからすべてのチャットデータを取得
  @override
  Future<List<Map<String, dynamic>>> getAllSelectChat() async {
    try {
      // トランザクション開始
      var txn = db!.transaction('select_chat', idbModeReadOnly);
      var store = txn.objectStore('select_chat');

      // すべてのデータを取得
      var result = await store.getAll();
      await txn.completed;

      List<Map<String, dynamic>> results = result
          .where((chat) => chat != null)
          .map((chat) => (chat as Map).cast<String, dynamic>())
          .toList();

      // ソート順に従ってソート
      results.sort((a, b) {
        // globalSortOrderに基づいてソート条件を設定
        if (globalSortOrder.contains('created_at')) {
          if (globalSortOrder.contains('DESC')) {
            return b['created_at'].compareTo(a['created_at']);
          } else {
            return a['created_at'].compareTo(b['created_at']);
          }
        } else if (globalSortOrder.contains('updated_at')) {
          if (globalSortOrder.contains('DESC')) {
            return b['updated_at'].compareTo(a['updated_at']);
          } else {
            return a['updated_at'].compareTo(b['updated_at']);
          }
        } else {
          return 0; // デフォルトでソートなし
        }
      });

      return results;
    } catch (e) {
      print('getAllSelectChat関数でエラーが発生しました: $e');
      return [];
    }
  }

  // select_chatテーブルから特定のIDのチャットを取得
  @override
  Future<Map<String, dynamic>?> getSelectChatById(int id) async {
    var txn = db!.transaction('select_chat', idbModeReadOnly);
    var store = txn.objectStore('select_chat');
    var result = await store.getObject(id);
    await txn.completed;
    return result as Map<String, dynamic>?;
  }

  // 特定のIDのチャットのタイトルを更新
  @override
  Future<void> updateChatTitle(String title, int id) async {
    var txn = db!.transaction('select_chat', idbModeReadWrite);
    var store = txn.objectStore('select_chat');
    var chat = await store.getObject(id);

    if (chat != null && chat is Map<String, dynamic>) {
      chat['title'] = title;
      await store.put(chat);
    }
    await txn.completed;
  }

  // select_chatテーブルに新しいチャットを追加
  @override
  Future<int?> insertNewChat() async {
    try {
      var txn = db!.transaction('select_chat', idbModeReadWrite);
      var store = txn.objectStore('select_chat');
      var key = await store.add({
        'title': '新しいchat',
        'created_at': DateTime.now().toString(),
        'updated_at': DateTime.now().toString(),
      });
      await txn.completed;
      return key as int?;
    } catch (e) {
      print('新しいチャットの追加に失敗しました: $e');
      return null;
    }
  }

  // 特定のIDのチャットの更新日時を更新
  @override
  Future<void> updateChatUpdatedAt(int id) async {
    var txn = db!.transaction('select_chat', idbModeReadWrite);
    var store = txn.objectStore('select_chat');
    var chat = await store.getObject(id);
    if (chat != null && chat is Map<String, dynamic>) {
      chat['updated_at'] = DateTime.now().toString();
      await store.put(chat); // idを明示的に渡さずに、オブジェクトのみを渡す
    }
    await txn.completed;
  }

// 特定のIDのチャットを削除
  @override
  Future<void> deleteChat(int chatId) async {
    try {
      // select_chat テーブルから該当するエントリを削除
      var txnSelectChat = db!.transaction('select_chat', idbModeReadWrite);
      await txnSelectChat.objectStore('select_chat').delete(chatId);
      await txnSelectChat.completed;

      // chat テーブルから該当する chat_id に基づいてすべてのレコードを削除
      var txnChat = db!.transaction('chat', idbModeReadWrite);
      var index = txnChat.objectStore('chat').index('chat_id');

      // chat_id に該当するすべてのレコードを取得
      var records = await index.getAll(chatId);

      // すべての該当レコードを削除
      for (var record in records) {
        var recordMap = record as Map<String, dynamic>; // 型をMapにキャスト
        await txnChat
            .objectStore('chat')
            .delete(recordMap['id']); // 各レコードのIDで削除
      }

      await txnChat.completed;
      print("deleteChat 関数終了: chat_id = $chatId に該当するレコードを削除しました。");
    } catch (e) {
      print('チャットの削除に失敗しました: $e');
    }
  }

  // cost_dataテーブルにコストデータを保存
  @override
  Future<void> saveCostDataLocally(
    double nowTotalCost,
    int userTextLength,
    int inputTokens,
    double inCost,
    int gptTextLength,
    int outputTokens,
    double outCost,
    String model,
  ) async {
    var txn = db!.transaction('cost_data', idbModeReadWrite);
    var store = txn.objectStore('cost_data');
    await store.put({
      'now_cost': nowTotalCost,
      'monthly_cost': globalMonthlyCost,
      'user_text_length': userTextLength,
      'user_token_count': inputTokens,
      'user_cost': inCost,
      'GPT_text_length': gptTextLength,
      'GPT_token_count': outputTokens,
      'GPT_cost': outCost,
      'selectedModel': model,
      'timestamp': DateTime.now().toString(),
    });

    await txn.completed;
  }
}
