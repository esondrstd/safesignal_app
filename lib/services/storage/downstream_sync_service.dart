import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safesignal/core/database/models/outbox_event.dart';
import 'package:safesignal/core/database/repositories/outbox_repository.dart';

class DownstreamSyncService {
  final OutboxRepository _repo;
  final supabase = Supabase.instance.client;

  DownstreamSyncService(this._repo);

  Future<void> syncFromSupabase(String userId) async {
    try {
      // 1. Pull all events NOT created by this device
      final response = await supabase
          .from('mesh_events')
          .select()
          .neq('user_id', userId)
          .order('created_at', ascending: false);

      final List<dynamic> rows = response;

      for (final row in rows) {
        final exists = await _repo.existsByParentEventId(row['id']);
        if (exists) continue;

        final outboxEvent = OutboxEvent(
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

        await _repo.queueEvent(outboxEvent);
      }

      print("Downstream sync complete: ${rows.length} events");

    } catch (e) {
      print("Downstream sync error: $e");
    }
  }
}
