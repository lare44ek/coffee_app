// lib/providers/app_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/marking.dart';
import '../models/stock_item.dart';
import '../models/note.dart';
import '../models/order_item.dart';
import '../models/catalog.dart';
import '../models/product.dart';
import '../services/api_service.dart';

// ---------------------------------------------------------------------------
// Каталог продуктов (из БД)
// ---------------------------------------------------------------------------

/// Загружает каталог с сервера. Заменяет хардкод [kProductCatalog].
///
/// Использование:
///   ref.watch(productsProvider).when(data:..., loading:..., error:...)
/// Обновить:
///   ref.invalidate(productsProvider)
final productsProvider = FutureProvider<List<Product>>((ref) async {
  return ApiService.getProducts();
});

// ---------------------------------------------------------------------------
// Маркировки
// ---------------------------------------------------------------------------

/// Хранит список маркировок, синхронизируется с API.
class MarkingsNotifier extends StateNotifier<List<Marking>> {
  MarkingsNotifier() : super(const []) {
    _load();
  }

  Future<void> _load() async {
    try {
      state = await ApiService.getMarkings();
    } catch (_) {}
  }

  Future<void> add(Marking marking, {String? author}) async {
    final tempId = 'tmp_${DateTime.now().millisecondsSinceEpoch}';
    final withTemp = Marking(
      id: tempId,
      product: marking.product,
      openedAt: marking.openedAt,
      expiresAt: marking.expiresAt,
    );
    state = [...state, withTemp];
    if (marking.product.id == null) return;
    try {
      final serverId = await ApiService.createMarking(
        marking,
        marking.product.id!,
        author: author,
      );
      state = state
          .map((m) => m.id == tempId
              ? Marking(
                  id: serverId,
                  product: m.product,
                  openedAt: m.openedAt,
                  expiresAt: m.expiresAt,
                )
              : m)
          .toList();
    } catch (_) {}
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

/// Отображаемое имя (реальные Фамилия Имя). Используется как автор
/// в заметках и маркировках. Логин остаётся в [currentUserProvider].
final displayNameProvider = StateProvider<String?>((ref) => null);

// ---------------------------------------------------------------------------
// Остатки
// ---------------------------------------------------------------------------

/// Хранит все позиции на складе (вскрытые и закрытые).
class StockNotifier extends StateNotifier<List<StockItem>> {
  StockNotifier() : super(const []) {
    _load();
  }

  Future<void> _load() async {
    try {
      state = await ApiService.getStock();
    } catch (_) {}
  }

  Future<void> add(StockItem item) async {
    state = [...state, item];
    if (item.product.id == null) return;
    try {
      final serverId = await ApiService.createStockItem(item, item.product.id!);
      state = state
          .map((s) => s.id == item.id
              ? StockItem(
                  id: serverId,
                  product: s.product,
                  quantity: s.quantity,
                  status: s.status,
                  openedAt: s.openedAt,
                  expiresAt: s.expiresAt,
                )
              : s)
          .toList();
    } catch (_) {}
  }

  Future<void> remove(String id) async {
    state = state.where((s) => s.id != id).toList();
    try {
      await ApiService.deleteStockItem(id);
    } catch (_) {
      await _load();
    }
  }

  Future<void> update(StockItem updated) async {
    state = state.map((s) => s.id == updated.id ? updated : s).toList();
    try {
      await ApiService.updateStockItem(updated);
    } catch (_) {
      await _load();
    }
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
  NotesNotifier() : super(const []) {
    _load();
  }

  Future<void> _load() async {
    try {
      state = await ApiService.getNotes();
    } catch (_) {}
  }

  Future<void> add(Note note) async {
    state = [note, ...state];
    try {
      final serverId = await ApiService.createNote(note);
      state = state
          .map((n) => n.id == note.id
              ? Note(
                  id: serverId,
                  authorName: n.authorName,
                  text: n.text,
                  createdAt: n.createdAt,
                )
              : n)
          .toList();
    } catch (_) {}
  }

  Future<void> update(Note updated) async {
    state = state.map((n) => n.id == updated.id ? updated : n).toList();
    try {
      await ApiService.updateNote(updated.id, updated.text);
    } catch (_) {
      await _load();
    }
  }

  Future<void> remove(String id) async {
    state = state.where((n) => n.id != id).toList();
    try {
      await ApiService.deleteNote(id);
    } catch (_) {
      await _load();
    }
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
