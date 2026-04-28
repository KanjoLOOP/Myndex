import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData dark() {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary:           AppColors.cyan,
      onPrimary:         AppColors.bgPrimary,
      primaryContainer:  AppColors.surface,
      onPrimaryContainer: AppColors.cyan,
      secondary:         AppColors.blue,
      onSecondary:       AppColors.textPrimary,
      secondaryContainer: AppColors.surfaceHigh,
      onSecondaryContainer: AppColors.textPrimary,
      tertiary:          AppColors.purple,
      onTertiary:        AppColors.textPrimary,
      tertiaryContainer: AppColors.surface,
      onTertiaryContainer: AppColors.purple,
      error:             Color(0xFFFF6B6B),
      onError:           AppColors.bgPrimary,
      errorContainer:    Color(0xFF3D0000),
      onErrorContainer:  Color(0xFFFF6B6B),
      surface:           AppColors.bgPrimary,
      onSurface:         AppColors.textPrimary,
      onSurfaceVariant:  AppColors.textSecondary,
      outline:           AppColors.border,
      outlineVariant:    AppColors.surface,
      shadow:            Colors.black,
      scrim:             Colors.black54,
      inverseSurface:    AppColors.textPrimary,
      onInverseSurface:  AppColors.bgPrimary,
      inversePrimary:    AppColors.blue,
      surfaceTint:       AppColors.cyan,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.bgPrimary,
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgPrimary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
        ),
        titleTextStyle: AppTextStyles.titleLg,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      // Cards
      cardTheme: CardThemeData(
        color: AppColors.bgSecondary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      // BottomNav
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.bgSecondary,
        indicatorColor: AppColors.blue.withValues(alpha: 0.2),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.cyan, size: 24);
          }
          return const IconThemeData(color: AppColors.textDisabled, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.labelMd.copyWith(color: AppColors.cyan);
          }
          return AppTextStyles.labelMd;
        }),
        elevation: 0,
        height: 72,
      ),
      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cyan, width: 1.5),
        ),
        hintStyle: AppTextStyles.bodyMd,
        labelStyle: AppTextStyles.bodyMd,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.blue.withValues(alpha: 0.25),
        labelStyle: AppTextStyles.labelMd.copyWith(color: AppColors.textSecondary),
        side: const BorderSide(color: AppColors.border),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      // Dividers
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      // Text
      textTheme: const TextTheme(
        displayLarge:  AppTextStyles.displayLg,
        headlineLarge: AppTextStyles.headlineLg,
        headlineMedium: AppTextStyles.headlineMd,
        titleLarge:    AppTextStyles.titleLg,
        titleMedium:   AppTextStyles.titleMd,
        bodyLarge:     AppTextStyles.bodyLg,
        bodyMedium:    AppTextStyles.bodyMd,
        labelMedium:   AppTextStyles.labelMd,
        labelSmall:    AppTextStyles.labelSm,
      ),
      // List tiles
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
        textColor: AppColors.textPrimary,
        iconColor: AppColors.textSecondary,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  static ThemeData light() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary:           AppColors.blue, // Usamos azul en lugar de cyan para mejor contraste en modo claro
      onPrimary:         AppColors.bgPrimaryLight,
      primaryContainer:  AppColors.surfaceLight,
      onPrimaryContainer: AppColors.blue,
      secondary:         AppColors.cyan,
      onSecondary:       AppColors.textPrimaryLight,
      secondaryContainer: AppColors.surfaceHighLight,
      onSecondaryContainer: AppColors.textPrimaryLight,
      tertiary:          AppColors.purple,
      onTertiary:        AppColors.textPrimaryLight,
      tertiaryContainer: AppColors.surfaceLight,
      onTertiaryContainer: AppColors.purple,
      error:             Color(0xFFE53E3E),
      onError:           AppColors.bgPrimaryLight,
      errorContainer:    Color(0xFFFED7D7),
      onErrorContainer:  Color(0xFFE53E3E),
      surface:           AppColors.bgPrimaryLight,
      onSurface:         AppColors.textPrimaryLight,
      onSurfaceVariant:  AppColors.textSecondaryLight,
      outline:           AppColors.borderLight,
      outlineVariant:    AppColors.surfaceLight,
      shadow:            Colors.black12,
      scrim:             Colors.black54,
      inverseSurface:    AppColors.textPrimaryLight,
      onInverseSurface:  AppColors.bgPrimaryLight,
      inversePrimary:    AppColors.blue,
      surfaceTint:       AppColors.blue,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.bgPrimaryLight,
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgPrimaryLight,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),
        titleTextStyle: AppTextStyles.titleLg.copyWith(color: AppColors.textPrimaryLight),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryLight),
      ),
      // Cards
      cardTheme: CardThemeData(
        color: AppColors.bgSecondaryLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      // BottomNav
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.bgSecondaryLight,
        indicatorColor: AppColors.blue.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.blue, size: 24);
          }
          return const IconThemeData(color: AppColors.textDisabledLight, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.labelMd.copyWith(color: AppColors.blue);
          }
          return AppTextStyles.labelMd.copyWith(color: AppColors.textDisabledLight);
        }),
        elevation: 0,
        height: 72,
      ),
      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
        ),
        hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.textDisabledLight),
        labelStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondaryLight),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedColor: AppColors.blue.withValues(alpha: 0.15),
        labelStyle: AppTextStyles.labelMd.copyWith(color: AppColors.textSecondaryLight),
        side: const BorderSide(color: AppColors.borderLight),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      // Dividers
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
        space: 1,
      ),
      // Text
      textTheme: TextTheme(
        displayLarge:  AppTextStyles.displayLg.copyWith(color: AppColors.textPrimaryLight),
        headlineLarge: AppTextStyles.headlineLg.copyWith(color: AppColors.textPrimaryLight),
        headlineMedium: AppTextStyles.headlineMd.copyWith(color: AppColors.textPrimaryLight),
        titleLarge:    AppTextStyles.titleLg.copyWith(color: AppColors.textPrimaryLight),
        titleMedium:   AppTextStyles.titleMd.copyWith(color: AppColors.textPrimaryLight),
        bodyLarge:     AppTextStyles.bodyLg.copyWith(color: AppColors.textPrimaryLight),
        bodyMedium:    AppTextStyles.bodyMd.copyWith(color: AppColors.textPrimaryLight),
        labelMedium:   AppTextStyles.labelMd.copyWith(color: AppColors.textSecondaryLight),
        labelSmall:    AppTextStyles.labelSm.copyWith(color: AppColors.textSecondaryLight),
      ),
      // List tiles
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
        textColor: AppColors.textPrimaryLight,
        iconColor: AppColors.textSecondaryLight,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
