// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'login_page.dart';

void main() {
  runApp(
    // ProviderScope — обязательная обёртка: хранит все провайдеры приложения.
    // Должна быть ровно одна, в самом корне дерева.
    const ProviderScope(
      child: CoffeeApp(),
    ),
  );
}

class CoffeeApp extends StatelessWidget {
  const CoffeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.brown,
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}
