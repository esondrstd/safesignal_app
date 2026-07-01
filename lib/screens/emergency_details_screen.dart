import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/emergency_providers.dart';

class EmergencyDetailsScreen extends ConsumerStatefulWidget {
  final int? parentEventId; // mesh_events.id for offline, null for online

  const EmergencyDetailsScreen({
    super.key,
    required this.parentEventId,
  });

  @override
  ConsumerState<EmergencyDetailsScreen> createState() =>
      _EmergencyDetailsScreenState();
}

class _EmergencyDetailsScreenState
    extends ConsumerState<EmergencyDetailsScreen> {
  String? selectedCategory;
  final TextEditingController descriptionController = TextEditingController();

  final List<String> categories = [
    "Medical",
    "Fire",
    "Flood",
    "Crime",
    "Accident",
    "Other",
  ];

  bool submitting = false;

  Future<void> _submit() async {
    if (submitting) return;
    submitting = true;

    final category = selectedCategory;
    final description = descriptionController.text.trim();

    await ref.read(emergencyStateProvider.notifier).submitAdditionalDetails(
          category: category,
          description: description,
          parentEventId: widget.parentEventId, // ⭐ FIXED: pass parentEventId
        );

    if (!mounted) return;

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Additional Details"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Emergency Category",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Select Category",
              ),
              initialValue: selectedCategory,
              items: categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) {
                setState(() => selectedCategory = value);
              },
            ),

            const SizedBox(height: 30),

            const Text(
              "Description (optional)",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Describe the situation...",
              ),
            ),

            const Spacer(),

            SizedBox(
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: _submit,
                child: const Text("Submit"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
