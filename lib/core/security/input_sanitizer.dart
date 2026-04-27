/// Saneador de entradas de texto.
///
/// Centraliza las reglas de validación y limpieza para evitar que
/// datos maliciosos o malformados lleguen a la base de datos, a la API
/// externa o al sistema de ficheros.
///
/// IMPORTANTE: estas reglas se aplican tanto a la entrada manual del
/// usuario como a los datos que vienen de un import JSON. Cualquier
/// otra capa (datasource, repositorio, UI) debe pasar por aquí antes
/// de persistir o exponer texto.
library;

class InputSanitizer {
  // Límites duros para evitar abuso de almacenamiento o ataques de
  // denegación de servicio por entradas gigantes.
  static const int maxTitleLength = 300;
  static const int maxNotesLength = 10000;
  static const int maxQueryLength = 200;
  static const int maxUrlLength = 2048;

  /// Devuelve el título recortado y validado.
  ///
  /// - Quita espacios al principio y al final.
  /// - Colapsa secuencias de espacios/tabs múltiples a uno solo.
  /// - Limita la longitud máxima.
  /// - Lanza [FormatException] si queda vacío.
  static String sanitizeTitle(String raw) {
    final trimmed = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmed.isEmpty) {
      throw const FormatException('El título no puede estar vacío');
    }
    if (trimmed.length > maxTitleLength) {
      return trimmed.substring(0, maxTitleLength);
    }
    return trimmed;
  }

  /// Limpia las notas personales preservando saltos de línea pero
  /// eliminando caracteres de control que no deberían estar presentes
  /// (excepto tabuladores, retornos y saltos de línea).
  static String? sanitizeNotes(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    // Filtra caracteres de control (excepto \t \n \r) que pueden causar
    // problemas de renderizado o ser usados como vector de inyección.
    final cleaned = trimmed.replaceAll(
      RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'),
      '',
    );
    if (cleaned.length > maxNotesLength) {
      return cleaned.substring(0, maxNotesLength);
    }
    return cleaned;
  }

  /// Valida que la URL de imagen sea http(s) y razonable.
  ///
  /// Devuelve `null` si la cadena es vacía o inválida (por ejemplo si
  /// alguien intenta meter `file://`, `javascript:` o `data:`).
  static String? sanitizeImageUrl(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.length > maxUrlLength) return null;
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return null;
    // Solo se permiten esquemas seguros y resolubles a través de la red.
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    if (!uri.hasAuthority || uri.host.isEmpty) return null;
    return trimmed;
  }

  /// Sanea la cadena de búsqueda: recorta, limita y escapa los
  /// comodines de SQL LIKE para que el usuario no pueda usar `%` o `_`
  /// y forzar barridos de toda la tabla.
  static String sanitizeSearchQuery(String raw) {
    final trimmed = raw.trim();
    if (trimmed.length > maxQueryLength) {
      return _escapeLike(trimmed.substring(0, maxQueryLength));
    }
    return _escapeLike(trimmed);
  }

  /// Escapa los comodines de LIKE en SQLite usando `\` como carácter
  /// de escape. El uso del carácter de escape se declara con
  /// `ESCAPE '\'` en la query.
  static String _escapeLike(String input) {
    return input
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
  }

  /// Valida que la puntuación esté en el rango permitido (0..10).
  /// Devuelve `null` si está fuera de rango o si es 0 (sin puntuar).
  static double? sanitizeScore(num? raw) {
    if (raw == null) return null;
    final value = raw.toDouble();
    if (value <= 0) return null;
    if (value > 10) return 10.0;
    return value;
  }
}
