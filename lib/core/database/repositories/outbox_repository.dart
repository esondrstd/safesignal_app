import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:safesignal/core/database/models/outbox_event.dart';
import 'package:safesignal/core/database/sqlite_database_provider.dart';
import 'dart:convert';

class OutboxRepository {
  final Database db;

  OutboxRepository(this.db);

  // ------------------------------------------------------------
  // INSERT NEW OUTBOX EVENT
  // ------------------------------------------------------------
  Future<int> queueEvent(OutboxEvent event) async {
    return await db.insert(
      'outbox_events',
      event.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ------------------------------------------------------------
  // FETCH PENDING EVENTS (status = queued)
  // ------------------------------------------------------------
  Future<List<OutboxEvent>> getPendingEvents({int limit = 20}) async {
    final rows = await db.query(
      'outbox_events',
      where: 'status = ?',
      whereArgs: ['queued'],
      orderBy: 'created_at ASC',
      limit: limit,
    );

    return rows.map(_mapRowToEvent).toList();
  }

  // ------------------------------------------------------------
  // ⭐ FETCH ALL RELAY EVENTS (MERGED LOCAL + CLOUD)
  // ------------------------------------------------------------
  Future<List<OutboxEvent>> getAllRelayEvents({int limit = 500}) async {
    final rows = await db.query(
      'outbox_events',
      where: 'type = ?',
      whereArgs: ['relay'],
      orderBy: 'created_at ASC',
      limit: limit,
    );

    return rows.map(_mapRowToEvent).toList();
  }

  // ------------------------------------------------------------
  // ⭐ CHECK IF CLOUD EVENT ALREADY EXISTS LOCALLY
  // ------------------------------------------------------------
  Future<bool> existsByParentEventId(int parentId) async {
    final rows = await db.query(
      'outbox_events',
      where: 'parent_event_id = ?',
      whereArgs: [parentId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  // ------------------------------------------------------------
  // ⭐ STEP 7: LOOP PREVENTION — CHECK REBROADCAST HISTORY
  // ------------------------------------------------------------
  Future<bool> hasRebroadcast(String eph, int hop) async {
    final rows = await db.query(
      'rebroadcast_history',
      where: 'ephemeral_id = ? AND hop = ?',
      whereArgs: [eph, hop],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  // ------------------------------------------------------------
  // ⭐ STEP 7: LOOP PREVENTION — RECORD REBROADCAST
  // ------------------------------------------------------------
  Future<void> recordRebroadcast(String eph, int hop) async {
    await db.insert(
      'rebroadcast_history',
      {
        'ephemeral_id': eph,
        'hop': hop,
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }

  // ------------------------------------------------------------
  // ⭐ STEP 8: BUILD FULL HOP CHAIN FOR A GIVEN EVENT
  // ------------------------------------------------------------
  Future<List<OutboxEvent>> buildHopChain(int parentEventId) async {
    final rows = await db.query(
      'outbox_events',
      where: 'parent_event_id = ?',
      whereArgs: [parentEventId],
      orderBy: 'created_at ASC',   // ensures hop chain order
    );

    return rows.map(_mapRowToEvent).toList();
  }

  // ------------------------------------------------------------
  // MARK SENDING
  // ------------------------------------------------------------
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

  // ------------------------------------------------------------
  // MARK DELIVERED
  // ------------------------------------------------------------
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

  // ------------------------------------------------------------
  // MARK FAILED
  // ------------------------------------------------------------
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

  // ------------------------------------------------------------
  // INCREMENT RETRY COUNT
  // ------------------------------------------------------------
  Future<void> incrementRetryCount(int id) async {
    await db.rawUpdate('''
      UPDATE outbox_events
      SET retry_count = retry_count + 1
      WHERE id = ?
    ''', [id]);
  }

  // ------------------------------------------------------------
  // DELETE OLD DELIVERED EVENTS
  // ------------------------------------------------------------
  Future<int> deleteOldEvents({int days = 7}) async {
    final cutoff = DateTime.now()
        .subtract(Duration(days: days))
        .toIso8601String();

    return await db.delete(
      'outbox_events',
      where: 'status = ? AND created_at < ?',
      whereArgs: ['delivered', cutoff],
    );
  }

  // ------------------------------------------------------------
  // INTERNAL: MAP ROW → OUTBOX EVENT
  // ------------------------------------------------------------
  OutboxEvent _mapRowToEvent(Map<String, Object?> row) {
    final mutable = Map<String, Object?>.from(row);

    if (mutable['content'] != null && mutable['content'] is String) {
      try {
        mutable['content'] = jsonDecode(mutable['content'] as String);
      } catch (_) {
        mutable['content'] = null;
      }
    }

    return OutboxEvent.fromMap(mutable);
  }
}

// ------------------------------------------------------------
// RIVERPOD PROVIDER
// ------------------------------------------------------------
final outboxRepositoryProvider = FutureProvider<OutboxRepository>((ref) async {
  final db = await ref.watch(sqliteDatabaseProvider.future);
  return OutboxRepository(db);
});
