// lib/core/services/mesh_ingestion_service.dart

import 'package:safesignal/core/database/repositories/inbox_repository.dart';
import 'package:safesignal/core/services/outbox_service.dart';
import 'package:safesignal/core/database/models/outbox_event.dart';

class MeshIngestionService {
  final InboxRepository inboxRepository;
  final OutboxService outboxService;

  MeshIngestionService(this.inboxRepository, this.outboxService);

  Future<void> relayRecentInboxEvents() async {
    final events = await inboxRepository.getRecentInboxEvents(limit: 50);

    for (final e in events) {
      final outboxEvent = OutboxEvent(
        statusCode: e.statusCode,          // 0/1/2 severity
        createdAt: DateTime.now(),
        status: 'queued',
        retryCount: 0,
        type: 'relay',

        parentEventId: e.id,               // inbox event ID

        // Mesh relay payload stored in TEXT "content"
        content: {
          'ephemeralId': e.ephemeralId,
          'rssi': e.rssi,
          'detectedAt': e.detectedAt.toIso8601String(),
          'hop': 1,                        // ingestion always creates hop 1
        },

        emergencyCategory: null,           // relays do not carry category

        lat: e.receiverLat ?? 0.0,         // non-nullable in schema
        lng: e.receiverLng ?? 0.0,

        address: null,
        userId: 'mesh-node',
      );

      final id = await outboxService.queueEvent(outboxEvent);
      print('Mesh: queued relay outbox_event id=$id from inbox_event id=${e.id}');
    }
  }
}
