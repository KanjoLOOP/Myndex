import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../content/presentation/providers/content_providers.dart';
import '../../../../core/utils/json_utils.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        children: [
          const _SectionHeader('Datos'),
          ListTile(
            leading: const Icon(Icons.upload_outlined),
            title: const Text('Exportar biblioteca'),
            subtitle: const Text('Guarda un JSON con todo tu contenido'),
            onTap: () => _export(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Importar biblioteca'),
            subtitle: const Text('Carga un JSON exportado previamente'),
            onTap: () => _import(context, ref),
          ),
          const Divider(),
          const _SectionHeader('Acerca de'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Myndex'),
            subtitle: Text('v1.0.0 · Gestión personal de contenido'),
          ),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    try {
      final repo = ref.read(contentRepositoryProvider);
      final data = await repo.exportAll();
      final json = JsonUtils.encode({'version': 1, 'items': data});
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/myndex_backup.json');
      await file.writeAsString(json);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'Myndex backup'),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar: $e')),
        );
      }
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.single.path == null) return;
      final file = File(result.files.single.path!);
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final items = (decoded['items'] as List).cast<Map<String, dynamic>>();
      final repo = ref.read(contentRepositoryProvider);
      final count = await repo.importAll(items);
      ref.invalidate(contentListProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count elementos importados')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al importar: $e')),
        );
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(title,
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(color: Theme.of(context).colorScheme.primary)),
    );
  }
}
