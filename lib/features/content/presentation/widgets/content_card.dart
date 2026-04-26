import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/content_item.dart';

class ContentCard extends StatelessWidget {
  final ContentItem item;
  final VoidCallback onTap;

  const ContentCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            _Thumbnail(imageUrl: item.imageUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(children: [
                      _TypeChip(item.type.label),
                      const SizedBox(width: 8),
                      _StatusDot(item.status.label, colorScheme),
                    ]),
                    if (item.score != null) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        Icon(Icons.star_rounded, size: 14, color: colorScheme.primary),
                        const SizedBox(width: 2),
                        Text('${item.score}',
                            style: Theme.of(context).textTheme.bodySmall),
                      ]),
                    ],
                  ],
                ),
              ),
            ),
            const Icon(Icons.chevron_right),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final String? imageUrl;
  const _Thumbnail({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        width: 60, height: 80,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.image_not_supported_outlined),
      );
    }
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      width: 60,
      height: 80,
      fit: BoxFit.cover,
      placeholder: (_, __) => const SizedBox(
          width: 60, height: 80,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
      errorWidget: (_, __, ___) => const Icon(Icons.broken_image_outlined),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  const _TypeChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSecondaryContainer)),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final String label;
  final ColorScheme colorScheme;
  const _StatusDot(this.label, this.colorScheme);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
          width: 6, height: 6,
          decoration: BoxDecoration(
              shape: BoxShape.circle, color: colorScheme.primary)),
      const SizedBox(width: 4),
      Text(label, style: Theme.of(context).textTheme.labelSmall),
    ]);
  }
}
