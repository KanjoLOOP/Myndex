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
  ContentType? _selectedType;

  static const _typeFilters = [
    (label: 'All',     type: null as ContentType?),
    (label: 'Movies',  type: ContentType.movie),
    (label: 'Series',  type: ContentType.series),
    (label: 'Books',   type: ContentType.book),
    (label: 'Games',   type: ContentType.game),
    (label: 'Anime',   type: ContentType.anime),
  ];

  @override
  Widget build(BuildContext context) {
    // Aplicar filtro de tipo
    final filter = ref.watch(filterStateProvider);
    final asyncItems = ref.watch(contentListProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        titleSpacing: 20,
        title: GradientText(
          'Myndex',
          style: AppTextStyles.headlineLg.copyWith(fontSize: 26),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textSecondary),
            onPressed: () => context.go('/explore'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Filtros de tipo (scrollable chips) ──────────────────────────
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _typeFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = _typeFilters[i];
                final selected = _selectedType == f.type;
                return _FilterChip(
                  label: f.label,
                  selected: selected,
                  onTap: () {
                    setState(() => _selectedType = f.type);
                    ref.read(filterStateProvider.notifier).update(
                          (s) => s.copyWith(
                            type: f.type,
                            clearType: f.type == null,
                          ),
                        );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // ── Lista de contenido ──────────────────────────────────────────
          Expanded(
            child: asyncItems.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.cyan),
              ),
              error: (e, _) => Center(
                child: Text('Error: $e', style: AppTextStyles.bodyMd),
              ),
              data: (items) => items.isEmpty
                  ? _EmptyState(hasFilter: _selectedType != null)
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(label, style: AppTextStyles.labelMd),
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
        width: 60, height: 60,
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
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.movie_filter_outlined, size: 40, color: AppColors.textDisabled),
        ),
        const SizedBox(height: 20),
        Text(
          hasFilter ? 'Sin resultados' : 'Tu biblioteca está vacía',
          style: AppTextStyles.titleMd,
        ),
        const SizedBox(height: 8),
        Text(
          hasFilter
              ? 'Prueba con otro filtro'
              : 'Pulsa + para añadir tu primer contenido',
          style: AppTextStyles.bodyMd,
          textAlign: TextAlign.center,
        ),
      ]),
    );
  }
}
