import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:safesignal/core/database/models/outbox_event.dart';
import 'package:safesignal/core/database/sqlite_database_provider.dart';

class OutboxRepository {
  final Database db;

  OutboxRepository(this.db);

  // Insert a new event into the outbox queue
  Future<int> queueEvent(OutboxEvent event) async {
    return await db.insert(
      'outbox_events',
      event.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Fetch events that are still pending delivery (status = 'queued')
  Future<List<OutboxEvent>> getPendingEvents({int limit = 20}) async {
    final rows = await db.query(
      'outbox_events',
      where: 'status = ?',
      whereArgs: ['queued'],
      orderBy: 'created_at ASC',
      limit: limit,
    );

    return rows.map((row) => OutboxEvent.fromMap(row)).toList();
  }

  // Mark event as currently being sent
  Future<void> markSending(int id) async {
    await db.update(
      'outbox_events',
      {
        'status': 'sending',
        'last_attempt_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Mark event as delivered
  Future<void> markDelivered(int id) async {
    await db.update(
      'outbox_events',
      {
        'status': 'delivered',
        'last_attempt_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Mark event as failed (optional statusCode)
  Future<void> markFailed(int id, {int? statusCode}) async {
    await db.update(
      'outbox_events',
      {
        'status': 'failed',
        'status_code': ?statusCode,
        'last_attempt_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Increment retry_count
  Future<void> incrementRetryCount(int id) async {
    await db.rawUpdate('''
      UPDATE outbox_events
      SET retry_count = retry_count + 1
      WHERE id = ?
    ''', [id]);
  }

  // Delete old delivered events to keep DB small
  Future<int> deleteOldEvents({int days = 7}) async {
    final cutoff = DateTime.now().subtract(Duration(days: days)).toIso8601String();

    return await db.delete(
      'outbox_events',
      where: 'status = ? AND created_at < ?',
      whereArgs: ['delivered', cutoff],
    );
  }
}

// Riverpod provider
final outboxRepositoryProvider = FutureProvider<OutboxRepository>((ref) async {
  final db = await ref.watch(sqliteDatabaseProvider.future);
  return OutboxRepository(db);
});

