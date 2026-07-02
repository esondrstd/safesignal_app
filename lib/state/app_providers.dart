import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';

import 'app_state.dart';
import 'app_state_notifier.dart';

import 'package:safesignal/core/database/repositories/inbox_repository.dart';
import 'package:safesignal/core/database/repositories/outbox_repository.dart';
import 'package:safesignal/core/database/sqlite_database_provider.dart';

import 'package:safesignal/core/services/connectivity_watcher.dart';

/// ------------------------------------------------------------
/// APP STATE PROVIDERS
/// ------------------------------------------------------------

final appStateNotifierProvider =
    StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier();
});

final appStateProvider = Provider<AppState>((ref) {
  return ref.watch(appStateNotifierProvider);
});

/// ------------------------------------------------------------
/// SUPABASE CLIENT PROVIDER (normalized access)
/// ------------------------------------------------------------

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// ------------------------------------------------------------
/// DATABASE REPOSITORY PROVIDERS
/// ------------------------------------------------------------
/// These match your actual repository constructors:
/// InboxRepository(Database db)
/// OutboxRepository(Database db)

final inboxRepositoryProvider =
    FutureProvider<InboxRepository>((ref) async {
  final db = await ref.watch(sqliteDatabaseProvider.future);
  return InboxRepository(db);
});

final outboxRepositoryProvider =
    FutureProvider<OutboxRepository>((ref) async {
  final db = await ref.watch(sqliteDatabaseProvider.future);
  return OutboxRepository(db);
});

/// ------------------------------------------------------------
/// CONNECTIVITY WATCHER PROVIDER
/// ------------------------------------------------------------

final connectivityWatcherProvider = Provider<ConnectivityWatcher>((ref) {
  return ConnectivityWatcher(ref);
});
