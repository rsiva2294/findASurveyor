import 'package:find_a_surveyor/model/surveyor_model.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  Database? _database;

  DatabaseService();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('favorites.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);

      return await openDatabase(
        path,
        version: 5,
        onCreate: _createDB,
        onUpgrade: _onUpgrade,
      );
    } catch (e, stack) {
      await FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Database init failed');
      rethrow;
    }
  }

  Future _createDB(Database db, int version) async {
    try {
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
    } catch (e, stack) {
      await FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Creating favorites table failed');
      rethrow;
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      if (oldVersion < 5) {
        await db.execute('DROP TABLE IF EXISTS favorites');
        await _createDB(db, newVersion);
      }
    } catch (e, stack) {
      await FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Database upgrade failed');
      rethrow;
    }
  }

  Future<void> addFavorite(Surveyor surveyor) async {
    try {
      final db = await database;
      await db.insert(
        'favorites',
        surveyor.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e, stack) {
      await FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Add favorite failed');
      rethrow;
    }
  }

  Future<List<Surveyor>> getFavorites() async {
    try {
      final db = await database;
      final maps = await db.query('favorites', orderBy: 'surveyorNameEn ASC');

      if (maps.isEmpty) {
        return [];
      }
      return maps.map((map) => Surveyor.fromMap(map)).toList();
    } catch (e, stack) {
      await FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Get favorites failed');
      rethrow;
    }
  }

  Future<void> removeFavorite(String id) async {
    try {
      final db = await database;
      await db.delete(
        'favorites',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e, stack) {
      await FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Remove favorite failed');
      rethrow;
    }
  }

  Future<bool> isFavorite(String id) async {
    try {
      final db = await database;
      final maps = await db.query(
        'favorites',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [id],
      );
      return maps.isNotEmpty;
    } catch (e, stack) {
      await FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Check isFavorite failed');
      return false;
    }
  }

  Future<void> clearFavorites() async {
    try {
      final db = await database;
      await db.delete('favorites');
    } catch (e, stack) {
      await FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Clear favorites failed');
      rethrow;
    }
  }

  Future<void> bulkInsertFavorites(List<Surveyor> surveyors) async {
    try {
      final db = await database;
      final batch = db.batch();
      for (var surveyor in surveyors) {
        batch.insert(
          'favorites',
          surveyor.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (e, stack) {
      await FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Bulk insert favorites failed');
      rethrow;
    }
  }

  Future<void> close() async {
    try {
      final db = await database;
      _database = null;
      await db.close();
    } catch (e, stack) {
      await FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Closing database failed');
      rethrow;
    }
  }
}