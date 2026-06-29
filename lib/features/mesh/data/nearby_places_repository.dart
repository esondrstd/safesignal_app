import 'package:sqflite/sqflite.dart';

class NearbyPlacesRepository {
  final Database db;

  NearbyPlacesRepository(this.db);

  Future<List<Map<String, dynamic>>> getNearbyPlaces(String userId) async {
    return await db.query(
      'nearby_places',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'distance ASC',
    );
  }
}
