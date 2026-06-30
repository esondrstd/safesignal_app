import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/repositories/inbox_repository.dart';
import '../core/database/repositories/outbox_repository.dart';
import '../core/database/models/inbox_event.dart';
import '../core/database/models/outbox_event.dart';

class MeshGraphScreen extends ConsumerStatefulWidget {
  const MeshGraphScreen({super.key});

  @override
  ConsumerState<MeshGraphScreen> createState() => _MeshGraphScreenState();
}

class _MeshGraphScreenState extends ConsumerState<MeshGraphScreen> {
  List<InboxEvent> inboxEvents = [];
  List<OutboxEvent> outboxEvents = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final inboxRepo = await ref.read(inboxRepositoryProvider.future);
    final outboxRepo = await ref.read(outboxRepositoryProvider.future);

    final inbox = await inboxRepo.getRecentInboxEvents(limit: 200);
    final outbox = await outboxRepo.getPendingEvents(limit: 200);

    setState(() {
      inboxEvents = inbox;
      outboxEvents = outbox;
    });
  }

  @override
  Widget build(BuildContext context) {
    final graph = _buildGraph();

    return Scaffold(
      appBar: AppBar(title: const Text("Mesh Graph")),
      body: graph.isEmpty
          ? const Center(child: Text("No mesh events yet"))
          : InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(200),
              minScale: 0.2,
              maxScale: 3.0,
              child: CustomPaint(
                painter: MeshGraphPainter(graph),
                size: const Size(double.infinity, double.infinity),
              ),
            ),
    );
  }

  /// Build a graph structure:
  /// {
  ///   "HOP-1-xxxx": { "hop": 1, "rssi": -45, "lat": 29.76, "lng": -95.36 },
  ///   "HOP-2-xxxx": { "hop": 2, ... },
  ///   ...
  /// }
  Map<String, Map<String, dynamic>> _buildGraph() {
    final graph = <String, Map<String, dynamic>>{};

    for (final o in outboxEvents) {
      final eph = o.content?['ephemeralId'];
      final hop = o.content?['hop'] ?? 1;

      if (eph != null) {
        graph[eph] = {
          'hop': hop,
          'rssi': o.content?['rssi'],
          'lat': o.lat,
          'lng': o.lng,
          'timestamp': o.createdAt,
        };
      }
    }

    return graph;
  }
}

class MeshGraphPainter extends CustomPainter {
  final Map<String, Map<String, dynamic>> graph;

  MeshGraphPainter(this.graph);

  @override
  void paint(Canvas canvas, Size size) {
    final paintNode = Paint()..style = PaintingStyle.fill;
    final paintEdge = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 2;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Layout: nodes spaced horizontally by hop number
    const double baseY = 200;
    const double hopSpacing = 180;
    const double nodeSpacing = 140;

    final sorted = graph.entries.toList()
      ..sort((a, b) => (a.value['hop'] as int).compareTo(b.value['hop'] as int));

    final positions = <String, Offset>{};

    int index = 0;
    for (final entry in sorted) {
      final eph = entry.key;
      final hop = entry.value['hop'] as int;

      final x = hop * hopSpacing + 100;
      final y = baseY + (index * nodeSpacing);

      positions[eph] = Offset(x, y);
      index++;
    }

    // Draw edges (hop → hop+1)
    for (final entry in sorted) {
      final eph = entry.key;
      final hop = entry.value['hop'] as int;

      final nextHop = hop + 1;

      // SAFE LOOKUP — no invalid return types
      final nextCandidates = sorted.where((e) => e.value['hop'] == nextHop);
      final nextNode = nextCandidates.isNotEmpty ? nextCandidates.first : null;

      if (nextNode != null) {
        final p1 = positions[eph]!;
        final p2 = positions[nextNode.key]!;

        canvas.drawLine(p1, p2, paintEdge);
      }
    }

    // Draw nodes
    for (final entry in sorted) {
      final eph = entry.key;
      final hop = entry.value['hop'] as int;
      final rssi = entry.value['rssi'];
      final pos = positions[eph]!;

      // Color by hop depth
      paintNode.color = Colors.blueAccent.withOpacity(0.4 + hop * 0.1);

      canvas.drawCircle(pos, 40, paintNode);

      // Label
      textPainter.text = TextSpan(
        text: "Hop $hop\n$rssi dBm",
        style: const TextStyle(color: Colors.white, fontSize: 14),
      );
      textPainter.layout();
      textPainter.paint(canvas, pos - Offset(30, 30));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
