import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/database/repositories/outbox_repository.dart';

final emergencyStateProvider =
    StateNotifierProvider<EmergencyStateNotifier, EmergencyState>(
  (ref) => EmergencyStateNotifier(ref),
);

class EmergencyState {
  final String? alertId;        // Supabase emergency row ID (uuid)
  final int? parentEventId;     // OutboxEvent.id (offline → cloud mapping)

  EmergencyState({
    this.alertId,
    this.parentEventId,
  });

  EmergencyState copyWith({
    String? alertId,
    int? parentEventId,
  }) {
    return EmergencyState(
      alertId: alertId ?? this.alertId,
      parentEventId: parentEventId ?? this.parentEventId,
    );
  }
}

class EmergencyStateNotifier extends StateNotifier<EmergencyState> {
  final Ref ref;

  EmergencyStateNotifier(this.ref) : super(EmergencyState());

  // Called by EmergencyAlertService after online send
  void setAlertId(String id) {
    state = state.copyWith(alertId: id);
  }

  // Called by Outbox sync layer when offline event is uploaded to Supabase
  void setParentEventId(int id) {
    state = state.copyWith(parentEventId: id);
  }

  // ------------------------------------------------------------
  // ADDITIONAL DETAILS (CATEGORY + DESCRIPTION)
  // ------------------------------------------------------------
  Future<void> submitAdditionalDetails({
    required String? category,
    required String? description,
    required int? parentEventId, // ⭐ NEW
  }) async {
    final supabase = Supabase.instance.client;

    // ------------------------------------------------------------
    // ONLINE ALERT → update by alertId
    // ------------------------------------------------------------
    if (state.alertId != null && state.alertId!.isNotEmpty) {
      await supabase
          .from("emergencies")
          .update({
            "emergency_category": category,
            if (description != null && description.isNotEmpty)
              "emergency_description": description,
          })
          .eq("id", state.alertId!);

      // Update local state
      state = state.copyWith(
        parentEventId: parentEventId,
      );

      return;
    }

    // ------------------------------------------------------------
    // OFFLINE ALERT → update by parent_event_id
    // ------------------------------------------------------------
    if (parentEventId != null) {
      await supabase
          .from("emergencies")
          .update({
            "emergency_category": category,
            if (description != null && description.isNotEmpty)
              "emergency_description": description,
          })
          .eq("parent_event_id", parentEventId);

      // Update OutboxEvent locally
      if (category != null) {
        final repo = await ref.read(outboxRepositoryProvider.future);

        // Fetch the hop chain starting at parentEventId
        final events = await repo.buildHopChain(parentEventId);

        if (events.isNotEmpty) {
          final event = events.first;

          final updated = event.copyWith(
            emergencyCategory: category,
          );

          await repo.queueEvent(updated); // reinsert updated event
        }
      }

      // Update local state
      state = state.copyWith(
        parentEventId: parentEventId,
      );

      return;
    }

    // ------------------------------------------------------------
    // Edge case: no alertId and no parentEventId
    // ------------------------------------------------------------
    // Nothing to attach yet — ignore silently.
  }
}
