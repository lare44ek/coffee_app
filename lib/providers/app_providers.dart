// lib/providers/app_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/marking.dart';
import '../models/stock_item.dart';
import '../models/note.dart';
import '../models/order_item.dart';
import '../models/catalog.dart';
import '../models/product.dart';

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

// ---------------------------------------------------------------------------
// Остатки
// ---------------------------------------------------------------------------

/// Хранит все позиции на складе (вскрытые и закрытые).
class StockNotifier extends StateNotifier<List<StockItem>> {
  StockNotifier() : super(_demo);

  // Тестовые данные — показывают оба состояния и подсветку истекающих.
  static final List<StockItem> _demo = [
    StockItem(
      id: 'demo_1',
      product: const Product(
          name: 'Молоко 3,2% (упаковка)', shelfLifeHours: 72),
      quantity: 2,
      status: StockStatus.opened,
      openedAt: DateTime.now().subtract(const Duration(hours: 60)),
      expiresAt: DateTime.now().add(const Duration(hours: 12)), // истекает скоро
    ),
    StockItem(
      id: 'demo_2',
      product: const Product(name: 'Сливки 10%', shelfLifeHours: 48),
      quantity: 1,
      status: StockStatus.opened,
      openedAt: DateTime.now().subtract(const Duration(hours: 6)),
      expiresAt: DateTime.now().add(const Duration(hours: 42)),
    ),
    StockItem(
      id: 'demo_3',
      product: const Product(
          name: 'Сироп ванильный', shelfLifeHours: 2160),
      quantity: 3,
      status: StockStatus.closed,
    ),
    StockItem(
      id: 'demo_4',
      product: const Product(name: 'Матча зеленая', shelfLifeHours: 8760),
      quantity: 1,
      status: StockStatus.closed,
    ),
  ];

  void add(StockItem item) {
    state = [...state, item];
  }

  void remove(String id) {
    state = state.where((item) => item.id != id).toList();
  }

  void update(StockItem updated) {
    state = state
        .map((item) => item.id == updated.id ? updated : item)
        .toList();
  }
}

final stockProvider =
    StateNotifierProvider<StockNotifier, List<StockItem>>(
  (ref) => StockNotifier(),
);

// ---------------------------------------------------------------------------
// Заметки смены
// ---------------------------------------------------------------------------

/// Список заметок — новые добавляются в начало.
class NotesNotifier extends StateNotifier<List<Note>> {
  NotesNotifier()
      : super([
          Note(
            id: 'demo_n1',
            authorName: 'Андрей Б.',
            text: 'Не забыть заказать молоко — заканчивается.',
            createdAt: DateTime(2025, 2, 2, 20, 30),
          ),
          Note(
            id: 'demo_n2',
            authorName: 'Дмитрий Уткин',
            text: 'Кофемашину протёр, всё чисто.',
            createdAt: DateTime(2025, 2, 2, 18, 0),
          ),
        ]);

  /// Добавить новую заметку в начало списка.
  void add(Note note) {
    state = [note, ...state];
  }

  void update(Note updated) {
    state = state.map((n) => n.id == updated.id ? updated : n).toList();
  }

  void remove(String id) {
    state = state.where((n) => n.id != id).toList();
  }
}

final notesProvider =
    StateNotifierProvider<NotesNotifier, List<Note>>(
  (ref) => NotesNotifier(),
);

// ---------------------------------------------------------------------------
// Заказ
// ---------------------------------------------------------------------------

/// Список позиций для заказа.
///
/// Авто-позиции (id = 'auto_*') вычисляются реактивно из [stockProvider]:
/// продукт попадает в заказ, если суммарный остаток ≤ минимуму из [kMinStock].
/// Ручные позиции (id = 'manual_*') добавляются пользователем через FAB.
class OrderNotifier extends StateNotifier<List<OrderItem>> {
  final Ref _ref;

  OrderNotifier(this._ref) : super([]) {
    // Слушаем изменения остатков и сразу пересчитываем заказ.
    // fireImmediately: true — первый расчёт происходит при инициализации.
    _ref.listen<List<StockItem>>(
      stockProvider,
      (_, stockItems) => _syncFromStock(stockItems),
      fireImmediately: true,
    );
  }

  /// Пересчитывает авто-позиции, сохраняя состояние чекбоксов
  /// и ручные добавления пользователя.
  void _syncFromStock(List<StockItem> stockItems) {
    // Суммируем количество по имени продукта.
    final totals = <String, int>{};
    final productMap = <String, Product>{};
    for (final item in stockItems) {
      totals[item.product.name] =
          (totals[item.product.name] ?? 0) + item.quantity;
      productMap[item.product.name] = item.product;
    }

    final autoItems = <OrderItem>[];
    for (final entry in totals.entries) {
      final min = kMinStock[entry.key] ?? 1;
      if (entry.value <= min) {
        // Сохраняем состояние чекбокса если позиция уже была в списке.
        final existing =
            state.where((o) => o.id == 'auto_${entry.key}').firstOrNull;
        autoItems.add(OrderItem(
          id: 'auto_${entry.key}',
          product: productMap[entry.key]!,
          currentStock: entry.value,
          minStock: min,
          isChecked: existing?.isChecked ?? false,
        ));
      }
    }

    // Ручные позиции — оставляем, но убираем те, что уже есть в авто.
    final autoNames = autoItems.map((o) => o.product.name).toSet();
    final manualItems = state
        .where((o) =>
            o.id.startsWith('manual_') &&
            !autoNames.contains(o.product.name))
        .toList();

    state = [...autoItems, ...manualItems];
  }

  void addManual(OrderItem item) {
    // Не добавляем дубликаты.
    if (state.any((o) => o.product.name == item.product.name)) return;
    state = [...state, item];
  }

  void updateOrderQuantity(String id, int quantity) {
    if (quantity < 1) return;
    state = state
        .map((o) => o.id == id ? o.copyWith(orderQuantity: quantity) : o)
        .toList();
  }

  void toggleCheck(String id) {
    state = state
        .map((o) => o.id == id ? o.copyWith(isChecked: !o.isChecked) : o)
        .toList();
  }

  void remove(String id) {
    state = state.where((o) => o.id != id).toList();
  }
}

final orderProvider =
    StateNotifierProvider<OrderNotifier, List<OrderItem>>(
  (ref) => OrderNotifier(ref),
);
