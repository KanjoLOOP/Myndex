import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../content/domain/entities/content_item.dart';
import '../../../content/presentation/widgets/content_card.dart';
import '../providers/vault_providers.dart';

class CollectionDetailPage extends ConsumerStatefulWidget {
  final int collectionId;
  const CollectionDetailPage({super.key, required this.collectionId});

  @override
  ConsumerState<CollectionDetailPage> createState() =>
      _CollectionDetailPageState();
}

class _CollectionDetailPageState
    extends ConsumerState<CollectionDetailPage> {
  bool _reorderMode = false;
  List<ContentItem>? _localOrder;

  @override
  Widget build(BuildContext context) {
    final asyncCollections = ref.watch(collectionsProvider);
    final asyncItems =
        ref.watch(collectionItemsProvider(widget.collectionId));

    final collectionName = asyncCollections.valueOrNull
            ?.where((c) => c.id == widget.collectionId)
            .firstOrNull
            ?.name ??
        'Colección';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(collectionName, style: AppTextStyles.titleLg),
        actions: [
          if (asyncItems.valueOrNull?.isNotEmpty ?? false)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _reorderMode = !_reorderMode;
                  if (!_reorderMode) _localOrder = null;
                });
              },
              icon: Icon(
                _reorderMode ? Icons.check : Icons.swap_vert,
                size: 18,
                color: _reorderMode ? AppColors.cyan : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              label: Text(
                _reorderMode ? 'Listo' : 'Ordenar',
                style: AppTextStyles.labelMd.copyWith(
                  color: _reorderMode
                      ? AppColors.cyan
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
      body: asyncItems.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.cyan)),
        error: (e, _) =>
            const Center(child: Text('No se pudo cargar la colección')),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.collections_bookmark_outlined,
                      size: 40,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                Text('Colección vacía',
                    style: AppTextStyles.titleMd.copyWith(
                        color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 8),
                Text(
                  'Añade contenido desde su página de detalle\n→ Menú → Añadir a colección',
                  style: AppTextStyles.bodyMd.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ]),
            );
          }

          final displayItems = _localOrder ?? List<ContentItem>.from(items);

          if (_reorderMode) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Text(
                    'Arrastra para reordenar',
                    style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.cyan),
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        _localOrder ??= List<ContentItem>.from(items);
                        if (newIndex > oldIndex) newIndex--;
                        final item = _localOrder!.removeAt(oldIndex);
                        _localOrder!.insert(newIndex, item);
                      });
                    },
                    itemCount: displayItems.length,
                    itemBuilder: (_, i) {
                      final item = displayItems[i];
                      return _ReorderTile(
                        key: ValueKey(item.id),
                        item: item,
                        rank: i + 1,
                      );
                    },
                  ),
                ),
              ],
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.62,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: displayItems.length,
            itemBuilder: (_, i) => ContentCard(
              item: displayItems[i],
              onTap: () =>
                  context.push('/content/${displayItems[i].id}'),
            ),
          );
        },
      ),
    );
  }
}

class _ReorderTile extends StatelessWidget {
  final ContentItem item;
  final int rank;
  const _ReorderTile({super.key, required this.item, required this.rank});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: rank <= 3 ? AppColors.gradientH : null,
            color: rank <= 3
                ? null
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '$rank',
              style: AppTextStyles.labelMd.copyWith(
                color: rank <= 3
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: AppTextStyles.bodyMd.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(item.type.label,
                    style: AppTextStyles.labelSm.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant)),
              ]),
        ),
        Icon(Icons.drag_handle_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
      ]),
    );
  }
}
