import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/content_types.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../domain/entities/content_item.dart';
import '../providers/content_providers.dart';

class ContentFormPage extends ConsumerStatefulWidget {
  final int? id;
  const ContentFormPage({super.key, this.id});

  @override
  ConsumerState<ContentFormPage> createState() => _ContentFormPageState();
}

class _ContentFormPageState extends ConsumerState<ContentFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _genreCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _imageCtrl;

  ContentType _type = ContentType.movie;
  ContentStatus _status = ContentStatus.pending;
  double _score = 0; // 0-10, displayed as 0-5 stars
  bool _loading = false;

  static const _types = [
    (type: ContentType.movie,  label: 'Movie',  icon: Icons.movie_outlined),
    (type: ContentType.series, label: 'Series', icon: Icons.tv_outlined),
    (type: ContentType.book,   label: 'Book',   icon: Icons.menu_book_outlined),
    (type: ContentType.game,   label: 'Game',   icon: Icons.sports_esports_outlined),
    (type: ContentType.anime,  label: 'Anime',  icon: Icons.animation_outlined),
  ];

  static const _statuses = [
    (status: ContentStatus.pending,    label: 'Planning to Watch'),
    (status: ContentStatus.inProgress, label: 'In Progress'),
    (status: ContentStatus.completed,  label: 'Completed'),
    (status: ContentStatus.dropped,    label: 'Dropped'),
  ];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _genreCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
    _imageCtrl = TextEditingController();
    if (widget.id != null) _loadExisting();
  }

  Future<void> _loadExisting() async {
    final item = await ref.read(contentRepositoryProvider).getById(widget.id!);
    if (item != null && mounted) {
      setState(() {
        _titleCtrl.text = item.title;
        _notesCtrl.text = item.notes ?? '';
        _imageCtrl.text = item.imageUrl ?? '';
        _type   = item.type;
        _status = item.status;
        _score  = item.score ?? 0;
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _genreCtrl.dispose();
    _notesCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final now = DateTime.now();
    final item = ContentItem(
      id: widget.id,
      title: _titleCtrl.text.trim(),
      type: _type,
      status: _status,
      score: _score > 0 ? _score : null,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      imageUrl: _imageCtrl.text.trim().isEmpty ? null : _imageCtrl.text.trim(),
      addedAt: now,
      updatedAt: now,
    );
    await ref.read(saveContentProvider).call(item);
    ref.invalidate(contentListProvider);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: Text(
          widget.id == null ? 'Add New Content' : 'Edit Content',
          style: AppTextStyles.titleLg,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            // ── Content Type ─────────────────────────────────────────
            Text('CONTENT TYPE', style: AppTextStyles.labelMd.copyWith(
                letterSpacing: 1.2, color: AppColors.textDisabled)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _types.map((t) {
                final selected = _type == t.type;
                return GestureDetector(
                  onTap: () => setState(() => _type = t.type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: selected ? AppColors.gradientH : null,
                      color: selected ? null : AppColors.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                          color: selected ? Colors.transparent : AppColors.border),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(t.icon, size: 16,
                          color: selected ? Colors.white : AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(t.label,
                          style: AppTextStyles.labelMd.copyWith(
                              color: selected ? Colors.white : AppColors.textSecondary,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.w500)),
                    ]),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 28),
            // ── Search bar (placeholder visual) ──────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(children: [
                const Icon(Icons.search, color: AppColors.textDisabled, size: 20),
                const SizedBox(width: 10),
                Text('Search for title...',
                    style: AppTextStyles.bodyMd.copyWith(color: AppColors.textDisabled)),
              ]),
            ),

            const SizedBox(height: 28),
            const Divider(color: AppColors.border),
            const SizedBox(height: 20),

            // ── Manual Entry ─────────────────────────────────────────
            Text('MANUAL ENTRY', style: AppTextStyles.labelMd.copyWith(
                letterSpacing: 1.2, color: AppColors.textDisabled)),
            const SizedBox(height: 16),

            _FieldLabel('Title'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleCtrl,
              style: AppTextStyles.bodyLg,
              decoration: const InputDecoration(hintText: 'Enter full title'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
            ),

            const SizedBox(height: 16),
            _FieldLabel('Genre'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _genreCtrl,
              style: AppTextStyles.bodyLg,
              decoration: const InputDecoration(hintText: 'e.g., Sci-Fi, Thriller'),
            ),

            const SizedBox(height: 16),
            _FieldLabel('Image URL (optional)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _imageCtrl,
              style: AppTextStyles.bodyLg,
              decoration: const InputDecoration(hintText: 'https://...'),
            ),

            const SizedBox(height: 16),
            _FieldLabel('Status'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<ContentStatus>(
                  value: _status,
                  dropdownColor: AppColors.bgSecondary,
                  iconEnabledColor: AppColors.textSecondary,
                  style: AppTextStyles.bodyLg,
                  isExpanded: true,
                  items: _statuses.map((s) => DropdownMenuItem(
                    value: s.status,
                    child: Text(s.label),
                  )).toList(),
                  onChanged: (v) => setState(() => _status = v!),
                ),
              ),
            ),

            const SizedBox(height: 20),
            _FieldLabel('Rating'),
            const SizedBox(height: 10),
            _InteractiveStars(
              value: _score,
              onChanged: (v) => setState(() => _score = v),
            ),

            const SizedBox(height: 20),
            _FieldLabel('Personal Notes'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 5,
              style: AppTextStyles.bodyLg,
              decoration: const InputDecoration(
                  hintText: 'Add your thoughts, review, or quotes here...'),
            ),

            const SizedBox(height: 32),
            GradientButton(
              label: 'Save Content',
              loading: _loading,
              onPressed: _loading ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTextStyles.bodyMd.copyWith(color: AppColors.textPrimary));
}

class _InteractiveStars extends StatelessWidget {
  final double value; // 0-10
  final ValueChanged<double> onChanged;
  const _InteractiveStars({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final stars = (value / 2).round();
    return Row(
      children: List.generate(5, (i) {
        return GestureDetector(
          onTap: () => onChanged((i + 1) * 2.0),
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(
              i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
              color: i < stars ? AppColors.cyan : AppColors.textDisabled,
              size: 36,
            ),
          ),
        );
      }),
    );
  }
}
