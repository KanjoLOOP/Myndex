import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds (Dark)
  static const bgPrimary   = Color(0xFF0B0F1A);
  static const bgSecondary = Color(0xFF121826);
  static const surface     = Color(0xFF1A2236);
  static const surfaceHigh = Color(0xFF1F2C42);

  // Backgrounds (Light)
  static const bgPrimaryLight   = Color(0xFFF3F4F6); // Gris muy claro
  static const bgSecondaryLight = Color(0xFFFFFFFF); // Blanco puro
  static const surfaceLight     = Color(0xFFF9FAFB); // Gris casi blanco
  static const surfaceHighLight = Color(0xFFE5E7EB); // Gris claro

  // Text (Dark)
  static const textPrimary   = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFA1A1AA);
  static const textDisabled  = Color(0xFF6B7280);

  // Text (Light)
  static const textPrimaryLight   = Color(0xFF111827);
  static const textSecondaryLight = Color(0xFF4B5563);
  static const textDisabledLight  = Color(0xFF9CA3AF);

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

  // Borders / dividers (Dark)
  static const border = Color(0xFF1F2C42);

  // Borders / dividers (Light)
  static const borderLight = Color(0xFFE5E7EB);
}
