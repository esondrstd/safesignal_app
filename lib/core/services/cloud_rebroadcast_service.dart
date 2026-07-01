import 'package:safesignal/core/database/models/outbox_event.dart';
import 'package:safesignal/core/database/repositories/outbox_repository.dart';

class CloudRebroadcastService {
  final OutboxRepository _repo;

  CloudRebroadcastService(this._repo);

  Future<void> rebroadcast(OutboxEvent cloudEvent, String localUserId) async {
    try {
      final eph = cloudEvent.content?['ephemeralId'];
      final hop = cloudEvent.content?['hop'] ?? 1;

      // ------------------------------------------------------------
      // ⭐ TTL: ignore events older than 30 seconds
      // ------------------------------------------------------------
      final age = DateTime.now().difference(cloudEvent.createdAt);
      if (age > const Duration(seconds: 30)) {
        print("Rebroadcast skipped: TTL expired");
        return;
      }

      // ------------------------------------------------------------
      // ⭐ Max hop count: stop after hop 6
      // ------------------------------------------------------------
      if (hop >= 6) {
        print("Rebroadcast skipped: max hop reached");
        return;
      }

      // ------------------------------------------------------------
      // ⭐ Loop prevention: skip if already rebroadcast
      // ------------------------------------------------------------
      if (await _repo.hasRebroadcast(eph, hop)) {
        print("Rebroadcast skipped: already rebroadcast eph=$eph hop=$hop");
        return;
      }

      // Record this rebroadcast to prevent future loops
      await _repo.recordRebroadcast(eph, hop);

      // ------------------------------------------------------------
      // ⭐ Build Hop N+1
      // ------------------------------------------------------------

      // ⭐ FIX: Prevent null crash when cloudEvent.content is null
      final baseContent = cloudEvent.content ?? {};

      final newEvent = OutboxEvent(
        statusCode: cloudEvent.statusCode,
        createdAt: DateTime.now(),
        status: 'queued',
        retryCount: 0,
        type: 'relay',
        parentEventId: cloudEvent.parentEventId,
        content: {
          ...baseContent,
          'hop': hop + 1,
          'source': 'cloud-rebroadcast',
        },
        emergencyCategory: cloudEvent.emergencyCategory,
        lat: cloudEvent.lat,
        lng: cloudEvent.lng,
        address: cloudEvent.address,
        userId: localUserId,
      );

      // Insert Hop N+1 into Outbox → delivery → upload → realtime → other devices
      await _repo.queueEvent(newEvent);

      print("Cloud rebroadcast: created Hop ${hop + 1} for eph=$eph");

    } catch (e) {
      print("Cloud rebroadcast error: $e");
    }
  }
}
