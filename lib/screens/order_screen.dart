// lib/screens/order_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order_item.dart';
import '../models/product.dart';
import '../models/catalog.dart'; // kMinStock
import '../providers/app_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/product_picker_field.dart';

class OrderScreen extends ConsumerWidget {
  const OrderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(orderProvider);
    final unchecked = items.where((i) => !i.isChecked).toList();
    final checked = items.where((i) => i.isChecked).toList();

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: const AppHeader(title: 'Заказ'),
      body: items.isEmpty
          ? const Center(
              child: Text(
                'Всё в порядке!\nПродуктов для заказа нет.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                if (unchecked.isNotEmpty) ...[
                  Text(
                    'Необходимо заказать',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onCard(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...unchecked.map((item) => _OrderCard(item: item)),
                  const SizedBox(height: 20),
                ],
                if (checked.isNotEmpty) ...[
                  Text(
                    'Заказано (${checked.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...checked.map((item) => _OrderCard(item: item)),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'orderFab',
        onPressed: () => _showAddSheet(context, ref),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddOrderSheet(
        onAdd: (item) => ref.read(orderProvider.notifier).addManual(item),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Карточка позиции заказа (с раскрытием для редактирования кол-ва)
// ---------------------------------------------------------------------------

class _OrderCard extends ConsumerStatefulWidget {
  final OrderItem item;

  const _OrderCard({required this.item});

  @override
  ConsumerState<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends ConsumerState<_OrderCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppTheme.card(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _expanded ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Основная строка
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              leading: Checkbox(
                value: item.isChecked,
                onChanged: (_) =>
                    ref.read(orderProvider.notifier).toggleCheck(item.id),
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
              ),
              title: Builder(
                builder: (context) => Text(
                  item.product.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: item.isChecked ? Colors.grey : AppTheme.onCard(context),
                    decoration:
                        item.isChecked ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              subtitle: Text(
                'Остаток: ${item.currentStock} шт.',
                style: TextStyle(
                  fontSize: 13,
                  color: item.isChecked
                      ? Colors.grey.shade400
                      : AppColors.warning,
                  fontWeight:
                      item.isChecked ? FontWeight.normal : FontWeight.w600,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Количество к заказу
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: item.isChecked
                          ? Colors.grey.shade100
                          : AppColors.accent.withAlpha(40),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${item.orderQuantity} шт.',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: item.isChecked
                            ? Colors.grey
                            : AppColors.accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down,
                        color: Colors.grey, size: 20),
                  ),
                ],
              ),
            ),

            // Раскрывающаяся панель редактирования
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: _expanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 12, 12),
                      child: Row(
                        children: [
                          const Text(
                            'Заказать:',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                size: 22),
                            color: AppColors.primary,
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(4),
                            onPressed: item.orderQuantity > 1
                                ? () => ref
                                    .read(orderProvider.notifier)
                                    .updateOrderQuantity(
                                        item.id, item.orderQuantity - 1)
                                : null,
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              '${item.orderQuantity}',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline,
                                size: 22),
                            color: AppColors.primary,
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(4),
                            onPressed: () => ref
                                .read(orderProvider.notifier)
                                .updateOrderQuantity(
                                    item.id, item.orderQuantity + 1),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => ref
                                .read(orderProvider.notifier)
                                .remove(item.id),
                            icon: const Icon(Icons.close, size: 16),
                            label: const Text('Убрать'),
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Шторка ручного добавления в заказ
// ---------------------------------------------------------------------------

class _AddOrderSheet extends StatefulWidget {
  final void Function(OrderItem) onAdd;

  const _AddOrderSheet({required this.onAdd});

  @override
  State<_AddOrderSheet> createState() => _AddOrderSheetState();
}

class _AddOrderSheetState extends State<_AddOrderSheet> {
  Product? _product;
  int _stock = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ручка шторки
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text(
            'Добавить в заказ',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          ProductPickerField(
            value: _product,
            onChanged: (p) => setState(() => _product = p),
          ),
          const SizedBox(height: 16),

          // Текущий остаток
          Row(
            children: [
              const Text('Текущий остаток:', style: TextStyle(fontSize: 16)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                color: AppColors.primary,
                onPressed: () =>
                    setState(() => _stock = (_stock - 1).clamp(0, 99)),
              ),
              SizedBox(
                width: 32,
                child: Text(
                  '$_stock',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                color: AppColors.primary,
                onPressed: () =>
                    setState(() => _stock = (_stock + 1).clamp(0, 99)),
              ),
              const Text('шт.',
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _product == null
                ? null
                : () {
                    widget.onAdd(
                      OrderItem(
                        id:
                            'manual_${DateTime.now().millisecondsSinceEpoch}',
                        product: _product!,
                        currentStock: _stock,
                        minStock: kMinStock[_product!.name] ?? 1,
                      ),
                    );
                    Navigator.pop(context);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Добавить',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

