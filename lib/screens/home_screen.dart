import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/app_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("SafeSignal"),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text(
                "Welcome to SafeSignal",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 24),

              _InfoTile(
                label: "Anonymous ID",
                value: appState.anonymousId.isEmpty
                    ? "loading..."
                    : appState.anonymousId,
              ),

              const SizedBox(height: 16),

              _InfoTile(
                label: "Install Secret",
                value: appState.installSecret.isEmpty
                    ? "loading..."
                    : appState.installSecret,
              ),

              const SizedBox(height: 16),

              _InfoTile(
                label: "App Instance Hash",
                value: appState.appInstanceHash.isEmpty
                    ? "computing..."
                    : appState.appInstanceHash,
              ),

              const SizedBox(height: 32),

              const Text(
                "Send an Alert",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              // ⭐ CRITICAL ALERT
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/critical_alert');
                  },
                  child: const Text("Critical Alert"),
                ),
              ),

              const SizedBox(height: 16),

              // ⭐ NON-URGENT ALERT
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/non_urgent_alert');
                  },
                  child: const Text("Non-Urgent Alert"),
                ),
              ),

              const SizedBox(height: 16),

              // ⭐ SAFE ALERT
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/safe_alert');
                  },
                  child: const Text("Safe"),
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                "Mesh Tools",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/mesh_graph');
                  },
                  child: const Text("Open Mesh Graph"),
                ),
              ),

              const SizedBox(height: 16),

              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/mesh_analytics');
                  },
                  child: const Text("Open Mesh Analytics"),
                ),
              ),

              const SizedBox(height: 16),

              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/mesh_map');
                  },
                  child: const Text("Open Mesh Map"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}
