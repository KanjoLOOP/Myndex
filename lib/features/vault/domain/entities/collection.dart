/// Colección personalizada del usuario.
///
/// Agrupa items de contenido bajo un nombre libre (ej. "Maratón Marvel").
/// Los items se almacenan en la tabla `collection_items` (N:M).
class Collection {
  final int? id;
  final String name;
  final DateTime createdAt;

  /// Número de items en la colección. Campo calculado, no persistido.
  final int itemCount;

  const Collection({
    this.id,
    required this.name,
    required this.createdAt,
    this.itemCount = 0,
  });

  Collection copyWith({int? id, String? name, DateTime? createdAt, int? itemCount}) =>
      Collection(
        id: id ?? this.id,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
        itemCount: itemCount ?? this.itemCount,
      );
}
