enum ContentType {
  movie('Película'),
  series('Serie'),
  game('Videojuego'),
  book('Libro'),
  anime('Anime'),
  podcast('Podcast'),
  other('Otro');

  final String label;
  const ContentType(this.label);
}

enum ContentStatus {
  pending('Pendiente'),
  inProgress('En progreso'),
  completed('Completado'),
  dropped('Abandonado');

  final String label;
  const ContentStatus(this.label);
}
