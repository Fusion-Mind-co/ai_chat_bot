// database_service.dart

import 'package:flutter/foundation.dart'; // kIsWebを使うために必要
import 'sqlite_database.dart';
import 'indexeddb_database.dart';
import 'database_interface.dart';

class DatabaseService {
  static DatabaseInterface? _instance;

  static DatabaseInterface getDatabaseInstance() {
    if (_instance == null) {
      // ここで適切にデータベースのインスタンスを作成しているか確認
      if (kIsWeb) {
        _instance = IndexedDBDatabase();
        print('Web用のIndexedDBが初期化されました');
      } else {
        _instance = SQLiteDatabase();
        print('モバイル用のSQLiteが初期化されました');
      }
    }
    return _instance!;
  }
}
