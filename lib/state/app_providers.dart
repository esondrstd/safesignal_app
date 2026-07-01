import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_state.dart';
import 'app_state_notifier.dart';

/// The notifier provider — used by services and initialization logic.
/// This is the one your AppInitializer and OutboxService expect.
final appStateNotifierProvider =
    StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier();
});

/// The read-only provider — used by widgets.
/// This lets UI read the AppState without exposing mutation methods.
final appStateProvider = Provider<AppState>((ref) {
  return ref.watch(appStateNotifierProvider);
});

