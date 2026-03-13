import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite service for the Smart Check-in MVP.
///
/// Stores check-in and check-out data for the [class_sessions] table.
///
/// Typical usage:
///   // On check-in
///   final int sessionId = await DatabaseService.instance.saveCheckIn(data: {...});
///
///   // On check-out (using the id returned above)
///   await DatabaseService.instance.saveCheckOut(id: sessionId, data: {...});
class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  static const String _dbName = 'smart_checkin.db';
  static const int _dbVersion = 1;
  static const String _table = 'class_sessions';

  /// Set to the row id each time [saveCheckIn] succeeds.
  /// [FinishClassScreen] reads this to update the same row on check-out.
  static int? lastCheckInId;

  Database? _db;

  // ── Initialisation ────────────────────────────────────────────────────────

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_table (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,

        -- Check-in fields
        checkin_time    TEXT,
        checkin_lat     REAL,
        checkin_lng     REAL,
        qr_checkin      TEXT,
        previous_topic  TEXT,
        expected_topic  TEXT,
        mood            INTEGER,

        -- Check-out fields (nullable until checkout)
        checkout_time   TEXT,
        checkout_lat    REAL,
        checkout_lng    REAL,
        qr_checkout     TEXT,
        learned_today   TEXT,
        feedback        TEXT
      )
    ''');
  }

  // ── saveCheckIn ───────────────────────────────────────────────────────────

  /// Inserts a new session row with check-in data.
  ///
  /// Returns the auto-generated row [id] which should be stored in screen
  /// state so [saveCheckOut] can update the same row later.
  ///
  /// Required keys in [data]:
  ///   checkin_time    (String  – ISO-8601)
  ///   checkin_lat     (double)
  ///   checkin_lng     (double)
  ///   qr_checkin      (String)
  ///   previous_topic  (String)
  ///   expected_topic  (String)
  ///   mood            (int  1-5)
  Future<int> saveCheckIn({required Map<String, dynamic> data}) async {
    final db = await database;
    final id = await db.insert(
      _table,
      {
        'checkin_time': data['checkin_time'],
        'checkin_lat': data['checkin_lat'],
        'checkin_lng': data['checkin_lng'],
        'qr_checkin': data['qr_checkin'],
        'previous_topic': data['previous_topic'],
        'expected_topic': data['expected_topic'],
        'mood': data['mood'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    DatabaseService.lastCheckInId = id;
    return id;
  }

  // ── saveCheckOut ──────────────────────────────────────────────────────────

  /// Updates an existing session row (identified by [id]) with check-out data.
  ///
  /// Required keys in [data]:
  ///   checkout_time   (String  – ISO-8601)
  ///   checkout_lat    (double)
  ///   checkout_lng    (double)
  ///   qr_checkout     (String)
  ///   learned_today   (String)
  ///   feedback        (String)
  Future<void> saveCheckOut({
    required int id,
    required Map<String, dynamic> data,
  }) async {
    final db = await database;
    await db.update(
      _table,
      {
        'checkout_time': data['checkout_time'],
        'checkout_lat': data['checkout_lat'],
        'checkout_lng': data['checkout_lng'],
        'qr_checkout': data['qr_checkout'],
        'learned_today': data['learned_today'],
        'feedback': data['feedback'],
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Returns every session row, newest first. Useful for a history screen.
  Future<List<Map<String, dynamic>>> getAllSessions() async {
    final db = await database;
    return db.query(_table, orderBy: 'id DESC');
  }

  /// Closes the database connection (call only when truly done, e.g. tests).
  Future<void> close() async {
    final db = await database;
    await db.close();
    _db = null;
  }
}
