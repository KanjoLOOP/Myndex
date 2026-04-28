import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/content_types.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/external_search_result.dart';
import '../providers/external_search_providers.dart';

/// Bottom sheet de búsqueda externa que consulta TMDB / RAWG / Open
/// Library según el [ContentType] seleccionado.
///
/// Devuelve un [ExternalSearchResult] cuando el usuario selecciona
/// un resultado, o `null` si cierra sin elegir.
///
/// Incluye:
/// - Debounce de 400 ms para no machacar las APIs
/// - Indicador de carga
/// - Manejo de errores amigable
/// - Resultados con portada, título y subtítulo
Future<ExternalSearchResult?> showExternalSearchSheet({
  required BuildContext context,
  required ContentType type,
}) {
  return showModalBottomSheet<ExternalSearchResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).cardTheme.color,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => _ExternalSearchSheet(
        type: type,
        scrollController: scrollController,
      ),
    ),
  );
}

// ─── Sheet body ───────────────────────────────────────────────────

class _ExternalSearchSheet extends ConsumerStatefulWidget {
  final ContentType type;
  final ScrollController scrollController;

  const _ExternalSearchSheet({
    required this.type,
    required this.scrollController,
  });

  @override
  ConsumerState<_ExternalSearchSheet> createState() =>
      _ExternalSearchSheetState();
}

class _ExternalSearchSheetState extends ConsumerState<_ExternalSearchSheet> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  String _lastQuery = '';

  String get _sourceLabel => switch (widget.type) {
        ContentType.movie  => 'TMDB',
        ContentType.series => 'TMDB',
        ContentType.game   => 'RAWG',
        ContentType.book   => 'Open Library',
        _                  => 'API',
      };

  @override
  void dispose() {
    _ctrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String raw) {
    _debounce?.cancel();
    final query = raw.trim();
    if (query == _lastQuery) return;
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _lastQuery = query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Handle ────────────────────────────────────────────
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),

        // ── Header ────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                'Buscar en $_sourceLabel',
                style: AppTextStyles.titleLg,
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Search field ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            controller: _ctrl,
            autofocus: true,
            style: AppTextStyles.bodyLg,
            onChanged: _onQueryChanged,
            decoration: InputDecoration(
              hintText: 'Título de ${widget.type.label.toLowerCase()}...',
              prefixIcon: Icon(
                Icons.search,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
              suffixIcon: _ctrl.text.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _ctrl.clear();
                        _onQueryChanged('');
                      },
                      child: Icon(
                        Icons.clear,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 18,
                      ),
                    )
                  : null,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Results ───────────────────────────────────────────
        Expanded(
          child: _lastQuery.isEmpty
              ? _EmptyHint(sourceLabel: _sourceLabel)
              : _ResultsList(
                  type: widget.type,
                  query: _lastQuery,
                  scrollController: widget.scrollController,
                ),
        ),
      ],
    );
  }
}

// ─── Results list ─────────────────────────────────────────────────

class _ResultsList extends ConsumerWidget {
  final ContentType type;
  final String query;
  final ScrollController scrollController;

  const _ResultsList({
    required this.type,
    required this.query,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncResults = ref.watch(
      externalSearchProvider((type: type, query: query)),
    );

    return asyncResults.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: AppColors.cyan),
        ),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              const Text(
                'No se pudo buscar',
                style: AppTextStyles.titleMd,
              ),
              const SizedBox(height: 8),
              const Text(
                'Comprueba tu conexión a internet',
                style: AppTextStyles.bodyMd,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      data: (results) {
        if (results.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  const Text('Sin resultados', style: AppTextStyles.titleMd),
                  const SizedBox(height: 8),
                  const Text(
                    'Prueba con otro título',
                    style: AppTextStyles.bodyMd,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          itemCount: results.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _ResultTile(
            result: results[i],
            onTap: () => Navigator.pop(context, results[i]),
          ),
        );
      },
    );
  }
}

// ─── Single result tile ───────────────────────────────────────────

class _ResultTile extends StatelessWidget {
  final ExternalSearchResult result;
  final VoidCallback onTap;

  const _ResultTile({required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            // ── Thumbnail ─────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 54,
                height: 76,
                child: result.imageUrl != null && result.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: result.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _ThumbPlaceholder(result.type),
                        errorWidget: (_, __, ___) =>
                            _ThumbPlaceholder(result.type),
                      )
                    : _ThumbPlaceholder(result.type),
              ),
            ),
            const SizedBox(width: 14),

            // ── Info ──────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.title,
                    style: AppTextStyles.bodyLg.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (result.subtitle != null &&
                      result.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      result.subtitle!,
                      style: AppTextStyles.labelMd.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      result.source.toUpperCase(),
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.cyan,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Add icon ──────────────────────────────────────
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.gradientH,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Placeholders ─────────────────────────────────────────────────

class _ThumbPlaceholder extends StatelessWidget {
  final ContentType type;
  const _ThumbPlaceholder(this.type);

  IconData get icon => switch (type) {
        ContentType.movie   => Icons.movie_outlined,
        ContentType.series  => Icons.tv_outlined,
        ContentType.book    => Icons.menu_book_outlined,
        ContentType.game    => Icons.sports_esports_outlined,
        ContentType.anime   => Icons.animation_outlined,
        ContentType.podcast => Icons.podcasts_outlined,
        ContentType.other   => Icons.category_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).cardTheme.color,
      child: Center(child: Icon(icon, size: 22, color: Theme.of(context).colorScheme.onSurfaceVariant)),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String sourceLabel;
  const _EmptyHint({required this.sourceLabel});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (b) => AppColors.gradientH.createShader(
                Rect.fromLTWH(0, 0, b.width, b.height),
              ),
              child: const Icon(Icons.travel_explore, size: 56),
            ),
            const SizedBox(height: 20),
            Text(
              'Busca en $sourceLabel',
              style: AppTextStyles.titleMd,
            ),
            const SizedBox(height: 8),
            const Text(
              'Escribe un título para encontrar portadas,\naños y más información automáticamente',
              style: AppTextStyles.bodyMd,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
