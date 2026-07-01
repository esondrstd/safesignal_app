// lib/state/bootstrap_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/app_initializer.dart';

final bootstrapProvider = FutureProvider<void>((ref) async {
  final initializer = AppInitializer(ref);
  await initializer.initialize();
});