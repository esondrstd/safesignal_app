import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sqliteDatabaseProvider = FutureProvider<Database>((ref) async {
  final dbDir = await getDatabasesPath();
  final dbPath = join(dbDir, 'safesignal.db');

  final exists = await databaseExists(dbPath);

  if (!exists) {
    ByteData data = await rootBundle.load('assets/db/safesignal.db');
    List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

    await File(dbPath).writeAsBytes(bytes, flush: true);
  }

  final db = await openDatabase(dbPath);
  return db;
});



