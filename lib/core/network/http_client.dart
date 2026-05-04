import 'package:dio/dio.dart';

import '../constants/app_constants.dart';

class HttpClientFactory {
  static Dio forBaseUrl(String baseUrl) {
    final uri = Uri.parse(baseUrl);
    if (uri.scheme != 'https') {
      throw StateError('HttpClientFactory: solo se permiten URLs HTTPS');
    }

    return Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(milliseconds: AppConstants.httpConnectTimeoutMs),
      receiveTimeout: const Duration(milliseconds: AppConstants.httpReceiveTimeoutMs),
      sendTimeout: const Duration(milliseconds: AppConstants.httpConnectTimeoutMs),
      headers: {
        'Accept': 'application/json',
        'User-Agent': '${AppConstants.appName}/1.0',
      },
      validateStatus: (status) => status != null && status >= 200 && status < 300,
      followRedirects: true,
      maxRedirects: 3,
    ));
  }
}
