import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/database/repositories/outbox_repository.dart';
import '../core/database/models/outbox_event.dart';

class MeshMapScreen extends ConsumerStatefulWidget {
  const MeshMapScreen({super.key});

  @override
  ConsumerState<MeshMapScreen> createState() => _MeshMapScreenState();
}

class _MeshMapScreenState extends ConsumerState<MeshMapScreen> {
  List<OutboxEvent> events = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = await ref.read(outboxRepositoryProvider.future);
    final all = await repo.getAllRelayEvents(limit: 1000);

    setState(() {
      events = all.where((e) => e.lat != null && e.lng != null).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Mesh Map")),
        body: const Center(child: Text("No mesh events with location yet")),
      );
    }

    final markers = events.map((e) {
      return Marker(
        point: LatLng(e.lat!, e.lng!),
        width: 18,
        height: 18,
        child: const Icon(
          Icons.circle,
          color: Colors.lightBlueAccent,
          size: 12,
        ),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Mesh Map")),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(events.first.lat!, events.first.lng!),
          initialZoom: 14,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.safesignal.app',
          ),
          MarkerLayer(markers: markers),
        ],
      ),
    );
  }
}

