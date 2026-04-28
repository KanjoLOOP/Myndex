import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/content_types.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../content/presentation/providers/content_providers.dart';

class AdvancedFilterSheet extends ConsumerStatefulWidget {
  const AdvancedFilterSheet({super.key});

  @override
  ConsumerState<AdvancedFilterSheet> createState() => _AdvancedFilterSheetState();
}

class _AdvancedFilterSheetState extends ConsumerState<AdvancedFilterSheet> {
  ContentStatus? _status;
  double? _minScore;

  @override
  void initState() {
    super.initState();
    // Leer estado actual de los filtros
    final currentFilter = ref.read(filterStateProvider);
    _status = currentFilter.status;
    _minScore = currentFilter.minScore;
  }

  void _apply() {
    ref.read(filterStateProvider.notifier).update((state) => state.copyWith(
          status: _status,
          minScore: _minScore,
          clearStatus: _status == null,
          clearScore: _minScore == null,
        ));
    Navigator.pop(context);
  }

  void _clear() {
    setState(() {
      _status = null;
      _minScore = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle ──
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Filtros Avanzados', style: AppTextStyles.titleLg),
              TextButton(
                onPressed: _clear,
                child: const Text('Limpiar', style: TextStyle(color: AppColors.cyan)),
              )
            ],
          ),
          const SizedBox(height: 20),

          // ── Filtro por Estado ──
          Text('ESTADO', style: AppTextStyles.labelMd.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: ContentStatus.values.map((s) {
              final selected = _status == s;
              return GestureDetector(
                onTap: () => setState(() => _status = selected ? null : s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: selected ? AppColors.gradientH : null,
                    color: selected ? null : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? Colors.transparent : Theme.of(context).dividerColor,
                    ),
                  ),
                  child: Text(
                    s.label,
                    style: AppTextStyles.labelMd.copyWith(
                      color: selected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 32),

          // ── Filtro por Puntuación ──
          Text('PUNTUACIÓN MÍNIMA', style: AppTextStyles.labelMd.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star_half_rounded, color: AppColors.cyan),
              Expanded(
                child: Slider(
                  value: (_minScore ?? 0) / 2,
                  min: 0,
                  max: 5,
                  divisions: 5,
                  activeColor: AppColors.cyan,
                  inactiveColor: Theme.of(context).dividerColor,
                  label: _minScore != null && _minScore! > 0 ? (_minScore! / 2).toInt().toString() : 'Cualquiera',
                  onChanged: (v) => setState(() => _minScore = v == 0 ? null : v * 2),
                ),
              ),
              SizedBox(
                width: 30,
                child: Text(
                  _minScore != null && _minScore! > 0 ? '${(_minScore! / 2).toInt()}+' : 'Todas',
                  style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _minScore != null && _minScore! > 0 ? AppColors.cyan : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          GradientButton(
            label: 'Aplicar Filtros',
            onPressed: _apply,
          ),
        ],
      ),
    );
  }
}
