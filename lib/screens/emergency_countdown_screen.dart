import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/emergency_providers.dart';

import '../../core/services/emergency_alert_service.dart';
import 'emergency_details_screen.dart';

class EmergencyCountdownScreen extends ConsumerStatefulWidget {
  final String alertType;

  const EmergencyCountdownScreen({
    super.key,
    required this.alertType,
  });

  @override
  ConsumerState<EmergencyCountdownScreen> createState() =>
      _EmergencyCountdownScreenState();
}

class _EmergencyCountdownScreenState
    extends ConsumerState<EmergencyCountdownScreen> {
  int secondsLeft = 5;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (secondsLeft == 1) {
        _sendAlert();
      } else {
        setState(() => secondsLeft--);
      }
    });
  }

  Future<void> _sendAlert() async {
    timer?.cancel();

    // Trigger alert (online or offline)
    await ref
        .read(emergencyAlertServiceProvider)
        .triggerAlert(widget.alertType);

    // Read updated emergency state
    final emergencyState = ref.read(emergencyStateProvider);
    final parentEventId = emergencyState.parentEventId;

    print("COUNTDOWN SCREEN → parentEventId = $parentEventId");

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => EmergencyDetailsScreen(
          parentEventId: parentEventId,
          alertType: widget.alertType,   // ⭐ REQUIRED — THIS FIXES YOUR ERROR
        ),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          "Sending alert in $secondsLeft...",
          style: const TextStyle(fontSize: 32),
        ),
      ),
    );
  }
}
