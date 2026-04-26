import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/presentation/providers/content_providers.dart';
import '../../domain/backup_service.dart';

/// Provider del servicio de backup. Reusa el repositorio de contenido.
final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(ref.watch(contentRepositoryProvider)),
);
