import 'dart:convert';

/// Helpers genéricos de JSON.
///
/// Para flujos no triviales (export/import del backup, parsing de
/// respuestas de API) prefiere los servicios específicos de cada
/// feature (ver `features/backup/domain/backup_service.dart`).
class JsonUtils {
  /// Serializa con indentación de 2 espacios (legible para humanos).
  static String encode(Object data) =>
      const JsonEncoder.withIndent('  ').convert(data);

  /// Deserializa de forma defensiva: cualquier error se propaga
  /// como [FormatException] para que el llamador decida cómo
  /// tratarlo (NO devuelve null silenciosamente).
  static dynamic decode(String json) => jsonDecode(json);
}
