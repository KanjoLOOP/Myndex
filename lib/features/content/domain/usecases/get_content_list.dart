import '../../../../core/constants/content_types.dart';
import '../entities/content_item.dart';
import '../repositories/content_repository.dart';

/// Use case: obtener la lista de contenido aplicando filtros.
///
/// Encapsula una operación atómica del dominio. Aunque hoy parece
/// pasarela hacia el repositorio, mantenerlo como use case permite:
///   1. Añadir reglas (p. ej. ordenación por defecto, paginación)
///      sin tocar a quien lo consume.
///   2. Mockear fácilmente desde la presentación.
class GetContentList {
  final ContentRepository repository;
  const GetContentList(this.repository);

  Future<List<ContentItem>> call({
    ContentType? filterType,
    ContentStatus? filterStatus,
    double? minScore,
  }) {
    return repository.getAll(
      filterType: filterType,
      filterStatus: filterStatus,
      minScore: minScore,
    );
  }
}
