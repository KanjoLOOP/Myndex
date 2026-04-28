import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:sqlite3/open.dart';

/// Configuración global de la suite de tests.
///
/// Drift usa `NativeDatabase.memory()` que requiere `sqlite3` nativa.
/// En tests Dart VM (sin Flutter engine) `sqlite3_flutter_libs` NO carga
/// automáticamente, así que tenemos que apuntar a la DLL/so/dylib correcto.
///
/// Estrategia (no requiere copiar manualmente la DLL):
///   • Windows: busca la DLL en orden:
///       1. `sqlite3.dll` en cwd o PATH (si el usuario la tiene).
///       2. `build/windows/x64/runner/Debug/sqlite3.dll`
///          (la deja `flutter build windows --debug`).
///       3. `.dart_tool/sqlite3/sqlite3.dll` (cache local creada por este
///          mismo script la primera vez que falla).
///       4. Si nada funciona, descarga la versión oficial 3.46.1 desde
///          sqlite.org y la cachea en `.dart_tool/sqlite3/`.
///   • Linux:   `libsqlite3.so` o `libsqlite3.so.0`.
///   • macOS:   Drift se apaña con la del sistema.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  if (Platform.isWindows) {
    open.overrideFor(OperatingSystem.windows, _resolveWindows);
  } else if (Platform.isLinux) {
    open.overrideFor(OperatingSystem.linux, _resolveLinux);
  }
  await testMain();
}

DynamicLibrary _resolveWindows() {
  // Lista de candidatos en orden de preferencia.
  const candidates = <String>[
    'sqlite3.dll',
    'build/windows/x64/runner/Debug/sqlite3.dll',
    'build/windows/runner/Debug/sqlite3.dll',
    '.dart_tool/sqlite3/sqlite3.dll',
  ];
  for (final path in candidates) {
    final f = File(path);
    if (f.existsSync()) {
      try {
        return DynamicLibrary.open(f.absolute.path);
      } catch (_) {/* prueba el siguiente */}
    }
    // Para `sqlite3.dll` a secas también probamos resolver via PATH.
    if (path == 'sqlite3.dll') {
      try {
        return DynamicLibrary.open('sqlite3.dll');
      } catch (_) {/* prueba el siguiente */}
    }
  }
  // Último recurso: descargar y cachear la DLL oficial.
  final cached = _downloadOfficialSqliteDll();
  return DynamicLibrary.open(cached.absolute.path);
}

DynamicLibrary _resolveLinux() {
  try {
    return DynamicLibrary.open('libsqlite3.so');
  } catch (_) {
    return DynamicLibrary.open('libsqlite3.so.0');
  }
}

/// Descarga `sqlite3.dll` x64 oficial y la deja en `.dart_tool/sqlite3/`.
/// Se ejecuta como mucho una vez por workspace.
File _downloadOfficialSqliteDll() {
  final cacheDir = Directory('.dart_tool/sqlite3')..createSync(recursive: true);
  final dll = File('${cacheDir.path}/sqlite3.dll');
  if (dll.existsSync()) return dll;

  // SQLite official precompiled x64 DLL (year=2024 build).
  // Si quieres fijar versión, sustituye por la URL versionada.
  const url =
      'https://sqlite.org/2024/sqlite-dll-win-x64-3460100.zip';
  // ignore: avoid_print
  print('[test config] Descargando sqlite3.dll desde $url ...');
  final zipPath = '${cacheDir.path}/sqlite3.zip';

  final ps = Process.runSync(
    'powershell',
    [
      '-NoProfile',
      '-Command',
      'Invoke-WebRequest -Uri "$url" -OutFile "$zipPath"; '
          'Expand-Archive -Path "$zipPath" -DestinationPath "${cacheDir.path}" -Force; '
          'Remove-Item "$zipPath" -Force',
    ],
    runInShell: true,
  );
  if (ps.exitCode != 0 || !dll.existsSync()) {
    throw StateError(
      'No se pudo descargar sqlite3.dll automáticamente.\n'
      'stdout: ${ps.stdout}\nstderr: ${ps.stderr}\n'
      'Solución manual: descarga la DLL desde https://www.sqlite.org/download.html '
      '(sqlite-dll-win-x64) y colócala en la raíz del proyecto.',
    );
  }
  return dll;
}
