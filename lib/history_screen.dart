// lib/history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/app_providers.dart';
import 'widgets/app_header.dart';

// ConsumerWidget — как StatelessWidget, но с доступом к ref.
// Параметр history в конструкторе больше не нужен: экран сам читает данные.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch перестраивает виджет каждый раз, когда список меняется.
    final history = ref.watch(markingsProvider);

    return Scaffold(
      appBar: const AppHeader(title: 'История'),
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
                // Новые записи сверху
                final marking = history[history.length - 1 - index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      marking.historyText,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
