import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Core init
import 'core/app_initializer.dart';

// Inbox + BLE
import 'core/database/repositories/inbox_repository.dart';
import 'package:safesignal/core/services/ble_scan_service.dart';

// Providers
import 'state/app_providers.dart';

// Core screens only
import 'screens/home_screen.dart';
import 'screens/emergency_countdown_screen.dart';
import 'screens/emergency_details_screen.dart';

import 'package:safesignal/core/database/models/outbox_event.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://vpcqpfrrcicydpnjmgeb.supabase.co',
    publishableKey: 'sb_publishable_D2-ROQYpebR4NynUHLKEFg_0nYtrdd0',
  );

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
    try {
      // 1. Bootstrap identity + app state
      final initializer = AppInitializer(ref);
      await initializer.initialize();

      // 2. BLE scanning (core system)
      final inboxRepo = await ref.read(inboxRepositoryProvider.future);
      final ble = BleScanService(inboxRepo);
      await ble.startScanning();

      setState(() => _initialized = true);
    } catch (e) {
      debugPrint("INIT ERROR: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeSignal',
      theme: ThemeData.dark(),
      initialRoute: '/',

      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const HomeScreen());

          case '/countdown':
            final alertType = settings.arguments as String;
            return MaterialPageRoute(
              builder: (_) => EmergencyCountdownScreen(
                alertType: alertType,
              ),
            );

          case '/details':
            final alertId = settings.arguments;

            // HARD FIX: normalize type
            final int parsedAlertId = alertId is int
                ? alertId
                : int.tryParse(alertId.toString()) ?? -1;

            return MaterialPageRoute(
              builder: (_) => EmergencyDetailsScreen(
                alertId: parsedAlertId,
              ),
            );

          default:
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(child: Text("Unknown Route")),
              ),
            );
        }
      },

      home: _initialized
          ? const HomeScreen()
          : const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
    );
  }
}