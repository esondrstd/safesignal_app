import 'package:safesignal/core/database/models/inbox_event.dart';
import 'package:safesignal/core/database/models/outbox_event.dart';

class RelayBuilder {
  static OutboxEvent buildRelay({
    required InboxEvent inbox,
    required String userId,
    required int hop,
  }) {
    return OutboxEvent(
      statusCode: inbox.statusCode ?? 0,   // relays inherit severity if present
      createdAt: DateTime.now(),
      status: 'queued',
      retryCount: 0,
      type: 'relay',
      parentEventId: inbox.id,             // ⭐ correct field

      // ⭐ Mesh relay payload stored in TEXT "content"
      content: {
        'ephemeralId': inbox.ephemeralId,
        'hop': hop,
        'rssi': inbox.rssi,
        'detectedAt': inbox.detectedAt.toIso8601String(),
      },

      // ⭐ InboxEvent does NOT have emergencyCategory → relays use null
      emergencyCategory: null,

      // ⭐ lat/lng are NOT NULL in schema → must be non-null
      lat: inbox.receiverLat ?? 0.0,
      lng: inbox.receiverLng ?? 0.0,

      // ⭐ InboxEvent does NOT have address → null
      address: null,

      userId: userId,
    );
  }
}

