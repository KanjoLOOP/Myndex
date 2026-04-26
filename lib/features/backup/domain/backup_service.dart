import 'dart:convert';
import 'dart:io';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failures.dart';
import '../../content/domain/repositories/content_repository.dart';

/// Servicio de export/import del backup en JSON.
///
/// Diseño:
/// - Esquema versionado (`schemaVersion`) para poder migrar formatos
///   en futuras releases sin romper backups antiguos.
/// - El export solo escribe en directorio privado de la app; luego
///   la UI usa share_plus para que el usuario decida dónde mandarlo.
/// - El import valida tamaño máximo, valida el schemaVersion y
///   delega la deduplicación al repositorio.
///
/// Mantenido aislado de la UI a propósito: así se puede testear sin
/// instanciar Flutter.
class BackupService {
  final ContentRepository _repo;

  BackupService(this._repo);

  // ─── Export ─────────────────────────────────────────────────────

  /// Genera el JSON completo del backup como string.
  /// Útil para tests o para enviar el contenido por otra vía.
  Future<String> exportToString() async {
    final items = await _repo.exportAll();
    final payload = {
      'app': AppConstants.appName,
      'schemaVersion': AppConstants.exportSchemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'count': items.length,
      'items': items,
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Escribe el backup en un fichero del directorio que se pasa.
  ///
  /// El llamador es responsable de pasar `path_provider`'s
  /// `getApplicationDocumentsDirectory()` (no lo hacemos aquí para
  /// no acoplar este servicio a Flutter, que facilita tests).
  ///
  /// Devuelve la ruta absoluta del fichero generado.
  Future<String> exportToFile(Directory targetDir) async {
    try {
      final json = await exportToString();
      final file = File('${targetDir.path}/${AppConstants.exportFileName}');
      // writeAsString sobreescribe el fichero existente, comportamiento
      // intencional: solo guardamos el último backup local.
      await file.writeAsString(json, flush: true);
      return file.path;
    } on FileSystemException {
      throw const ExportFailure('No se pudo escribir el fichero de backup.');
    }
  }

  // ─── Import ─────────────────────────────────────────────────────

  /// Importa un fichero JSON desde la ruta indicada.
  ///
  /// - Rechaza ficheros más grandes que [AppConstants.maxImportFileSizeBytes].
  /// - Rechaza JSON con `schemaVersion` superior al soportado.
  /// - Devuelve el número de items realmente importados (sin
  ///   duplicados si `skipDuplicates`).
  Future<int> importFromFile(
    String path, {
    bool skipDuplicates = true,
  }) async {
    final file = File(path);
    if (!await file.exists()) {
      throw const ImportFailure('El fichero no existe.');
    }
    final size = await file.length();
    if (size > AppConstants.maxImportFileSizeBytes) {
      throw const ImportFailure('El fichero supera el tamaño máximo permitido.');
    }

    final content = await file.readAsString();
    return importFromString(content, skipDuplicates: skipDuplicates);
  }

  /// Importa desde una cadena JSON ya cargada en memoria.
  ///
  /// Capa intermedia útil para tests y para flujos donde el contenido
  /// viene de un origen distinto a un fichero (clipboard, push…).
  Future<int> importFromString(
    String raw, {
    bool skipDuplicates = true,
  }) async {
    if (raw.length > AppConstants.maxImportFileSizeBytes) {
      throw const ImportFailure('Datos demasiado grandes.');
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw const ImportFailure('JSON con formato inválido.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const ImportFailure('Estructura JSON inesperada.');
    }

    final version = decoded['schemaVersion'];
    if (version is! int) {
      throw const ImportFailure('Falta el campo schemaVersion.');
    }
    if (version > AppConstants.exportSchemaVersion) {
      throw ImportFailure(
        'Backup más reciente (v$version) que esta versión de la app.',
      );
    }

    final items = decoded['items'];
    if (items is! List) {
      throw const ImportFailure('El backup no contiene una lista de items.');
    }

    final mapped = items
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    return _repo.importAll(mapped, skipDuplicates: skipDuplicates);
  }
}
