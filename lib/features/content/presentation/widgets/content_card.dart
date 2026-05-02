import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/content_types.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/content_item.dart';

/// Tarjeta de contenido mostrada en la cuadrícula principal.
/// Muestra portada, título, estado, progreso y puntuación.
class ContentCard extends StatelessWidget {
  final ContentItem item;
  final VoidCallback onTap;

  const ContentCard({super.key, required this.item, required this.onTap});

  /// Ratio de progreso de 0.0 a 1.0, o null si no hay datos de progreso.
  double? get _progressRatio {
    final total = item.totalUnits;
    if (total == null || total == 0) return null;
    return ((item.progressUnits ?? 0) / total).clamp(0.0, 1.0);
  }

  /// Texto legible del tiempo restante (p.ej. "2h 30m"), o null si no hay datos.
  String? get _remainingTime {
    final total = item.totalUnits;
    final dur   = item.estimatedDurationMinutes;
    if (total == null || dur == null || total == 0) return null;

    final current    = item.progressUnits ?? 0;
    final remaining  = total - current;
    if (remaining <= 0) return null;

    // Minutos por unidad = duración total / unidades totales
    final minsLeft = (dur / total * remaining).round();
    if (minsLeft < 60) return '${minsLeft}min';
    final h = minsLeft ~/ 60;
    final m = minsLeft % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final ratio = _progressRatio;
    final time  = _remainingTime;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Portada ──────────────────────────────────────────────
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: item.imageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: (_, __) => _Placeholder(item.type),
                            errorWidget: (_, __, ___) => _Placeholder(item.type),
                          )
                        : _Placeholder(item.type),
                  ),
                  // Favorito badge
                  if (item.isFavorite)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Color(0xFFFF6B6B),
                          size: 14,
                        ),
                      ),
                    ),
                  // Tiempo restante badge (top-left)
                  if (time != null &&
                      item.status == ContentStatus.inProgress)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.timer_outlined,
                              size: 10, color: AppColors.cyan),
                          const SizedBox(width: 3),
                          Text(time,
                              style: AppTextStyles.labelSm.copyWith(
                                  color: AppColors.cyan, fontSize: 9)),
                        ]),
                      ),
                    ),
                ],
              ),
            ),

            // ── Barra de progreso ────────────────────────────────────
            if (ratio != null && item.status == ContentStatus.inProgress)
              ClipRRect(
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 3,
                  backgroundColor:
                      Theme.of(context).colorScheme.surface,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.cyan),
                ),
              ),

            // ── Metadata ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTextStyles.titleMd.copyWith(fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(children: [
                    // Punto de color indicando el estado del item
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: item.status.color,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        // Muestra "X/Y" cuando está en progreso con unidades registradas
                        item.status == ContentStatus.inProgress &&
                                item.progressUnits != null &&
                                item.totalUnits != null
                            ? '${item.progressUnits}/${item.totalUnits}'
                            : item.status.label,
                        style: AppTextStyles.labelSm
                            .copyWith(color: item.status.color),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.score != null) ...[
                      const Icon(Icons.star_rounded,
                          size: 11, color: AppColors.cyan),
                      const SizedBox(width: 2),
                      Text('${item.score}',
                          style: AppTextStyles.labelSm
                              .copyWith(color: AppColors.cyan)),
                    ],
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder cuando el item no tiene portada.
/// Muestra el icono del tipo de contenido centrado.
class _Placeholder extends StatelessWidget {
  final ContentType type;
  const _Placeholder(this.type);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: Icon(type.icon, size: 40,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}
