// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Хелпер для цветов, зависящих от текущей темы.
///
/// Использование:
///   Scaffold(backgroundColor: AppTheme.bg(context), ...)
///   Container(color: AppTheme.card(context), ...)
///   Text('...', style: TextStyle(color: AppTheme.onCard(context)))
abstract class AppTheme {
  // Тёмные аналоги фирменных цветов — тёплые кофейные оттенки.
  static const Color _darkBg   = Color(0xFF1C1816);
  static const Color _darkCard = Color(0xFF2E2724);

  /// Фон экрана (Scaffold).
  static Color bg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _darkBg
          : AppColors.background;

  /// Поверхность карточки / контейнера.
  static Color card(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _darkCard
          : Colors.white;

  /// Основной цвет текста — читаемый поверх [card] и [bg].
  static Color onCard(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : AppColors.text;

  // ── ThemeData ──────────────────────────────────────────────────────────────

  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          error: AppColors.warning,
          surface: Colors.white,
        ),
      );

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: _darkBg,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          error: AppColors.warning,
          surface: _darkCard,
        ),
      );
}
