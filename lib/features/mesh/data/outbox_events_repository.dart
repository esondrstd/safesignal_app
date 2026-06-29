import 'package:sqflite/sqflite.dart';

class OutboxEventsRepository {
  final Database db;

  OutboxEventsRepository(this.db);

  Future<int> insertOutboxEvent({
    required int statusCode,
    required String status,
    required String type,
    required String content,
    required double lat,
    required double lng,
    required String userId,
    String? address,
    int? parentEventId,
  }) async {
    return await db.insert('outbox_events', {
      'status_code': statusCode,
      'created_at': DateTime.now().toIso8601String(),
      'last_attempt_at': null,
      'status': status,
      'retry_count': 0,
      'type': type,
      'parent_event_id': parentEventId,
      'content': content,
      'lat': lat,
      'lng': lng,
      'address': address,
      'user_id': userId,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingOutboxEvents() async {
    return await db.query(
      'outbox_events',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'created_at ASC',
    );
  }

  Future<void> markAttempt(int id) async {
    await db.update(
      'outbox_events',
      {
        'last_attempt_at': DateTime.now().toIso8601String(),
        'retry_count': 1,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markCompleted(int id) async {
    await db.update(
      'outbox_events',
      {'status': 'completed'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
