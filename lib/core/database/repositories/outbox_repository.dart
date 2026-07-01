import 'dart:convert';
import 'package:sqflite/sqflite.dart';

import '../models/outbox_event.dart';

class OutboxRepository {
  final Database db;

  OutboxRepository(this.db);

  // ------------------------------------------------------------
  // INSERT NEW OUTBOX EVENT
  // ------------------------------------------------------------
  Future<int> queueEvent(OutboxEvent event) async {
    final map = event.toMap();

    // SQLite autoincrement safety
    map.remove('id');

    return await db.insert(
      'outbox_events',
      map,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  // ------------------------------------------------------------
  // FETCH PENDING EVENTS
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
  // FETCH RELAY EVENTS
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
  // DUPLICATE CHECK
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
  // REBROADCAST LOOP PROTECTION
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

  Future<void> recordRebroadcast(String eph, int hop) async {
    await db.insert('rebroadcast_history', {
      'ephemeral_id': eph,
      'hop': hop,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // ------------------------------------------------------------
  // HOP CHAIN
  // ------------------------------------------------------------
  Future<List<OutboxEvent>> buildHopChain(int parentEventId) async {
    final rows = await db.query(
      'outbox_events',
      where: 'parent_event_id = ?',
      whereArgs: [parentEventId],
      orderBy: 'created_at ASC',
    );

    return rows.map(_mapRowToEvent).toList();
  }

  // ------------------------------------------------------------
  // STATUS UPDATES
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

  Future<void> markFailed(int id, {int? statusCode}) async {
    await db.update(
      'outbox_events',
      {
        'status': 'failed',
        'status_code': statusCode,
        'last_attempt_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> incrementRetryCount(int id) async {
    await db.rawUpdate('''
      UPDATE outbox_events
      SET retry_count = retry_count + 1
      WHERE id = ?
    ''', [id]);
  }

  // ------------------------------------------------------------
  // CLEANUP
  // ------------------------------------------------------------
  Future<int> deleteOldEvents({int days = 7}) async {
    final cutoff = DateTime.now()
        .subtract(Duration(days: days))
        .toIso8601String();

    return db.delete(
      'outbox_events',
      where: 'status = ? AND created_at < ?',
      whereArgs: ['delivered', cutoff],
    );
  }

  // ------------------------------------------------------------
  // SAFE MAPPER (CRITICAL FIX)
  // ------------------------------------------------------------
  OutboxEvent _mapRowToEvent(Map<String, Object?> row) {
    final map = Map<String, Object?>.from(row);

    // ----------------------------
    // SAFE JSON CONTENT PARSING
    // ----------------------------
    final rawContent = map['content'];

    if (rawContent is String) {
      try {
        map['content'] = jsonDecode(rawContent);
      } catch (_) {
        map['content'] = null;
      }
    }

    // ----------------------------
    // SAFE TYPE NORMALIZATION
    // ----------------------------
    map['lat'] = (map['lat'] is num)
        ? (map['lat'] as num).toDouble()
        : 0.0;

    map['lng'] = (map['lng'] is num)
        ? (map['lng'] as num).toDouble()
        : 0.0;

    return OutboxEvent.fromMap(map);
  }
}