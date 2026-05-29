// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'main_app.dart';
import 'providers/app_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final savedUser = prefs.getString('username');
  final savedName = prefs.getString('display_name');

  runApp(
    ProviderScope(
      overrides: [
        if (savedUser != null)
          currentUserProvider.overrideWith((ref) => savedUser),
        if (savedName != null)
          displayNameProvider.overrideWith((ref) => savedName),
      ],
      child: CoffeeApp(initialUser: savedUser),
    ),
  );
}

class CoffeeApp extends StatelessWidget {
  final String? initialUser;
  const CoffeeApp({super.key, this.initialUser});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.brown,
        useMaterial3: true,
      ),
      home: initialUser != null ? const MainApp() : const LoginPage(),
    );
  }
}
