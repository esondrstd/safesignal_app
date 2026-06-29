import 'package:sqflite/sqflite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sqliteDatabaseProvider = FutureProvider<Database>((ref) async {
  const dbPath = r'C:\Users\esond\Desktop\Native Flutter SafeSignal\sqliteDB\safesignal.db';

  final db = await openDatabase(
    dbPath,
    version: 1,
  );

  return db;
});

