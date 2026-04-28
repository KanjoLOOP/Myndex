import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';

part 'app_database.g.dart';

/// Definición de la base de datos local con Drift (SQLite).
///
/// Solo hay una tabla por ahora: `content_items`. La estructura está
/// pensada para ser extensible: añadir un campo es una migración
/// (ver `schemaVersion` y la guía de Drift).
///
/// Notas de seguridad:
/// - La base de datos vive en el sandbox privado de la app, no es
///   accesible por otras apps en Android/iOS.
/// - No guardamos datos sensibles en claro: este es un caso de uso de
///   biblioteca personal y los datos no incluyen credenciales. Si en
///   el futuro se añadiese sincronización en la nube o información
///   personal sensible, valorar SQLCipher (sqlite3_flutter_libs lo
///   soporta) y proteger la clave con secure storage.

// ─── Type Converters ────────────────────────────────────────────────

class RatingDimensionsConverter extends TypeConverter<Map<String, int>, String> {
  const RatingDimensionsConverter();

  @override
  Map<String, int> fromSql(String fromDb) {
    if (fromDb.isEmpty) return {};
    final map = jsonDecode(fromDb) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, v as int));
  }

  @override
  String toSql(Map<String, int> value) {
    return jsonEncode(value);
  }
}

// ─── Tablas ───────────────────────────────────────────────────────


/// Tabla principal de contenido.
///
/// Los campos `type` y `status` se guardan como string (el `.name`
/// de los enums) en vez de int para que los backups JSON sean
/// legibles aunque cambie el orden de los enums.
class ContentItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 500)();
  TextColumn get type => text()();      // ContentType.name
  TextColumn get status => text()();    // ContentStatus.name
  RealColumn get score => real().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get genre => text().nullable()();            // género(s) libre, ej. "Acción, Aventura"
  TextColumn get externalId => text().nullable()();      // id de TMDB/RAWG/etc.
  TextColumn get externalSource => text().nullable()();  // 'tmdb','rawg','openlibrary'
  IntColumn get estimatedDurationMinutes => integer().nullable()();
  TextColumn get ratingDimensions => text().map(const RatingDimensionsConverter()).nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  IntColumn get progressUnits => integer().nullable()();
  IntColumn get totalUnits => integer().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Colecciones personalizadas del usuario.
class Collections extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Relación N:M entre colecciones e items de contenido.
class CollectionItems extends Table {
  IntColumn get collectionId => integer()();
  IntColumn get contentItemId => integer()();

  @override
  Set<Column> get primaryKey => {collectionId, contentItemId};
}

/// Registro de actividad para timeline y estadísticas.
class ActivityLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get contentId => integer()();
  TextColumn get action => text()(); // 'added', 'updated', 'completed', 'status_changed'
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
}

/// Tabla virtual para búsqueda rápida (FTS5)
class SearchIndex extends Table {
  IntColumn get contentId => integer()();
  TextColumn get title => text()();
  
  @override
  String get tableName => 'search_index';
}

// ─── Base de datos ────────────────────────────────────────────────

@DriftDatabase(tables: [ContentItems, Collections, CollectionItems, ActivityLog, SearchIndex])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Constructor inyectable para tests (DB en memoria).
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => AppConstants.dbVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      // Drop and create FTS5 virtual table properly since drift might just create a normal table for SearchIndex
      await customStatement('DROP TABLE IF EXISTS search_index');
      await customStatement('CREATE VIRTUAL TABLE search_index USING fts5(title, contentId UNINDEXED)');
      
      // Triggers for FTS5
      await customStatement('''
        CREATE TRIGGER IF NOT EXISTS search_index_insert AFTER INSERT ON content_items BEGIN
          INSERT INTO search_index (title, contentId) VALUES (new.title, new.id);
        END;
      ''');
      await customStatement('''
        CREATE TRIGGER IF NOT EXISTS search_index_delete AFTER DELETE ON content_items BEGIN
          DELETE FROM search_index WHERE contentId = old.id;
        END;
      ''');
      await customStatement('''
        CREATE TRIGGER IF NOT EXISTS search_index_update AFTER UPDATE ON content_items BEGIN
          DELETE FROM search_index WHERE contentId = old.id;
          INSERT INTO search_index (title, contentId) VALUES (new.title, new.id);
        END;
      ''');
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(contentItems, contentItems.genre);
      }
      if (from < 3) {
        await migrator.addColumn(contentItems, contentItems.isFavorite);
        await migrator.createTable(collections);
        await migrator.createTable(collectionItems);
      }
      if (from < 4) {
        await migrator.addColumn(contentItems, contentItems.estimatedDurationMinutes);
        await migrator.addColumn(contentItems, contentItems.ratingDimensions);
        await migrator.addColumn(contentItems, contentItems.completedAt);
        await migrator.addColumn(contentItems, contentItems.progressUnits);
        await migrator.addColumn(contentItems, contentItems.totalUnits);
        await migrator.createTable(activityLog);
        
        await customStatement('DROP TABLE IF EXISTS search_index');
        await customStatement('CREATE VIRTUAL TABLE search_index USING fts5(title, contentId UNINDEXED)');
        
        // Triggers for FTS5
        await customStatement('''
          CREATE TRIGGER IF NOT EXISTS search_index_insert AFTER INSERT ON content_items BEGIN
            INSERT INTO search_index (title, contentId) VALUES (new.title, new.id);
          END;
        ''');
        await customStatement('''
          CREATE TRIGGER IF NOT EXISTS search_index_delete AFTER DELETE ON content_items BEGIN
            DELETE FROM search_index WHERE contentId = old.id;
          END;
        ''');
        await customStatement('''
          CREATE TRIGGER IF NOT EXISTS search_index_update AFTER UPDATE ON content_items BEGIN
            DELETE FROM search_index WHERE contentId = old.id;
            INSERT INTO search_index (title, contentId) VALUES (new.title, new.id);
          END;
        ''');
        
        // Populate FTS5 table
        await customStatement('INSERT INTO search_index (title, contentId) SELECT title, id FROM content_items');
      }
    },
  );
}

// ─── Provider ─────────────────────────────────────────────────────

/// Provider de la DB. Se sobrescribe en `main.dart` con la instancia
/// real (o en tests con una DB en memoria).
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError(
    'databaseProvider debe sobrescribirse en ProviderScope (ver main.dart)',
  );
});
