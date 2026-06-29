//This is the central struct that holds anonymousId, installSecret, and all SafeSignal flags.

class AppState {
  // Identity
  final String anonymousId;
  final String installSecret;
  final String? ephemeralId;
  final DateTime? lastEphemeralRotation;

  // Status
  final int statusBits;
  final int timestampBucket;
  final String appInstanceHash;

  // Modes
  final bool offlineSafetyModeEnabled;
  final bool emergencyActive;
  final bool bleAdvertisingActive;
  final bool bleScanningActive;

  // Connectivity
  final bool isOnline;
  final bool supabaseConnected;

  const AppState({
    required this.anonymousId,
    required this.installSecret,
    this.ephemeralId,
    this.lastEphemeralRotation,
    required this.statusBits,
    required this.timestampBucket,
    required this.appInstanceHash,
    required this.offlineSafetyModeEnabled,
    required this.emergencyActive,
    required this.bleAdvertisingActive,
    required this.bleScanningActive,
    required this.isOnline,
    required this.supabaseConnected,
  });

  // Initial/default state
  factory AppState.initial() => const AppState(
        anonymousId: '',
        installSecret: '',
        ephemeralId: null,
        lastEphemeralRotation: null,
        statusBits: 0,
        timestampBucket: 0,
        appInstanceHash: '',
        offlineSafetyModeEnabled: false,
        emergencyActive: false,
        bleAdvertisingActive: false,
        bleScanningActive: false,
        isOnline: false,
        supabaseConnected: false,
      );

  // Immutable update helper
  AppState copyWith({
    String? anonymousId,
    String? installSecret,
    String? ephemeralId,
    DateTime? lastEphemeralRotation,
    int? statusBits,
    int? timestampBucket,
    String? appInstanceHash,
    bool? offlineSafetyModeEnabled,
    bool? emergencyActive,
    bool? bleAdvertisingActive,
    bool? bleScanningActive,
    bool? isOnline,
    bool? supabaseConnected,
  }) {
    return AppState(
      anonymousId: anonymousId ?? this.anonymousId,
      installSecret: installSecret ?? this.installSecret,
      ephemeralId: ephemeralId ?? this.ephemeralId,
      lastEphemeralRotation:
          lastEphemeralRotation ?? this.lastEphemeralRotation,
      statusBits: statusBits ?? this.statusBits,
      timestampBucket: timestampBucket ?? this.timestampBucket,
      appInstanceHash: appInstanceHash ?? this.appInstanceHash,
      offlineSafetyModeEnabled:
          offlineSafetyModeEnabled ?? this.offlineSafetyModeEnabled,
      emergencyActive: emergencyActive ?? this.emergencyActive,
      bleAdvertisingActive:
          bleAdvertisingActive ?? this.bleAdvertisingActive,
      bleScanningActive: bleScanningActive ?? this.bleScanningActive,
      isOnline: isOnline ?? this.isOnline,
      supabaseConnected: supabaseConnected ?? this.supabaseConnected,
    );
  }
}
