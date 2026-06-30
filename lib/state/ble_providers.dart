// lib/state/ble_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safesignal/core/services/ble_scan_service.dart';
import 'package:safesignal/core/database/repositories/inbox_repository.dart';

final bleScanServiceProvider = FutureProvider<BleScanService>((ref) async {
  final inboxRepo = await ref.read(inboxRepositoryProvider.future);
  return BleScanService(inboxRepo);
});
