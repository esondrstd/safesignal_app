import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// App State + Initialization
import 'core/app_initializer.dart';

// SQLite + Repositories + Models
import 'core/database/repositories/inbox_repository.dart';
import 'core/database/repositories/outbox_repository.dart';
import 'package:safesignal/core/database/models/outbox_event.dart';

// Services
import 'package:safesignal/core/services/outbox_service.dart';
import 'package:safesignal/core/services/ble_scan_service.dart';

// Screens
import 'screens/home_screen.dart';
import 'screens/mesh_graph_screen.dart';
import 'screens/mesh_analytics_screen.dart';
import 'screens/mesh_map_screen.dart';
import 'screens/propagation_timeline_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://vpcqpfrrcicydpnjmgeb.supabase.co',
    publishableKey: 'sb_publishable_D2-ROQYpebR4NynUHLKEFg_0nYtrdd0',
  );

  runApp(const ProviderScope(child: SafeSignalApp()));
}

final supabase = Supabase.instance.client;

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
    final initializer = AppInitializer(ref);
    await initializer.initialize();

    final outboxRepo = await ref.read(outboxRepositoryProvider.future);
    final outboxService = OutboxService(outboxRepo);
    outboxService.startRetryLoop();

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
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const HomeScreen());

          case '/mesh_graph':
            return MaterialPageRoute(builder: (_) => const MeshGraphScreen());

          case '/mesh_analytics':
            return MaterialPageRoute(builder: (_) => const MeshAnalyticsScreen());

          case '/mesh_map':
            return MaterialPageRoute(builder: (_) => const MeshMapScreen());

          case '/timeline':
            final args = settings.arguments;
            final chain = (args is List<OutboxEvent>) ? args : <OutboxEvent>[];

            return MaterialPageRoute(
              builder: (_) => PropagationTimelineScreen(chain: chain),
            );

          default:
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(child: Text("Unknown route")),
              ),
            );
        }
      },
    );
  }
}

