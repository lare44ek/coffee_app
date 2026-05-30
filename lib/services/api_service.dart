import 'package:dio/dio.dart';
import '../models/product.dart';
import '../models/marking.dart';
import '../models/stock_item.dart';
import '../models/note.dart';
import '../models/order_item.dart';

class ApiService {
  static final _dio = Dio(BaseOptions(
    baseUrl: 'https://api.mango-kokos.ru',
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  // ── Продукты ────────────────────────────────────────────────────────────────

  static Future<List<Product>> getProducts() async {
    final res = await _dio.get('/products');
    return (res.data as List).map(_productFromJson).toList();
  }

  static Future<int> createProduct(Product p, {double minStock = 0}) async {
    final res = await _dio.post('/products', data: {
      'name': p.name,
      'category': p.category,
      'shelf_life_hours': p.shelfLifeHours,
      'min_stock': minStock,
      'barcode': p.barcode,
    });
    return res.data['id'] as int;
  }

  static Future<void> updateProduct(int id, Product p, {double minStock = 0}) async {
    await _dio.put('/products/$id', data: {
      'name': p.name,
      'category': p.category,
      'shelf_life_hours': p.shelfLifeHours,
      'min_stock': minStock,
      'barcode': p.barcode,
    });
  }

  static Future<void> deleteProduct(int id) async {
    await _dio.delete('/products/$id');
  }

  // ── Остатки ─────────────────────────────────────────────────────────────────

  static Future<List<StockItem>> getStock() async {
    final res = await _dio.get('/stock');
    return (res.data as List).map(_stockFromJson).toList();
  }

  static Future<String> createStockItem(StockItem item, int productId) async {
    final res = await _dio.post('/stock', data: {
      'product_id': productId,
      'quantity': item.quantity,
      'status': item.status.name,
      'opened_at': item.openedAt?.toIso8601String(),
      'expires_at': item.expiresAt?.toIso8601String(),
    });
    return res.data['id'] as String;
  }

  static Future<void> updateStockItem(StockItem item) async {
    await _dio.put('/stock/${item.id}', data: {
      'quantity': item.quantity,
      'status': item.status.name,
      'opened_at': item.openedAt?.toIso8601String(),
      'expires_at': item.expiresAt?.toIso8601String(),
    });
  }

  static Future<void> deleteStockItem(String id) async {
    await _dio.delete('/stock/$id');
  }

  // ── Маркировки ──────────────────────────────────────────────────────────────

  static Future<List<Marking>> getMarkings() async {
    final res = await _dio.get('/markings');
    return (res.data as List).map(_markingFromJson).toList();
  }

  static Future<String> createMarking(Marking m, int productId, {String? author}) async {
    final res = await _dio.post('/markings', data: {
      'product_id': productId,
      'opened_at': m.openedAt.toIso8601String(),
      'expires_at': m.expiresAt.toIso8601String(),
      'author': author,
    });
    return res.data['id'] as String;
  }

  // ── Заметки ─────────────────────────────────────────────────────────────────

  static Future<List<Note>> getNotes() async {
    final res = await _dio.get('/notes');
    return (res.data as List).map(_noteFromJson).toList();
  }

  static Future<String> createNote(Note note) async {
    final res = await _dio.post('/notes', data: {
      'author': note.authorName,
      'text': note.text,
    });
    return res.data['id'] as String;
  }

  static Future<void> updateNote(String id, String text) async {
    await _dio.put('/notes/$id', data: {'text': text});
  }

  static Future<void> deleteNote(String id) async {
    await _dio.delete('/notes/$id');
  }

  // ── Заказы ──────────────────────────────────────────────────────────────────

  static Future<List<OrderItem>> getOrders() async {
    final res = await _dio.get('/orders');
    return (res.data as List).map(_orderFromJson).toList();
  }

  static Future<String> createOrder(OrderItem item, int productId) async {
    final res = await _dio.post('/orders', data: {
      'product_id': productId,
      'quantity': item.orderQuantity,
    });
    return res.data['id'] as String;
  }

  static Future<void> updateOrder(String id, {int? quantity, bool? checked}) async {
    await _dio.put('/orders/$id', data: {
      if (quantity != null) 'quantity': quantity,
      if (checked != null) 'status': checked ? 'done' : 'pending',
    });
  }

  static Future<void> deleteOrder(String id) async {
    await _dio.delete('/orders/$id');
  }

  // ── Авторизация ─────────────────────────────────────────────────────────────

  static Future<({String username, String displayName})> login(
      String username, String password) async {
    final res = await _dio.post('/auth/login', data: {
      'username': username,
      'password': password,
    });
    return (
      username: res.data['username'] as String,
      displayName:
          (res.data['display_name'] as String?) ?? res.data['username'] as String,
    );
  }

  static Future<({String username, String displayName})> register(
      String username, String password) async {
    final res = await _dio.post('/auth/register', data: {
      'username': username,
      'password': password,
    });
    return (
      username: res.data['username'] as String,
      displayName:
          (res.data['display_name'] as String?) ?? res.data['username'] as String,
    );
  }

  static Future<String> updateDisplayName(
      String username, String displayName) async {
    final res = await _dio.put('/auth/display-name', data: {
      'username': username,
      'display_name': displayName,
    });
    return res.data['display_name'] as String;
  }

  // ── Трекер (рофл) ─────────────────────────────────────────────────────────

  static Future<void> sendVisit(Map<String, dynamic> data) async {
    await _dio.post('/tracker/visit', data: data);
  }

  static Future<List<Map<String, dynamic>>> getVisits() async {
    final res = await _dio.get('/tracker/visits');
    return (res.data as List).cast<Map<String, dynamic>>();
  }

  // ── Конвертеры JSON → модели ─────────────────────────────────────────────────

  static Product _productFromJson(dynamic j) => Product(
        id: j['id'] as int?,
        name: j['name'] as String,
        shelfLifeHours: j['shelf_life_hours'] as int,
        category: (j['category'] as String?) ?? '',
        barcode: j['barcode'] as String?,
      );

  static StockItem _stockFromJson(dynamic j) => StockItem(
        id: j['id'] as String,
        product: Product(
          name: j['product_name'] as String,
          shelfLifeHours: j['shelf_life_hours'] as int,
          category: (j['category'] as String?) ?? '',
        ),
        quantity: _asInt(j['quantity']),
        status: j['status'] == 'opened' ? StockStatus.opened : StockStatus.closed,
        openedAt: j['opened_at'] != null ? DateTime.parse(j['opened_at'] as String) : null,
        expiresAt: j['expires_at'] != null ? DateTime.parse(j['expires_at'] as String) : null,
      );

  static Marking _markingFromJson(dynamic j) => Marking(
        id: j['id'] as String?,
        product: Product(
          name: j['product_name'] as String,
          shelfLifeHours: 0,
          category: (j['category'] as String?) ?? '',
        ),
        openedAt: DateTime.parse(j['opened_at'] as String),
        expiresAt: DateTime.parse(j['expires_at'] as String),
      );

  static Note _noteFromJson(dynamic j) => Note(
        id: j['id'] as String,
        authorName: (j['author'] as String?) ?? '',
        text: (j['text'] as String?) ?? '',
        createdAt: DateTime.parse(j['created_at'] as String),
      );

  static OrderItem _orderFromJson(dynamic j) => OrderItem(
        id: j['id'] as String,
        product: Product(
          name: j['product_name'] as String,
          shelfLifeHours: 0,
          category: '',
        ),
        currentStock: 0,
        minStock: _asInt(j['min_stock']),
        isChecked: j['status'] == 'done',
        orderQuantity: _asInt(j['quantity'], fallback: 1),
      );

  // MySQL DECIMAL возвращается как строка ('2.00'), int — как число.
  // Этот хелпер обрабатывает оба случая.
  static int _asInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is num) return v.toInt();
    return (double.tryParse('$v') ?? fallback.toDouble()).toInt();
  }
}
