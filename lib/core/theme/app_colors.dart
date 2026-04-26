import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const bgPrimary   = Color(0xFF0B0F1A);
  static const bgSecondary = Color(0xFF121826);
  static const surface     = Color(0xFF1A2236);
  static const surfaceHigh = Color(0xFF1F2C42);

  // Text
  static const textPrimary   = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFA1A1AA);
  static const textDisabled  = Color(0xFF6B7280);

  // Gradient stops
  static const cyan    = Color(0xFF22D3EE);
  static const blue    = Color(0xFF3B82F6);
  static const purple  = Color(0xFF8B5CF6);
  static const magenta = Color(0xFFD946EF);

  // Gradient
  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.33, 0.66, 1.0],
    colors: [cyan, blue, purple, magenta],
  );

  // Gradient horizontal (chips, nav pill, etc.)
  static const gradientH = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    stops: [0.0, 0.33, 0.66, 1.0],
    colors: [cyan, blue, purple, magenta],
  );

  // Status
  static const statusPending    = Color(0xFFA1A1AA);
  static const statusInProgress = Color(0xFF3B82F6);
  static const statusCompleted  = Color(0xFF22D3EE);
  static const statusDropped    = Color(0xFF6B7280);

  // Borders / dividers
  static const border = Color(0xFF1F2C42);
}
