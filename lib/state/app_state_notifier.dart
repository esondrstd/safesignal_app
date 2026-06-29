//This is the “brain” that mutates AppState.  All identity and mode changes go through a single, testable controller.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_state.dart';

class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(AppState.initial());

  // Identity
  void setAnonymousId(String id) {
    state = state.copyWith(anonymousId: id);
  }

  void setInstallSecret(String secret) {
    state = state.copyWith(installSecret: secret);
  }

  void setEphemeralId(String id, DateTime rotationTime) {
    state = state.copyWith(
      ephemeralId: id,
      lastEphemeralRotation: rotationTime,
    );
  }

  // Status
  void setStatusBits(int bits) {
    state = state.copyWith(statusBits: bits);
  }

  void setTimestampBucket(int bucket) {
    state = state.copyWith(timestampBucket: bucket);
  }

  void setAppInstanceHash(String hash) {
    state = state.copyWith(appInstanceHash: hash);
  }

  // Modes
  void setOfflineSafetyMode(bool enabled) {
    state = state.copyWith(offlineSafetyModeEnabled: enabled);
  }

  void setEmergencyActive(bool active) {
    state = state.copyWith(emergencyActive: active);
  }

  void setBleAdvertisingActive(bool active) {
    state = state.copyWith(bleAdvertisingActive: active);
  }

  void setBleScanningActive(bool active) {
    state = state.copyWith(bleScanningActive: active);
  }

  // Connectivity
  void setOnline(bool online) {
    state = state.copyWith(isOnline: online);
  }

  void setSupabaseConnected(bool connected) {
    state = state.copyWith(supabaseConnected: connected);
  }
}
