import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/database/app_database.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Punto de entrada de la app.
///
/// Inicializa Flutter, abre la base de datos local y arranca el
/// árbol de Riverpod sobreescribiendo el [databaseProvider] con la
/// instancia real.
///
/// Las API keys se inyectan en build time vía `--dart-define`:
/// ```bash
/// flutter run --dart-define=TMDB_API_KEY=xxx --dart-define=RAWG_API_KEY=yyy
/// ```
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase();
  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
      child: const MyndexApp(),
    ),
  );
}

/// Widget raíz: configura el [MaterialApp.router] con el tema oscuro
/// y el go_router definido en `core/router/app_router.dart`.
class MyndexApp extends ConsumerWidget {
  const MyndexApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Myndex',
      theme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
