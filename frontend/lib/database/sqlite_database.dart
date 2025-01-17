// database\sqlite_database.dart
import 'dart:convert';
import 'package:chatbot/globals.dart';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SQLiteDatabase {
  static SQLiteDatabase? _instance;
  Database? _database;
  bool _isInitialized = false;

  static SQLiteDatabase get instance {
    _instance ??= SQLiteDatabase._();
    return _instance!;
  }

  SQLiteDatabase._();

  Future<Database> get database async {
    try {
      if (global_DB_name == null) {
        throw Exception('Database name is not initialized');
      }

      if (_database == null || !_isInitialized) {
        print('Initializing database with name: $global_DB_name');
        _database = await _initDB();
        _isInitialized = true;
      } else {
        // 接続テスト
        try {
          await _database!.query('sqlite_master', limit: 1);
        } catch (e) {
          print('Database connection test failed. Reconnecting...');
          _database = await _initDB();
        }
      }
      return _database!;
    } catch (e) {
      print('Database connection error: $e');
      rethrow;
    }
  }

  Future<Database> _initDB() async {
    try {
      if (global_DB_name == null) {
        throw Exception('Database name is null during initialization');
      }

      final dbPath = await getDatabasesPath();
      final path = join(dbPath, global_DB_name! + '.db');

      print('Initializing database at path: $path');
      return await openDatabase(
        path,
        version: 1,
        onCreate: _createDB,
        onOpen: (db) {
          print('Database $global_DB_name.db opened successfully');
          _isInitialized = true;
        },
      );
    } catch (e) {
      print('Database initialization error: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  static Future<void> resetInstance() async {
    if (_instance != null) {
      if (_instance!._database != null) {
        print('Closing existing database connection');
        await _instance!._database!.close();
      }
      _instance!._database = null;
      _instance!._isInitialized = false;
      _instance = null;
      print('Database instance reset completed');
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

    print("データベース ${global_DB_name}.db のテーブルを作成しました");
  }

  // チャットメッセージの取得
  Future<List<Map<String, dynamic>>> getChatMessages(int chatId) async {
    try {
      print('メッセージ取得開始 - chatId: $chatId');
      final db = await database;
      final messages = await db.query(
        'chat',
        where: 'chat_id = ?',
        whereArgs: [chatId],
        orderBy: 'timestamp ASC',
      );
      print('取得成功: ${messages.length}件のメッセージ');
      return messages;
    } catch (e) {
      print('メッセージ取得でエラー: $e');
      return [];
    }
  }

  // チャットメッセージの保存
  Future<int> postChatDB(int chatId, String inputChat, bool isUserMessage,
      int? responseToMessageId) async {
    try {
      final db = await database;
      print('メッセージの保存開始 - chatId: $chatId');
      final result = await db.insert(
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
      print('メッセージを保存しました');
      return result;
    } catch (e) {
      print('メッセージ保存でエラー: $e');
      return 0;
    }
  }

  // 全てのチャットの取得
  Future<List<Map<String, dynamic>>> getAllSelectChat() async {
    try {
      final db = await database;
      print('全チャットの取得開始');
      final result = await db.query('select_chat', orderBy: globalSortOrder);
      print('取得したチャット数: ${result.length}');
      return result;
    } catch (e) {
      print('getAllSelectChatでエラー: $e');
      return [];
    }
  }

  // 特定のチャットの取得
  Future<Map<String, dynamic>?> getSelectChatById(int id) async {
    try {
      final db = await database;
      print('チャット情報の取得開始 - id: $id');
      final result = await db.query(
        'select_chat',
        where: 'id = ?',
        whereArgs: [id],
      );
      print('チャット情報取得完了');
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      print('getSelectChatByIdでエラー: $e');
      return null;
    }
  }

  // チャットの更新日時を更新
  Future<void> updateChatUpdatedAt(int id) async {
    try {
      final db = await database;
      print('チャット更新日時の更新開始 - id: $id');
      await db.update(
        'select_chat',
        {'updated_at': DateTime.now().toString()},
        where: 'id = ?',
        whereArgs: [id],
      );
      print('更新日時を更新しました');
    } catch (e) {
      print('updateChatUpdatedAtでエラー: $e');
    }
  }

  // 新規チャットの作成
  Future<int?> insertNewChat() async {
    try {
      final db = await database;
      final currentTime = DateTime.now().toString();
      print('新規チャット作成開始');
      final result = await db.insert(
        'select_chat',
        {
          'title': '新しいchat',
          'created_at': currentTime,
          'updated_at': currentTime,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('新規チャットを作成しました: ID=$result');
      return result;
    } catch (e) {
      print('insertNewChatでエラー: $e');
      return null;
    }
  }

  // チャットタイトルの更新
  Future<void> updateChatTitle(String title, int id) async {
    try {
      final db = await database;
      print('チャットタイトル更新開始 - id: $id');
      await db.update(
        'select_chat',
        {'title': title},
        where: 'id = ?',
        whereArgs: [id],
      );
      print('チャットタイトルを更新しました');
    } catch (e) {
      print('updateChatTitleでエラー: $e');
    }
  }

  // チャットの削除
  Future<void> deleteChat(int id) async {
    try {
      final db = await database;
      print('チャット削除開始 - id: $id');
      await db.delete('select_chat', where: 'id = ?', whereArgs: [id]);
      await db.delete('chat', where: 'chat_id = ?', whereArgs: [id]);
      print('チャットを削除しました');
    } catch (e) {
      print('deleteChatでエラー: $e');
    }
  }
}
