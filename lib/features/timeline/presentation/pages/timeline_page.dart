import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../stats/presentation/providers/stats_providers.dart';

class TimelinePage extends ConsumerWidget {
  const TimelinePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncLog = ref.watch(activityLogProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text('Mi Timeline', style: AppTextStyles.titleLg),
      ),
      body: asyncLog.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.cyan)),
        error: (e, _) =>
            const Center(child: Text('No se pudo cargar el historial')),
        data: (log) {
          if (log.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.timeline_outlined,
                      size: 40,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                Text('Sin actividad todavía',
                    style: AppTextStyles.titleMd.copyWith(
                        color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 8),
                Text('Añade o actualiza contenido para ver tu historial',
                    style: AppTextStyles.bodyMd.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center),
              ]),
            );
          }

          // Group by date
          final grouped = <String, List<dynamic>>{};
          for (final entry in log) {
            final date = (entry.timestamp as DateTime);
            final key =
                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            grouped.putIfAbsent(key, () => []).add(entry);
          }
          final keys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            itemCount: keys.length,
            itemBuilder: (_, i) {
              final dateKey = keys[i];
              final entries = grouped[dateKey]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      _formatDate(dateKey),
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.cyan,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  ...entries.map((e) => _TimelineEntry(entry: e)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(String key) {
    final parts = key.split('-');
    final date = DateTime(
        int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    final now = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(date.year, date.month, date.day))
        .inDays;

    if (diff == 0) return 'HOY';
    if (diff == 1) return 'AYER';
    final months = [
      'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
      'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _TimelineEntry extends StatelessWidget {
  final dynamic entry;
  const _TimelineEntry({required this.entry});

  @override
  Widget build(BuildContext context) {
    final action = entry.action as String;
    final timestamp = entry.timestamp as DateTime;
    final time =
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

    final (icon, label, color) = _actionMeta(action);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Timeline line + dot
        SizedBox(
          width: 32,
          child: Column(children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.5)),
              ),
              child: Icon(icon, size: 14, color: color),
            ),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(children: [
              Expanded(
                child: Text(label,
                    style: AppTextStyles.bodyMd.copyWith(
                        color: Theme.of(context).colorScheme.onSurface)),
              ),
              Text(time,
                  style: AppTextStyles.labelSm.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant)),
            ]),
          ),
        ),
      ]),
    );
  }

  (IconData, String, Color) _actionMeta(String action) => switch (action) {
        'added' => (Icons.add_circle_outline, 'Añadido a la biblioteca', AppColors.cyan),
        'completed' => (Icons.check_circle_outline, '¡Completado!', AppColors.statusCompleted),
        'updated' => (Icons.edit_outlined, 'Actualizado', AppColors.blue),
        'status_changed' => (Icons.swap_horiz_outlined, 'Estado cambiado', AppColors.purple),
        'deleted' => (Icons.delete_outline, 'Eliminado', AppColors.statusDropped),
        _ => (Icons.info_outline, action, AppColors.statusPending),
      };
}
