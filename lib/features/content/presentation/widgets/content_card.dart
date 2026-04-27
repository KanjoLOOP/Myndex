import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/content_types.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/content_item.dart';

class ContentCard extends StatelessWidget {
  final ContentItem item;
  final VoidCallback onTap;

  const ContentCard({super.key, required this.item, required this.onTap});

  Color _statusColor(ContentStatus s) => switch (s) {
        ContentStatus.pending    => AppColors.statusPending,
        ContentStatus.inProgress => AppColors.statusInProgress,
        ContentStatus.completed  => AppColors.statusCompleted,
        ContentStatus.dropped    => AppColors.statusDropped,
      };

  @override
  Widget build(BuildContext context) {
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
            // ── Portada ────────────────────────────────────────────────
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
                ],
              ),
            ),
            // ── Metadata ───────────────────────────────────────────────
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
                  const SizedBox(height: 6),
                  Row(children: [
                    // Status dot + label
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _statusColor(item.status),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(item.status.label,
                        style: AppTextStyles.labelSm
                            .copyWith(color: _statusColor(item.status))),
                  ]),
                  if (item.score != null) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.star_rounded, size: 12, color: AppColors.cyan),
                      const SizedBox(width: 3),
                      Text('${item.score}', style: AppTextStyles.labelSm.copyWith(color: AppColors.cyan)),
                    ]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final ContentType type;
  const _Placeholder(this.type);

  IconData get icon => switch (type) {
        ContentType.movie   => Icons.movie_outlined,
        ContentType.series  => Icons.tv_outlined,
        ContentType.book    => Icons.menu_book_outlined,
        ContentType.game    => Icons.sports_esports_outlined,
        ContentType.anime   => Icons.animation_outlined,
        ContentType.podcast => Icons.podcasts_outlined,
        ContentType.other   => Icons.category_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: Icon(icon, size: 40, color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}
