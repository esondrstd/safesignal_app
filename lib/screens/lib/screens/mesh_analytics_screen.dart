// lib/screens/mesh_analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safesignal/core/database/repositories/outbox_repository.dart';
import 'package:safesignal/core/database/models/outbox_event.dart';

class MeshAnalyticsScreen extends ConsumerWidget {
  const MeshAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<OutboxRepository>(
      future: ref.read(outboxRepositoryProvider.future),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final repo = snapshot.data!;
        return _MeshAnalyticsBody(repo: repo);
      },
    );
  }
}

class _MeshAnalyticsBody extends StatefulWidget {
  final OutboxRepository repo;
  const _MeshAnalyticsBody({required this.repo});

  @override
  State<_MeshAnalyticsBody> createState() => _MeshAnalyticsBodyState();
}

class _MeshAnalyticsBodyState extends State<_MeshAnalyticsBody> {
  List<OutboxEvent> events = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await widget.repo.getAllRelayEvents(limit: 1000);
    setState(() => events = all);
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _computeMetrics(events);

    return Scaffold(
      appBar: AppBar(title: const Text("Mesh Analytics")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            _metricCard("Mesh Stability Score", metrics.stabilityScore.toStringAsFixed(1)),
            _metricCard("Total Relay Events", "${metrics.totalEvents}"),
            _metricCard("Unique Ephemeral IDs", "${metrics.uniqueEphemeral}"),
            _metricCard("Max Hop Depth", "${metrics.maxHop}"),
            _metricCard("Average Hop Depth", metrics.avgHop.toStringAsFixed(2)),
            _metricCard("Failures", "${metrics.failures}"),
          ],
        ),
      ),
    );
  }

  _MeshMetrics _computeMetrics(List<OutboxEvent> events) {
    if (events.isEmpty) {
      return _MeshMetrics.empty();
    }

    final total = events.length;
    final ephSet = events.map((e) => e.content?['ephemeralId']).toSet();
    final hops = events.map((e) => e.content?['hop'] ?? 1).toList();
    final maxHop = hops.reduce((a, b) => a > b ? a : b);
    final avgHop = hops.reduce((a, b) => a + b) / hops.length;
    final failures = events.where((e) => e.status == 'failed').length;

    // Simple stability heuristic (you can tune this later)
    final stability = 100
        - failures * 2
        + avgHop * 3;

    return _MeshMetrics(
      totalEvents: total,
      uniqueEphemeral: ephSet.length,
      maxHop: maxHop,
      avgHop: avgHop,
      failures: failures,
      stabilityScore: stability.clamp(0, 100),
    );
  }

  Widget _metricCard(String label, String value) {
    return Card(
      color: Colors.blueGrey.shade900,
      child: ListTile(
        title: Text(label, style: const TextStyle(color: Colors.white)),
        subtitle: Text(value, style: const TextStyle(color: Colors.white70)),
      ),
    );
  }
}

class _MeshMetrics {
  final int totalEvents;
  final int uniqueEphemeral;
  final int maxHop;
  final double avgHop;
  final int failures;
  final double stabilityScore;

  _MeshMetrics({
    required this.totalEvents,
    required this.uniqueEphemeral,
    required this.maxHop,
    required this.avgHop,
    required this.failures,
    required this.stabilityScore,
  });

  factory _MeshMetrics.empty() => _MeshMetrics(
        totalEvents: 0,
        uniqueEphemeral: 0,
        maxHop: 0,
        avgHop: 0,
        failures: 0,
        stabilityScore: 0,
      );
}
