import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/database/repositories/outbox_repository.dart';
import '../../state/app_providers.dart';
import 'package:safesignal/core/services/emergency_alert_service.dart';

// ------------------------------------------------------------
// EMERGENCY ALERT SERVICE PROVIDER
// ------------------------------------------------------------
final emergencyAlertServiceProvider =
    Provider<EmergencyAlertService>((ref) {
  return EmergencyAlertService(ref);
});

// ------------------------------------------------------------
// EMERGENCY STATE
// ------------------------------------------------------------
final emergencyStateProvider =
    StateNotifierProvider<EmergencyStateNotifier, EmergencyState>(
  (ref) => EmergencyStateNotifier(ref),
);

class EmergencyState {
  final String? alertId;            // Supabase emergencies.id
  final int? parentEventId;         // LOCAL sqlite id
  final String? cloudEventId;       // Supabase mesh_events.id ⭐ FIX

  EmergencyState({
    this.alertId,
    this.parentEventId,
    this.cloudEventId,
  });

  EmergencyState copyWith({
    String? alertId,
    int? parentEventId,
    String? cloudEventId,
  }) {
    return EmergencyState(
      alertId: alertId ?? this.alertId,
      parentEventId: parentEventId ?? this.parentEventId,
      cloudEventId: cloudEventId ?? this.cloudEventId,
    );
  }
}

// ------------------------------------------------------------
// EMERGENCY STATE NOTIFIER
// ------------------------------------------------------------
class EmergencyStateNotifier extends StateNotifier<EmergencyState> {
  final Ref ref;

  EmergencyStateNotifier(this.ref) : super(EmergencyState());

  void setAlertId(String id) {
    state = state.copyWith(alertId: id);
  }

  void setParentEventId(int id) {
    state = state.copyWith(parentEventId: id);
  }

  void setCloudEventId(String id) {
    state = state.copyWith(cloudEventId: id);
  }

  // ------------------------------------------------------------
  // SUBMIT DETAILS
  // ------------------------------------------------------------
  Future<void> submitAdditionalDetails({
    required String? category,
    required String? description,
    required int? parentEventId,
    required String alertType,
  }) async {
    final supabase = Supabase.instance.client;

    final appState = ref.read(appStateProvider);
    final userId = appState.anonymousId;

    // ------------------------------------------------------------
    // ONLINE ALERT (direct Supabase emergency)
    // ------------------------------------------------------------
    if (state.alertId != null && state.alertId!.isNotEmpty) {
      await supabase
          .from("emergencies")
          .update({
            "user_id": userId,
            "alert_type": alertType,
            "emergency_category": category,
            if (description != null && description.isNotEmpty)
              "emergency_description": description,
          })
          .eq("id", state.alertId!)
          .select();

      state = state.copyWith(parentEventId: parentEventId);
      return;
    }

    // ------------------------------------------------------------
    // OFFLINE ALERT (mesh-based)
    // ------------------------------------------------------------

    final cloudId = state.cloudEventId;

    if (cloudId != null && cloudId.isNotEmpty) {
      // ⭐ FIX: use CLOUD mesh_event.id, NOT local parentEventId

      final updateResponse = await supabase
          .from("emergencies")
          .update({
            "user_id": userId,
            "alert_type": alertType,
            "emergency_category": category,
            if (description != null && description.isNotEmpty)
              "emergency_description": description,
          })
          .eq("parent_event_id", int.parse(cloudId)) // ⭐ FIX HERE
          .select();

      final bool noRowsUpdated = updateResponse.isEmpty;

      if (noRowsUpdated) {
        await supabase.from("emergencies").insert({
          "parent_event_id": int.parse(cloudId), // ⭐ FIX HERE
          "user_id": userId,
          "alert_type": alertType,
          "emergency_category": category,
          if (description != null && description.isNotEmpty)
            "emergency_description": description,
        });
      }

      // update local outbox metadata
      if (category != null) {
        final repo = await ref.read(outboxRepositoryProvider.future);
        final events = await repo.buildHopChain(parentEventId ?? 0);

        if (events.isNotEmpty) {
          final event = events.last;
          final updated = event.copyWith(emergencyCategory: category);
          await repo.queueEvent(updated);
        }
      }

      state = state.copyWith(parentEventId: parentEventId);
    }
  }
}