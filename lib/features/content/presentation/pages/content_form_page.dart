import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/content_types.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../domain/entities/content_item.dart';
import '../providers/content_providers.dart';
import '../widgets/external_search_delegate.dart';

class ContentFormPage extends ConsumerStatefulWidget {
  final int? id;
  const ContentFormPage({super.key, this.id});

  @override
  ConsumerState<ContentFormPage> createState() => _ContentFormPageState();
}

class _ContentFormPageState extends ConsumerState<ContentFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController _titleCtrl;
  late final TextEditingController _genreCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _imageCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _totalUnitsCtrl;
  late final TextEditingController _progressCtrl;

  // Fields
  ContentType   _type    = ContentType.movie;
  ContentStatus _status  = ContentStatus.pending;
  double        _score   = 0; // 0–10, shown as 0–5 stars
  bool          _loading = false;

  // API metadata
  String? _externalId;
  String? _externalSource;

  // Preserve original addedAt when editing
  DateTime? _existingAddedAt;

  // Rating dimensions (per type)
  Map<String, double> _ratingDims = {};

  // ── Type definitions ─────────────────────────────────────────────────────

  static const _types = [
    (type: ContentType.movie,   label: 'Cine',    icon: Icons.movie_outlined),
    (type: ContentType.series,  label: 'Series',  icon: Icons.tv_outlined),
    (type: ContentType.anime,   label: 'Anime',   icon: Icons.animation_outlined),
    (type: ContentType.book,    label: 'Libro',   icon: Icons.menu_book_outlined),
    (type: ContentType.game,    label: 'Juego',   icon: Icons.sports_esports_outlined),
    (type: ContentType.podcast, label: 'Podcast', icon: Icons.podcasts_outlined),
    (type: ContentType.other,   label: 'Otro',    icon: Icons.category_outlined),
  ];

  static const _statuses = [
    (status: ContentStatus.pending,    label: 'Pendiente'),
    (status: ContentStatus.inProgress, label: 'En curso'),
    (status: ContentStatus.completed,  label: 'Completado'),
    (status: ContentStatus.dropped,    label: 'Abandonado'),
  ];

  /// Rating dimensions per content type
  static const Map<ContentType, List<String>> _dimsByType = {
    ContentType.movie:   ['Historia', 'Dirección', 'Actuación', 'BSO', 'Ritmo'],
    ContentType.series:  ['Historia', 'Personajes', 'Guión', 'Ritmo', 'Actuación'],
    ContentType.anime:   ['Historia', 'Personajes', 'Animación', 'BSO', 'Emoción'],
    ContentType.book:    ['Historia', 'Escritura', 'Personajes', 'Ritmo', 'Originalidad'],
    ContentType.game:    ['Gameplay', 'Historia', 'Gráficos', 'BSO', 'Rejugabilidad'],
    ContentType.podcast: ['Contenido', 'Presentación', 'Frecuencia', 'Calidad'],
    ContentType.other:   ['Calidad', 'Disfrute', 'Originalidad'],
  };

  /// Progress unit label per type
  String get _unitLabel => switch (_type) {
    ContentType.series || ContentType.anime  => 'Episodios',
    ContentType.book                         => 'Páginas',
    ContentType.game                         => 'Horas',
    ContentType.podcast                      => 'Episodios',
    _                                        => 'Unidades',
  };

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _titleCtrl    = TextEditingController();
    _genreCtrl    = TextEditingController();
    _notesCtrl    = TextEditingController();
    _imageCtrl    = TextEditingController();
    _durationCtrl = TextEditingController();
    _totalUnitsCtrl = TextEditingController();
    _progressCtrl = TextEditingController();

    _initDimsForType(_type);
    if (widget.id != null) _loadExisting();
  }

  @override
  void dispose() {
    for (final c in [_titleCtrl, _genreCtrl, _notesCtrl, _imageCtrl,
                     _durationCtrl, _totalUnitsCtrl, _progressCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _initDimsForType(ContentType type) {
    final dims = _dimsByType[type] ?? [];
    _ratingDims = {for (final d in dims) d: _ratingDims[d] ?? 0.0};
  }

  void _onTypeChanged(ContentType type) {
    setState(() {
      _type = type;
      // Preserve dimension values that share the same name
      final dims = _dimsByType[type] ?? [];
      _ratingDims = {for (final d in dims) d: _ratingDims[d] ?? 0.0};
    });
  }

  Future<void> _loadExisting() async {
    final item = await ref.read(contentRepositoryProvider).getById(widget.id!);
    if (item != null && mounted) {
      setState(() {
        _titleCtrl.text    = item.title;
        _genreCtrl.text    = item.genre ?? '';
        _notesCtrl.text    = item.notes ?? '';
        _imageCtrl.text    = item.imageUrl ?? '';
        _type              = item.type;
        _status            = item.status;
        _score             = item.score ?? 0;
        _externalId        = item.externalId;
        _externalSource    = item.externalSource;
        _existingAddedAt   = item.addedAt;
        if (item.estimatedDurationMinutes != null) {
          _durationCtrl.text = '${item.estimatedDurationMinutes}';
        }
        if (item.totalUnits != null) {
          _totalUnitsCtrl.text = '${item.totalUnits}';
        }
        if (item.progressUnits != null) {
          _progressCtrl.text = '${item.progressUnits}';
        }
        if (item.ratingDimensions != null) {
          final dims = _dimsByType[item.type] ?? [];
          _ratingDims = {
            for (final d in dims)
              d: (item.ratingDimensions![d] ?? 0).toDouble(),
          };
        } else {
          _initDimsForType(item.type);
        }
      });
    }
  }

  // ── Save ─────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final now     = DateTime.now();
    final addedAt = _existingAddedAt ?? now;
    final genre   = _genreCtrl.text.trim();

    // Build rating dims map (int 0–10, only non-zero values)
    final dimsMap = <String, int>{
      for (final e in _ratingDims.entries)
        if (e.value > 0) e.key: e.value.round(),
    };

    final item = ContentItem(
      id:               widget.id,
      title:            _titleCtrl.text.trim(),
      type:             _type,
      status:           _status,
      score:            _score > 0 ? _score : null,
      genre:            genre.isNotEmpty ? genre : null,
      notes:            _notesCtrl.text.trim(),
      imageUrl:         _imageCtrl.text.trim(),
      externalId:       _externalId,
      externalSource:   _externalSource,
      addedAt:          addedAt,
      updatedAt:        now,
      estimatedDurationMinutes: int.tryParse(_durationCtrl.text.trim()),
      totalUnits:       int.tryParse(_totalUnitsCtrl.text.trim()),
      progressUnits:    int.tryParse(_progressCtrl.text.trim()),
      ratingDimensions: dimsMap.isNotEmpty ? dimsMap : null,
    );

    try {
      await ref.read(saveContentProvider).call(item);
      ref.invalidate(contentListProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar el contenido')),
      );
    }
  }

  Future<void> _openExternalSearch() async {
    final result = await showExternalSearchSheet(context: context, type: _type);
    if (result == null || !mounted) return;
    setState(() {
      _titleCtrl.text = result.title;
      if (result.imageUrl != null && result.imageUrl!.isNotEmpty) {
        _imageCtrl.text = result.imageUrl!;
      }
      _externalId     = result.externalId;
      _externalSource = result.source;
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.id == null ? 'Añadir contenido' : 'Editar contenido',
          style: AppTextStyles.titleLg,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 60),
          children: [

            // ════════════════════════════════════════════════════
            // 1. TIPO
            // ════════════════════════════════════════════════════
            _Section(
              icon: Icons.category_outlined,
              title: 'Tipo de contenido',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _types.map((t) {
                  final sel = _type == t.type;
                  return GestureDetector(
                    onTap: () => _onTypeChanged(t.type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        gradient: sel ? AppColors.gradientH : null,
                        color: sel
                            ? null
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: sel
                              ? Colors.transparent
                              : Theme.of(context).dividerColor,
                        ),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(t.icon,
                            size: 15,
                            color: sel
                                ? Colors.white
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant),
                        const SizedBox(width: 6),
                        Text(t.label,
                            style: AppTextStyles.labelMd.copyWith(
                              color: sel
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurface,
                              fontWeight: sel
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            )),
                      ]),
                    ),
                  );
                }).toList(),
              ),
            ),

            // ════════════════════════════════════════════════════
            // 2. BUSCAR EN LÍNEA
            // ════════════════════════════════════════════════════
            _Section(
              icon: Icons.travel_explore,
              title: 'Buscar en línea',
              child: GestureDetector(
                onTap: _openExternalSearch,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).inputDecorationTheme.fillColor,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(children: [
                    ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (b) => AppColors.gradientH
                          .createShader(
                              Rect.fromLTWH(0, 0, b.width, b.height)),
                      child: const Icon(Icons.travel_explore, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _externalSource != null
                            ? 'Vinculado a ${_externalSource!.toUpperCase()}'
                            : 'Buscar y autocompletar datos...',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: _externalSource != null
                              ? AppColors.cyan
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (_externalSource != null)
                      GestureDetector(
                        onTap: () => setState(() {
                          _externalId = null;
                          _externalSource = null;
                        }),
                        child: const Icon(Icons.link_off,
                            color: AppColors.textDisabled, size: 18),
                      )
                    else
                      const Icon(Icons.chevron_right,
                          color: AppColors.textDisabled, size: 18),
                  ]),
                ),
              ),
            ),

            // ════════════════════════════════════════════════════
            // 3. DATOS BÁSICOS
            // ════════════════════════════════════════════════════
            _Section(
              icon: Icons.edit_outlined,
              title: 'Datos básicos',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel('Título *'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleCtrl,
                    style: AppTextStyles.bodyLg,
                    decoration: const InputDecoration(
                        hintText: 'Introduce el título completo'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Campo obligatorio'
                            : null,
                  ),

                  const SizedBox(height: 16),
                  _FieldLabel('Género'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _genreCtrl,
                    style: AppTextStyles.bodyLg,
                    decoration: const InputDecoration(
                        hintText: 'ej. Acción, Aventura, Ciencia ficción'),
                  ),

                  const SizedBox(height: 16),
                  _FieldLabel('Imagen (URL)'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _imageCtrl,
                    style: AppTextStyles.bodyLg,
                    keyboardType: TextInputType.url,
                    decoration:
                        const InputDecoration(hintText: 'https://...'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final uri = Uri.tryParse(v.trim());
                      if (uri == null ||
                          (uri.scheme != 'http' &&
                              uri.scheme != 'https') ||
                          !uri.hasAuthority ||
                          uri.host.isEmpty) {
                        return 'Solo se admiten URLs http/https';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),

            // ════════════════════════════════════════════════════
            // 4. ESTADO Y PROGRESO
            // ════════════════════════════════════════════════════
            _Section(
              icon: Icons.timeline_outlined,
              title: 'Estado y progreso',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel('Estado'),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .inputDecorationTheme
                          .fillColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Theme.of(context).dividerColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<ContentStatus>(
                        value: _status,
                        dropdownColor: Theme.of(context).cardTheme.color,
                        iconEnabledColor: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                        style: AppTextStyles.bodyLg,
                        isExpanded: true,
                        items: _statuses
                            .map((s) => DropdownMenuItem(
                                  value: s.status,
                                  child: Text(s.label),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _status = v!),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel('Progreso ($_unitLabel)'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _progressCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            style: AppTextStyles.bodyLg,
                            decoration: InputDecoration(
                                hintText: 'ej. 12'),
                            validator: (v) {
                              if (v == null || v.isEmpty) return null;
                              final n = int.tryParse(v);
                              if (n == null || n < 0) return 'Nº inválido';
                              final total =
                                  int.tryParse(_totalUnitsCtrl.text);
                              if (total != null && n > total) {
                                return 'Mayor que el total';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel('Total ($_unitLabel)'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _totalUnitsCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            style: AppTextStyles.bodyLg,
                            decoration: InputDecoration(
                                hintText: 'ej. 24'),
                          ),
                        ],
                      ),
                    ),
                  ]),

                  const SizedBox(height: 16),
                  _FieldLabel('Duración estimada (minutos)'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _durationCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly
                    ],
                    style: AppTextStyles.bodyLg,
                    decoration: const InputDecoration(
                        hintText: 'ej. 120 para una película de 2h'),
                  ),
                ],
              ),
            ),

            // ════════════════════════════════════════════════════
            // 5. VALORACIÓN
            // ════════════════════════════════════════════════════
            _Section(
              icon: Icons.star_outline_rounded,
              title: 'Valoración',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel('Puntuación global'),
                  const SizedBox(height: 10),
                  _InteractiveStars(
                    value: _score,
                    onChanged: (v) => setState(() => _score = v),
                  ),

                  const SizedBox(height: 20),
                  _FieldLabel('Valoración por dimensiones'),
                  const SizedBox(height: 4),
                  Text(
                    'Arrastra para puntuar cada aspecto (0–10)',
                    style: AppTextStyles.labelSm.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  ...(_dimsByType[_type] ?? []).map((dim) {
                    final val = _ratingDims[dim] ?? 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                              child: Text(dim,
                                  style: AppTextStyles.bodyMd.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface)),
                            ),
                            Container(
                              width: 36,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.cyan.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  val.toStringAsFixed(1),
                                  style: AppTextStyles.labelSm.copyWith(
                                    color: AppColors.cyan,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 6),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppColors.cyan,
                              inactiveTrackColor: Theme.of(context)
                                  .colorScheme
                                  .surface,
                              thumbColor: AppColors.cyan,
                              overlayColor:
                                  AppColors.cyan.withValues(alpha: 0.2),
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 7),
                            ),
                            child: Slider(
                              value: val,
                              min: 0,
                              max: 10,
                              divisions: 10,
                              onChanged: (v) => setState(
                                  () => _ratingDims[dim] = v),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            // ════════════════════════════════════════════════════
            // 6. NOTAS
            // ════════════════════════════════════════════════════
            _Section(
              icon: Icons.notes_outlined,
              title: 'Notas personales',
              child: TextFormField(
                controller: _notesCtrl,
                maxLines: 5,
                style: AppTextStyles.bodyLg,
                decoration: const InputDecoration(
                  hintText:
                      'Añade tus pensamientos, reseñas o citas favoritas...',
                ),
              ),
            ),

            const SizedBox(height: 24),
            GradientButton(
              label: widget.id == null
                  ? 'Guardar en biblioteca'
                  : 'Actualizar',
              loading: _loading,
              onPressed: _loading ? null : _save,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── Section wrapper ───────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const _Section({required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: AppColors.cyan),
            const SizedBox(width: 8),
            Text(
              title.toUpperCase(),
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.cyan,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ]),
          const SizedBox(height: 4),
          Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ── Field label ───────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppTextStyles.bodyMd.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w500),
      );
}

// ── Interactive stars ─────────────────────────────────────────────────────

class _InteractiveStars extends StatelessWidget {
  final double value; // 0–10
  final ValueChanged<double> onChanged;
  const _InteractiveStars({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final stars = (value / 2).round();
    return Row(
      children: [
        ...List.generate(5, (i) {
          return GestureDetector(
            onTap: () => onChanged(
                stars == i + 1 ? 0 : (i + 1) * 2.0), // tap same = clear
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(
                i < stars
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: i < stars ? AppColors.cyan : AppColors.textDisabled,
                size: 38,
              ),
            ),
          );
        }),
        const SizedBox(width: 12),
        Text(
          value > 0
              ? '${(value / 2).toStringAsFixed(1)} / 5'
              : 'Sin puntuar',
          style: AppTextStyles.labelMd.copyWith(
              color: value > 0
                  ? AppColors.cyan
                  : Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
