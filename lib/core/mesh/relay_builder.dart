import 'package:safesignal/core/database/models/outbox_event.dart';
import 'package:safesignal/core/database/models/inbox_event.dart';

class RelayBuilder {
  static OutboxEvent buildRelay({
    required InboxEvent inbox,
    required String userId,
    required int hop,
  }) {
    return OutboxEvent(
      statusCode: inbox.statusCode,        // 0/1/2 severity
      createdAt: DateTime.now(),
      status: 'queued',
      retryCount: 0,
      type: 'relay',

      // InboxEvent fields that actually exist
      parentEventId: inbox.id,
      lat: inbox.receiverLat ?? 0.0,       // fallback if null
      lng: inbox.receiverLng ?? 0.0,
      userId: userId,

      // Relay content payload
      content: {
        'ephemeralId': inbox.ephemeralId,
        'rssi': inbox.rssi,
        'detectedAt': inbox.detectedAt.toIso8601String(),
        'hop': hop,
      },
    );
  }
}
