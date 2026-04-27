/// Enumeraciones del dominio.
///
/// Se persisten en la base de datos como cadenas usando `.name`
/// (p. ej. `'movie'`, `'pending'`). Cualquier renombrado de un valor
/// rompería la compatibilidad con backups antiguos: tratarlos como
/// inmutables.
library;

/// Tipo de contenido que el usuario puede trackear.
enum ContentType {
  movie('Película'),
  series('Serie'),
  game('Videojuego'),
  book('Libro'),
  anime('Anime'),
  podcast('Podcast'),
  other('Otro');

  /// Etiqueta legible en la UI (en castellano).
  final String label;
  const ContentType(this.label);
}

/// Estado de progreso/visualización del contenido.
enum ContentStatus {
  pending('Pendiente'),
  inProgress('En progreso'),
  completed('Completado'),
  dropped('Abandonado');

  final String label;
  const ContentStatus(this.label);
}
