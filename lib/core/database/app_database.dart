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

// ─── Base de datos ────────────────────────────────────────────────

@DriftDatabase(tables: [ContentItems, Collections, CollectionItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Constructor inyectable para tests (DB en memoria).
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => AppConstants.dbVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(contentItems, contentItems.genre);
      }
      if (from < 3) {
        await migrator.addColumn(contentItems, contentItems.isFavorite);
        await migrator.createTable(collections);
        await migrator.createTable(collectionItems);
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
