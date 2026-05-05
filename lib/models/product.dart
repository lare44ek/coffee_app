// lib/models/product.dart

/// Продукт из каталога кофейни.
class Product {
  final String name;

  /// Срок годности после вскрытия — в часах.
  final int shelfLifeHours;

  const Product({
    required this.name,
    required this.shelfLifeHours,
  });
}
