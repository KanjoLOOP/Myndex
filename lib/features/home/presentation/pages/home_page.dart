import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../content/presentation/providers/content_providers.dart';
import '../../../content/presentation/widgets/content_card.dart';
import '../../../content/domain/entities/content_item.dart';
import '../../../../core/constants/content_types.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(contentListProvider);
    final filter = ref.watch(filterStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Myndex'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: filter.type != null || filter.status != null,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: () => _showFilterSheet(context, ref, filter),
          ),
        ],
      ),
      body: asyncItems.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) => items.isEmpty
            ? _EmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: items.length,
                itemBuilder: (_, i) => ContentCard(
                  item: items[i],
                  onTap: () => context.push('/content/${items[i].id}'),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/content/new'),
        icon: const Icon(Icons.add),
        label: const Text('Añadir'),
      ),
    );
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref, FilterState current) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _FilterSheet(current: current, ref: ref),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.movie_outlined, size: 64,
              color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text('Nada por aquí todavía',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text('Añade tu primer contenido con el botón +'),
        ],
      ),
    );
  }
}

class _FilterSheet extends ConsumerWidget {
  final FilterState current;
  final WidgetRef ref;
  const _FilterSheet({required this.current, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef _) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filtros', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Text('Tipo', style: Theme.of(context).textTheme.labelLarge),
          Wrap(
            spacing: 8,
            children: ContentType.values.map((t) {
              final selected = current.type == t;
              return FilterChip(
                label: Text(t.label),
                selected: selected,
                onSelected: (v) {
                  ref.read(filterStateProvider.notifier).update(
                      (s) => s.copyWith(type: t, clearType: !v));
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text('Estado', style: Theme.of(context).textTheme.labelLarge),
          Wrap(
            spacing: 8,
            children: ContentStatus.values.map((s) {
              final selected = current.status == s;
              return FilterChip(
                label: Text(s.label),
                selected: selected,
                onSelected: (v) {
                  ref.read(filterStateProvider.notifier).update(
                      (st) => st.copyWith(status: s, clearStatus: !v));
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              ref.read(filterStateProvider.notifier).state = const FilterState();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.clear_all),
            label: const Text('Limpiar filtros'),
          ),
        ],
      ),
    );
  }
}
