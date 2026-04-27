// Smoke test: la app arranca sin crashear con una DB en memoria.
//
// No usa la DB nativa real (sqlite3.dll) — inyectamos una instancia de
// AppDatabase.forTesting con un NativeDatabase.memory().

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:myndex/core/database/app_database.dart';
import 'package:myndex/core/theme/theme_provider.dart';
import 'package:myndex/main.dart';

void main() {
  testWidgets('MyndexApp boots without crashing', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase.forTesting(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MyndexApp(),
      ),
    );

    // Una pump más para resolver providers async.
    await tester.pump();

    // Si llegamos aquí sin excepciones, la app arrancó.
    expect(tester.takeException(), isNull);

    await db.close();
  });
}
