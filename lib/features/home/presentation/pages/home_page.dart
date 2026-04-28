import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/content_types.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_text.dart';
import '../../../content/presentation/providers/content_providers.dart';
import '../../../content/presentation/widgets/content_card.dart';
import '../../../content/presentation/widgets/quick_add_sheet.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  ContentType?   _selectedType;
  ContentStatus? _selectedStatus;
  double?        _selectedMinScore;

  bool get _hasFilter =>
      _selectedType != null || _selectedStatus != null || _selectedMinScore != null;

  int get _activeFilterCount => [
        _selectedType,
        _selectedStatus,
        _selectedMinScore,
      ].where((v) => v != null).length;

  // ── Filter helpers ────────────────────────────────────────────────────────

  void _applyTypeFilter(ContentType? type) {
    setState(() => _selectedType = type);
    ref.read(filterStateProvider.notifier).update(
          (s) => s.copyWith(type: type, clearType: type == null),
        );
  }

  void _applyStatusFilter(ContentStatus? status) {
    setState(() => _selectedStatus = status);
    ref.read(filterStateProvider.notifier).update(
          (s) => s.copyWith(status: status, clearStatus: status == null),
        );
  }

  void _applyScoreFilter(double? minScore) {
    setState(() => _selectedMinScore = minScore);
    ref.read(filterStateProvider.notifier).update(
          (s) => s.copyWith(minScore: minScore, clearScore: minScore == null),
        );
  }

  void _clearAllFilters() {
    setState(() {
      _selectedType     = null;
      _selectedStatus   = null;
      _selectedMinScore = null;
    });
    ref.read(filterStateProvider.notifier).update((_) => const FilterState());
  }

  // ── Filter panel ──────────────────────────────────────────────────────────

  void _openFilterPanel() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterPanel(
        selectedType:     _selectedType,
        selectedStatus:   _selectedStatus,
        selectedMinScore: _selectedMinScore,
        onTypeChanged:    _applyTypeFilter,
        onStatusChanged:  _applyStatusFilter,
        onScoreChanged:   _applyScoreFilter,
        onClear:          _clearAllFilters,
      ),
    );
  }

  // ── Quick add ─────────────────────────────────────────────────────────────

  void _showQuickAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const QuickAddSheet(),
    );
  }

  void _goToAddForm() => context.push('/content/new');

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final asyncItems = ref.watch(contentListProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        titleSpacing: 20,
        title: GradientText(
          'Myndex',
          style: AppTextStyles.headlineLg.copyWith(fontSize: 26),
        ),
        actions: [
          // Stats
          IconButton(
            icon: Icon(Icons.bar_chart_outlined,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            onPressed: () => context.push('/stats'),
            tooltip: 'Estadísticas',
          ),
          // Search
          IconButton(
            icon: Icon(Icons.search,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            onPressed: () => context.go('/explore'),
            tooltip: 'Buscar',
          ),
          // Unified filter button with badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.tune_rounded,
                  color: _hasFilter
                      ? AppColors.cyan
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onPressed: _openFilterPanel,
                tooltip: 'Filtros',
              ),
              if (_hasFilter)
                Positioned(
                  top: 10,
                  right: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      gradient: AppColors.gradientH,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$_activeFilterCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Active filter summary pill ────────────────────────────────
          if (_hasFilter)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      if (_selectedType != null)
                        _ActiveFilterPill(
                          label: _selectedType!.label,
                          onRemove: () => _applyTypeFilter(null),
                        ),
                      if (_selectedStatus != null)
                        _ActiveFilterPill(
                          label: _selectedStatus!.label,
                          onRemove: () => _applyStatusFilter(null),
                        ),
                      if (_selectedMinScore != null)
                        _ActiveFilterPill(
                          label: '≥ ${(_selectedMinScore! / 2).toStringAsFixed(0)} ★',
                          onRemove: () => _applyScoreFilter(null),
                        ),
                    ]),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _clearAllFilters,
                  child: Text(
                    'Limpiar',
                    style: AppTextStyles.labelSm.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ]),
            )
          else
            const SizedBox(height: 8),

          // ── Content grid ──────────────────────────────────────────────
          Expanded(
            child: asyncItems.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.cyan),
              ),
              error: (e, _) => Center(
                child: Text('Error: $e', style: AppTextStyles.bodyMd),
              ),
              data: (items) => items.isEmpty
                  ? _EmptyState(hasFilter: _hasFilter)
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.62,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: items.length,
                      itemBuilder: (_, i) => ContentCard(
                        item: items[i],
                        onTap: () => context.push('/content/${items[i].id}'),
                      ),
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: _GradientFAB(
        onTap: _goToAddForm,
        onLongPress: _showQuickAddSheet,
      ),
    );
  }
}

// ── Active filter pill ────────────────────────────────────────────────────

class _ActiveFilterPill extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _ActiveFilterPill({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.only(left: 12, right: 4, top: 5, bottom: 5),
      decoration: BoxDecoration(
        color: AppColors.cyan.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.35)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(
          label,
          style: AppTextStyles.labelSm.copyWith(
            color: AppColors.cyan,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onRemove,
          child: const Icon(Icons.close, size: 14, color: AppColors.cyan),
        ),
      ]),
    );
  }
}

// ── Filter panel (bottom sheet) ───────────────────────────────────────────

