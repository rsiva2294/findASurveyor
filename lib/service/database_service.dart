
import 'package:find_a_surveyor/model/surveyor_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  // The database instance is now a private member variable
  Database? _database;

  // Public constructor
  DatabaseService();

  // The public getter still handles the async initialization automatically
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('favorites.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const nullableTextType = 'TEXT';
    const intType = 'INTEGER NOT NULL';
    const nullableIntType = 'INTEGER';
    const realType = 'REAL';

    await db.execute('''
      CREATE TABLE favorites ( 
        id $idType, 
        surveyorNameEn $textType,
        cityEn $textType,
        stateEn $textType,
        profilePictureUrl $nullableTextType,
        pincode $nullableTextType,
        mobileNo $nullableTextType,
        emailAddr $nullableTextType,
        departments $textType,
        licenseExpiryDate $nullableIntType,
        iiislaLevel $nullableTextType,
        iiislaMembershipNumber $nullableTextType,
        latitude $realType,
        longitude $realType,
        tierRank $intType
      )
    ''');
  }

  // --- CRUD Operations ---

  Future<void> addFavorite(Surveyor surveyor) async {
    final db = await database;
    // Use the toMap() method for insertion
    await db.insert(
      'favorites',
      surveyor.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Surveyor>> getFavorites() async {
    final db = await database;
    final maps = await db.query('favorites', orderBy: 'surveyorNameEn ASC');

    if (maps.isEmpty) {
      return [];
    }

    // Use the fromMap() factory constructor to create Surveyor objects
    return maps.map((map) => Surveyor.fromMap(map)).toList();
  }

  Future<void> removeFavorite(String id) async {
    final db = await database;
    await db.delete(
      'favorites',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> isFavorite(String id) async {
    final db = await database;
    final maps = await db.query(
      'favorites',
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [id],
    );
    return maps.isNotEmpty;
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}