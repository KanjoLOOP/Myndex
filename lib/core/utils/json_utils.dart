import 'dart:convert';

class JsonUtils {
  static String encode(Object data) =>
      const JsonEncoder.withIndent('  ').convert(data);

  static dynamic decode(String json) => jsonDecode(json);
}
