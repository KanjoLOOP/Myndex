import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/content_types.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../providers/content_providers.dart';

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
        body: Center(child: Text('Error: $e')),
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
                        Container(color: Theme.of(context).colorScheme.surface,
                            child: Icon(Icons.image_not_supported_outlined,
                                size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      // Gradient overlay bottom
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
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
                    // Título
                    Text(item.title, style: AppTextStyles.headlineLg),
                    const SizedBox(height: 12),

                    // Meta chips
                    Wrap(spacing: 8, children: [
                      _MetaChip(item.type.label),
                      if (item.externalSource != null)
                        _MetaChip(item.externalSource!.toUpperCase()),
                    ]),
                    const SizedBox(height: 16),

                    // Status badge
                    _StatusBadge(
                      label: item.status.label,
                      color: _statusColor(item.status),
                      icon: _statusIcon(item.status),
                    ),
                    const SizedBox(height: 20),

                    // Rating
                    if (item.score != null) ...[
                      Text('Tu valoración', style: AppTextStyles.titleMd.copyWith(color: Theme.of(context).colorScheme.onSurface)),
                      const SizedBox(height: 10),
                      _StarRating(score: item.score!),
                      const SizedBox(height: 20),
                    ],

                    // Botones acción
                    GradientButton(
                      label: 'Editar entrada',
                      icon: Icons.edit_outlined,
                      onPressed: () => context.push('/content/${item.id}/edit'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => _confirmDelete(context, ref),
                      icon: Icon(Icons.archive_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      label: Text('Archivar',
                          style: AppTextStyles.bodyMd.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        side: BorderSide(color: Theme.of(context).dividerColor),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28)),
                      ),
                    ),

                    // Notas personales
                    if (item.notes != null && item.notes!.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      const _SectionHeader('Notas personales'),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Text(item.notes!, style: AppTextStyles.bodyLg.copyWith(color: Theme.of(context).colorScheme.onSurface)),
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
            onTap: () { Navigator.pop(context); context.push('/content/$id/edit'); },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Color(0xFFFF6B6B)),
            title: const Text('Eliminar', style: TextStyle(color: Color(0xFFFF6B6B))),
            onTap: () { Navigator.pop(context); _confirmDelete(context, ref); },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Eliminar', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: Text('Esta acción no se puede deshacer.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar', style: TextStyle(color: Color(0xFFFF6B6B)))),
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
      child: Text(label, style: AppTextStyles.labelMd.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _StatusBadge({required this.label, required this.color, required this.icon});
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
  final double score; // 0..10
  const _StarRating({required this.score});
  @override
  Widget build(BuildContext context) {
    final stars = (score / 2).round(); // 0-5
    return Row(children: List.generate(5, (i) {
      return Icon(
        i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
        color: i < stars ? AppColors.cyan : Theme.of(context).colorScheme.onSurfaceVariant,
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
      Text(title, style: AppTextStyles.titleMd.copyWith(color: Theme.of(context).colorScheme.onSurface)),
    ]);
  }
}
