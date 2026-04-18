// lib/history_screen.dart
import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  final List<String> history; // Список маркировок, который будет передан сюда

  const HistoryScreen({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('История маркировок'),
        backgroundColor:  Color.fromRGBO(175, 146, 133, 1),
        foregroundColor: Color.fromRGBO(245, 245, 245, 1),
      ),
      body: history.isEmpty
          ? const Center(
              child: Text(
                'История пуста.\nСканируйте QR или сгенерируйте метку!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                // Отображаем каждую маркировку в карточке
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      history[history.length - 1 - index], // Показываем в обратном порядке (новые сверху)
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
