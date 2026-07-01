import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/repositories/outbox_repository.dart';
import '../core/services/outbox_service.dart';
import '../core/database/sqlite_database_provider.dart';

/// ----------------------------
/// OUTBOX REPOSITORY
/// ----------------------------
final outboxRepositoryProvider =
    FutureProvider<OutboxRepository>((ref) async {
  final db = await ref.watch(sqliteDatabaseProvider.future);
  return OutboxRepository(db);
});

/// ----------------------------
/// OUTBOX SERVICE (FIXED - NO THROW, NO WHEN)
/// ----------------------------
/// We keep it FutureProvider so initialization is deterministic.
final outboxServiceProvider =
    FutureProvider<OutboxService>((ref) async {
  final repo = await ref.watch(outboxRepositoryProvider.future);
  return OutboxService(repo, ref);
});