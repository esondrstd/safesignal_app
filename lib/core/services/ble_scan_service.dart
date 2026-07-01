// lib/core/services/ble_scan_service.dart

import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:safesignal/core/database/repositories/inbox_repository.dart';
import 'package:safesignal/core/database/models/inbox_event.dart';

class BleScanService {
  final InboxRepository inboxRepository;

  BleScanService(this.inboxRepository);

  StreamSubscription<List<ScanResult>>? _scanSub;

  Future<void> startScanning() async {
    // Ensure Bluetooth is on
    final isOn = await FlutterBluePlus.isOn;
    if (!isOn) {
      print('BLE: Bluetooth is OFF');
      return;
    }

    print('BLE: Starting scan');

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 0),
      continuousUpdates: true,
    );

    _scanSub = FlutterBluePlus.scanResults.listen((results) async {
      for (final r in results) {
        final device = r.device;
        final rssi = r.rssi;

        // TODO: replace with real ephemeral ID from advertisement payload
        final ephemeralId = device.id.id; // placeholder

        // ⭐ FIX: Always provide fallback lat/lng so OutboxEvent never receives null
        final event = InboxEvent(
          ephemeralId: ephemeralId,
          statusCode: 1,
          rssi: rssi,
          detectedAt: DateTime.now(),
          receiverLat: 29.7604,   // Houston fallback
          receiverLng: -95.3698,  // Houston fallback
        );

        final id = await inboxRepository.addInboxEvent(event);
        print('BLE: InboxEvent inserted id=$id ephemeralId=$ephemeralId rssi=$rssi');
      }
    });
  }

  Future<void> stopScanning() async {
    print('BLE: Stopping scan');
    await FlutterBluePlus.stopScan();
    await _scanSub?.cancel();
    _scanSub = null;
  }
}
