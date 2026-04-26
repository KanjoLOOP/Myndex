import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const _inter     = 'Inter';
  static const _workSans  = 'WorkSans';

  static const displayLg = TextStyle(
    fontFamily: _inter,
    fontSize: 57,
    fontWeight: FontWeight.w700,
    height: 64 / 57,
    letterSpacing: -0.25,
    color: AppColors.textPrimary,
  );

  static const headlineLg = TextStyle(
    fontFamily: _inter,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 40 / 32,
    color: AppColors.textPrimary,
  );

  static const headlineMd = TextStyle(
    fontFamily: _inter,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const titleLg = TextStyle(
    fontFamily: _inter,
    fontSize: 22,
    fontWeight: FontWeight.w500,
    height: 28 / 22,
    color: AppColors.textPrimary,
  );

  static const titleMd = TextStyle(
    fontFamily: _inter,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const bodyLg = TextStyle(
    fontFamily: _inter,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
  );

  static const bodyMd = TextStyle(
    fontFamily: _inter,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const labelMd = TextStyle(
    fontFamily: _workSans,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
    letterSpacing: 0.5,
    color: AppColors.textSecondary,
  );

  static const labelSm = TextStyle(
    fontFamily: _workSans,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: AppColors.textDisabled,
  );
}
