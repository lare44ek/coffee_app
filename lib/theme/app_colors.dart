// lib/theme/app_colors.dart
import 'package:flutter/material.dart';

/// Цветовая палитра Effoc — токены из Figma.
/// Используй эти константы везде вместо Color.fromRGBO(...).
abstract class AppColors {
  /// Фон — #F5F5F5
  static const Color background = Color(0xFFF5F5F5);

  /// Основной (шапка, акцентные элементы) — #AF9285
  static const Color primary = Color(0xFFAF9285);

  /// Текст — #212121
  static const Color text = Color(0xFF212121);

  /// Внимание (предупреждения, истекающие позиции) — #FF7E61
  static const Color warning = Color(0xFFFF7E61);

  /// Акцент (кнопки действий) — #FABF68
  static const Color accent = Color(0xFFFABF68);
}
