import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/content_types.dart';
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
  late final TextEditingController _notesCtrl;
  late final TextEditingController _imageCtrl;
  ContentType _type = ContentType.movie;
  ContentStatus _status = ContentStatus.pending;
  double _score = 0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
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
        _type = item.type;
        _status = item.status;
        _score = item.score ?? 0;
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
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
      appBar: AppBar(title: Text(widget.id == null ? 'Añadir contenido' : 'Editar')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Título *', border: OutlineInputBorder()),
              validator: (v) => v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ContentType>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Tipo', border: OutlineInputBorder()),
              items: ContentType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ContentStatus>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Estado', border: OutlineInputBorder()),
              items: ContentStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))).toList(),
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 16),
            Text('Puntuación: ${_score == 0 ? "-" : _score.toStringAsFixed(1)}',
                style: Theme.of(context).textTheme.labelLarge),
            Slider(
              value: _score,
              min: 0, max: 10, divisions: 20,
              onChanged: (v) => setState(() => _score = v),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _imageCtrl,
              decoration: const InputDecoration(labelText: 'URL imagen (opcional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Notas personales', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loading ? null : _save,
              icon: _loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_outlined),
              label: Text(_loading ? 'Guardando...' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
