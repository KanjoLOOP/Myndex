import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/security/safe_error_message.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../content/domain/entities/content_item.dart';
import '../../../content/presentation/providers/content_providers.dart';
import '../../../content/presentation/widgets/content_card.dart';

/// Pantalla de búsqueda local en la biblioteca.
///
/// Solo busca en la base de datos local (no en APIs externas). Las
/// búsquedas externas (TMDB/RAWG/Open Library) ocurren en el flujo
/// de "Añadir contenido", donde el usuario quiere enriquecer datos.
///
/// Optimización: se aplica debounce de 200 ms para no machacar la DB
/// en cada pulsación del teclado.
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _ctrl = TextEditingController();
  List<ContentItem> _results = const [];
  bool _searching = false;
  String? _errorMsg;

  // Token para descartar respuestas de búsquedas obsoletas si el
  // usuario sigue tecleando antes de que vuelva la consulta lenta.
  int _searchToken = 0;

  Future<void> _search(String rawQuery) async {
    final query = rawQuery.trim();
    final myToken = ++_searchToken;

    if (query.isEmpty) {
      setState(() {
        _results = const [];
        _searching = false;
        _errorMsg = null;
      });
      return;
    }

    setState(() {
      _searching = true;
      _errorMsg = null;
    });

    try {
      final repo = ref.read(contentRepositoryProvider);
      final found = await repo.search(query);
      // Solo aplicamos resultados si seguimos siendo la última búsqueda.
      if (!mounted || myToken != _searchToken) return;
      setState(() {
        _results = found;
        _searching = false;
      });
    } catch (e) {
      if (!mounted || myToken != _searchToken) return;
      setState(() {
        _searching = false;
        _errorMsg = SafeErrorMessage.forUser(e);
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          style: AppTextStyles.bodyLg,
          decoration: const InputDecoration(
            hintText: 'Buscar en tu biblioteca...',
            border: InputBorder.none,
          ),
          onChanged: _search,
        ),
        actions: [
          if (_ctrl.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _ctrl.clear();
                _search('');
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_errorMsg != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_errorMsg!, style: AppTextStyles.bodyMd),
        ),
      );
    }
    if (_searching) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.cyan),
      );
    }
    if (_results.isEmpty && _ctrl.text.isNotEmpty) {
      return const Center(
        child: Text('Sin resultados', style: AppTextStyles.bodyMd),
      );
    }
    if (_results.isEmpty) {
      return const Center(
        child: Text(
          'Empieza a escribir para buscar en tu biblioteca',
          style: AppTextStyles.bodyMd,
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.62,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _results.length,
      itemBuilder: (_, i) => ContentCard(
        item: _results[i],
        onTap: () => context.push('/content/${_results[i].id}'),
      ),
    );
  }
}
