// lib/providers/app_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/marking.dart';

// ---------------------------------------------------------------------------
// Маркировки
// ---------------------------------------------------------------------------

/// Хранит список всех сгенерированных маркировок за сессию.
///
/// Использование:
///   Читать:  ref.watch(markingsProvider)
///   Писать:  ref.read(markingsProvider.notifier).add(marking)
class MarkingsNotifier extends StateNotifier<List<Marking>> {
  MarkingsNotifier() : super(const []);

  void add(Marking marking) {
    // StateNotifier требует замены всего объекта state,
    // а не мутации — поэтому spread-оператор, а не .add()
    state = [...state, marking];
  }
}

final markingsProvider =
    StateNotifierProvider<MarkingsNotifier, List<Marking>>(
  (ref) => MarkingsNotifier(),
);

// ---------------------------------------------------------------------------
// Текущий пользователь
// ---------------------------------------------------------------------------

/// Логин залогиненного пользователя. null — не авторизован.
///
/// Пока хранит просто строку; когда появится модель User с ролью —
/// заменить тип на User? без изменений в остальном коде.
///
/// Использование:
///   Читать:  ref.watch(currentUserProvider)
///   Писать:  ref.read(currentUserProvider.notifier).state = login
final currentUserProvider = StateProvider<String?>((ref) => null);
