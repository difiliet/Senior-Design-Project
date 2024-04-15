import 'dart:io';
import 'package:applicants/JsonModels/userLogEntry.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:path/path.dart';
import 'package:applicants/JsonModels/user.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:intl/intl.dart';

class DatabaseHelper {
  final databaseName = "applicants.db";
  String userTable = "CREATE TABLE users (userId INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT NOT NULL, password TEXT NOT NULL, predictionsEnabled BOOLEAN NOT NULL, primaryColor TEXT NOT NULL, secondaryColor NOT NULL)";
  String userLogTemplate = "CREATE TABLE placeholder (entryId INTEGER PRIMARY KEY AUTOINCREMENT, entryDateTime DATETIME NOT NULL, workoutType TEXT NOT NULL, repetitions INT, time INT, weight FLOAT, notes TEXT)";
  
  Future<Database> initDB() async {
    // Handle windows or linux (Android and IOS do not need this)
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
    }
    databaseFactory = databaseFactoryFfi;

    final databasePath = await getDatabasesPath();
    final path = join(databasePath, databaseName);
    
    return await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute(userTable);
    });
  }

  // Login
  Future<bool> login(User user) async {
    final Database db = await initDB();
    var result = await db.rawQuery("SELECT * FROM users WHERE username = '${user.username}'");
    List<User> userSettings = result.map((e) => User.fromMap(e)).toList();

    if (userSettings.length == 1 && BCrypt.checkpw(user.password, userSettings[0].password)) {
      return true;
    } else {
      return false;
    }
  }

  // Signup
  Future<int> signup(User user) async {
    int status = 0;
    final Database db = await initDB();
    
    // Ensure username is not taken
    var result = await db.rawQuery("SELECT * FROM users WHERE username = '${user.username}'");
    if (!result.isNotEmpty) {
      // Hash and salt password before putting it into the database
      user.password = BCrypt.hashpw(user.password, BCrypt.gensalt());
      status = await db.insert('users', user.toMap());

      // Create user's table
      String userLogTable = userLogTemplate.replaceFirst('placeholder', '${user.username}EntryLog');
      await db.execute(userLogTable);
    }

    return status;
  }

  // Get user settings
  Future<User> getUserSettings(String username) async {
    final Database db = await initDB();
    List<Map<String, Object?>> result = await db.rawQuery("SELECT * FROM users WHERE username = '$username'");
    List<User> userSettings = result.map((e) => User.fromMap(e)).toList();
    return userSettings.first;
  }

  // Update user settings
  Future<int> updateUserSettings(String username, int predictionsEnabled, String primaryColor, String secondaryColor) async {
    final Database db = await initDB();
    return db.rawUpdate(
      'UPDATE users SET predictionsEnabled = ?, primaryColor = ?, secondaryColor = ? WHERE username = ?',
      [predictionsEnabled, primaryColor, secondaryColor, username]
    );
  }

  // Create log entry
  Future<int> createLogEntry(String userTable, UserLogEntry entry) async {
    final Database db = await initDB();
    return db.insert(userTable, entry.toMap());
  }

  // Get log entries
  Future<List<UserLogEntry>> getLogEntries(String userTable) async {
    final Database db = await initDB();
    List<Map<String, Object?>> result = await db.query(userTable);
    return result.map((e) => UserLogEntry.fromMap(e)).toList();
  }

  // Get log entries for specific dates
  Future<List<UserLogEntry>> getLogEntriesForDate(String userTable, String dateString) async {
    final Database db = await initDB();
    List<Map<String, Object?>> result = await db.rawQuery("SELECT * FROM $userTable WHERE entryDateTime BETWEEN '$dateString 00:00:00' AND '$dateString 24:00:00';");
    return result.map((e) => UserLogEntry.fromMap(e)).toList();
  }

  // Get log entries between specific dates
  Future<List<UserLogEntry>> getLogEntriesBetweenDates(String userTable, String fromDateString, String toDateString) async {
    final Database db = await initDB();
    List<Map<String, Object?>> result = await db.rawQuery("SELECT * FROM $userTable WHERE entryDateTime BETWEEN '$fromDateString 00:00:00' AND '$toDateString 24:00:00';");
    return result.map((e) => UserLogEntry.fromMap(e)).toList();
  }

  // Update log entry
  Future<int> updateLogEntry(String userTable, DateTime entryDateTime, String workoutType, int ? repetitions, int ? time, double ? weight, String ? notes, entryId) async {
    final Database db = await initDB();
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String formatedEntryDate = dateFormat.format(entryDateTime);

    return db.rawUpdate(
      'UPDATE $userTable SET entryDateTime = ?, workoutType = ?, repetitions = ?, time = ?, weight = ?, notes = ? WHERE entryId = ?',
      [formatedEntryDate, workoutType, repetitions, time, weight, notes, entryId]
    );
  }

  // Delete log entry
  Future<int> deleteLogEntry(String userTable, int id) async {
    final Database db = await initDB();
    return db.delete(userTable, where: 'entryId = ?', whereArgs: [id]);
  }
}