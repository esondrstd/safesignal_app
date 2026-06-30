// lib/screens/propagation_timeline_screen.dart
import 'package:flutter/material.dart';
import 'package:safesignal/core/database/models/outbox_event.dart';

class PropagationTimelineScreen extends StatelessWidget {
  final List<OutboxEvent> chain;

  const PropagationTimelineScreen({super.key, required this.chain});

  @override
  Widget build(BuildContext context) {
    final items = chain.map((e) {
      final hop = e.content?['hop'] ?? 1;
      return _TimelineItem(
        hop: hop,
        time: e.createdAt,
        device: e.userId,
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Propagation Timeline")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item = items[i];
          return Card(
            color: Colors.blueGrey.shade900,
            child: ListTile(
              title: Text("Hop ${item.hop}", style: const TextStyle(color: Colors.white)),
              subtitle: Text(
                "Device: ${item.device}\nTime: ${item.time.toIso8601String()}",
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TimelineItem {
  final int hop;
  final DateTime time;
  final String device;

  _TimelineItem({required this.hop, required this.time, required this.device});
}
