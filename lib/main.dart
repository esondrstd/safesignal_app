import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:safesignal/core/app/app_initializer.dart';
import 'package:safesignal/services/storage/secure_storage_service.dart';

import 'package:safesignal/state/app_providers.dart';
import 'package:safesignal/core/services/ble_scan_service.dart';
import 'package:safesignal/core/services/outbox_service.dart';

import 'shared/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: SafeSignalApp()));
}

class SafeSignalApp extends ConsumerStatefulWidget {
  const SafeSignalApp({super.key});

  @override
  ConsumerState<SafeSignalApp> createState() => _SafeSignalAppState();
}

class _SafeSignalAppState extends ConsumerState<SafeSignalApp> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // 1. Initialize app identity + Supabase
    final secureStorage = SecureStorageService();
    final initializer = AppInitializer(ref, secureStorage);
    await initializer.initialize();

    // 2. Start connectivity watcher
    final watcher = ref.read(connectivityWatcherProvider);
    watcher.start();

    // 3. Start OutboxService retry loop
    final outboxService =
    await ref.read(outboxServiceProvider.future);

    outboxService.startRetryLoop();

    // 4. Start BLE scanning
    final inboxRepo = await ref.read(inboxRepositoryProvider.future);
    final bleScanService = BleScanService(inboxRepo);
    await bleScanService.startScanning();

    setState(() => _initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      title: 'SafeSignal',
      theme: ThemeData.dark(),
      home: HomeScreen(),   // MUST NOT be const
    );
  }
}
