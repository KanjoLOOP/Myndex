import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/content_types.dart';
import '../../../../core/security/input_sanitizer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../vault/domain/entities/collection.dart';
import '../../../vault/presentation/providers/vault_providers.dart';
import '../providers/content_providers.dart';
import '../widgets/radar_rating_chart.dart';

class ContentDetailPage extends ConsumerWidget {
  final int id;
  const ContentDetailPage({super.key, required this.id});

  Color _statusColor(ContentStatus s) => switch (s) {
        ContentStatus.pending    => AppColors.statusPending,
        ContentStatus.inProgress => AppColors.statusInProgress,
        ContentStatus.completed  => AppColors.statusCompleted,
        ContentStatus.dropped    => AppColors.statusDropped,
      };

  IconData _statusIcon(ContentStatus s) => switch (s) {
        ContentStatus.pending    => Icons.schedule_outlined,
        ContentStatus.inProgress => Icons.play_circle_outline,
        ContentStatus.completed  => Icons.check_circle_outline,
        ContentStatus.dropped    => Icons.cancel_outlined,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItem = ref.watch(contentItemProvider(id));
    return asyncItem.when(
      loading: () => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator(color: AppColors.cyan)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: Text('No se pudo cargar el contenido')),
      ),
      data: (item) {
        if (item == null) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(),
            body: const Center(child: Text('Contenido no encontrado')),
          );
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: CustomScrollView(
            slivers: [
              // ── Hero image ──────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                leading: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
                actions: [
                  // Botón favorito
                  GestureDetector(
                    onTap: () =>
                        ref.read(toggleFavoriteProvider)(item),
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        item.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: item.isFavorite
                            ? const Color(0xFFFF6B6B)
                            : Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  // Menú contextual
                  GestureDetector(
                    onTap: () => _showMenu(context, ref),
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.more_vert, color: Colors.white),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: item.imageUrl!,
                          fit: BoxFit.cover,
                        )
                      else
                        Container(
                          color: Theme.of(context).colorScheme.surface,
                          child: Icon(Icons.image_not_supported_outlined,
                              size: 64,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                        ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Theme.of(context)
                                    .scaffoldBackgroundColor
                                    .withOpacity(0.8),
                                Theme.of(context).scaffoldBackgroundColor,
                              ],
                              stops: const [0.5, 0.85, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Content body ────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(item.title, style: AppTextStyles.headlineLg),
                    const SizedBox(height: 12),

                    Wrap(spacing: 8, children: [
                      _MetaChip(item.type.label),
                      if (item.genre != null && item.genre!.isNotEmpty)
                        _MetaChip(item.genre!),
                      if (item.externalSource != null)
                        _MetaChip(item.externalSource!.toUpperCase()),
                    ]),
                    const SizedBox(height: 16),

                    _StatusBadge(
                      label: item.status.label,
                      color: _statusColor(item.status),
                      icon: _statusIcon(item.status),
                    ),
                    const SizedBox(height: 20),

                    if (item.score != null) ...[
                      Text('Tu valoración',
                          style: AppTextStyles.titleMd.copyWith(
                              color: Theme.of(context).colorScheme.onSurface)),
                      const SizedBox(height: 10),
                      _StarRating(score: item.score!),
                      const SizedBox(height: 20),
                    ],

                    // ── Radar chart (multidimensional) ──────────────────
                    if (item.ratingDimensions != null &&
                        item.ratingDimensions!.isNotEmpty) ...[
                      RadarRatingChart(
                        dimensions: item.ratingDimensions!.map(
                          (k, v) => MapEntry(k, (v as num).toDouble()),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── Progreso ────────────────────────────────────────
                    if (item.totalUnits != null && item.totalUnits! > 0) ...[
                      _ProgressSection(
                        current: item.progressUnits ?? 0,
                        total: item.totalUnits!,
                        label: item.type == ContentType.series ||
                                item.type == ContentType.anime
                            ? 'Episodios'
                            : item.type == ContentType.book
                                ? 'Páginas'
                                : 'Unidades',
                      ),
                      const SizedBox(height: 20),
                    ],

                    GradientButton(
                      label: 'Editar entrada',
                      icon: Icons.edit_outlined,
                      onPressed: () =>
                          context.push('/content/${item.id}/edit'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => _confirmDelete(context, ref),
                      icon: Icon(Icons.delete_outline,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant),
                      label: Text('Eliminar',
                          style: AppTextStyles.bodyMd.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        side: BorderSide(
                            color: Theme.of(context).dividerColor),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28)),
                      ),
                    ),

                    if (item.notes != null && item.notes!.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      const _SectionHeader('Notas personales'),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Theme.of(context).dividerColor),
                        ),
                        child: Text(item.notes!,
                            style: AppTextStyles.bodyLg.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface)),
                      ),
                    ],

                    const SizedBox(height: 20),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: AppColors.cyan),
            title: const Text('Editar'),
            onTap: () {
              Navigator.pop(context);
              context.push('/content/$id/edit');
            },
          ),
          ListTile(
            leading: const Icon(Icons.collections_bookmark_outlined,
                color: AppColors.cyan),
            title: const Text('Añadir a colección'),
            onTap: () {
              Navigator.pop(context);
              _showCollectionSheet(context, ref);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline,
                color: Color(0xFFFF6B6B)),
            title: const Text('Eliminar',
                style: TextStyle(color: Color(0xFFFF6B6B))),
            onTap: () {
              Navigator.pop(context);
              _confirmDelete(context, ref);
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _showCollectionSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CollectionPickerSheet(contentItemId: id),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Eliminar',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface)),
        content: Text('Esta acción no se puede deshacer.',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar',
                  style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar',
                  style: TextStyle(color: Color(0xFFFF6B6B)))),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await ref.read(deleteContentProvider).call(id);
      ref.invalidate(contentListProvider);
      context.pop();
    }
  }
}

