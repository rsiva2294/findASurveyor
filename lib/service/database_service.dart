import 'package:find_a_surveyor/model/surveyor_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  // The database instance is now a private member variable, not static.
  Database? _database;

  // Public constructor allows for dependency injection via Provider.
  DatabaseService();

  // The public getter handles the async initialization automatically.
  Future<Database> get database async {
    if (_database != null) return _database!;
    // If the database doesn't exist, initialize it.
    _database = await _initDB('favorites.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // --- DATABASE MIGRATION LOGIC ---
    // Increment the version to trigger the onUpgrade callback for existing users.
    return await openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _onUpgrade, // Provide the migration logic
    );
  }

  // The table schema is designed to store all fields from our Surveyor model.
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
        addressLine1 $nullableTextType,
        addressLine2 $nullableTextType,
        addressLine3 $nullableTextType,
        departments $textType,
        licenseExpiryDate $nullableIntType,
        iiislaLevel $nullableTextType,
        iiislaMembershipNumber $nullableTextType,
        latitude $realType,
        longitude $realType,
        tierRank $intType,
        professionalRank $intType,
        claimedByUID $nullableTextType,
        isVerified $intType NOT NULL,
        aboutMe $nullableTextType,
        surveyorSince $nullableIntType,
        empanelments $textType,
        altMobileNo $nullableTextType,
        altEmailAddr $nullableTextType,
        officeAddress $nullableTextType,
        websiteUrl $nullableTextType,
        linkedinUrl $nullableTextType
      )
    ''');
  }

  // This method is called automatically when the database version increases.
  // It safely handles the migration for existing users.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // We check the oldVersion to see what migrations need to be run.
    if (oldVersion < 5) {
      // For this simple cache, the easiest migration is to drop the old
      // table and recreate it with the new schema. This will clear existing
      // favorites, but they will be re-synced from the cloud.
      await db.execute('DROP TABLE IF EXISTS favorites');
      await _createDB(db, newVersion);
    }
  }

  // --- CRUD Operations for Local Favorites Cache ---

  /// Adds a surveyor to the local favorites database.
  Future<void> addFavorite(Surveyor surveyor) async {
    final db = await database;
    await db.insert(
      'favorites',
      surveyor.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieves all surveyors from the local favorites database.
  Future<List<Surveyor>> getFavorites() async {
    final db = await database;
    final maps = await db.query('favorites', orderBy: 'surveyorNameEn ASC');

    if (maps.isEmpty) {
      return [];
    }
    return maps.map((map) => Surveyor.fromMap(map)).toList();
  }

  /// Removes a surveyor from the local favorites database by their ID.
  Future<void> removeFavorite(String id) async {
    final db = await database;
    await db.delete(
      'favorites',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Checks if a surveyor with a given ID exists in the local favorites.
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

  /// Clears all favorites from the local database. Useful for syncing.
  Future<void> clearFavorites() async {
    final db = await database;
    await db.delete('favorites');
  }

  /// Inserts a list of surveyors in a single batch transaction.
  Future<void> bulkInsertFavorites(List<Surveyor> surveyors) async {
    final db = await database;
    final batch = db.batch();
    for (var surveyor in surveyors) {
      batch.insert(
          'favorites',
          surveyor.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> close() async {
    final db = await database;
    _database = null;
    await db.close();
  }
}