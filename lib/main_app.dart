// lib/main_app.dart
import 'package:flutter/material.dart';
import 'label_generator_page.dart'; // Импортируем генератор
import 'history_screen.dart';      // Импортируем историю

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0; // Индекс выбранного экрана
  List<String> _history = []; // Список маркировок

  // Метод для добавления в историю
  void _addToHistory(String label) {
    setState(() {
      _history.add(label);
    });
  }

  // Убираем final List<Widget> _screens

  @override
  Widget build(BuildContext context) {
    // Теперь мы создаем список экранов прямо тут, в build
    final List<Widget> screens = [
      // LabelGeneratorPage теперь принимает callback
      // Мы передаём ему метод _addToHistory
      // Builder больше не нужен, так как мы внутри build
      LabelGeneratorPage(addToHistory: _addToHistory),
      // Обновляем HistoryScreen, передавая ему актуальный список
      HistoryScreen(history: _history),
    ];

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.brown,
        useMaterial3: true,
      ),
      home: Scaffold(
        body: IndexedStack( // IndexedStack отображает только один виджет из списка по индексу
          index: _selectedIndex,
          children: screens, // <-- Передаём сюда созданный в build список
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.label_outline),
              label: 'Маркировка',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'История',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed, // Все иконки фиксированного размера
        ),
      ),
    );
  }
}