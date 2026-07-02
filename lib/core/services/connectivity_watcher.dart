import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safesignal/state/app_providers.dart';

class ConnectivityWatcher {
  final Ref ref;
  Timer? _timer;

  ConnectivityWatcher(this.ref);

  void start() {
    _timer = Timer.periodic(const Duration(seconds: 10), (_) async {
      final client = Supabase.instance.client;

      try {
        // Lightweight ping: select 1 row from a tiny table
        await client.from('connectivity_ping').select().limit(1);

        ref.read(appStateNotifierProvider.notifier).setOnline(true);
        print("ConnectivityWatcher: ONLINE");
      } catch (_) {
        ref.read(appStateNotifierProvider.notifier).setOnline(false);
        print("ConnectivityWatcher: OFFLINE");
      }
      print("ConnectivityWatcher: pinging Supabase...");

    });
  }

  void stop() {
    _timer?.cancel();
  }
}
