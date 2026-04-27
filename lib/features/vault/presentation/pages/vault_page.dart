import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/security/input_sanitizer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_text.dart';
import '../../../content/presentation/widgets/content_card.dart';
import '../providers/vault_providers.dart';

class VaultPage extends ConsumerStatefulWidget {
  const VaultPage({super.key});

  @override
  ConsumerState<VaultPage> createState() => _VaultPageState();
}

class _VaultPageState extends ConsumerState<VaultPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        titleSpacing: 20,
        title: GradientText(
          'Baúl',
          style: AppTextStyles.headlineLg.copyWith(fontSize: 26),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.cyan,
          unselectedLabelColor:
              Theme.of(context).colorScheme.onSurfaceVariant,
          indicatorColor: AppColors.cyan,
          labelStyle: AppTextStyles.labelMd
              .copyWith(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Historial'),
            Tab(text: 'Favoritos'),
            Tab(text: 'Colecciones'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _HistorialTab(),
          _FavoritosTab(),
          _ColeccionesTab(),
        ],
      ),
    );
  }
}

// ── Historial (completados) ────────────────────────────────────────────────

class _HistorialTab extends ConsumerWidget {
  const _HistorialTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(completedItemsProvider);
    return async.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.cyan)),
      error: (e, _) => const Center(child: Text('Error al cargar los datos')),
      data: (items) => items.isEmpty
          ? _EmptyVault(
              icon: Icons.history,
              title: 'Sin historial',
              subtitle: 'Marca contenido como Completado para verlo aquí',
            )
          : _ContentGrid(items: items),
    );
  }
}

// ── Favoritos ──────────────────────────────────────────────────────────────

class _FavoritosTab extends ConsumerWidget {
  const _FavoritosTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(favoriteItemsProvider);
    return async.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.cyan)),
      error: (e, _) => const Center(child: Text('Error al cargar los datos')),
      data: (items) => items.isEmpty
          ? _EmptyVault(
              icon: Icons.favorite_border,
              title: 'Sin favoritos',
              subtitle:
                  'Pulsa el corazón en cualquier contenido para guardarlo aquí',
            )
          : _ContentGrid(items: items),
    );
  }
}

// ── Colecciones ────────────────────────────────────────────────────────────

class _ColeccionesTab extends ConsumerStatefulWidget {
  const _ColeccionesTab();

  @override
  ConsumerState<_ColeccionesTab> createState() => _ColeccionesTabState();
}

class _ColeccionesTabState extends ConsumerState<_ColeccionesTab> {
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _showCreateDialog() async {
    _nameCtrl.clear();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Nueva colección',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface)),
        content: TextField(
          controller: _nameCtrl,
          autofocus: true,
          style: AppTextStyles.bodyLg,
          decoration: const InputDecoration(hintText: 'Nombre...'),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar',
                  style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant))),
          TextButton(
              onPressed: () =>
                  Navigator.pop(ctx, _nameCtrl.text.trim()),
              child: const Text('Crear',
                  style: TextStyle(color: AppColors.cyan))),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      try {
        final sanitized = InputSanitizer.sanitizeTitle(name);
        await ref.read(createCollectionProvider)(sanitized);
      } on FormatException {
        // Nombre vacío tras sanitizar — ignorar
      }
    }
  }

  Future<void> _confirmDelete(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Eliminar colección',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface)),
        content: Text(
            'Se elimina la colección, no el contenido dentro de ella.',
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
    if (ok == true) {
      await ref.read(deleteCollectionProvider)(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(collectionsProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: async.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.cyan)),
        error: (e, _) => const Center(child: Text('Error al cargar los datos')),
        data: (collections) => collections.isEmpty
            ? _EmptyVault(
                icon: Icons.collections_bookmark_outlined,
                title: 'Sin colecciones',
                subtitle:
                    'Crea una colección para agrupar tu contenido favorito',
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: collections.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final col = collections[i];
                  return GestureDetector(
                    onTap: () =>
                        context.push('/vault/collection/${col.id}'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Theme.of(context).dividerColor),
                      ),
                      child: Row(children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: AppColors.gradientH,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                              Icons.collections_bookmark_outlined,
                              color: Colors.white,
                              size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(col.name,
                                  style: AppTextStyles.titleMd.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface)),
                              Text('${col.itemCount} items',
                                  style: AppTextStyles.labelSm.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 20,
                              color: Color(0xFFFF6B6B)),
                          onPressed: () => _confirmDelete(col.id!),
                        ),
                      ]),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: GestureDetector(
        onTap: _showCreateDialog,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: AppColors.gradientH,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.blue.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────

class _ContentGrid extends StatelessWidget {
  final List items;
  const _ContentGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.62,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (ctx, i) => ContentCard(
        item: items[i],
        onTap: () => ctx.push('/content/${items[i].id}'),
      ),
    );
  }
}

class _EmptyVault extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyVault(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon,
                size: 40,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          Text(title,
              style: AppTextStyles.titleMd.copyWith(
                  color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text(subtitle,
              style: AppTextStyles.bodyMd.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}