class _FilterPanel extends StatefulWidget {
  final ContentType?   selectedType;
  final ContentStatus? selectedStatus;
  final double?        selectedMinScore;
  final ValueChanged<ContentType?>   onTypeChanged;
  final ValueChanged<ContentStatus?> onStatusChanged;
  final ValueChanged<double?>        onScoreChanged;
  final VoidCallback onClear;

  const _FilterPanel({
    required this.selectedType,
    required this.selectedStatus,
    required this.selectedMinScore,
    required this.onTypeChanged,
    required this.onStatusChanged,
    required this.onScoreChanged,
    required this.onClear,
  });

  @override
  State<_FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<_FilterPanel> {
  late ContentType?   _type;
  late ContentStatus? _status;
  late double?        _score;

  @override
  void initState() {
    super.initState();
    _type   = widget.selectedType;
    _status = widget.selectedStatus;
    _score  = widget.selectedMinScore;
  }

  static const _types = [
    (label: 'Todos', type: null as ContentType?),
    (label: 'Cine',   type: ContentType.movie),
    (label: 'Series', type: ContentType.series),
    (label: 'Libros', type: ContentType.book),
    (label: 'Juegos', type: ContentType.game),
    (label: 'Anime',  type: ContentType.anime),
    (label: 'Podcast', type: ContentType.podcast),
    (label: 'Otro',   type: ContentType.other),
  ];

  static const _statuses = [
    (label: 'Todos',       status: null as ContentStatus?),
    (label: 'Pendiente',   status: ContentStatus.pending),
    (label: 'En curso',    status: ContentStatus.inProgress),
    (label: 'Completado',  status: ContentStatus.completed),
    (label: 'Abandonado',  status: ContentStatus.dropped),
  ];

  static const _scores = [
    (label: 'Sin filtro', score: null as double?),
    (label: '≥ 2 ★',     score: 4.0),
    (label: '≥ 3 ★',     score: 6.0),
    (label: '≥ 4 ★',     score: 8.0),
    (label: 'Solo 5 ★',  score: 10.0),
  ];

  void _apply() {
    widget.onTypeChanged(_type);
    widget.onStatusChanged(_status);
    widget.onScoreChanged(_score);
    Navigator.of(context).pop();
  }

  void _clear() {
    widget.onClear();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final hasLocal = _type != null || _status != null || _score != null;

    return Container(
      margin: const EdgeInsets.only(top: 80),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Text('Filtros',
                  style: AppTextStyles.titleMd.copyWith(
                      color: Theme.of(context).colorScheme.onSurface)),
              const Spacer(),
              if (hasLocal)
                TextButton(
                  onPressed: () => setState(() {
                    _type   = null;
                    _status = null;
                    _score  = null;
                  }),
                  child: Text('Limpiar todo',
                      style: AppTextStyles.labelMd.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ),
            ]),
          ),
          const Divider(height: 1),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Tipo ──────────────────────────────────────────────
                  _SectionLabel('Tipo de contenido'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _types.map((t) => _Chip(
                      label: t.label,
                      selected: _type == t.type,
                      onTap: () => setState(() => _type = t.type),
                    )).toList(),
                  ),
                  const SizedBox(height: 24),

                  // ── Estado ────────────────────────────────────────────
                  _SectionLabel('Estado'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _statuses.map((s) => _Chip(
                      label: s.label,
                      selected: _status == s.status,
                      onTap: () => setState(() => _status = s.status),
                    )).toList(),
                  ),
                  const SizedBox(height: 24),

                  // ── Puntuación ────────────────────────────────────────
                  _SectionLabel('Puntuación mínima'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _scores.map((sc) => _Chip(
                      label: sc.label,
                      selected: _score == sc.score,
                      onTap: () => setState(() => _score = sc.score),
                    )).toList(),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Apply button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: GestureDetector(
                onTap: _apply,
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientH,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.blue.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      hasLocal ? 'Aplicar filtros' : 'Ver todos',
                      style: AppTextStyles.titleMd.copyWith(
                          color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chip inside panel ─────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.gradientH : null,
          color: selected ? null : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMd.copyWith(
            color: selected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.labelSm.copyWith(
        color: AppColors.cyan,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
  }
}

// ── Gradient FAB ──────────────────────────────────────────────────────────

class _GradientFAB extends StatefulWidget {
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _GradientFAB({required this.onTap, required this.onLongPress});

  @override
  State<_GradientFAB> createState() => _GradientFABState();
}

class _GradientFABState extends State<_GradientFAB>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0,
      upperBound: 0.06,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Añadir  •  Mantén pulsado para entrada rápida',
      child: GestureDetector(
        onTap: () {
          _ctrl.forward().then((_) => _ctrl.reverse());
          widget.onTap();
        },
        onLongPress: () {
          _ctrl.forward().then((_) => _ctrl.reverse());
          widget.onLongPress();
        },
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppColors.gradientH,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blue.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  const _EmptyState({this.hasFilter = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(Icons.movie_filter_outlined,
              size: 40,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        Text(
          hasFilter ? 'Sin resultados' : 'Tu biblioteca está vacía',
          style: AppTextStyles.titleMd
              .copyWith(color: Theme.of(context).colorScheme.onSurface),
        ),
        const SizedBox(height: 8),
        Text(
          hasFilter
              ? 'Prueba con otro filtro'
              : 'Pulsa + para añadir tu primer contenido',
          style: AppTextStyles.bodyMd.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ]),
    );
  }
}
