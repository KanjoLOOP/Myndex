import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../content/presentation/widgets/content_card.dart';
import '../providers/vault_providers.dart';

class CollectionDetailPage extends ConsumerWidget {
  final int collectionId;
  const CollectionDetailPage({super.key, required this.collectionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCollections = ref.watch(collectionsProvider);
    final asyncItems = ref.watch(collectionItemsProvider(collectionId));

    final collectionName = asyncCollections.valueOrNull
            ?.where((c) => c.id == collectionId)
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
      ),
      body: asyncItems.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.cyan)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) => items.isEmpty
            ? Center(
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
              )
            : GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.62,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) => ContentCard(
                  item: items[i],
                  onTap: () => context.push('/content/${items[i].id}'),
                ),
              ),
      ),
    );
  }
}
