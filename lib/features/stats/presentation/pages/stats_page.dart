import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/content_types.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/library_stats.dart';
import '../providers/stats_providers.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(libraryStatsProvider);
    final activityAsync = ref.watch(activityLogProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: const Text('Estadísticas', style: AppTextStyles.titleLg),
        actions: [
          IconButton(
            icon: const Icon(Icons.timeline_outlined),
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            tooltip: 'Mi Timeline',
            onPressed: () => context.push('/timeline'),
          ),
          IconButton(
            icon: const Icon(Icons.watch_later_outlined),
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            tooltip: 'Smart Backlog',
            onPressed: () => context.push('/smart-backlog'),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.cyan)),
        error: (e, _) => const Center(child: Text('No se pudieron cargar las estadísticas')),
        data: (stats) => stats.total == 0
            ? _EmptyStats()
            : _StatsBody(
                stats: stats,
                activityLog: activityAsync.valueOrNull ?? [],
              ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────

class _EmptyStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(Icons.bar_chart_outlined, size: 40,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        Text('Sin datos todavía',
            style: AppTextStyles.titleMd
                .copyWith(color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 8),
        Text('Añade contenido a tu biblioteca para ver estadísticas',
            style: AppTextStyles.bodyMd.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center),
      ]),
    );
  }
}

// ── Main body ──────────────────────────────────────────────────────────────

class _StatsBody extends StatelessWidget {
  final LibraryStats stats;
  final List<dynamic> activityLog;
  const _StatsBody({required this.stats, required this.activityLog});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      children: [
        // ── Hero metrics ─────────────────────────────────────────────
        Row(children: [
          Expanded(
              child: _HeroCard(
                  label: 'Total',
                  value: '${stats.total}',
                  icon: Icons.video_library_outlined)),
          const SizedBox(width: 12),
          Expanded(
              child: _HeroCard(
                  label: 'Completados',
                  value: '${stats.completed}',
                  icon: Icons.check_circle_outline,
                  color: AppColors.statusCompleted)),
          const SizedBox(width: 12),
          Expanded(
              child: _HeroCard(
                  label: 'Favoritos',
                  value: '${stats.favorites}',
                  icon: Icons.favorite_outline,
                  color: const Color(0xFFFF6B6B))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: _HeroCard(
                  label: 'En curso',
                  value: '${stats.inProgress}',
                  icon: Icons.play_circle_outline,
                  color: AppColors.statusInProgress)),
          const SizedBox(width: 12),
          Expanded(
              child: _HeroCard(
                  label: 'Pendiente',
                  value: '${stats.pending}',
                  icon: Icons.schedule_outlined,
                  color: AppColors.statusPending)),
          const SizedBox(width: 12),
          Expanded(
              child: _HeroCard(
                  label: 'Abandonado',
                  value: '${stats.dropped}',
                  icon: Icons.cancel_outlined,
                  color: AppColors.statusDropped)),
        ]),

        const SizedBox(height: 24),
        
        // ── Actividad reciente ─────────────────────────────────────────
        if (activityLog.isNotEmpty) ...[
          const _SectionTitle('Actividad Reciente (7 días)'),
          const SizedBox(height: 12),
          _ActivityChart(activityLog: activityLog),
          const SizedBox(height: 24),
        ],

        // ── Score medio ───────────────────────────────────────────────
        if (stats.averageScore != null) ...[
          const _SectionTitle('Puntuación media'),
          const SizedBox(height: 12),
          _ScoreCard(score: stats.averageScore!, total: stats.total),
          const SizedBox(height: 24),
        ],

        // ── Por tipo ──────────────────────────────────────────────────
        const _SectionTitle('Por tipo'),
        const SizedBox(height: 12),
        _TypeBars(byType: stats.byType, total: stats.total),
        const SizedBox(height: 24),

        // ── Por estado ────────────────────────────────────────────────
        const _SectionTitle('Por estado'),
        const SizedBox(height: 12),
        _StatusBars(byStatus: stats.byStatus, total: stats.total),
        const SizedBox(height: 24),

        // ── Top valorados ─────────────────────────────────────────────
        if (stats.topRated.isNotEmpty) ...[
          const _SectionTitle('Top valorados'),
          const SizedBox(height: 12),
          ...stats.topRated.asMap().entries.map((e) => _TopRatedTile(
                rank: e.key + 1,
                item: e.value,
              )),
        ],
      ],
    );
  }
}

// ── Hero card ──────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _HeroCard(
      {required this.label,
      required this.value,
      required this.icon,
      this.color = AppColors.cyan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 8),
        Text(value,
            style: AppTextStyles.headlineMd
                .copyWith(color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 2),
        Text(label,
            style: AppTextStyles.labelSm.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ]),
    );
  }
}

// ── Score card ─────────────────────────────────────────────────────────────

class _ScoreCard extends StatelessWidget {
  final double score; // 0–10
  final int total;
  const _ScoreCard({required this.score, required this.total});

