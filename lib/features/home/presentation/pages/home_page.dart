import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/content_types.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_text.dart';
import '../../../content/presentation/providers/content_providers.dart';
import '../../../content/presentation/widgets/content_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  ContentType?   _selectedType;
  ContentStatus? _selectedStatus;
  double?        _selectedMinScore;

  static const _typeFilters = [
    (label: 'Todo',    type: null as ContentType?),
    (label: 'Cine',    type: ContentType.movie),
    (label: 'Series',  type: ContentType.series),
    (label: 'Libros',  type: ContentType.book),
    (label: 'Juegos',  type: ContentType.game),
    (label: 'Anime',   type: ContentType.anime),
  ];

  static const _statusFilters = [
    (label: 'Todos',      status: null as ContentStatus?),
    (label: 'Pendiente',  status: ContentStatus.pending),
    (label: 'En curso',   status: ContentStatus.inProgress),
    (label: 'Completado', status: ContentStatus.completed),
    (label: 'Abandonado', status: ContentStatus.dropped),
  ];

  // score stored as 0-10; displayed as stars (÷2)
  static const _scoreOptions = [
    (label: 'Sin filtro', score: null as double?),
    (label: '≥ 2 ★',     score: 4.0),
    (label: '≥ 3 ★',     score: 6.0),
    (label: '≥ 4 ★',     score: 8.0),
    (label: 'Solo 5 ★',  score: 10.0),
  ];

  bool get _hasAdvancedFilter =>
      _selectedStatus != null || _selectedMinScore != null;

  void _applyTypeFilter(ContentType? type) {
    setState(() => _selectedType = type);
    ref.read(filterStateProvider.notifier).update(
          (s) => s.copyWith(type: type, clearType: type == null),
        );
  }

  void _applyStatusFilter(ContentStatus? status) {
    setState(() => _selectedStatus = status);
    ref.read(filterStateProvider.notifier).update(
          (s) => s.copyWith(status: status, clearStatus: status == null),
        );
  }

  void _applyScoreFilter(double? minScore) {
    setState(() => _selectedMinScore = minScore);
    ref.read(filterStateProvider.notifier).update(
          (s) => s.copyWith(minScore: minScore, clearScore: minScore == null),
        );
  }

  void _clearAllFilters() {
    setState(() {
      _selectedType     = null;
      _selectedStatus   = null;
      _selectedMinScore = null;
    });
    ref.read(filterStateProvider.notifier).update(
          (_) => const FilterState(),
        );
  }

  void _openScoreSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Puntuación mínima',
                style: AppTextStyles.titleMd.copyWith(
                    color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _scoreOptions.map((o) {
                final selected = _selectedMinScore == o.score;
                return GestureDetector(
                  onTap: () {
                    _applyScoreFilter(o.score);
                    Navigator.of(ctx).pop();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: selected ? AppColors.gradientH : null,
                      color: selected
                          ? null
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? Colors.transparent
                            : Theme.of(context).dividerColor,
                      ),
                    ),
                    child: Text(
                      o.label,
                      style: AppTextStyles.labelMd.copyWith(
                        color: selected
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncItems = ref.watch(contentListProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        titleSpacing: 20,
        title: GradientText(
          'Myndex',
          style: AppTextStyles.headlineLg.copyWith(fontSize: 26),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            onPressed: () => context.go('/explore'),
          ),
          // Score filter with active indicator
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.tune_rounded,
                  color: _selectedMinScore != null
                      ? AppColors.cyan
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onPressed: _openScoreSheet,
                tooltip: 'Filtrar por puntuación',
              ),
              if (_selectedMinScore != null)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.cyan,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Filtros de tipo ────────────────────────────────────────
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _typeFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = _typeFilters[i];
                return _FilterChip(
                  label: f.label,
                  selected: _selectedType == f.type,
                  onTap: () => _applyTypeFilter(f.type),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // ── Filtros de estado ──────────────────────────────────────
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _statusFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = _statusFilters[i];
                return _FilterChip(
                  label: f.label,
                  selected: _selectedStatus == f.status,
                  onTap: () => _applyStatusFilter(f.status),
                );
              },
            ),
          ),

          // ── Indicador de filtros activos ───────────────────────────
          if (_hasAdvancedFilter)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.cyan, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  'Filtros activos',
                  style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.cyan),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _clearAllFilters,
                  child: Text(
                    'Limpiar todo',
                    style: AppTextStyles.labelMd.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ]),
            )
          else
            const SizedBox(height: 8),

          // ── Lista de contenido ─────────────────────────────────────
          Expanded(
            child: asyncItems.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.cyan),
              ),
              error: (e, _) => Center(
                child: Text('Error: $e', style: AppTextStyles.bodyMd),
              ),
              data: (items) => items.isEmpty
                  ? _EmptyState(
                      hasFilter: _selectedType != null ||
                          _selectedStatus != null ||
                          _selectedMinScore != null,
                    )
                  : GridView.builder(
                      padding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 100),
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
                        onTap: () =>
                            context.push('/content/${items[i].id}'),
                      ),
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: _GradientFAB(
        onPressed: () => context.push('/content/new'),
      ),
    );
  }
}

// ── Filter chip ────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: AppColors.gradientH,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label,
              style: AppTextStyles.labelMd.copyWith(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Text(label,
            style: AppTextStyles.labelMd.copyWith(
                color: Theme.of(context).colorScheme.onSurface)),
      ),
    );
  }
}

// ── FAB con gradiente ──────────────────────────────────────────────────────
class _GradientFAB extends StatelessWidget {
  final VoidCallback onPressed;
  const _GradientFAB({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: AppColors.gradientH,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.blue.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  const _EmptyState({this.hasFilter = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(Icons.movie_filter_outlined,
              size: 40,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        Text(
          hasFilter ? 'Sin resultados' : 'Tu biblioteca está vacía',
          style: AppTextStyles.titleMd
              .copyWith(color: Theme.of(context).colorScheme.onSurface),
        ),
        const SizedBox(height: 8),
        Text(
          hasFilter
              ? 'Prueba con otro filtro'
              : 'Pulsa + para añadir tu primer contenido',
          style: AppTextStyles.bodyMd.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ]),
    );
  }
}
