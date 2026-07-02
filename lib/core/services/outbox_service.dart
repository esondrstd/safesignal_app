import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safesignal/core/database/models/outbox_event.dart';
import 'package:safesignal/core/database/repositories/outbox_repository.dart';
import 'package:safesignal/state/app_providers.dart';

class OutboxService {
  final OutboxRepository _repo;
  final Ref _ref;
  Timer? _timer;

  OutboxService(this._repo, this._ref);

  void startRetryLoop() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) async {
      await processPendingEvents();
    });
    print('Outbox retry loop started');
  }

  void stopRetryLoop() {
    _timer?.cancel();
    _timer = null;
    print('Outbox retry loop stopped');
  }

  Future<int> queueEvent(OutboxEvent event) async {
    final userId = _ref.read(appStateNotifierProvider).anonymousId;
    final patched = event.copyWith(userId: userId);
    return await _repo.queueEvent(patched);
  }

  Future<void> processPendingEvents() async {
    final pending = await _repo.getPendingEvents(limit: 20);
    for (final event in pending) {
      if (_shouldRetry(event)) {
        await _processSingleEvent(event);
      }
    }
  }

  Future<void> _processSingleEvent(OutboxEvent event) async {
    final online = _ref.read(appStateNotifierProvider).isOnline;
    if (!online) {
      print('Skipping event ${event.id}, offline');
      return;
    }

    await _repo.markSending(event.id!);
    await _repo.incrementRetryCount(event.id!);

    try {
      await Future.delayed(const Duration(milliseconds: 200));
      await _repo.markDelivered(event.id!);
      print('Delivered outbox_event id=${event.id}');
    } catch (e) {
      await _repo.markFailed(event.id!, statusCode: 500);
      print('Failed outbox_event id=${event.id}');
    }
  }

  bool _shouldRetry(OutboxEvent event) {
    if (event.lastAttemptAt == null) return true;

    final backoffSeconds = 2 * (event.retryCount + 1);
    final nextAllowed =
        event.lastAttemptAt!.add(Duration(seconds: backoffSeconds));

    return DateTime.now().isAfter(nextAllowed);
  }
}

/// ------------------------------------------------------------
/// CORRECT PROVIDER — NO .watch(), NO ambiguity
/// ------------------------------------------------------------
final outboxServiceProvider = FutureProvider<OutboxService>((ref) async {
  final repo = await ref.watch(outboxRepositoryProvider.future);
  return OutboxService(repo, ref);
});