// ── Collection picker sheet ────────────────────────────────────────────────

class _CollectionPickerSheet extends ConsumerStatefulWidget {
  final int contentItemId;
  const _CollectionPickerSheet({required this.contentItemId});

  @override
  ConsumerState<_CollectionPickerSheet> createState() =>
      _CollectionPickerSheetState();
}

class _CollectionPickerSheetState
    extends ConsumerState<_CollectionPickerSheet> {
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _createAndAdd() async {
    final raw = _nameCtrl.text.trim();
    if (raw.isEmpty) return;
    final String name;
    try {
      name = InputSanitizer.sanitizeTitle(raw);
    } on FormatException {
      return;
    }
    final col = await ref.read(createCollectionProvider)(name);
    if (col.id != null) {
      await ref.read(toggleItemInCollectionProvider)(
          col.id!, widget.contentItemId, true);
    }
    _nameCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final asyncCollections = ref.watch(collectionsProvider);
    final asyncMemberships =
        ref.watch(collectionIdsForItemProvider(widget.contentItemId));

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Colecciones',
              style: AppTextStyles.titleMd
                  .copyWith(color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 16),

          // Nueva colección inline
          Row(children: [
            Expanded(
              child: TextField(
                controller: _nameCtrl,
                style: AppTextStyles.bodyMd,
                decoration: InputDecoration(
                  hintText: 'Nueva colección...',
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _createAndAdd,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.gradientH,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
          ]),
          const SizedBox(height: 12),

          asyncCollections.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => const Text('No se pudieron cargar las colecciones'),
            data: (collections) {
              if (collections.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text('Todavía no hay colecciones.',
                      style: AppTextStyles.bodyMd.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant)),
                );
              }
              final memberIds = asyncMemberships.valueOrNull ?? {};
              return Column(
                children: collections
                    .map((col) => _CollectionTile(
                          collection: col,
                          isMember: memberIds.contains(col.id),
                          onToggle: (add) async {
                            await ref
                                .read(toggleItemInCollectionProvider)(
                                    col.id!, widget.contentItemId, add);
                          },
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CollectionTile extends StatelessWidget {
  final Collection collection;
  final bool isMember;
  final Future<void> Function(bool add) onToggle;
  const _CollectionTile(
      {required this.collection,
      required this.isMember,
      required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        Icons.collections_bookmark_outlined,
        color: isMember ? AppColors.cyan : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(collection.name,
          style: AppTextStyles.bodyMd
              .copyWith(color: Theme.of(context).colorScheme.onSurface)),
      subtitle: Text('${collection.itemCount} items',
          style: AppTextStyles.labelSm.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant)),
      trailing: Checkbox(
        value: isMember,
        activeColor: AppColors.cyan,
        onChanged: (v) => onToggle(v ?? false),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  final String label;
  const _MetaChip(this.label);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Text(label,
          style: AppTextStyles.labelMd.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _StatusBadge(
      {required this.label, required this.color, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.labelMd.copyWith(color: color)),
      ]),
    );
  }
}

class _StarRating extends StatelessWidget {
  final double score;
  const _StarRating({required this.score});
  @override
  Widget build(BuildContext context) {
    final stars = (score / 2).round();
    return Row(
        children: List.generate(5, (i) {
      return Icon(
        i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
        color: i < stars
            ? AppColors.cyan
            : Theme.of(context).colorScheme.onSurfaceVariant,
        size: 32,
      );
    }));
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Icon(Icons.notes_outlined, size: 18, color: AppColors.cyan),
      const SizedBox(width: 8),
      Text(title,
          style: AppTextStyles.titleMd
              .copyWith(color: Theme.of(context).colorScheme.onSurface)),
    ]);
  }
}

// ── Progress section ───────────────────────────────────────────────────────

class _ProgressSection extends StatelessWidget {
  final int current;
  final int total;
  final String label;
  const _ProgressSection({
    required this.current,
    required this.total,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = (current / total).clamp(0.0, 1.0);
    final pct = (ratio * 100).round();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.timeline_outlined, size: 18, color: AppColors.cyan),
          const SizedBox(width: 8),
          Text('Progreso',
              style: AppTextStyles.titleMd
                  .copyWith(color: Theme.of(context).colorScheme.onSurface)),
          const Spacer(),
          Text('$current / $total $label  ($pct%)',
              style: AppTextStyles.labelSm.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor:
                Theme.of(context).colorScheme.surface,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.cyan),
            minHeight: 8,
          ),
        ),
      ]),
    );
  }
}
