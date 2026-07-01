// lib/core/supabase/emergency_api.dart

import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class EmergencyApi {
  // ------------------------------------------------------------
  // CREATE INITIAL EMERGENCY ALERT (ONLINE)
  // ------------------------------------------------------------
  //
  // This is called by EmergencyAlertService when online.
  // It creates the cloud emergency row and returns its UUID.
  //
  static Future<String> createInitialAlert({
    required String alertType,
    required String userId,
    int? parentEventId, // used if offline event later syncs
  }) async {
    final response = await supabase
        .from("emergencies")
        .insert({
          "alert_type": alertType,
          "created_at": DateTime.now().toIso8601String(),
          "user_id": userId,
          "parent_event_id": ?parentEventId,
        })
        .select("id")
        .single();

    return response["id"] as String;
  }

  // ------------------------------------------------------------
  // UPDATE EMERGENCY CATEGORY + DESCRIPTION
  // ------------------------------------------------------------
  //
  // Called by EmergencyStateNotifier.submitAdditionalDetails().
  //
  // emergency_category → stored in Supabase AND OutboxEvent (if offline)
  // emergency_description → stored ONLY in Supabase
  //
  static Future<void> updateAlertDetailsById({
    required String alertId,
    required String? category,
    required String? description,
  }) async {
    await supabase
        .from("emergencies")
        .update({
          "emergency_category": category,
          if (description != null && description.isNotEmpty)
            "emergency_description": description,
        })
        .eq("id", alertId);
  }

  // ------------------------------------------------------------
  // UPDATE EMERGENCY DETAILS USING PARENT EVENT ID
  // ------------------------------------------------------------
  //
  // Used when the alert was sent OFFLINE.
  // The OutboxEvent.id becomes parent_event_id in Supabase.
  //
  static Future<void> updateAlertDetailsByParentEventId({
    required int parentEventId,
    required String? category,
    required String? description,
  }) async {
    await supabase
        .from("emergencies")
        .update({
          "emergency_category": category,
          if (description != null && description.isNotEmpty)
            "emergency_description": description,
        })
        .eq("parent_event_id", parentEventId);
  }

  // ------------------------------------------------------------
  // USED BY OUTBOX SYNC LAYER
  // ------------------------------------------------------------
  //
  // When an offline OutboxEvent is uploaded to Supabase,
  // the sync layer calls this to create the cloud row
  // and attach parent_event_id = OutboxEvent.id.
  //
  static Future<String> createAlertFromOutboxEvent({
    required String alertType,
    required String userId,
    required int parentEventId,
    required String? emergencyCategory,
  }) async {
    final response = await supabase
        .from("emergencies")
        .insert({
          "alert_type": alertType,
          "created_at": DateTime.now().toIso8601String(),
          "user_id": userId,
          "parent_event_id": parentEventId,
          "emergency_category": emergencyCategory,
        })
        .select("id")
        .single();

    return response["id"] as String;
  }
}
