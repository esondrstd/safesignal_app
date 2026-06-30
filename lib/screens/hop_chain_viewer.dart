import 'package:flutter/material.dart';
import 'package:safesignal/core/database/models/outbox_event.dart';

class HopChainViewer extends StatelessWidget {
  final List<OutboxEvent> chain;

  const HopChainViewer({super.key, required this.chain});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Hop Chain (${chain.length} hops)",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),

          Expanded(
            child: ListView.builder(
              itemCount: chain.length,
              itemBuilder: (_, i) {
                final hop = chain[i];
                final hopNum = hop.content?['hop'] ?? 1;

                return Card(
                  child: ListTile(
                    title: Text("Hop $hopNum"),
                    subtitle: Text(
                      "Device: ${hop.userId}\n"
                      "Time: ${hop.createdAt.toIso8601String()}",
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
