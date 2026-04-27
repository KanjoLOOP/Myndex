import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/security/safe_error_message.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_text.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../backup/presentation/providers/backup_providers.dart';
import '../../../content/presentation/providers/content_providers.dart';

/// Pantalla de Ajustes.
///
/// Aquí viven las acciones globales: export/import del backup JSON,
/// preferencias de apariencia y enlaces informativos. Toda la lógica
/// real de backup vive en [BackupService]; esta página es solo glue.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        titleSpacing: 20,
        title: const Text('Ajustes', style: AppTextStyles.titleLg),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          // ── Gestión de datos ──────────────────────────────────────
          _SectionHeader('Gestión de datos'),
          const SizedBox(height: 10),
          _SettingsGroup(children: [
            _SettingsTile(
              icon: Icons.upload_outlined,
              iconColor: AppColors.cyan,
              title: 'Exportar biblioteca (JSON)',
              onTap: () => _export(context, ref),
            ),
            Divider(color: Theme.of(context).dividerColor, height: 1),
            _SettingsTile(
              icon: Icons.download_outlined,
              iconColor: AppColors.cyan,
              title: 'Importar biblioteca (JSON)',
              onTap: () => _import(context, ref),
            ),
          ]),

          const SizedBox(height: 24),
          // ── Apariencia ────────────────────────────────────────────
          _SectionHeader('Apariencia'),
          const SizedBox(height: 10),
          _SettingsGroup(children: [
            _SettingsTile(
              icon: Icons.dark_mode_outlined,
              iconColor: AppColors.cyan,
              title: 'Modo oscuro',
              trailing: Switch(
                value: ref.watch(themeProvider) == ThemeMode.dark,
                onChanged: (_) => ref.read(themeProvider.notifier).toggleTheme(),
                activeColor: AppColors.cyan,
                activeTrackColor: AppColors.blue.withOpacity(0.4),
              ),
            ),
            Divider(color: Theme.of(context).dividerColor, height: 1),
            _SettingsTile(
              icon: Icons.palette_outlined,
              iconColor: AppColors.cyan,
              title: 'Color del tema',
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (b) => AppColors.gradientH.createShader(
                      Rect.fromLTWH(0, 0, b.width, b.height)),
                  child: const Text('Gradiente Neón',
                      style: AppTextStyles.bodyMd),
                ),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurfaceVariant, size: 18),
              ]),
            ),
          ]),

          const SizedBox(height: 24),
          // ── General ───────────────────────────────────────────────
          _SectionHeader('General'),
          const SizedBox(height: 10),
          _SettingsGroup(children: [
            _SettingsTile(
              icon: Icons.help_outline,
              iconColor: AppColors.cyan,
              title: 'Ayuda y soporte',
              onTap: () {},
            ),
            Divider(color: Theme.of(context).dividerColor, height: 1),
            _SettingsTile(
              icon: Icons.info_outline,
              iconColor: AppColors.cyan,
              title: 'Acerca de Myndex',
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

  // ─── Acciones ───────────────────────────────────────────────────

  /// Genera el backup, lo escribe en el directorio privado de la app
  /// y abre el sheet de compartir para que el usuario lo guarde
  /// donde quiera (Drive, email, almacenamiento local…).
  Future<void> _export(BuildContext context, WidgetRef ref) async {
    try {
      final service = ref.read(backupServiceProvider);
      final dir = await getApplicationDocumentsDirectory();
      final path = await service.exportToFile(dir);
      if (!context.mounted) return;
      await Share.shareXFiles(
        [XFile(path)],
        text: 'Copia de seguridad Myndex',
      );
    } catch (e) {
      if (!context.mounted) return;
      _showSnack(context, SafeErrorMessage.forUser(e), error: true);
    }
  }

  /// Permite al usuario elegir un fichero JSON y lo importa.
  /// Por defecto se omiten duplicados (mismo título + tipo).
  Future<void> _import(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        // No retenemos el dato fuera de uso, el picker libera el tmp.
        withData: false,
      );
      final path = result?.files.single.path;
      if (path == null) return;

      final service = ref.read(backupServiceProvider);
      final count = await service.importFromFile(path);
      ref.invalidate(contentListProvider);
      if (!context.mounted) return;
      _showSnack(context, '$count elementos importados');
    } catch (e) {
      if (!context.mounted) return;
      _showSnack(context, SafeErrorMessage.forUser(e), error: true);
    }
  }

  // ─── Utilidades de UI ───────────────────────────────────────────

  void _showSnack(BuildContext context, String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor:
          error ? const Color(0xFFFF6B6B) : AppColors.blue,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: GradientText('Myndex', style: AppTextStyles.headlineMd),
        content: Text(
          'Tu biblioteca personal de contenido.\n'
          'Films, series, juegos, libros — todo en un sitio.',
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

// ─── Sub-widgets ──────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) =>
      GradientText(title, style: AppTextStyles.titleMd);
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
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
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(title, style: AppTextStyles.bodyLg.copyWith(color: Theme.of(context).colorScheme.onSurface)),
      trailing: trailing ??
          (onTap != null
              ? Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant)
              : null),
    );
  }
}
