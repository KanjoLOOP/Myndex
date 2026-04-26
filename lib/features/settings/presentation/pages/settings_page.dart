import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_text.dart';
import '../../../../core/utils/json_utils.dart';
import '../../../content/presentation/providers/content_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        titleSpacing: 20,
        title: const Text('Settings', style: AppTextStyles.titleLg),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textSecondary),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          // ── Data Management ────────────────────────────────────────
          _SectionHeader('Data Management'),
          const SizedBox(height: 10),
          _SettingsGroup(children: [
            _SettingsTile(
              icon: Icons.upload_outlined,
              iconColor: AppColors.cyan,
              title: 'Export Library (JSON)',
              onTap: () => _export(context, ref),
            ),
            const Divider(color: AppColors.border, height: 1),
            _SettingsTile(
              icon: Icons.download_outlined,
              iconColor: AppColors.cyan,
              title: 'Import Library (JSON)',
              onTap: () => _import(context, ref),
            ),
          ]),

          const SizedBox(height: 24),
          // ── Appearance ─────────────────────────────────────────────
          _SectionHeader('Appearance'),
          const SizedBox(height: 10),
          _SettingsGroup(children: [
            _SettingsTile(
              icon: Icons.dark_mode_outlined,
              iconColor: AppColors.cyan,
              title: 'Dark Mode',
              trailing: Switch(
                value: true,
                onChanged: (_) {},
                activeColor: AppColors.cyan,
                activeTrackColor: AppColors.blue.withOpacity(0.4),
              ),
            ),
            const Divider(color: AppColors.border, height: 1),
            _SettingsTile(
              icon: Icons.palette_outlined,
              iconColor: AppColors.cyan,
              title: 'Theme Color',
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (b) => AppColors.gradientH.createShader(
                      Rect.fromLTWH(0, 0, b.width, b.height)),
                  child: const Text('Neon Gradient',
                      style: AppTextStyles.bodyMd),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right, color: AppColors.textDisabled, size: 18),
              ]),
            ),
          ]),

          const SizedBox(height: 24),
          // ── General ────────────────────────────────────────────────
          _SectionHeader('General'),
          const SizedBox(height: 10),
          _SettingsGroup(children: [
            _SettingsTile(
              icon: Icons.help_outline,
              iconColor: AppColors.cyan,
              title: 'Help & Support',
              onTap: () {},
            ),
            const Divider(color: AppColors.border, height: 1),
            _SettingsTile(
              icon: Icons.info_outline,
              iconColor: AppColors.cyan,
              title: 'About Myndex',
              onTap: () => _showAbout(context),
            ),
          ]),

          const SizedBox(height: 32),
          Center(
            child: GradientText(
              'Myndex Version 1.0.0',
              style: AppTextStyles.labelMd,
            ),
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
      if (context.mounted) _showSnack(context, 'Error al exportar: $e', error: true);
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform
          .pickFiles(type: FileType.custom, allowedExtensions: ['json']);
      if (result?.files.single.path == null) return;
      final raw = await File(result!.files.single.path!).readAsString();
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final items = (decoded['items'] as List).cast<Map<String, dynamic>>();
      final count = await ref.read(contentRepositoryProvider).importAll(items);
      ref.invalidate(contentListProvider);
      if (context.mounted) _showSnack(context, '$count elementos importados');
    } catch (e) {
      if (context.mounted) _showSnack(context, 'Error al importar: $e', error: true);
    }
  }

  void _showSnack(BuildContext context, String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? const Color(0xFFFF6B6B) : AppColors.blue,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: GradientText('Myndex', style: AppTextStyles.headlineMd),
        content: Text(
          'Tu biblioteca personal de contenido.\nFilms, series, juegos, libros — todo en un sitio.',
          style: AppTextStyles.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar', style: TextStyle(color: AppColors.cyan)),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) {
    return GradientText(title, style: AppTextStyles.titleMd);
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(title, style: AppTextStyles.bodyLg),
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right, color: AppColors.textDisabled)
              : null),
    );
  }
}