  @override
  Widget build(BuildContext context) {
    final stars = score / 2; // 0–5
    final fullStars = stars.floor();
    final hasHalf = (stars - fullStars) >= 0.5;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(children: [
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (b) =>
              AppColors.gradientH.createShader(Rect.fromLTWH(0, 0, b.width, b.height)),
          child: Text(
            score.toStringAsFixed(1),
            style: AppTextStyles.headlineLg.copyWith(fontSize: 40),
          ),
        ),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            ...List.generate(5, (i) {
              if (i < fullStars) {
                return const Icon(Icons.star_rounded,
                    color: AppColors.cyan, size: 22);
              } else if (i == fullStars && hasHalf) {
                return const Icon(Icons.star_half_rounded,
                    color: AppColors.cyan, size: 22);
              } else {
                return Icon(Icons.star_outline_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 22);
              }
            }),
          ]),
          const SizedBox(height: 4),
          Text('sobre 10 · $total ítems',
              style: AppTextStyles.labelSm.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ]),
      ]),
    );
  }
}

// ── Type bars ──────────────────────────────────────────────────────────────

class _TypeBars extends StatelessWidget {
  final Map<ContentType, int> byType;
  final int total;
  const _TypeBars({required this.byType, required this.total});

  static const _typeColors = {
    ContentType.movie:   AppColors.cyan,
    ContentType.series:  AppColors.blue,
    ContentType.book:    AppColors.purple,
    ContentType.game:    AppColors.magenta,
    ContentType.anime:   Color(0xFFF59E0B),
    ContentType.podcast: Color(0xFF10B981),
    ContentType.other:   AppColors.statusDropped,
  };

  @override
  Widget build(BuildContext context) {
    final entries = byType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: entries.map((e) {
          final color = _typeColors[e.key] ?? AppColors.cyan;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _HBar(
              label: e.key.label,
              count: e.value,
              total: total,
              color: color,
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Status bars ────────────────────────────────────────────────────────────

class _StatusBars extends StatelessWidget {
  final Map<ContentStatus, int> byStatus;
  final int total;
  const _StatusBars({required this.byStatus, required this.total});

  static const _statusLabels = {
    ContentStatus.pending:    'Pendiente',
    ContentStatus.inProgress: 'En curso',
    ContentStatus.completed:  'Completado',
    ContentStatus.dropped:    'Abandonado',
  };

  @override
  Widget build(BuildContext context) {
    final entries = byStatus.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: entries.map((e) {
          // Usamos .color de la extensión en lugar de un mapa local duplicado
          final color = e.key.color;
          final label = _statusLabels[e.key] ?? e.key.name;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _HBar(
              label: label,
              count: e.value,
              total: total,
              color: color,
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Horizontal bar ─────────────────────────────────────────────────────────

class _HBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  const _HBar(
      {required this.label,
      required this.count,
      required this.total,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : count / total;
    final pct = (ratio * 100).round();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
          child: Text(label,
              style: AppTextStyles.bodyMd
                  .copyWith(color: Theme.of(context).colorScheme.onSurface)),
        ),
        Text('$count  ($pct%)',
            style: AppTextStyles.labelSm.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ]),
      const SizedBox(height: 6),
      LayoutBuilder(builder: (_, constraints) {
        return Stack(children: [
          Container(
            height: 8,
            width: constraints.maxWidth,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            height: 8,
            width: constraints.maxWidth * ratio,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ]);
      }),
    ]);
  }
}

// ── Top rated tile ─────────────────────────────────────────────────────────

class _TopRatedTile extends StatelessWidget {
  final int rank;
  final dynamic item; // ContentItem

  const _TopRatedTile({required this.rank, required this.item});

  @override
  Widget build(BuildContext context) {
    final stars = (item.score / 2).round();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(children: [
        // Rank badge
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            gradient: rank == 1 ? AppColors.gradientH : null,
            color: rank == 1
                ? null
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '$rank',
              style: AppTextStyles.labelMd.copyWith(
                color: rank == 1
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Title + type
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.title,
                style: AppTextStyles.bodyMd.copyWith(
                    color: Theme.of(context).colorScheme.onSurface),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(item.type.label,
                style: AppTextStyles.labelSm.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ]),
        ),
        // Stars
        Row(mainAxisSize: MainAxisSize.min, children: [
          ...List.generate(5, (i) => Icon(
                i < stars
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                size: 14,
                color: i < stars
                    ? AppColors.cyan
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              )),
        ]),
      ]),
    );
  }
}

// ── Section title ──────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.labelMd.copyWith(
        letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

// ── Activity Chart (fl_chart) ───────────────────────────────────────────────

class _ActivityChart extends StatelessWidget {
  final List<dynamic> activityLog;
  const _ActivityChart({required this.activityLog});

  @override
  Widget build(BuildContext context) {
    // Group activity by day for the last 7 days
    final now = DateTime.now();
    final counts = List.filled(7, 0);
    
    for (final log in activityLog) {
      final timestamp = log.timestamp as DateTime;
      final diff = now.difference(timestamp).inDays;
      if (diff >= 0 && diff < 7) {
        counts[6 - diff]++;
      }
    }

    final maxY = counts.isEmpty ? 1.0 : counts.reduce((a, b) => a > b ? a : b).toDouble();
    final actualMaxY = maxY < 5 ? 5.0 : maxY;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: actualMaxY,
          minY: 0,
          barTouchData: const BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final daysAgo = 6 - value.toInt();
                  final date = now.subtract(Duration(days: daysAgo));
                  final dayStr = ['L', 'M', 'X', 'J', 'V', 'S', 'D'][date.weekday - 1];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      dayStr,
                      style: AppTextStyles.labelSm.copyWith(
                        color: value.toInt() == 6 ? AppColors.cyan : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: value.toInt() == 6 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(7, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: counts[i].toDouble(),
                  gradient: AppColors.gradientH,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
