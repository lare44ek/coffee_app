// lib/models/product.dart

/// Продукт из каталога кофейни.
class Product {
  /// id из БД. null — для локально созданных (демо/оффлайн) продуктов.
  final int? id;

  final String name;

  /// Срок годности после вскрытия — в часах.
  final int shelfLifeHours;

  /// Категория для группировки в UI. Пустая строка = без категории.
  final String category;

  /// Штрих-код (EAN-13) для поиска при сканировании.
  /// null — у локальных/демо-продуктов и пока код не привязан.
  final String? barcode;

  const Product({
    this.id,
    required this.name,
    required this.shelfLifeHours,
    this.category = '',
    this.barcode,
  });
}
