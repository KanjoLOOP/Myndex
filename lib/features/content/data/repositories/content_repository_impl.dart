import '../../../../core/constants/content_types.dart';
import '../../../../core/security/input_sanitizer.dart';
import '../../domain/entities/content_item.dart';
import '../../domain/repositories/content_repository.dart';
import '../datasources/content_local_datasource.dart';

/// Implementación del repositorio de contenido.
///
/// Encadena el saneo de inputs con la persistencia local. Toda
/// validación pasa por aquí; el datasource asume que recibe datos ya
/// limpios.
class ContentRepositoryImpl implements ContentRepository {
  final ContentLocalDatasource _local;

  ContentRepositoryImpl(this._local);

  @override
  Future<List<ContentItem>> getAll({
    ContentType? filterType,
    ContentStatus? filterStatus,
    double? minScore,
    bool? filterFavorite,
  }) =>
      _local.getAll(
        filterType: filterType,
        filterStatus: filterStatus,
        minScore: minScore,
        filterFavorite: filterFavorite,
      );

  @override
  Future<ContentItem?> getById(int id) => _local.getById(id);

  @override
  Future<ContentItem> create(ContentItem item) {
    final sane = _sanitize(item);
    return _local.insert(sane);
  }

  @override
  Future<ContentItem> update(ContentItem item) async {
    if (item.id == null) {
      throw StateError('Imposible actualizar: id ausente');
    }
    final existing = await _local.getById(item.id!);
    if (existing == null) {
      throw StateError('Imposible actualizar: item no encontrado');
    }
    // Conservamos el addedAt original sin importar lo que mande la UI.
    final preserved = item.copyWith(addedAt: existing.addedAt);
    final sane = _sanitize(preserved);
    return _local.update(sane);
  }

  @override
  Future<void> delete(int id) => _local.delete(id);

  @override
  Future<List<ContentItem>> search(String query) => _local.search(query);

  @override
  Future<List<Map<String, dynamic>>> exportAll() async {
    final items = await _local.getAllUnfiltered();
    return items.map((e) => e.toJson()).toList();
  }

  @override
  Future<int> importAll(
    List<Map<String, dynamic>> data, {
    bool skipDuplicates = true,
  }) async {
    final toImport = <ContentItem>[];
    for (final json in data) {
      // ContentItem.fromJson lanza FormatException ante datos malos;
      // capturamos para no abortar el lote completo.
      try {
        final parsed = ContentItem.fromJson(json);
        final sane = _sanitize(parsed);
        if (skipDuplicates &&
            await _local.existsByTitleAndType(sane.title, sane.type)) {
          continue;
        }
        toImport.add(sane);
      } on FormatException {
        // Saltar entradas individuales malformadas.
        continue;
      }
    }
    return _local.insertBatch(toImport);
  }

  /// Aplica el sanitizer a los campos de texto y URL de un item antes
  /// de cualquier persistencia. Centraliza la defensa para que ningún
  /// camino (manual, import, API) pueda saltársela.
  ContentItem _sanitize(ContentItem item) {
    return item.copyWith(
      title: InputSanitizer.sanitizeTitle(item.title),
      notes: InputSanitizer.sanitizeNotes(item.notes),
      imageUrl: InputSanitizer.sanitizeImageUrl(item.imageUrl),
      score: InputSanitizer.sanitizeScore(item.score),
      // Si `notes`/`imageUrl` quedaron `null` tras saneo y antes había
      // valor, copyWith no los ha puesto a null porque solo sustituye
      // si el nuevo valor es no-null. Forzamos explícitamente.
      clearNotes: item.notes != null &&
          (InputSanitizer.sanitizeNotes(item.notes) == null),
      clearImageUrl: item.imageUrl != null &&
          (InputSanitizer.sanitizeImageUrl(item.imageUrl) == null),
      clearScore: item.score != null &&
          (InputSanitizer.sanitizeScore(item.score) == null),
    );
  }

  @override
  Future<List<dynamic>> getActivityLog() => _local.getActivityLog();
}
