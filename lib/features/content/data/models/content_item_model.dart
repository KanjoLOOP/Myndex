import 'package:drift/drift.dart';

import '../../../../core/constants/content_types.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/content_item.dart';

/// Mappers entre la fila de Drift y la entidad de dominio.
///
/// Mantenemos la frontera entre capa de datos y dominio: la UI nunca
/// debe ver un `ContentItem$` (clase generada por Drift). Eso permite
/// cambiar el motor de persistencia sin tocar la presentación.
extension ContentItemRowMapper on ContentItem$ {
  /// Convierte la fila Drift en entidad de dominio.
  ///
  /// Tolera valores corruptos en `type` y `status` cayendo a `other`/
  /// `pending` para no crashear la app si alguien manipuló la DB
  /// manualmente. En import nuevo sí validamos estrictamente.
  ContentItem toDomain() => ContentItem(
        id: id,
        title: title,
        type: ContentType.values
                .where((t) => t.name == type)
                .firstOrNull ??
            ContentType.other,
        status: ContentStatus.values
                .where((s) => s.name == status)
                .firstOrNull ??
            ContentStatus.pending,
        score: score,
        notes: notes,
        imageUrl: imageUrl,
        externalId: externalId,
        externalSource: externalSource,
        addedAt: addedAt,
        updatedAt: updatedAt,
      );
}

extension ContentItemEntityMapper on ContentItem {
  /// Compañero para INSERT.
  ///
  /// `addedAt` y `updatedAt` se envían como [Value] explícito porque
  /// los gestionamos desde el dominio (no dejamos los defaults de
  /// SQLite, así controlamos las fechas también en imports).
  ContentItemsCompanion toInsertCompanion() => ContentItemsCompanion.insert(
        title: title,
        type: type.name,
        status: status.name,
        score: Value(score),
        notes: Value(notes),
        imageUrl: Value(imageUrl),
        externalId: Value(externalId),
        externalSource: Value(externalSource),
        addedAt: Value(addedAt),
        updatedAt: Value(updatedAt),
      );

  /// Compañero para UPDATE.
  ///
  /// Diferencia clave respecto a [toInsertCompanion]: usamos
  /// `ContentItemsCompanion(...)` en vez de `.insert(...)` para que
  /// los campos no marcados queden como `Value.absent()` y no se
  /// sobrescriban accidentalmente. Además, **nunca** tocamos `addedAt`
  /// en un UPDATE (el `addedAt` original es inmutable a partir del
  /// primer guardado).
  ContentItemsCompanion toUpdateCompanion() => ContentItemsCompanion(
        title: Value(title),
        type: Value(type.name),
        status: Value(status.name),
        score: Value(score),
        notes: Value(notes),
        imageUrl: Value(imageUrl),
        externalId: Value(externalId),
        externalSource: Value(externalSource),
        // NO incluimos addedAt: queda absent → no se modifica.
        updatedAt: Value(updatedAt),
      );
}
