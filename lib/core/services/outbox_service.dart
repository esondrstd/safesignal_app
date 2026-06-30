import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safesignal/core/database/models/outbox_event.dart';
import 'package:safesignal/core/database/repositories/outbox_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class OutboxService {
  final OutboxRepository _repo;
  Timer? _timer;

  OutboxService(this._repo);

  // ------------------------------------------------------------
  // START PERIODIC RETRY LOOP
  // ------------------------------------------------------------
  void startRetryLoop() {
    _timer?.cancel();

    _timer = Timer.periodic(
      const Duration(seconds: 10),
      (_) async {
        await processPendingEvents();
      },
    );

    print('Outbox retry loop started');
  }

  void stopRetryLoop() {
    _timer?.cancel();
    _timer = null;
    print('Outbox retry loop stopped');
  }

  // ------------------------------------------------------------
  // QUEUE NEW OUTBOX EVENT
  // ------------------------------------------------------------
  Future<int> queueEvent(OutboxEvent event) async {
    return await _repo.queueEvent(event);
  }

  // ------------------------------------------------------------
  // PROCESS ALL PENDING EVENTS
  // ------------------------------------------------------------
  Future<void> processPendingEvents() async {
    final pending = await _repo.getPendingEvents(limit: 20);

    for (final event in pending) {
      if (_shouldRetry(event)) {
        await _processSingleEvent(event);
      }
    }
  }

  // ------------------------------------------------------------
  // PROCESS ONE EVENT (DELIVERY + SUPABASE SYNC)
  // ------------------------------------------------------------
  Future<void> _processSingleEvent(OutboxEvent event) async {
    // Skip if offline
    final online = await _isOnline();
    if (!online) {
      print('Skipping event ${event.id}, offline');
      return;
    }

    await _repo.markSending(event.id!);
    await _repo.incrementRetryCount(event.id!);

    try {
      // ------------------------------------------------------------
      // 1. DELIVER EVENT (BLE / HTTP / etc.)
      // ------------------------------------------------------------
      // In production, replace this with real delivery logic.
      await Future.delayed(const Duration(milliseconds: 200));

      // Mark delivered locally
      await _repo.markDelivered(event.id!);

      print(
        'Delivered outbox_event id=${event.id} '
        '(category=${event.emergencyCategory}, type=${event.type})'
      );

      // ------------------------------------------------------------
      // 2. SYNC TO SUPABASE
      // ------------------------------------------------------------
      await _syncToSupabase(event);

    } catch (e) {
      await _repo.markFailed(event.id!, statusCode: 500);

      print(
        'Failed outbox_event id=${event.id} '
        '(category=${event.emergencyCategory}, type=${event.type})'
      );
    }
  }

  // ------------------------------------------------------------
  // SUPABASE SYNC
  // ------------------------------------------------------------
  Future<void> _syncToSupabase(OutboxEvent e) async {
    try {
      final payload = {
        'user_id': e.userId,
        'parent_event_id': e.parentEventId,
        'hop': e.content?['hop'] ?? 1,
        'ephemeral_id': e.content?['ephemeralId'] ?? 'unknown',
        'rssi': e.content?['rssi'],
        'status_code': e.statusCode,
        'lat': e.lat,
        'lng': e.lng,
        'content': e.content ?? {},
      };

      await supabase.from('mesh_events').insert(payload);

      print('Supabase: synced mesh_event for outbox_event id=${e.id}');
    } catch (err) {
      print('Supabase sync error for outbox_event id=${e.id}: $err');
      // Optional: add sync_failed flag in DB if needed
    }
  }

  // ------------------------------------------------------------
  // NETWORK CHECK
  // ------------------------------------------------------------
  Future<bool> _isOnline() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ------------------------------------------------------------
  // EXPONENTIAL BACKOFF
  // ------------------------------------------------------------
  bool _shouldRetry(OutboxEvent event) {
    if (event.lastAttemptAt == null) return true;

    final backoffSeconds = 2 * (event.retryCount + 1);
    final nextAllowed =
        event.lastAttemptAt!.add(Duration(seconds: backoffSeconds));

    return DateTime.now().isAfter(nextAllowed);
  }
}

// ------------------------------------------------------------
// RIVERPOD PROVIDER
// ------------------------------------------------------------
final outboxServiceProvider = Provider<OutboxService>((ref) {
  final repoAsync = ref.watch(outboxRepositoryProvider);

  return repoAsync.maybeWhen(
    data: (repo) => OutboxService(repo),
    orElse: () => throw Exception('OutboxRepository not ready yet'),
  );
});







