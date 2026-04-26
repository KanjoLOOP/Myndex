import 'package:intl/intl.dart';

class AppDateUtils {
  static final _formatter = DateFormat('dd/MM/yyyy');

  static String format(DateTime date) => _formatter.format(date);
  static String formatRelative(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'Hoy';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    return format(date);
  }
}
