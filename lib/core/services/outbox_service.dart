import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safesignal/core/database/models/outbox_event.dart';
import 'package:safesignal/core/database/repositories/outbox_repository.dart';
import 'package:safesignal/state/app_providers.dart';


class OutboxService {
  final OutboxRepository _repo;
  final WidgetRef _ref;        // ⭐ FIX: use WidgetRef, not Ref
  Timer? _timer;

  OutboxService(this._repo, this._ref);

  // ------------------------------------------------------------
  // PHASE 2D — START PERIODIC RETRY LOOP
  // ------------------------------------------------------------
  void startRetryLoop() {
    _timer?.cancel(); // avoid duplicates

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
  // QUEUE NEW OUTBOX EVENT (auto‑inject anonymousId)
  // ------------------------------------------------------------
  Future<int> queueEvent(OutboxEvent event) async {
    final userId = _ref.read(appStateNotifierProvider).anonymousId;

    final patched = event.copyWith(userId: userId);

    return await _repo.queueEvent(patched);
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
  // PROCESS ONE EVENT
  // ------------------------------------------------------------
  Future<void> _processSingleEvent(OutboxEvent event) async {
    // Skip if offline (use global app state)
    final online = _ref.read(appStateNotifierProvider).isOnline;
    if (!online) {
      print('Skipping event ${event.id}, offline');
      return;
    }

    await _repo.markSending(event.id!);
    await _repo.incrementRetryCount(event.id!);

    try {
      // TODO: Replace with real Supabase call
      await Future.delayed(const Duration(milliseconds: 200));

      await _repo.markDelivered(event.id!);
      print('Delivered outbox_event id=${event.id}');
    } catch (e) {
      await _repo.markFailed(event.id!, statusCode: 500);
      print('Failed outbox_event id=${event.id}');
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
    data: (repo) => OutboxService(repo, ref as WidgetRef),   // ⭐ FIX: cast Ref → WidgetRef
    orElse: () => throw Exception('OutboxRepository not ready yet'),
  );
});
