//This is how the rest of the app accesses AppState.  Is how widgets and services read and mutate global state.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_state.dart';
import 'app_state_notifier.dart';

final appStateProvider =
    StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier();
});
