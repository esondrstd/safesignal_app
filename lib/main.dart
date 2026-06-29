
//App home page

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'state/app_providers.dart';
import 'state/app_state.dart';
import 'core/app_initializer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Supabase
  await Supabase.initialize(
    url: 'https://tkzrucdpkfgnbsinugpz.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRrenJ1Y2Rwa2ZnbmJzaW51Z3B6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE5MTY2NTksImV4cCI6MjA1NzQ5MjY1OX0.HQGDCN3gD_imgzbi3lM-oy3lcPJHX2hwNO_pb0kr5gU',
  );

  runApp(const ProviderScope(child: SafeSignalApp()));
}

// Global Supabase client (still useful)
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
    // 🔧 Run our AppInitializer to set anonymousId, installSecret, appInstanceHash, etc.
    final initializer = AppInitializer(ref);
    await initializer.initialize();

    setState(() {
      _initialized = true;
    });
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
      home: const HomeScreen(),
    );

  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "SafeSignal Home",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            const Text(
              "Anonymous ID:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              appState.anonymousId.isEmpty
                  ? "loading..."
                  : appState.anonymousId,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            const Text(
              "Install Secret:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              appState.installSecret.isEmpty
                  ? "loading..."
                  : appState.installSecret,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            const Text(
              "App Instance Hash:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              appState.appInstanceHash.isEmpty
                  ? "computing..."
                  : appState.appInstanceHash,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () async {
                await supabase.from('test_table').insert({
                  'message': 'SafeSignal connected',
                  'created_at': DateTime.now().toIso8601String(),
                });
              },
              child: const Text('Test Supabase Write'),
            ),
          ],
        ),
      ),
    );
  }
}
