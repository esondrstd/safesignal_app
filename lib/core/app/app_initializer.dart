import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safesignal/core/services/outbox_service.dart';

class AppInitializer {
  static Future<void> initialize(WidgetRef ref) async {
    // Start OutboxService retry loop (Phase 2D)
    final outboxService = ref.read(outboxServiceProvider);
    outboxService.startRetryLoop();

    print('AppInitializer: Outbox retry loop started');
  }
}
