import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:safesignal/state/app_providers.dart';
import 'package:safesignal/core/database/models/inbox_event.dart';
import 'package:safesignal/core/database/models/outbox_event.dart';
import 'package:safesignal/core/services/outbox_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "SafeSignal Home",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              const Text("Anonymous ID:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(appState.anonymousId.isEmpty ? "loading..." : appState.anonymousId),

              const SizedBox(height: 20),

              const Text("Install Secret:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(appState.installSecret.isEmpty ? "loading..." : appState.installSecret),

              const SizedBox(height: 20),

              const Text("App Instance Hash:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(appState.appInstanceHash.isEmpty ? "computing..." : appState.appInstanceHash),

              const SizedBox(height: 40),

              // 1. Simulate BLE event
              ElevatedButton(
                onPressed: () async {
                  final inboxRepo = await ref.read(inboxRepositoryProvider.future);
                  await inboxRepo.simulateBleEvent(rssi: -60);
                },
                child: const Text('1. Simulate BLE Event'),
              ),

              const SizedBox(height: 20),

              // 2. Print inbox
              ElevatedButton(
                onPressed: () async {
                  final inboxRepo = await ref.read(inboxRepositoryProvider.future);
                  final events = await inboxRepo.getRecentInboxEvents(limit: 10);

                  print('Inbox events (latest 10):');
                  for (final e in events) {
                    print('${e.id} ${e.ephemeralId} ${e.rssi} ${e.detectedAt}');
                  }
                },
                child: const Text('2. Print Inbox Events'),
              ),

              const SizedBox(height: 20),

              // 3. Simulate Mesh Relay
              ElevatedButton(
                onPressed: () async {
                  final inboxRepo = await ref.read(inboxRepositoryProvider.future);
                  final outboxRepo = await ref.read(outboxRepositoryProvider.future);

                  final inboxEvents = await inboxRepo.getRecentInboxEvents(limit: 1);
                  if (inboxEvents.isEmpty) {
                    print("SIMULATION: No inbox events to relay.");
                    return;
                  }

                  final e = inboxEvents.first;

                  final outboxEvent = OutboxEvent(
                    statusCode: 200,
                    createdAt: DateTime.now(),
                    status: 'queued',
                    retryCount: 0,
                    type: 'relay',
                    parentEventId: e.id,
                    content: {
                      'ephemeralId': e.ephemeralId,
                      'rssi': e.rssi,
                      'detectedAt': e.detectedAt.toIso8601String(),
                    },
                    lat: e.receiverLat ?? 29.7604,
                    lng: e.receiverLng ?? -95.3698,
                    address: null,
                    userId: 'sim-user',
                  );

                  final outboxId = await outboxRepo.queueEvent(outboxEvent);
                  print("SIMULATION: Queued outbox relay event id=$outboxId from inbox=${e.id}");
                },
                child: const Text('3. Simulate Mesh Relay'),
              ),

              const SizedBox(height: 20),

              // 4. Test Inbox + Outbox
              ElevatedButton(
                onPressed: () async {
                  try {
                    final inboxRepo = await ref.read(inboxRepositoryProvider.future);

                    final inboxId = await inboxRepo.addInboxEvent(
                      InboxEvent(
                        ephemeralId: 'mesh-test-123',
                        statusCode: 1,
                        rssi: -60,
                        detectedAt: DateTime.now(),
                        receiverLat: 29.7604,
                        receiverLng: -95.3698,
                      ),
                    );

                    print('Inserted inbox_event id=$inboxId');

                    final inboxEvents = await inboxRepo.getRecentInboxEvents(limit: 5);
                    print('Recent inbox events:');
                    for (final e in inboxEvents) {
                      print('${e.id} ${e.ephemeralId} ${e.statusCode} ${e.rssi} ${e.detectedAt}');
                    }

                    // ⭐ FIX: await the FutureProvider
                    final outboxService = await ref.read(outboxServiceProvider.future);

                    final outboxEvent = OutboxEvent(
                      statusCode: 200,
                      createdAt: DateTime.now(),
                      status: 'queued',
                      retryCount: 0,
                      type: 'relay',
                      parentEventId: inboxId,
                      content: {
                        'ephemeralId': 'mesh-test-123',
                        'rssi': -60,
                      },
                      lat: 29.7604,
                      lng: -95.3698,
                      address: 'Houston, TX',
                      userId: 'debug-user',
                    );

                    final outboxId = await outboxService.queueEvent(outboxEvent);
                    print('Queued outbox_event id=$outboxId');

                    await outboxService.processPendingEvents();
                    print('Outbox retry cycle completed');
                  } catch (e) {
                    print('ERROR: $e');
                  }
                },
                child: const Text('4. Test Inbox + Outbox'),
              ),

              const SizedBox(height: 20),

              // 5. Test Supabase Write
              ElevatedButton(
                onPressed: () async {
                  final client = ref.read(supabaseClientProvider);
                  await client.from('test_table').insert({
                    'message': 'SafeSignal connected',
                    'created_at': DateTime.now().toIso8601String(),
                  });
                },
                child: const Text('5. Test Supabase Write'),
              ),

              const SizedBox(height: 40),

              // A. Run Full Simulation
              ElevatedButton(
                onPressed: () async {
                  final inboxRepo = await ref.read(inboxRepositoryProvider.future);
                  final outboxService = await ref.read(outboxServiceProvider.future);

                  print("=== FULL SIMULATION START ===");

                  final id = await inboxRepo.simulateBleEvent(rssi: -60);
                  print("FullSim: Inserted inbox_event id=$id");

                  final inboxEvents = await inboxRepo.getRecentInboxEvents(limit: 10);
                  print("FullSim: Inbox count=${inboxEvents.length}");

                  final e = inboxEvents.first;

                  final outboxEvent = OutboxEvent(
                    statusCode: 200,
                    createdAt: DateTime.now(),
                    status: 'queued',
                    retryCount: 0,
                    type: 'relay',
                    parentEventId: e.id,
                    content: {
                      'ephemeralId': e.ephemeralId,
                      'rssi': e.rssi,
                      'detectedAt': e.detectedAt.toIso8601String(),
                    },
                    lat: 29.7604,
                    lng: -95.3698,
                    address: null,
                    userId: 'fullsim-user',
                  );

                  final outboxId = await outboxService.queueEvent(outboxEvent);
                  print("FullSim: Queued outbox_event id=$outboxId");

                  await outboxService.processPendingEvents();
                  print("FullSim: Retry engine completed");

                  print("=== FULL SIMULATION END ===");
                },
                child: const Text('Run Full Simulation'),
              ),

              const SizedBox(height: 20),

              // B. Multi-Hop Mesh Simulation
              ElevatedButton(
                onPressed: () async {
                  final inboxRepo = await ref.read(inboxRepositoryProvider.future);
                  final outboxService = await ref.read(outboxServiceProvider.future);

                  print("=== MULTI-HOP SIMULATION START ===");

                  for (int hop = 1; hop <= 4; hop++) {
                    final eph = "HOP-$hop-${DateTime.now().millisecondsSinceEpoch}";
                    final inboxId = await inboxRepo.simulateBleEvent(
                      ephemeralId: eph,
                      rssi: -40 - hop * 5,
                    );

                    print("Hop $hop: Inserted inbox_event id=$inboxId eph=$eph");

                    final outboxEvent = OutboxEvent(
                      statusCode: 200,
                      createdAt: DateTime.now(),
                      status: 'queued',
                      retryCount: 0,
                      type: 'relay',
                      parentEventId: inboxId,
                      content: {
                        'ephemeralId': eph,
                        'hop': hop,
                        'rssi': -40 - hop * 5,
                      },
                      lat: 29.7604 + hop * 0.0001,
                      lng: -95.3698 - hop * 0.0001,
                      address: null,
                      userId: 'hop-sim-user',
                    );

                    final outboxId = await outboxService.queueEvent(outboxEvent);
                    print("Hop $hop: Queued outbox_event id=$outboxId");
                  }

                  await outboxService.processPendingEvents();
                  print("=== MULTI-HOP SIMULATION END ===");
                },
                child: const Text('Multi-Hop Mesh Simulation'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
