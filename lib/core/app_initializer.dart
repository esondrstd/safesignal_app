import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/app_providers.dart';
import '../services/storage/secure_storage_service.dart';
import '../services/storage/install_secret_generator.dart';

class AppInitializer {
  final WidgetRef ref;
  final SecureStorageService _secureStorage;

  AppInitializer(this.ref) : _secureStorage = SecureStorageService();

  Future<void> initialize() async {
    final appStateNotifier = ref.read(appStateProvider.notifier);

    // 1. Load anonymousId (for now, placeholder).
    final anonymousId = await _loadAnonymousId();
    appStateNotifier.setAnonymousId(anonymousId);

    // 2. Load or generate installSecret.
    var installSecret = await _secureStorage.getInstallSecret();
    if (installSecret == null || installSecret.isEmpty) {
      installSecret = InstallSecretGenerator.generate();
      await _secureStorage.setInstallSecret(installSecret);
    }
    appStateNotifier.setInstallSecret(installSecret);

    // 3. Compute appInstanceHash.
    final appInstanceHash = _computeAppInstanceHash(
      anonymousId: anonymousId,
      installSecret: installSecret,
    );
    appStateNotifier.setAppInstanceHash(appInstanceHash);

    // 4. Set initial connectivity flags (we’ll make these real later).
    appStateNotifier.setOnline(true); // placeholder
    appStateNotifier.setSupabaseConnected(true); // placeholder
  }

  Future<String> _loadAnonymousId() async {
    // TODO: replace with real Supabase anonymous ID.
    return 'anon-placeholder';
  }

  String _computeAppInstanceHash({
    required String anonymousId,
    required String installSecret,
  }) {
    final combined = '$anonymousId::$installSecret';
    return combined.hashCode.toRadixString(16);
  }
}
