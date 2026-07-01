import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/models/outbox_event.dart';
import '../../state/app_providers.dart';
import '../../state/emergency_providers.dart';
import '../supabase/emergency_api.dart';

final outboxSyncServiceProvider =
    Provider<OutboxSyncService>((ref) => OutboxSyncService(ref));

class OutboxSyncService {
  final Ref ref;
  OutboxSyncService(this.ref);

  final supabase = Supabase.instance.client;

  // ------------------------------------------------------------
  // MAIN ENTRYPOINT
  // ------------------------------------------------------------
  Future<void> syncPendingEvents() async {
    final repo = await ref.read(outboxRepositoryProvider.future);
    final pending = await repo.getPendingEvents();

    for (final event in pending) {
      try {
        // prevent crash
        if (event.id == null) {
          print("OutboxSyncService: null id skipped");
          continue;
        }

        await _syncSingleEvent(event);
        await repo.markDelivered(event.id!);

      } catch (e) {
        if (event.id != null) {
          await repo.incrementRetryCount(event.id!);
        }
        print("OutboxSyncService error: $e");
      }
    }
  }

  // ------------------------------------------------------------
  // SYNC ONE EVENT
  // ------------------------------------------------------------
  Future<void> _syncSingleEvent(OutboxEvent event) async {
    final meshEventId = await _uploadMeshEvent(event);

    if (event.type == "emergency") {
      await _uploadEmergencyRow(event, meshEventId);

      ref.read(emergencyStateProvider.notifier)
          .setParentEventId(meshEventId);
    }
  }

  // ------------------------------------------------------------
  // UPLOAD → mesh_events
  // ------------------------------------------------------------
  Future<int> _uploadMeshEvent(OutboxEvent event) async {
    final safeUserId =
        event.userId.isNotEmpty ? event.userId : "unknown";

    final response = await supabase
        .from("mesh_events")
        .insert({
          "created_at": event.createdAt.toIso8601String(),
          "user_id": safeUserId,
          "parent_event_id": event.parentEventId,
          "status_code": event.statusCode,
          "lat": event.lat,
          "lng": event.lng,
          "content": event.content ?? {},
        })
        .select("id")
        .single();

    return response["id"] as int;
  }

  // ------------------------------------------------------------
  // EMERGENCY ROW SYNC
  // ------------------------------------------------------------
  Future<void> _uploadEmergencyRow(
    OutboxEvent event,
    int meshEventId,
  ) async {
    await EmergencyApi.createAlertFromOutboxEvent(
      alertType: event.content?["alert_type"] ?? "unknown",
      userId: event.userId,
      parentEventId: meshEventId,
      emergencyCategory: event.emergencyCategory,
    );
  }
}