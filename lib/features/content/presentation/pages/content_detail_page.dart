import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/content_providers.dart';

class ContentDetailPage extends ConsumerWidget {
  final int id;
  const ContentDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItem = ref.watch(contentItemProvider(id));
    return asyncItem.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (item) {
        if (item == null) return const Scaffold(body: Center(child: Text('No encontrado')));
        return Scaffold(
          appBar: AppBar(
            title: Text(item.title),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.push('/content/${item.id}/edit'),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Eliminar'),
                      content: Text('¿Eliminar "${item.title}"?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    await ref.read(deleteContentProvider).call(id);
                    ref.invalidate(contentListProvider);
                    context.pop();
                  }
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(item.imageUrl!, height: 220, fit: BoxFit.cover),
                ),
              const SizedBox(height: 16),
              _Row('Tipo', item.type.label),
              _Row('Estado', item.status.label),
              if (item.score != null) _Row('Puntuación', '${item.score} / 10'),
              if (item.notes != null && item.notes!.isNotEmpty) ...[
                const Divider(height: 32),
                Text('Notas', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Text(item.notes!),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text('$label: ', style: Theme.of(context).textTheme.labelLarge),
          Text(value),
        ],
      ),
    );
  }
}
