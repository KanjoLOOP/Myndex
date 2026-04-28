import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/content_types.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/content_item.dart';
import '../providers/content_providers.dart';

class QuickAddSheet extends ConsumerStatefulWidget {
  const QuickAddSheet({super.key});

  @override
  ConsumerState<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<QuickAddSheet> {
  final _ctrl = TextEditingController();
  ContentType _selectedType = ContentType.movie;
  bool _isSaving = false;

  void _save() async {
    final title = _ctrl.text.trim();
    if (title.isEmpty) return;

    setState(() => _isSaving = true);

    final item = ContentItem(
      title: title,
      type: _selectedType,
      status: ContentStatus.pending,
      addedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      final repo = ref.read(contentRepositoryProvider);
      await repo.create(item);
      ref.invalidate(contentListProvider);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Añadido rápidamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Quick Add', style: AppTextStyles.titleLg),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Título del contenido...',
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ContentType.values.map((t) {
              final selected = _selectedType == t;
              return GestureDetector(
                onTap: () => setState(() => _selectedType = t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.cyan : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? Colors.transparent : Theme.of(context).dividerColor,
                    ),
                  ),
                  child: Text(
                    t.name.toUpperCase(),
                    style: AppTextStyles.labelMd.copyWith(
                      color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cyan,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Guardar Rápido', style: AppTextStyles.titleMd.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
