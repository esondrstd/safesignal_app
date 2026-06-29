class InboxEventsRepository {
  final Database db;

  InboxEventsRepository(this.db);

  Future<int> insertInboxEvent({
    required String ephemeralId,
    required int statusCode,
    required int rssi,
    required DateTime detectedAt,
    double? lat,
    double? lng,
  }) async {
    return await db.insert('inbox_events', {
      'ephemeral_id': ephemeralId,
      'status_code': statusCode,
      'rssi': rssi,
      'detected_at': detectedAt.toIso8601String(),
      'receiver_location_lat': lat,
      'receiver_location_lng': lng,
    });
  }

  Future<List<Map<String, dynamic>>> getRecentInboxEvents() async {
    return await db.query(
      'inbox_events',
      orderBy: 'detected_at DESC',
      limit: 200,
    );
  }
}
