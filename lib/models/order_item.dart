// lib/models/order_item.dart
import 'package:flutter/foundation.dart';
import 'product.dart';

/// Позиция в списке заказа.
@immutable
class OrderItem {
  final String id;
  final Product product;

  /// Текущий остаток на момент добавления в заказ.
  final int currentStock;

  /// Минимальный порог — ниже него продукт попадает в заказ автоматически.
  final int minStock;

  final bool isChecked;

  /// Сколько единиц нужно заказать — редактируется пользователем.
  /// По умолчанию = minStock - currentStock (сколько не хватает до минимума),
  /// но не меньше 1.
  final int orderQuantity;

  const OrderItem({
    required this.id,
    required this.product,
    required this.currentStock,
    required this.minStock,
    this.isChecked = false,
    int? orderQuantity,
  }) : orderQuantity = orderQuantity ?? (minStock - currentStock < 1 ? 1 : minStock - currentStock);

  OrderItem copyWith({int? currentStock, bool? isChecked, int? orderQuantity}) {
    return OrderItem(
      id: id,
      product: product,
      currentStock: currentStock ?? this.currentStock,
      minStock: minStock,
      isChecked: isChecked ?? this.isChecked,
      orderQuantity: orderQuantity ?? this.orderQuantity,
    );
  }
}
