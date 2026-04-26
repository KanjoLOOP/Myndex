import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'app_database.g.dart';

// --- Tables ---

class ContentItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 500)();
  TextColumn get type => text()(); // ContentType.name
  TextColumn get status => text()(); // ContentStatus.name
  RealColumn get score => real().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get externalId => text().nullable()(); // ID from TMDB/RAWG/etc.
  TextColumn get externalSource => text().nullable()(); // 'tmdb','rawg','openlibrary'
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// --- Database ---

@DriftDatabase(tables: [ContentItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'myndex');
  }
}

// --- Provider ---

final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('Override databaseProvider in ProviderScope');
});
