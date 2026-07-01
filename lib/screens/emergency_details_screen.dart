import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/emergency_providers.dart';

class EmergencyDetailsScreen extends ConsumerWidget {
  final int? parentEventId;
  final String alertType;

  const EmergencyDetailsScreen({
    super.key,
    required this.parentEventId,
    required this.alertType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emergencyState = ref.watch(emergencyStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Alert Type: $alertType",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Text(
              "Parent Event ID: ${parentEventId ?? 'None'}",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),

            const Text(
              "Add Additional Details:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: () async {
                await ref.read(emergencyStateProvider.notifier).submitAdditionalDetails(
                  category: "general",
                  description: "User provided details",
                  parentEventId: parentEventId,
                  alertType: alertType,   // ⭐ REQUIRED FOR SUPABASE
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Details submitted")),
                );
              },
              child: const Text("Submit Details"),
            ),
          ],
        ),
      ),
    );
  }
}
