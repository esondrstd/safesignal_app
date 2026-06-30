import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/repositories/outbox_repository.dart';
import '../core/database/models/outbox_event.dart';

class MeshGraphScreen extends ConsumerStatefulWidget {
  const MeshGraphScreen({super.key});

  @override
  ConsumerState<MeshGraphScreen> createState() => _MeshGraphScreenState();
}

class _MeshGraphScreenState extends ConsumerState<MeshGraphScreen> {
  List<OutboxEvent> relayEvents = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final outboxRepo = await ref.read(outboxRepositoryProvider.future);

    final outbox = await outboxRepo.getAllRelayEvents(limit: 500);

    setState(() {
      relayEvents = outbox;
    });
  }

  @override
  Widget build(BuildContext context) {
    final graph = _groupByHop(relayEvents);

    return Scaffold(
      appBar: AppBar(title: const Text("Mesh Graph")),
      body: relayEvents.isEmpty
          ? const Center(child: Text("No mesh events yet"))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummary(graph),
                  const SizedBox(height: 30),
                  _buildVerticalHopFlow(graph),
                ],
              ),
            ),
    );
  }

  // ------------------------------------------------------------
  // SUMMARY SECTION
  // ------------------------------------------------------------
  Widget _buildSummary(Map<int, List<OutboxEvent>> graph) {
    final totalEvents = relayEvents.length;

    final hops = graph.keys.toList()..sort();
    final latestHop = hops.isNotEmpty ? hops.last : 0;

    final rssiValues = relayEvents
        .map((e) => e.content?['rssi'])
        .whereType<int>()
        .toList();

    final minRssi = rssiValues.isEmpty ? null : rssiValues.reduce((a, b) => a < b ? a : b);
    final maxRssi = rssiValues.isEmpty ? null : rssiValues.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Mesh Summary",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          _summaryLine("Total Relay Events", "$totalEvents"),
          _summaryLine("Total Hops", "${hops.length}"),
          _summaryLine("Latest Hop", "$latestHop"),
          _summaryLine("RSSI Range", minRssi == null ? "N/A" : "$minRssi dBm → $maxRssi dBm"),
        ],
      ),
    );
  }

  Widget _summaryLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        "$label: $value",
        style: const TextStyle(color: Colors.white70, fontSize: 16),
      ),
    );
  }

  // ------------------------------------------------------------
  // GROUP BY HOP
  // ------------------------------------------------------------
  Map<int, List<OutboxEvent>> _groupByHop(List<OutboxEvent> events) {
    final map = <int, List<OutboxEvent>>{};

    for (final e in events) {
      final hop = (e.content?['hop'] ?? 1) as int;
      map.putIfAbsent(hop, () => []);
      map[hop]!.add(e);
    }

    return map;
  }

  // ------------------------------------------------------------
  // VERTICAL HOP FLOW
  // ------------------------------------------------------------
  Widget _buildVerticalHopFlow(Map<int, List<OutboxEvent>> graph) {
    final hops = graph.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: hops.map((hop) {
        final events = graph[hop]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hop $hop",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: events.map((e) {
                return SizedBox(
                  width: 180,
                  child: _buildNodeTile(e),
                );
              }).toList(),
            ),

            const SizedBox(height: 40),
          ],
        );
      }).toList(),
    );
  }

  // ------------------------------------------------------------
  // NODE TILE
  // ------------------------------------------------------------
  Widget _buildNodeTile(OutboxEvent e) {
    final eph = e.content?['ephemeralId'] ?? "unknown";
    final hop = (e.content?['hop'] ?? 1) as int;
    final rssi = e.content?['rssi'];

    return GestureDetector(
      onTap: () => _showDetails(e),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade700,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eph,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text("Hop $hop", style: _infoStyle()),
            Text("$rssi dBm", style: _infoStyle()),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // DETAILS MODAL
  // ------------------------------------------------------------
  void _showDetails(OutboxEvent e) {
    final eph = e.content?['ephemeralId'] ?? "unknown";
    final hop = (e.content?['hop'] ?? 1) as int;
    final rssi = e.content?['rssi'];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.blueGrey.shade900,
        title: Text(
          eph,
          style: const TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detail("Hop", hop),
              _detail("RSSI", "$rssi dBm"),
              _detail("Timestamp", e.createdAt.toIso8601String()),
              _detail("Lat", e.lat),
              _detail("Lng", e.lng),
              _detail("StatusCode", e.statusCode),
              _detail("ParentEventId", e.parentEventId),
              const SizedBox(height: 12),
              const Text("Content JSON:", style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 6),
              Text(
                e.content?.toString() ?? "{}",
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text("View Hop Chain", style: TextStyle(color: Colors.lightBlueAccent)),
            onPressed: () {
              Navigator.pop(context);
              _safeShowHopChain(e.parentEventId);
            },
          ),
          TextButton(
            child: const Text("Close", style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // SAFE HOP CHAIN WRAPPER
  // ------------------------------------------------------------
  void _safeShowHopChain(int? parentEventId) {
    if (parentEventId == null) {
      print("No parentEventId — cannot build hop chain.");
      return;
    }
    _showHopChain(parentEventId);
  }

  // ------------------------------------------------------------
  // HOP CHAIN VIEWER
  // ------------------------------------------------------------
  Future<void> _showHopChain(int parentEventId) async {
    final repo = await ref.read(outboxRepositoryProvider.future);
    final chain = await repo.buildHopChain(parentEventId);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.blueGrey.shade900,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hop Chain (${chain.length} hops)",
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: ListView.builder(
                  itemCount: chain.length,
                  itemBuilder: (_, i) {
                    final hopEvent = chain[i];
                    final hopNum = (hopEvent.content?['hop'] ?? 1) as int;

                    return Card(
                      color: Colors.blueGrey.shade700,
                      child: ListTile(
                        title: Text("Hop $hopNum", style: const TextStyle(color: Colors.white)),
                        subtitle: Text(
                          "Device: ${hopEvent.userId}\n"
                          "Time: ${hopEvent.createdAt.toIso8601String()}",
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detail(String label, Object? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        "$label: $value",
        style: const TextStyle(color: Colors.white70),
      ),
    );
  }

  TextStyle _infoStyle() {
    return const TextStyle(color: Colors.white70, fontSize: 13);
  }
}


