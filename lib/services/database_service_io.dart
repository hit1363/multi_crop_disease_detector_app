import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/scan_record.dart';

class DatabaseService {
  DatabaseService._internal();

  factory DatabaseService() => _instance;

  static final DatabaseService _instance = DatabaseService._internal();

  static const String _databaseName = 'scan_history.db';
  static const int _databaseVersion = 4;
  static const String _tableName = 'scans';

  Database? _database;

  Future<Database> get database async {
    final existingDatabase = _database;
    if (existingDatabase != null) {
      return existingDatabase;
    }

    final databasePath = await getDatabasesPath();
    final path = p.join(databasePath, _databaseName);

    final database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            image_path TEXT,
            image_bytes TEXT,
            disease_name TEXT,
            disease_id TEXT,
            confidence REAL,
            timestamp TEXT,
            crop_name TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE $_tableName ADD COLUMN crop_name TEXT');
        }
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE $_tableName ADD COLUMN image_bytes TEXT',
          );
        }
        if (oldVersion < 4) {
          await db.execute(
            'ALTER TABLE $_tableName ADD COLUMN disease_id TEXT',
          );
        }
      },
    );

    _database = database;
    return database;
  }

  Future<int> insertScan(ScanRecord scan) async {
    final db = await database;
    return db.insert(
      _tableName,
      scan.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ScanRecord>> getAllScans() async {
    final db = await database;
    final rows = await db.query(_tableName, orderBy: 'timestamp DESC');
    return rows.map(ScanRecord.fromMap).toList(growable: false);
  }

  Future<int> deleteScan(int id) async {
    final db = await database;
    return db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
