import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/pages/home_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/content/presentation/pages/content_detail_page.dart';
import '../../features/content/presentation/pages/content_form_page.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/library',
    routes: [
      ShellRoute(
        builder: (context, state, child) => _ScaffoldWithNav(child: child),
        routes: [
          GoRoute(path: '/library',  builder: (_, __) => const HomePage()),
          GoRoute(path: '/explore',  builder: (_, __) => const SearchPage()),
          GoRoute(path: '/vault',    builder: (_, __) => const _VaultPage()),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
        ],
      ),
      GoRoute(
        path: '/content/:id',
        builder: (context, state) =>
            ContentDetailPage(id: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/content/new',
        builder: (_, __) => const ContentFormPage(),
      ),
      GoRoute(
        path: '/content/:id/edit',
        builder: (context, state) =>
            ContentFormPage(id: int.parse(state.pathParameters['id']!)),
      ),
    ],
  );
});

// ── Placeholder Vault ──────────────────────────────────────────────────────
class _VaultPage extends StatelessWidget {
  const _VaultPage();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.archive_outlined, size: 64, color: AppColors.textDisabled),
          const SizedBox(height: 16),
          Text('Vault', style: AppTextStyles.headlineMd.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text('Próximamente', style: AppTextStyles.bodyMd),
        ]),
      ),
    );
  }
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
      backgroundColor: AppColors.bgPrimary,
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (i) => context.go(_routes[i]),
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          indicatorColor: AppColors.blue.withOpacity(0.2),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.video_library_outlined),
              selectedIcon: Icon(Icons.video_library),
              label: 'Library',
            ),
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: 'Explore',
            ),
            NavigationDestination(
              icon: Icon(Icons.archive_outlined),
              selectedIcon: Icon(Icons.archive),
              label: 'Vault',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
