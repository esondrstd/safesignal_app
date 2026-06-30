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
        statusCode: 200,
        createdAt: DateTime.now(),
        status: 'queued',
        retryCount: 0,
        type: 'relay',
        parentEventId: e.id!,
        content: {
          'ephemeralId': e.ephemeralId,
          'rssi': e.rssi,
        },
        lat: e.receiverLat,
        lng: e.receiverLng,
        address: null,
        userId: 'mesh-node',
      );

      final id = await outboxService.queueEvent(outboxEvent);
      print('Mesh: queued relay outbox_event id=$id from inbox_event id=${e.id}');
    }
  }
}
