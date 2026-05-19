// lib/models/product.dart

/// Продукт из каталога кофейни.
class Product {
  final String name;

  /// Срок годности после вскрытия — в часах.
  final int shelfLifeHours;

  /// Категория для группировки в UI. Пустая строка = без категории.
  final String category;

  const Product({
    required this.name,
    required this.shelfLifeHours,
    this.category = '',
  });
}
