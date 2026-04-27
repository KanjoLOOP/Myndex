import 'package:drift/drift.dart';

import '../../../../core/constants/content_types.dart';
import '../../../../core/database/app_database.dart' hide ContentItem;
import '../../../../core/security/input_sanitizer.dart';
import '../../domain/entities/content_item.dart';
import '../models/content_item_model.dart';

/// Datasource local sobre Drift (SQLite).
///
/// Encapsula todas las queries SQL contra la tabla `ContentItems`.
/// La capa superior (repositorio) solo conoce métodos de alto nivel,
/// no SQL.
///
/// Notas de seguridad:
/// - Toda condición se construye con expresiones parametrizadas de
///   Drift, por lo que no es posible inyección SQL desde el usuario.
/// - La búsqueda LIKE escapa los comodines `%` y `_` previamente
///   con [InputSanitizer.sanitizeSearchQuery] para que el usuario no
///   pueda forzar un barrido completo de la tabla con un `%`.
class ContentLocalDatasource {
  final AppDatabase _db;

  ContentLocalDatasource(this._db);

  /// Lista todos los items aplicando filtros opcionales.
  /// Resultado ordenado por `addedAt` desc (más reciente primero).
  Future<List<ContentItem>> getAll({
    ContentType? filterType,
    ContentStatus? filterStatus,
    double? minScore,
  }) async {
    final query = _db.select(_db.contentItems);

    if (filterType != null) {
      query.where((t) => t.type.equals(filterType.name));
    }
    if (filterStatus != null) {
      query.where((t) => t.status.equals(filterStatus.name));
    }
    if (minScore != null) {
      query.where((t) => t.score.isBiggerOrEqualValue(minScore));
    }

    query.orderBy([(t) => OrderingTerm.desc(t.addedAt)]);
    final rows = await query.get();
    return rows.map((r) => r.toDomain()).toList();
  }

  /// Obtiene un único item por id, o `null` si no existe.
  Future<ContentItem?> getById(int id) async {
    final row = await (_db.select(_db.contentItems)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row?.toDomain();
  }

  /// Inserta un nuevo item. Devuelve la entidad con el id asignado.
  Future<ContentItem> insert(ContentItem item) async {
    final id = await _db.into(_db.contentItems).insert(item.toInsertCompanion());
    return item.copyWith(id: id);
  }

  /// Actualiza un item existente. Conserva el `addedAt` original
  /// gracias al companion de update (ver content_item_model.dart).
  ///
  /// Lanza [StateError] si el item no tiene id.
  Future<ContentItem> update(ContentItem item) async {
    if (item.id == null) {
      throw StateError('No se puede actualizar un item sin id');
    }
    await (_db.update(_db.contentItems)..where((t) => t.id.equals(item.id!)))
        .write(item.toUpdateCompanion());
    return item;
  }

  /// Borra un item por id.
  Future<void> delete(int id) async {
    await (_db.delete(_db.contentItems)..where((t) => t.id.equals(id))).go();
  }

  /// Búsqueda local por título.
  ///
  /// La query del usuario se sanea (escape de `%` y `_`, recorte de
  /// longitud) antes de embeberla en el patrón LIKE. La consulta se
  /// emite como `customSelect` parametrizada para poder declarar el
  /// `ESCAPE '\\'`, que Drift no expone en su DSL de alto nivel.
  Future<List<ContentItem>> search(String query) async {
    final sanitized = InputSanitizer.sanitizeSearchQuery(query);
    if (sanitized.isEmpty) return const [];

    final pattern = '%$sanitized%';
    final raw = await _db.customSelect(
      "SELECT * FROM content_items "
      "WHERE title LIKE ? ESCAPE '\\' "
      "ORDER BY added_at DESC",
      variables: [Variable.withString(pattern)],
      readsFrom: {_db.contentItems},
    ).get();

    return raw
        .map((r) => _db.contentItems.map(r.data).toDomain())
        .toList();
  }

  /// Devuelve **todos** los items sin filtros (para export JSON).
  Future<List<ContentItem>> getAllUnfiltered() async {
    final rows = await (_db.select(_db.contentItems)
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
    return rows.map((r) => r.toDomain()).toList();
  }

  /// Comprueba si ya existe un item con el mismo título y tipo.
  /// Utilizado por el importer para detectar duplicados sin recurrir
  /// a un LIKE costoso.
  Future<bool> existsByTitleAndType(String title, ContentType type) async {
    final row = await (_db.select(_db.contentItems)
          ..where((t) =>
              t.title.equals(title) & t.type.equals(type.name))
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }

  /// Inserta múltiples items en una sola transacción.
  /// Más rápido que muchos inserts individuales y atómico: si algo
  /// falla, no queda nada importado a medias.
  Future<int> insertBatch(List<ContentItem> items) async {
    if (items.isEmpty) return 0;
    return _db.transaction(() async {
      var count = 0;
      for (final item in items) {
        await _db
            .into(_db.contentItems)
            .insert(item.toInsertCompanion(), mode: InsertMode.insert);
        count++;
      }
      return count;
    });
  }
}
