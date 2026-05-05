// lib/widgets/app_header.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Единая шапка для всех экранов приложения.
///
/// Использование:
/// ```dart
/// appBar: AppHeader(title: 'Маркировка'),
/// appBar: AppHeader(title: 'История', actions: [IconButton(...)]),
/// ```
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const AppHeader({
    super.key,
    required this.title,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      toolbarHeight: 80,
      flexibleSpace: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (actions != null)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: actions!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
