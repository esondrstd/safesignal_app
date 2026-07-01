// lib/core/services/emergency_alert_service.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../state/app_providers.dart';
import '../../state/emergency_providers.dart';

import '../database/models/outbox_event.dart';
import '../database/repositories/outbox_repository.dart';

class EmergencyAlertService {
  final Ref ref;

  EmergencyAlertService(this.ref);

  // ------------------------------------------------------------
  // PUBLIC ENTRYPOINT
  // ------------------------------------------------------------
  Future<void> triggerAlert(String type) async {
    final isOnline = await _checkOnline();

    if (isOnline) {
      await _sendToSupabase(type);
    } else {
      await _sendViaMeshRelay(type);
    }
  }

  // ------------------------------------------------------------
  // ONLINE CHECK
  // ------------------------------------------------------------
  Future<bool> _checkOnline() async {
    try {
      final supabase = Supabase.instance.client;

      await supabase
          .from('health')
          .select('id')
          .limit(1);

      return true;
    } catch (_) {
      return false;
    }
  }

  // ------------------------------------------------------------
  // ONLINE ALERT (ROOT EMERGENCY)
  // ------------------------------------------------------------
  Future<void> _sendToSupabase(String type) async {
    final supabase = Supabase.instance.client;
    final appState = ref.read(appStateProvider);

    final response = await supabase
        .from("emergencies")
        .insert({
          "alert_type": type,
          "created_at": DateTime.now().toIso8601String(),
          "user_id": appState.anonymousId,
        })
        .select("id")
        .single();

    // FIX: force int safety
    final dynamic rawId = response["id"];
    final int alertId = rawId is int ? rawId : int.parse(rawId.toString());

    ref.read(emergencyStateProvider.notifier).setAlertId(alertId);

    print("Emergency root alert created id=$alertId");
  }

  // ------------------------------------------------------------
  // OFFLINE ALERT (MESH RELAY)
  // ------------------------------------------------------------
  Future<void> _sendViaMeshRelay(String type) async {
    final repoAsync = ref.read(outboxRepositoryProvider.future);
    final OutboxRepository repo = await repoAsync;

    final appState = ref.read(appStateProvider);

    final int severity = switch (type) {
      "critical" => 2,
      "non_urgent" => 1,
      "safe" => 0,
      _ => 1,
    };

    final event = OutboxEvent(
      statusCode: severity,
      createdAt: DateTime.now(),
      status: "queued",
      retryCount: 0,
      type: "emergency",
      parentEventId: null,
      content: {
        "alert_type": type,
        "timestamp": DateTime.now().toIso8601String(),
      },
      emergencyCategory: null,
      lat: 0.0,
      lng: 0.0,
      address: null,
      userId: appState.anonymousId,
    );

    await repo.queueEvent(event);

    print("Offline emergency queued via mesh relay");
  }
}