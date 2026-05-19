// lib/main_app.dart
import 'package:flutter/material.dart';
import 'label_generator_page.dart';
import 'screens/stock_screen.dart';
import 'screens/notes_screen.dart';
import 'screens/order_screen.dart';
import 'theme/app_colors.dart';

// Обычный StatefulWidget — ref здесь не нужен,
// единственный локальный стейт это индекс нижнего меню.
class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0;

  static const _screens = [
    LabelGeneratorPage(),
    StockScreen(),
    NotesScreen(),
    OrderScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.label_outline),
            activeIcon: Icon(Icons.label),
            label: 'Маркировка',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Остатки',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sticky_note_2_outlined),
            activeIcon: Icon(Icons.sticky_note_2),
            label: 'Заметки',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            activeIcon: Icon(Icons.shopping_cart),
            label: 'Заказ',
          ),
        ],
      ),
    );
  }
}
