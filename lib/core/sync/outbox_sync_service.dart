import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/models/outbox_event.dart';
import '../database/repositories/outbox_repository.dart';
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
        // ⭐ FIX: Prevent null id crash
        if (event.id == null) {
          print("OutboxSyncService: event has null id, skipping");
          continue;
        }

        await _syncSingleEvent(event);
        await repo.markDelivered(event.id!);

      } catch (e) {
        // ⭐ FIX: Prevent null id crash
        if (event.id != null) {
          await repo.incrementRetryCount(event.id!);
        }
        print("OutboxSyncService error: $e");
      }
    }
  }

  // ------------------------------------------------------------
  // SYNC ONE EVENT → mesh_events → emergencies (if needed)
  // ------------------------------------------------------------
  Future<void> _syncSingleEvent(OutboxEvent event) async {
    // 1. Upload to mesh_events
    final meshEventId = await _uploadMeshEvent(event);

    // 2. If emergency → create emergency row
    if (event.type == "emergency") {
      await _uploadEmergencyRow(event, meshEventId);

      // Store parentEventId for EmergencyDetailsScreen
      ref
          .read(emergencyStateProvider.notifier)
          .setParentEventId(meshEventId);
    }
  }

  // ------------------------------------------------------------
  // UPLOAD OUTBOX EVENT → mesh_events
  // ------------------------------------------------------------
  Future<int> _uploadMeshEvent(OutboxEvent event) async {
    // ⭐ FIX: Prevent null/empty userId crash
    final safeUserId = event.userId.isNotEmpty ? event.userId : "unknown";

    final response = await supabase
        .from("mesh_events")
        .insert({
          "created_at": event.createdAt.toIso8601String(),
          "user_id": safeUserId,
          "parent_event_id": event.parentEventId,
          "status_code": event.statusCode,
          "lat": event.lat,
          "lng": event.lng,
          "content": event.content ?? {},   // ⭐ FIX: safe fallback
        })
        .select("id")
        .single();

    return response["id"] as int;
  }

  // ------------------------------------------------------------
  // CREATE EMERGENCY ROW (OFFLINE PATH)
  // ------------------------------------------------------------
  Future<void> _uploadEmergencyRow(
      OutboxEvent event, int meshEventId) async {
    await EmergencyApi.createAlertFromOutboxEvent(
      alertType: event.content?["alert_type"] ?? "unknown",
      userId: event.userId,
      parentEventId: meshEventId,
      emergencyCategory: event.emergencyCategory,
    );
  }
}
