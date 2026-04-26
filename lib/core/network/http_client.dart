import 'package:dio/dio.dart';

import '../constants/app_constants.dart';

/// Fábrica de clientes HTTP.
///
/// Centraliza la configuración de Dio para todas las APIs externas.
/// Aplica timeouts razonables, fuerza HTTPS, y desactiva el log
/// detallado en release para no filtrar URLs/headers en logs del
/// dispositivo.
///
/// Cada datasource (TMDB, RAWG, Open Library) recibe una instancia
/// independiente vía [forBaseUrl]; así un fallo en un proveedor no
/// arrastra a los demás (interceptors, cookies, etc.).
class HttpClientFactory {
  /// Construye un Dio listo para usar contra [baseUrl].
  ///
  /// - Solo permite https (rechaza http en runtime).
  /// - Timeouts duros para evitar UX colgada.
  /// - User-Agent identificable para que las APIs no bloqueen por
  ///   defecto.
  static Dio forBaseUrl(String baseUrl) {
    final uri = Uri.parse(baseUrl);
    if (uri.scheme != 'https') {
      throw StateError(
        'HttpClientFactory rechaza esquemas no-HTTPS: $baseUrl',
      );
    }

    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(
        milliseconds: AppConstants.httpConnectTimeoutMs,
      ),
      receiveTimeout: const Duration(
        milliseconds: AppConstants.httpReceiveTimeoutMs,
      ),
      sendTimeout: const Duration(
        milliseconds: AppConstants.httpConnectTimeoutMs,
      ),
      headers: {
        'Accept': 'application/json',
        'User-Agent': '${AppConstants.appName}/1.0 (offline-first)',
      },
      // Permitimos solo respuestas 2xx; cualquier otra dispara
      // DioException, que SafeErrorMessage traduce de forma genérica.
      validateStatus: (status) => status != null && status >= 200 && status < 300,
      // Importante: no enviar cookies de sesión a APIs externas
      // (no tenemos sesión propia, es solo enriquecimiento).
      followRedirects: true,
      maxRedirects: 3,
    ));

    return dio;
  }
}
