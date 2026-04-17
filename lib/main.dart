// lib/main.dart
import 'package:flutter/material.dart';
import 'login_page.dart'; // Импортируем LoginPage

void main() {
  runApp(const CoffeeApp());
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
      // Теперь стартуем с LoginPage
      home: const LoginPage(),
      // Убираем routes или другие настройки home, если были
    );
  }
}