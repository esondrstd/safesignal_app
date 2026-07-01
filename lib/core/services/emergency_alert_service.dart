// lib/core/emergency/emergency_alert_service.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/repositories/outbox_repository.dart';
import '../../state/app_providers.dart';
import '../../state/emergency_providers.dart';
import 'package:safesignal/core/database/models/outbox_event.dart';

final emergencyAlertServiceProvider =
    Provider<EmergencyAlertService>((ref) => EmergencyAlertService(ref));

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
      await supabase.from('health').select('*').limit(1);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ------------------------------------------------------------
  // SEND ALERT TO SUPABASE (ONLINE)
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

    final alertId = response["id"] as String;
    ref.read(emergencyStateProvider.notifier).setAlertId(alertId);
  }

  // ------------------------------------------------------------
  // SEND ALERT VIA MESH RELAY (OFFLINE)
  // ------------------------------------------------------------
  Future<void> _sendViaMeshRelay(String type) async {
    final repo = await ref.read(outboxRepositoryProvider.future);
    final appState = ref.read(appStateProvider);

    // Map alert type → severity code
    final int severity = switch (type) {
      "critical" => 2,
      "non_urgent" => 1,
      "safe" => 0,
      _ => 1,
    };

    final event = OutboxEvent(
      id: null, // autoincrement
      statusCode: severity,
      createdAt: DateTime.now(),
      lastAttemptAt: null,
      status: "queued",
      retryCount: 0,

      type: "emergency",
      parentEventId: null,

      content: {
        "alert_type": type,
        "timestamp": DateTime.now().toIso8601String(),
      },

      emergencyCategory: null, // user fills this later in Supabase only

      lat: 0.0, // required double
      lng: 0.0, // required double
      address: null,

      userId: appState.anonymousId,
    );

    await repo.queueEvent(event);
  }
}


