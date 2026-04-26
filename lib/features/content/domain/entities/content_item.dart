import '../../../../core/constants/content_types.dart';

/// Entidad principal del dominio.
///
/// Representa cualquier pieza de contenido que el usuario quiere
/// trackear: una película, una serie, un libro, un videojuego, etc.
///
/// Es inmutable: cualquier modificación produce una nueva instancia
/// vía [copyWith]. Esto encaja con Riverpod (comparación por valor) y
/// evita estados inconsistentes en la UI.
///
/// Reglas de invariantes:
/// - [title] no puede ser vacío (validado en la capa de saneo).
/// - [score] vive en el rango (0, 10] o es `null`. Cero significa
///   "sin puntuar" y se persiste como `null`.
/// - [addedAt] **nunca** debe sobreescribirse al actualizar; es la
///   fecha en la que el usuario añadió el ítem por primera vez.
/// - [updatedAt] se actualiza en cada modificación.
class ContentItem {
  /// `null` cuando aún no se ha guardado en la base de datos.
  /// Drift autogenera el id con autoIncrement al insertar.
  final int? id;

  /// Título visible.
  final String title;

  /// Tipo de contenido (movie, series, book, game, anime, podcast, other).
  final ContentType type;

  /// Estado de visualización/lectura/juego.
  final ContentStatus status;

  /// Puntuación 0..10 (representada como 0..5 estrellas en la UI).
  /// `null` significa "sin puntuar".
  final double? score;

  /// Notas personales del usuario. Texto libre.
  final String? notes;

  /// URL de la imagen de portada (https only). Puede venir de TMDB,
  /// Open Library, RAWG o ser introducida manualmente por el usuario.
  final String? imageUrl;

  /// Identificador del recurso en la API externa de origen, si existe.
  final String? externalId;

  /// Origen del enriquecimiento: 'tmdb', 'rawg', 'openlibrary'…
  final String? externalSource;

  /// Fecha en la que el usuario añadió el ítem a la biblioteca.
  /// **No se modifica al actualizar.**
  final DateTime addedAt;

  /// Fecha de la última modificación. Se refresca con cada save.
  final DateTime updatedAt;

  const ContentItem({
    this.id,
    required this.title,
    required this.type,
    required this.status,
    this.score,
    this.notes,
    this.imageUrl,
    this.externalId,
    this.externalSource,
    required this.addedAt,
    required this.updatedAt,
  });

  /// Crea una copia con los campos indicados sustituidos.
  ContentItem copyWith({
    int? id,
    String? title,
    ContentType? type,
    ContentStatus? status,
    double? score,
    String? notes,
    String? imageUrl,
    String? externalId,
    String? externalSource,
    DateTime? addedAt,
    DateTime? updatedAt,
    // Flags explícitos para poner valores a null sin colisionar con
    // el patrón `?? this.x`.
    bool clearScore = false,
    bool clearNotes = false,
    bool clearImageUrl = false,
    bool clearExternalId = false,
    bool clearExternalSource = false,
  }) {
    return ContentItem(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      status: status ?? this.status,
      score: clearScore ? null : (score ?? this.score),
      notes: clearNotes ? null : (notes ?? this.notes),
      imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
      externalId: clearExternalId ? null : (externalId ?? this.externalId),
      externalSource:
          clearExternalSource ? null : (externalSource ?? this.externalSource),
      addedAt: addedAt ?? this.addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Serialización para export JSON.
  ///
  /// El campo `id` se incluye solo de forma informativa: al importar
  /// se descarta para que la base de datos genere uno nuevo y no
  /// haya colisiones con el contenido existente.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type.name,
        'status': status.name,
        'score': score,
        'notes': notes,
        'imageUrl': imageUrl,
        'externalId': externalId,
        'externalSource': externalSource,
        'addedAt': addedAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// Deserialización defensiva desde JSON.
  ///
  /// Lanza [FormatException] si los campos obligatorios faltan o
  /// tienen tipos incorrectos. El llamador (importer) es responsable
  /// de capturar y reportar el error con [ImportFailure].
  factory ContentItem.fromJson(Map<String, dynamic> json) {
    final title = json['title'];
    if (title is! String || title.trim().isEmpty) {
      throw const FormatException('Campo "title" obligatorio y no vacío');
    }

    final typeName = json['type'];
    if (typeName is! String) {
      throw const FormatException('Campo "type" obligatorio');
    }
    final type = ContentType.values
        .where((t) => t.name == typeName)
        .firstOrNull;
    if (type == null) {
      throw FormatException('Tipo de contenido desconocido: $typeName');
    }

    final statusName = json['status'];
    if (statusName is! String) {
      throw const FormatException('Campo "status" obligatorio');
    }
    final status = ContentStatus.values
        .where((s) => s.name == statusName)
        .firstOrNull;
    if (status == null) {
      throw FormatException('Estado desconocido: $statusName');
    }

    DateTime parseDate(Object? raw, String field) {
      if (raw is! String) {
        throw FormatException('Campo "$field" debe ser ISO 8601 string');
      }
      try {
        return DateTime.parse(raw);
      } on FormatException {
        throw FormatException('Campo "$field" con formato de fecha inválido');
      }
    }

    return ContentItem(
      id: null, // ignoramos el id del export para evitar colisiones
      title: title,
      type: type,
      status: status,
      score: (json['score'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      imageUrl: json['imageUrl'] as String?,
      externalId: json['externalId'] as String?,
      externalSource: json['externalSource'] as String?,
      addedAt: parseDate(json['addedAt'], 'addedAt'),
      updatedAt: parseDate(json['updatedAt'], 'updatedAt'),
    );
  }
}
