import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Radar chart for multidimensional ratings.
/// [dimensions] is a Map<String, double> where values are 0.0–10.0.
class RadarRatingChart extends StatelessWidget {
  final Map<String, double> dimensions;
  const RadarRatingChart({super.key, required this.dimensions});

  @override
  Widget build(BuildContext context) {
    if (dimensions.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Valoración detallada',
              style: AppTextStyles.titleMd
                  .copyWith(color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: CustomPaint(
              painter: _RadarPainter(
                dimensions: dimensions,
                fillColor: AppColors.cyan.withOpacity(0.25),
                strokeColor: AppColors.cyan,
                gridColor: Theme.of(context).dividerColor,
                labelColor: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 12),
          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: dimensions.entries.map((e) {
              return Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: AppColors.cyan, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(
                  '${e.key}: ${e.value.toStringAsFixed(1)}',
                  style: AppTextStyles.labelSm.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ]);
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final Map<String, double> dimensions;
  final Color fillColor;
  final Color strokeColor;
  final Color gridColor;
  final Color labelColor;

  _RadarPainter({
    required this.dimensions,
    required this.fillColor,
    required this.strokeColor,
    required this.gridColor,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = min(size.width, size.height) / 2 - 28;
    final labels = dimensions.keys.toList();
    final values = dimensions.values.toList();
    final n = labels.length;
    if (n < 3) return;

    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw grid rings (3 levels)
    for (int ring = 1; ring <= 3; ring++) {
      final r = maxRadius * ring / 3;
      final path = Path();
      for (int i = 0; i < n; i++) {
        final angle = (2 * pi * i / n) - pi / 2;
        final x = center.dx + r * cos(angle);
        final y = center.dy + r * sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Draw axes
    for (int i = 0; i < n; i++) {
      final angle = (2 * pi * i / n) - pi / 2;
      final x = center.dx + maxRadius * cos(angle);
      final y = center.dy + maxRadius * sin(angle);
      canvas.drawLine(center, Offset(x, y), gridPaint);
    }

    // Draw data polygon
    final dataPath = Path();
    for (int i = 0; i < n; i++) {
      final angle = (2 * pi * i / n) - pi / 2;
      final r = maxRadius * (values[i] / 10.0).clamp(0.0, 1.0);
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      if (i == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
    }
    dataPath.close();
    canvas.drawPath(dataPath, fillPaint);
    canvas.drawPath(dataPath, strokePaint);

    // Draw dots at vertices
    final dotPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.fill;
    for (int i = 0; i < n; i++) {
      final angle = (2 * pi * i / n) - pi / 2;
      final r = maxRadius * (values[i] / 10.0).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(center.dx + r * cos(angle), center.dy + r * sin(angle)),
        4,
        dotPaint,
      );
    }

    // Draw labels
    final textStyle = TextStyle(
        color: labelColor, fontSize: 11, fontWeight: FontWeight.w500);
    for (int i = 0; i < n; i++) {
      final angle = (2 * pi * i / n) - pi / 2;
      final labelR = maxRadius + 20;
      final x = center.dx + labelR * cos(angle);
      final y = center.dy + labelR * sin(angle);
      final tp = TextPainter(
        text: TextSpan(text: labels[i], style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.dimensions != dimensions || old.strokeColor != strokeColor;
}
