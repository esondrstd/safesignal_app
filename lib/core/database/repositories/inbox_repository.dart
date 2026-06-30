import 'package:sqflite/sqflite.dart';
import '../sqlite_database_provider.dart';
import '../models/inbox_event.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InboxRepository {
  final Database db;

  InboxRepository(this.db);

  // ⭐ Normal BLE ingestion
  Future<int> addInboxEvent(InboxEvent event) async {
    return await db.insert('inbox_events', event.toMap());
  }

  // ⭐ Simulation: Insert a fake BLE event (for emulator / iPhone testing)
  Future<int> simulateBleEvent({
    String? ephemeralId,
    int rssi = -55,
  }) async {
    final fakeId = ephemeralId ?? "SIM-${DateTime.now().millisecondsSinceEpoch}";

    final event = InboxEvent(
      ephemeralId: fakeId,
      statusCode: 1,
      rssi: rssi,
      detectedAt: DateTime.now(),
      receiverLat: null,
      receiverLng: null,
    );

    final id = await addInboxEvent(event);
    print("SIMULATION: Inserted fake BLE inbox event id=$id eph=$fakeId rssi=$rssi");
    return id;
  }

  Future<List<InboxEvent>> getRecentInboxEvents({int limit = 50}) async {
    final rows = await db.rawQuery(
      'SELECT * FROM inbox_events ORDER BY detected_at DESC LIMIT ?',
      [limit],
    );
    return rows.map((r) => InboxEvent.fromMap(r)).toList();
  }

  Future<List<InboxEvent>> getInboxEventsByEphemeralId(String ephemeralId) async {
    final rows = await db.query(
      'inbox_events',
      where: 'ephemeral_id = ?',
      whereArgs: [ephemeralId],
      orderBy: 'detected_at DESC',
    );
    return rows.map((r) => InboxEvent.fromMap(r)).toList();
  }

  Future<int> deleteOldInboxEvents(DateTime cutoff) async {
    return await db.delete(
      'inbox_events',
      where: 'detected_at < ?',
      whereArgs: [cutoff.toIso8601String()],
    );
  }
}

// Riverpod provider
final inboxRepositoryProvider = FutureProvider<InboxRepository>((ref) async {
  final db = await ref.watch(sqliteDatabaseProvider.future);
  return InboxRepository(db);
});
