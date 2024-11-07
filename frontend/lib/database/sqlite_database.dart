// sqlite_database.dart

import 'package:chatbot/globals.dart'; // グローバル変数のインポート
import 'package:sqflite/sqflite.dart'; // sqfliteのインポート
import 'package:path/path.dart'; // ファイルパス管理用
import 'database_interface.dart'; // DatabaseInterfaceのインターフェースを実装

// データベースを管理するための変数名を変更
Database? sqfliteDatabase;

class SQLiteDatabase implements DatabaseInterface {
  @override
  Future<void> createDB() async {
    try {
      sqfliteDatabase = await openDatabase(
        join(await getDatabasesPath(), global_DB_name! + '.db'), // データベース名を指定
        version: 1,
        onCreate: (db, version) async {
          print("データベース ${global_DB_name}.db を作成しました");
          await db.execute(
              "CREATE TABLE chat (id INTEGER PRIMARY KEY, chat_id INTEGER, content TEXT, timestamp TEXT, is_user INTEGER, response_to_message_id INTEGER)");
          await db.execute(
              "CREATE TABLE select_chat (id INTEGER PRIMARY KEY, title TEXT, created_at TEXT, updated_at TEXT)");
          await db.execute(
              "CREATE TABLE cost_data (id INTEGER PRIMARY KEY, now_cost REAL, monthly_cost REAL, user_text_length INTEGER, user_token_count INTEGER, user_cost REAL, GPT_text_length INTEGER, GPT_token_count INTEGER, GPT_cost REAL, selectedModel TEXT, timestamp TEXT)");
        },
        onOpen: (db) {
          print("データベース ${global_DB_name}.db を開きました");
        },
      );
    } catch (e) {
      print('SQLiteデータベースの作成またはオープンに失敗しました: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getChatMessages(int chatId) async {
    try {
      return await sqfliteDatabase?.query(
            'chat',
            where: 'chat_id = ?',
            whereArgs: [chatId],
          ) ??
          [];
    } catch (e) {
      print('getChatMessagesでエラーが発生しました: $e');
      return [];
    }
  }

  @override
  Future<int> postChatDB(int chatId, String inputChat, bool isUserMessage,
      int? responseToMessageId) async {
    try {
      return await sqfliteDatabase?.insert(
            'chat',
            {
              'chat_id': chatId,
              'content': inputChat,
              'timestamp': DateTime.now().toString(),
              'is_user': isUserMessage ? 1 : 0,
              'response_to_message_id': responseToMessageId,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          ) ??
          0;
    } catch (e) {
      print('postChatDBでエラーが発生しました: $e');
      return 0;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAllSelectChat() async {
    try {
      return await sqfliteDatabase?.query('select_chat',
              orderBy: globalSortOrder) ??
          [];
    } catch (e) {
      print('getAllSelectChatでエラーが発生しました: $e');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>?> getSelectChatById(int id) async {
    try {
      final List<Map<String, dynamic>> result = await sqfliteDatabase?.query(
            'select_chat',
            where: 'id = ?',
            whereArgs: [id],
          ) ??
          [];
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      print('getSelectChatByIdでエラーが発生しました: $e');
      return null;
    }
  }

  @override
  Future<void> updateChatUpdatedAt(int id) async {
    try {
      await sqfliteDatabase?.update(
        'select_chat',
        {'updated_at': DateTime.now().toString()},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('updateChatUpdatedAtでエラーが発生しました: $e');
    }
  }

  @override
  Future<int?> insertNewChat() async {
    try {
      final currentTime = DateTime.now().toString();
      return await sqfliteDatabase?.insert(
        'select_chat',
        {
          'title': '新しいchat',
          'created_at': currentTime,
          'updated_at': currentTime,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('insertNewChatでエラーが発生しました: $e');
      return null;
    }
  }

  @override
  Future<void> updateChatTitle(String title, int id) async {
    try {
      await sqfliteDatabase?.update(
        'select_chat',
        {'title': title},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('updateChatTitleでエラーが発生しました: $e');
    }
  }

  @override
  Future<void> deleteChat(int id) async {
    try {
      await sqfliteDatabase
          ?.delete('select_chat', where: 'id = ?', whereArgs: [id]);
      await sqfliteDatabase
          ?.delete('chat', where: 'chat_id = ?', whereArgs: [id]);
    } catch (e) {
      print('deleteChatでエラーが発生しました: $e');
    }
  }

  @override
  Future<void> saveCostDataLocally(
      double nowTotalCost,
      int userTextLength,
      int inputTokens,
      double inCost,
      int gptTextLength,
      int outputTokens,
      double outCost,
      String model) async {
    try {
      await sqfliteDatabase?.insert(
        'cost_data',
        {
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
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('saveCostDataLocallyでエラーが発生しました: $e');
    }
  }
}
