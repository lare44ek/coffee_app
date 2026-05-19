// lib/models/stock_item.dart
import 'package:flutter/foundation.dart';
import 'product.dart';

enum StockStatus { closed, opened }

/// Позиция продукта на складе кофейни.
@immutable
class StockItem {
  final String id;
  final Product product;
  final int quantity;
  final StockStatus status;

  /// Заполняется только для вскрытых позиций.
  final DateTime? openedAt;
  final DateTime? expiresAt;

  const StockItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.status,
    this.openedAt,
    this.expiresAt,
  });

  /// Истекает в ближайшие 24 часа — подсвечиваем красным.
  bool get isExpiringSoon {
    if (status != StockStatus.opened || expiresAt == null) return false;
    return expiresAt!.difference(DateTime.now()).inHours <= 24;
  }

  StockItem copyWith({
    int? quantity,
    StockStatus? status,
    DateTime? openedAt,
    DateTime? expiresAt,
  }) {
    return StockItem(
      id: id,
      product: product,
      quantity: quantity ?? this.quantity,
      status: status ?? this.status,
      openedAt: openedAt ?? this.openedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
