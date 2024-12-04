import 'package:chatbot/globals.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SQLiteDatabase {
  static SQLiteDatabase? _instance;
  Database? _database;

  // シングルトンパターンの実装
  static SQLiteDatabase get instance {
    _instance ??= SQLiteDatabase._();
    return _instance!;
  }

  SQLiteDatabase._();

  // データベースへのアクセスを提供
  Future<Database> get database async {
    _database ??= await _initDB();
    return _database!;
  }

  // データベースの初期化
  Future<Database> _initDB() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, global_DB_name! + '.db');

      return await openDatabase(
        path,
        version: 1,
        onCreate: _createDB,
        onOpen: (db) {
          print("データベース ${global_DB_name}.db を開きました");
        },
      );
    } catch (e) {
      print('SQLiteデータベースの初期化に失敗しました: $e');
      rethrow;
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute("""
      CREATE TABLE chat (
        id INTEGER PRIMARY KEY, 
        chat_id INTEGER, 
        content TEXT, 
        timestamp TEXT, 
        is_user INTEGER, 
        response_to_message_id INTEGER
      )""");

    await db.execute("""
      CREATE TABLE select_chat (
        id INTEGER PRIMARY KEY, 
        title TEXT, 
        created_at TEXT, 
        updated_at TEXT
      )""");

    await db.execute("""
      CREATE TABLE cost_data (
        id INTEGER PRIMARY KEY, 
        now_cost REAL, 
        monthly_cost REAL, 
        user_text_length INTEGER, 
        user_token_count INTEGER, 
        user_cost REAL, 
        GPT_text_length INTEGER, 
        GPT_token_count INTEGER, 
        GPT_cost REAL, 
        selectedModel TEXT, 
        timestamp TEXT
      )""");

    print("データベース ${global_DB_name}.db のテーブルを作成しました");
  }

  // チャットメッセージの取得
  Future<List<Map<String, dynamic>>> getChatMessages(int chatId) async {
    final db = await database;
    try {
      return await db.query(
        'chat',
        where: 'chat_id = ?',
        whereArgs: [chatId],
      );
    } catch (e) {
      print('getChatMessagesでエラーが発生しました: $e');
      return [];
    }
  }

  // チャットメッセージの保存
  Future<int> postChatDB(int chatId, String inputChat, bool isUserMessage,
      int? responseToMessageId) async {
    final db = await database;
    try {
      return await db.insert(
        'chat',
        {
          'chat_id': chatId,
          'content': inputChat,
          'timestamp': DateTime.now().toString(),
          'is_user': isUserMessage ? 1 : 0,
          'response_to_message_id': responseToMessageId,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('postChatDBでエラーが発生しました: $e');
      return 0;
    }
  }

  // 全てのチャットの取得
  Future<List<Map<String, dynamic>>> getAllSelectChat() async {
    final db = await database;
    try {
      return await db.query('select_chat', orderBy: globalSortOrder);
    } catch (e) {
      print('getAllSelectChatでエラーが発生しました: $e');
      return [];
    }
  }

  // 特定のチャットの取得
  Future<Map<String, dynamic>?> getSelectChatById(int id) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> result = await db.query(
        'select_chat',
        where: 'id = ?',
        whereArgs: [id],
      );
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      print('getSelectChatByIdでエラーが発生しました: $e');
      return null;
    }
  }

  // チャットの更新日時を更新
  Future<void> updateChatUpdatedAt(int id) async {
    final db = await database;
    try {
      await db.update(
        'select_chat',
        {'updated_at': DateTime.now().toString()},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('updateChatUpdatedAtでエラーが発生しました: $e');
    }
  }

  // 新規チャットの作成
  Future<int?> insertNewChat() async {
    final db = await database;
    try {
      final currentTime = DateTime.now().toString();
      return await db.insert(
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

  // チャットタイトルの更新
  Future<void> updateChatTitle(String title, int id) async {
    final db = await database;
    try {
      await db.update(
        'select_chat',
        {'title': title},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('updateChatTitleでエラーが発生しました: $e');
    }
  }

  // チャットの削除
  Future<void> deleteChat(int id) async {
    final db = await database;
    try {
      await db.delete('select_chat', where: 'id = ?', whereArgs: [id]);
      await db.delete('chat', where: 'chat_id = ?', whereArgs: [id]);
    } catch (e) {
      print('deleteChatでエラーが発生しました: $e');
    }
  }

  // コストデータの保存
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
    final db = await database;
    try {
      await db.insert(
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