/// Convierte excepciones en mensajes seguros para el usuario.
///
/// Motivación de seguridad: los mensajes crudos de [Exception] o
/// [DioException] pueden contener rutas absolutas del filesystem,
/// stacktraces, headers, hosts internos, o partes de la query SQL.
/// Esa información no debe llegar nunca a un SnackBar/Dialog en
/// producción porque ayuda a un atacante a perfilar la app.
///
/// Reglas de uso:
/// - En la UI, mostrar siempre [SafeErrorMessage.forUser].
/// - En logs internos (consola, Crashlytics) sí se puede registrar el
///   error original a través de [SafeErrorMessage.forLog].
library;

import 'package:dio/dio.dart';

import '../errors/failures.dart';

class SafeErrorMessage {
  /// Mensaje genérico apto para mostrar al usuario final.
  static String forUser(Object error) {
    if (error is Failure) {
      return error.message;
    }
    if (error is DioException) {
      return _mapDioException(error);
    }
    if (error is FormatException) {
      return 'Formato de datos no válido.';
    }
    if (error is StateError) {
      // No reveles el contenido interno del StateError (puede incluir
      // nombres de variables de entorno o claves).
      return 'La acción no está disponible en este momento.';
    }
    return 'Ha ocurrido un error inesperado.';
  }

  /// Mensaje detallado para logs internos. NO mostrar al usuario.
  static String forLog(Object error, [StackTrace? stack]) {
    final base = error.toString();
    if (stack == null) return base;
    return '$base\n$stack';
  }

  static String _mapDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Tiempo de espera agotado. Comprueba tu conexión.';
      case DioExceptionType.connectionError:
        return 'No se pudo conectar al servicio.';
      case DioExceptionType.badCertificate:
        return 'Certificado del servidor no válido.';
      case DioExceptionType.cancel:
        return 'Petición cancelada.';
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode ?? 0;
        if (status == 401 || status == 403) {
          return 'API key no válida o sin permisos.';
        }
        if (status == 429) {
          return 'Demasiadas peticiones, espera un momento.';
        }
        if (status >= 500) {
          return 'El servicio está fallando. Inténtalo más tarde.';
        }
        return 'Respuesta no válida del servicio.';
      case DioExceptionType.unknown:
        return 'Error de red.';
    }
  }
}
