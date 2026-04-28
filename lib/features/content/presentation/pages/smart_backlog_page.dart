import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/content_types.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../content/domain/entities/content_item.dart';
import '../../../content/presentation/providers/content_providers.dart';
import '../../../content/presentation/widgets/content_card.dart';

class SmartBacklogPage extends ConsumerStatefulWidget {
  const SmartBacklogPage({super.key});

  @override
  ConsumerState<SmartBacklogPage> createState() => _SmartBacklogPageState();
}

class _SmartBacklogPageState extends ConsumerState<SmartBacklogPage> {
  int _freeMinutes = 120;
  ContentType? _filterType;

  static const _presets = [
    (label: '30 min', minutes: 30),
    (label: '1 hora', minutes: 60),
    (label: '2 horas', minutes: 120),
    (label: '3 horas', minutes: 180),
    (label: 'Todo el día', minutes: 480),
  ];

  @override
  Widget build(BuildContext context) {
    final asyncItems = ref.watch(contentListProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: const Text('Smart Backlog', style: AppTextStyles.titleLg),
      ),
      body: asyncItems.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.cyan)),
        error: (e, _) => const Center(child: Text('Error al cargar')),
        data: (items) {
          final suggestions = _getSuggestions(items);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Free time selector
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('¿Cuánto tiempo libre tienes?',
                        style: AppTextStyles.titleMd.copyWith(
                            color: Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _presets.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final p = _presets[i];
                          final selected = _freeMinutes == p.minutes;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _freeMinutes = p.minutes),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                gradient:
                                    selected ? AppColors.gradientH : null,
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
                                p.label,
                                style: AppTextStyles.labelMd.copyWith(
                                  color: selected
                                      ? Colors.white
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Type filter chips
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _TypeChip(
                            label: 'Todos',
                            selected: _filterType == null,
                            onTap: () =>
                                setState(() => _filterType = null),
                          ),
                          ...ContentType.values.map((t) => _TypeChip(
                                label: t.label,
                                selected: _filterType == t,
                                onTap: () =>
                                    setState(() => _filterType = t),
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),

              // Results
              if (suggestions.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.hourglass_empty_outlined,
                              size: 48,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                          const SizedBox(height: 16),
                          Text(
                            'No hay contenido que encaje en\n${_formatTime(_freeMinutes)}',
                            style: AppTextStyles.bodyMd.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                        ]),
                  ),
                )
              else
                Expanded(
                  child: GridView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.62,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: suggestions.length,
                    itemBuilder: (_, i) => ContentCard(
                      item: suggestions[i],
                      onTap: () =>
                          context.push('/content/${suggestions[i].id}'),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  List<ContentItem> _getSuggestions(List<ContentItem> items) {
    return items.where((item) {
      // Only pending or in-progress items
      if (item.status == ContentStatus.completed ||
          item.status == ContentStatus.dropped) {
        return false;
      }
      // Type filter
      if (_filterType != null && item.type != _filterType) return false;
      // Duration filter: if item has estimated duration, use it
      if (item.estimatedDurationMinutes != null) {
        return item.estimatedDurationMinutes! <= _freeMinutes;
      }
      // Fallback: estimate by type
      final est = _defaultDuration(item.type);
      return est <= _freeMinutes;
    }).toList();
  }

  int _defaultDuration(ContentType type) => switch (type) {
        ContentType.movie => 110,
        ContentType.series => 45,
        ContentType.anime => 24,
        ContentType.book => 240,
        ContentType.game => 360,
        ContentType.podcast => 45,
        ContentType.other => 60,
      };

  String _formatTime(int minutes) {
    if (minutes < 60) return '$minutes minutos';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h h' : '$h h $m min';
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TypeChip(
      {required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.cyan
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMd.copyWith(
            color: selected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
            fontWeight:
                selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
