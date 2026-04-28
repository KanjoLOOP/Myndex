import '../../../../core/constants/content_types.dart';
import '../entities/content_item.dart';

/// Contrato del repositorio de contenido.
///
/// La capa de dominio depende de esta abstracción, no de Drift ni de
/// ningún cliente HTTP. La implementación concreta vive en
/// `data/repositories/content_repository_impl.dart`.
///
/// Esta indirección permite, por ejemplo, inyectar un repositorio
/// fake en los tests sin necesidad de levantar una base de datos.
abstract class ContentRepository {
  /// Lista todos los items aplicando filtros opcionales.
  Future<List<ContentItem>> getAll({
    ContentType? filterType,
    ContentStatus? filterStatus,
    double? minScore,
    bool? filterFavorite,
  });

  /// Obtiene un item por id, o `null` si no existe.
  Future<ContentItem?> getById(int id);

  /// Persiste un item nuevo. Devuelve la entidad con el id asignado.
  Future<ContentItem> create(ContentItem item);

  /// Actualiza un item existente. Conserva su `addedAt` original.
  Future<ContentItem> update(ContentItem item);

  /// Borra el item por id.
  Future<void> delete(int id);

  /// Búsqueda local por título (case-insensitive, escapa LIKE).
  Future<List<ContentItem>> search(String query);

  /// Devuelve todos los items serializados (para export JSON).
  Future<List<Map<String, dynamic>>> exportAll();

  /// Importa un lote desde JSON. Si `skipDuplicates`, se ignoran
  /// items con mismo `(title, type)` que ya existan en la DB.
  /// Devuelve el número de items realmente insertados.
  Future<int> importAll(
    List<Map<String, dynamic>> data, {
    bool skipDuplicates = true,
  });

  /// Recupera el registro de actividades.
  Future<List<dynamic>> getActivityLog();
}
