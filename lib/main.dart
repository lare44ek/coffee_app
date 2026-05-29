// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'main_app.dart';
import 'providers/app_providers.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final savedUser = prefs.getString('username');
  final savedName = prefs.getString('display_name');
  final savedAvatar = prefs.getString('avatar_url');
  // Читаем тему до старта, чтобы не было мигания светлой темы при запуске.
  final isDark = prefs.getBool('dark_mode') ?? false;

  runApp(
    ProviderScope(
      overrides: [
        if (savedUser != null)
          currentUserProvider.overrideWith((ref) => savedUser),
        if (savedName != null)
          displayNameProvider.overrideWith((ref) => savedName),
        if (savedAvatar != null)
          avatarUrlProvider.overrideWith((ref) => savedAvatar),
        themeModeProvider.overrideWith(
          (ref) => ThemeModeNotifier(isDark ? ThemeMode.dark : ThemeMode.light),
        ),
      ],
      child: CoffeeApp(initialUser: savedUser),
    ),
  );
}

class CoffeeApp extends ConsumerWidget {
  final String? initialUser;
  const CoffeeApp({super.key, this.initialUser});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: initialUser != null ? const MainApp() : const LoginPage(),
    );
  }
}
