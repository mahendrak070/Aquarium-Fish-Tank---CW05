import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Future<Database> database() async {
    return openDatabase(
      join(await getDatabasesPath(), 'aquarium.db'),
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE settings(id INTEGER PRIMARY KEY, fishCount INTEGER, speed REAL, color INTEGER)",
        );
      },
      version: 1,
    );
  }

  static Future<void> saveSettings(
      int fishCount, double speed, int color) async {
    final db = await database();
    await db.insert(
      'settings',
      {'id': 1, 'fishCount': fishCount, 'speed': speed, 'color': color},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<Map<String, dynamic>> loadSettings() async {
    final db = await database();
    final List<Map<String, dynamic>> maps =
        await db.query('settings', where: 'id = ?', whereArgs: [1]);

    if (maps.isNotEmpty) {
      return maps.first;
    } else {
      // Default settings if nothing is saved
      return {
        'fishCount': 0,
        'speed': 1.0,
        'color': 0xFFFF0000
      }; // Default to red
    }
  }
}