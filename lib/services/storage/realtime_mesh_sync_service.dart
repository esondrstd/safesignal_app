import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safesignal/core/database/models/outbox_event.dart';
import 'package:safesignal/core/database/repositories/outbox_repository.dart';
import 'package:safesignal/core/services/cloud_rebroadcast_service.dart';

class RealtimeMeshSyncService {
  final OutboxRepository _repo;
  final SupabaseClient _supabase = Supabase.instance.client;

  RealtimeMeshSyncService(this._repo);

  void start(String localUserId) {
    final channel = _supabase.channel('mesh_events_channel');

    // ⭐ Correct API for your version
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'mesh_events',
      callback: (payload) async {
        try {
          final row = payload.newRecord;

          // Ignore events created by this device
          if (row['user_id'] == localUserId) return;

          // Avoid duplicates
          final exists = await _repo.existsByParentEventId(row['id']);
          if (exists) return;

          // Convert Supabase row → OutboxEvent
          final cloudEvent = OutboxEvent(
            statusCode: row['status_code'],
            createdAt: DateTime.parse(row['created_at']),
            status: 'delivered',
            retryCount: 0,
            type: 'relay',
            parentEventId: row['parent_event_id'],
            content: row['content'],
            emergencyCategory: null,
            lat: row['lat'],
            lng: row['lng'],
            address: null,
            userId: row['user_id'],
          );

          // Insert cloud event locally
          await _repo.queueEvent(cloudEvent);
          print("Realtime: Inserted cloud mesh event id=${row['id']}");

          // ⭐ Cloud → Device → Hop N+1 rebroadcast
          final rebroadcaster = CloudRebroadcastService(_repo);
          await rebroadcaster.rebroadcast(cloudEvent, localUserId);

        } catch (e) {
          print("Realtime mesh sync error: $e");
        }
      },
    );

    channel.subscribe();
    print("Realtime mesh sync subscribed");
  }
}
