// lib/models/marking.dart
import 'product.dart';

/// Одна запись о вскрытии продукта.
class Marking {
  final String? id;
  final Product product;
  final DateTime openedAt;
  final DateTime expiresAt;

  const Marking({
    this.id,
    required this.product,
    required this.openedAt,
    required this.expiresAt,
  });

  /// Строка для отображения на экране маркировки (формат DD.MM HHMM).
  String get openedLine => _fmt(openedAt);
  String get expiresLine => _fmt(expiresAt);

  /// Текст для карточки истории.
  String get historyText => '${product.name}\n$openedLine\n$expiresLine';

  static String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}${dt.minute.toString().padLeft(2, '0')}';
}
