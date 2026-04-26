import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../content/presentation/providers/content_providers.dart';
import '../../../content/presentation/widgets/content_card.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _ctrl = TextEditingController();
  List results = [];
  bool _searching = false;

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => results = []);
      return;
    }
    setState(() => _searching = true);
    final repo = ref.read(contentRepositoryProvider);
    final found = await repo.search(query.trim());
    setState(() { results = found; _searching = false; });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Buscar en tu biblioteca...',
            border: InputBorder.none,
          ),
          onChanged: _search,
        ),
        actions: [
          if (_ctrl.text.isNotEmpty)
            IconButton(icon: const Icon(Icons.clear), onPressed: () {
              _ctrl.clear();
              setState(() => results = []);
            }),
        ],
      ),
      body: _searching
          ? const Center(child: CircularProgressIndicator())
          : results.isEmpty && _ctrl.text.isNotEmpty
              ? const Center(child: Text('Sin resultados'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: results.length,
                  itemBuilder: (_, i) => ContentCard(
                    item: results[i],
                    onTap: () => context.push('/content/${results[i].id}'),
                  ),
                ),
    );
  }
}
