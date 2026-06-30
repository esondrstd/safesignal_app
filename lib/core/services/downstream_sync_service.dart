import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safesignal/core/database/models/outbox_event.dart';
import 'package:safesignal/core/database/repositories/outbox_repository.dart';
import 'package:safesignal/core/services/cloud_rebroadcast_service.dart';

class DownstreamSyncService {
  final OutboxRepository _repo;
  final SupabaseClient _supabase = Supabase.instance.client;

  DownstreamSyncService(this._repo);

  // ------------------------------------------------------------
  // DOWNSTREAM SYNC: Pull mesh events from Supabase → local SQLite
  // ------------------------------------------------------------
  Future<void> syncFromSupabase(String localUserId) async {
    try {
      // 1. Pull all mesh events NOT created by this device
      final response = await _supabase
          .from('mesh_events')
          .select()
          .neq('user_id', localUserId)
          .order('created_at', ascending: false);

      final List<dynamic> rows = response;

      int insertedCount = 0;

      for (final row in rows) {
        // 2. Skip if already stored locally
        final exists = await _repo.existsByParentEventId(row['id']);
        if (exists) continue;

        // 3. Convert Supabase row → OutboxEvent
        final outboxEvent = OutboxEvent(
          statusCode: row['status_code'],
          createdAt: DateTime.parse(row['created_at']),
          status: 'delivered', // cloud events are already delivered
          retryCount: 0,
          type: 'relay',
          parentEventId: row['parent_event_id'],
          content: row['content'],
          emergencyCategory: null,
          lat: row['lat'],
          lng: row['lng'],
          address: null,
          userId: row['user_id'], // original device identity
        );

        // 4. Insert into local SQLite
        await _repo.queueEvent(outboxEvent);
        insertedCount++;

        // ------------------------------------------------------------
        // ⭐ 5. REBROADCAST CLOUD EVENT → Hop N+1
        // ------------------------------------------------------------
        final rebroadcaster = CloudRebroadcastService(_repo);
        await rebroadcaster.rebroadcast(outboxEvent, localUserId);
      }

      print("Downstream sync complete: $insertedCount new events");

    } catch (e) {
      print("Downstream sync error: $e");
    }
  }
}
