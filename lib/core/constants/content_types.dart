/// Enumeraciones del dominio y sus extensiones de presentación.
///
/// Los valores se persisten en la base de datos como cadenas usando `.name`
/// (p. ej. `'movie'`, `'pending'`). Cualquier renombrado de un valor
/// rompería la compatibilidad con backups antiguos: tratarlos como inmutables.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

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

/// Propiedades visuales de [ContentStatus].
/// Centraliza colores e iconos para que no se dupliquen en cada widget.
extension ContentStatusPresentation on ContentStatus {
  /// Color del estado (punto de color, etiqueta, gráficas).
  Color get color => switch (this) {
        ContentStatus.pending    => AppColors.statusPending,
        ContentStatus.inProgress => AppColors.statusInProgress,
        ContentStatus.completed  => AppColors.statusCompleted,
        ContentStatus.dropped    => AppColors.statusDropped,
      };

  /// Icono representativo del estado (usado en detalles y badges).
  IconData get statusIcon => switch (this) {
        ContentStatus.pending    => Icons.schedule_outlined,
        ContentStatus.inProgress => Icons.play_circle_outline,
        ContentStatus.completed  => Icons.check_circle_outline,
        ContentStatus.dropped    => Icons.cancel_outlined,
      };
}

/// Propiedades visuales de [ContentType].
/// Centraliza los iconos para que no se dupliquen en cada widget.
extension ContentTypePresentation on ContentType {
  IconData get icon => switch (this) {
        ContentType.movie   => Icons.movie_outlined,
        ContentType.series  => Icons.tv_outlined,
        ContentType.book    => Icons.menu_book_outlined,
        ContentType.game    => Icons.sports_esports_outlined,
        ContentType.anime   => Icons.animation_outlined,
        ContentType.podcast => Icons.podcasts_outlined,
        ContentType.other   => Icons.category_outlined,
      };
}
