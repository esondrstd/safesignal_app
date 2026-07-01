import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/models/outbox_event.dart';
import '../database/repositories/outbox_repository.dart';
import '../../state/app_providers.dart';

final supabase = Supabase.instance.client;

class OutboxService {
  final OutboxRepository _repo;
  final Ref ref;

  Timer? _timer;
  bool _isProcessing = false;

  OutboxService(this._repo, this.ref);

  // ============================================================
  // START LOOP
  // ============================================================
  void startRetryLoop() {
    _timer?.cancel();

    _timer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => processPendingEvents(),
    );

    print('OutboxService: retry loop started');
  }

  void stopRetryLoop() {
    _timer?.cancel();
    _timer = null;

    print('OutboxService: retry loop stopped');
  }

  // ============================================================
  // MAIN PROCESSOR (NO OVERLAP GUARANTEE)
  // ============================================================
  Future<void> processPendingEvents() async {
    if (_isProcessing) return;

    _isProcessing = true;

    try {
      final pending = await _repo.getPendingEvents(limit: 20);

      for (final event in pending) {
        if (event.id == null) continue;

        if (!_shouldRetry(event)) continue;

        await _processSingleEvent(event);
      }
    } catch (e) {
      print('OutboxService error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  // ============================================================
  // SINGLE EVENT PIPELINE
  // ============================================================
  Future<void> _processSingleEvent(OutboxEvent event) async {
    final id = event.id;
    if (id == null) return;

    // ❗ Check network FIRST (avoid wasted DB writes)
    if (!await _isOnline()) return;

    try {
      await _repo.markSending(id);

      await _syncToSupabase(event);

      await _repo.markDelivered(id);

      print('Outbox delivered id=$id');
    } catch (e) {
      await _repo.markFailed(id, statusCode: 500);

      await _repo.incrementRetryCount(id);

      print('Outbox failed id=$id: $e');
    }
  }

  // ============================================================
  // SUPABASE SYNC
  // ============================================================
  Future<void> _syncToSupabase(OutboxEvent e) async {
    final appState = ref.read(appStateProvider);

    final safeUserId = e.userId.isNotEmpty
        ? e.userId
        : appState.anonymousId;

    final payload = {
      'user_id': safeUserId,
      'parent_event_id': e.parentEventId,
      'hop': (e.content?['hop'] ?? 1),
      'ephemeral_id': e.content?['ephemeralId'] ?? 'unknown',
      'rssi': e.content?['rssi'],
      'status_code': e.statusCode,
      'lat': e.lat,
      'lng': e.lng,
      'content': e.content ?? {},
    };

    await supabase.from('mesh_events').insert(payload);
  }

  // ============================================================
  // NETWORK CHECK (SAFE + LIGHTWEIGHT)
  // ============================================================
  Future<bool> _isOnline() async {
    try {
      final result = await InternetAddress.lookup('google.com');

      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // BACKOFF STRATEGY
  // ============================================================
  bool _shouldRetry(OutboxEvent event) {
    final lastAttempt = event.lastAttemptAt ?? event.createdAt;

    final delaySeconds = 2 * (event.retryCount + 1);

    final nextAllowed = lastAttempt.add(
      Duration(seconds: delaySeconds),
    );

    return DateTime.now().isAfter(nextAllowed);
  }
}