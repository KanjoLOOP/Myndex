import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/content/presentation/pages/content_detail_page.dart';
import '../../features/content/presentation/pages/content_form_page.dart';
import '../../features/content/presentation/pages/smart_backlog_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/stats/presentation/pages/stats_page.dart';
import '../../features/timeline/presentation/pages/timeline_page.dart';
import '../../features/vault/presentation/pages/collection_detail_page.dart';
import '../../features/vault/presentation/pages/vault_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/library',
    routes: [
      ShellRoute(
        builder: (context, state, child) => _ScaffoldWithNav(child: child),
        routes: [
          GoRoute(path: '/library',  builder: (_, __) => const HomePage()),
          GoRoute(path: '/explore',  builder: (_, __) => const SearchPage()),
          GoRoute(path: '/vault',    builder: (_, __) => const VaultPage()),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
        ],
      ),
      GoRoute(
        path: '/content/new',
        builder: (_, __) => const ContentFormPage(),
      ),
      GoRoute(
        path: '/content/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) return const _NotFoundPage();
          return ContentDetailPage(id: id);
        },
      ),
      GoRoute(
        path: '/content/:id/edit',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) return const _NotFoundPage();
          return ContentFormPage(id: id);
        },
      ),
      GoRoute(
        path: '/vault/collection/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) return const _NotFoundPage();
          return CollectionDetailPage(collectionId: id);
        },
      ),
      GoRoute(
        path: '/stats',
        builder: (_, __) => const StatsPage(),
      ),
      GoRoute(
        path: '/smart-backlog',
        builder: (_, __) => const SmartBacklogPage(),
      ),
      GoRoute(
        path: '/timeline',
        builder: (_, __) => const TimelinePage(),
      ),
    ],
  );
});

// ── 404 ───────────────────────────────────────────────────────────────────
class _NotFoundPage extends StatelessWidget {
  const _NotFoundPage();
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Página no encontrada')),
      );
}

// ── Shell con NavigationBar ────────────────────────────────────────────────
class _ScaffoldWithNav extends StatefulWidget {
  final Widget child;
  const _ScaffoldWithNav({required this.child});

  @override
  State<_ScaffoldWithNav> createState() => _ScaffoldWithNavState();
}

class _ScaffoldWithNavState extends State<_ScaffoldWithNav> {
  static const _routes = ['/library', '/explore', '/vault', '/settings'];

  int _indexFromLocation(String location) {
    if (location.startsWith('/explore'))  return 1;
    if (location.startsWith('/vault'))    return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final selectedIndex = _indexFromLocation(location);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (i) => context.go(_routes[i]),
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          indicatorColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.video_library_outlined),
              selectedIcon: Icon(Icons.video_library),
              label: 'Biblioteca',
            ),
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: 'Explorar',
            ),
            NavigationDestination(
              icon: Icon(Icons.archive_outlined),
              selectedIcon: Icon(Icons.archive),
              label: 'Baúl',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Ajustes',
            ),
          ],
        ),
      ),
    );
  }
}
