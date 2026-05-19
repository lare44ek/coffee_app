// lib/screens/stock_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/stock_item.dart';
import '../models/product.dart';

import '../providers/app_providers.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header.dart';
import '../widgets/product_picker_field.dart';
import '../qr_scanner_screen.dart';

class StockScreen extends ConsumerWidget {
  const StockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(stockProvider);
    // Вскрытые — сортируем по дате истечения (самые срочные сверху).
    final opened = items.where((i) => i.status == StockStatus.opened).toList()
      ..sort((a, b) {
        if (a.expiresAt == null && b.expiresAt == null) return 0;
        if (a.expiresAt == null) return 1;
        if (b.expiresAt == null) return -1;
        return a.expiresAt!.compareTo(b.expiresAt!);
      });
    final closed = items.where((i) => i.status == StockStatus.closed).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(title: 'Остатки'),
      body: items.isEmpty
          ? const Center(
              child: Text(
                'Продуктов нет.\nНажмите + чтобы добавить.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                if (opened.isNotEmpty) ...[
                  _SectionHeader(title: 'Вскрыто', count: opened.length),
                  const SizedBox(height: 8),
                  ...opened.map((item) => _StockCard(item: item)),
                  const SizedBox(height: 20),
                ],
                if (closed.isNotEmpty) ...[
                  _SectionHeader(title: 'Закрыто', count: closed.length),
                  const SizedBox(height: 8),
                  ...closed.map((item) => _StockCard(item: item)),
                ],
              ],
            ),
      floatingActionButton: const _SpeedDialFab(),
    );
  }
}

// ---------------------------------------------------------------------------
// Заголовок секции
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(40),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Карточка продукта (с раскрытием по тапу)
// ---------------------------------------------------------------------------

class _StockCard extends ConsumerStatefulWidget {
  final StockItem item;

  const _StockCard({required this.item});

  @override
  ConsumerState<_StockCard> createState() => _StockCardState();
}

class _StockCardState extends ConsumerState<_StockCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isWarn = item.isExpiringSoon;
    final isClosed = item.status == StockStatus.closed;

    final bgColor = isWarn ? AppColors.warning.withAlpha(35) : Colors.white;
    final borderColor = _expanded
        ? AppColors.primary
        : (isWarn ? AppColors.warning : Colors.transparent);
    final borderWidth = (_expanded || isWarn) ? 1.5 : 0.0;

    return Padding(
      // Отступ снаружи Dismissible — иначе фон свайпа выходит за карточку.
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        // Обрезаем фон удаления по скруглённым углам карточки.
        borderRadius: BorderRadius.circular(12),
        child: Dismissible(
          key: Key(item.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: AppColors.warning.withAlpha(200),
            child: const Icon(Icons.delete_outline, color: Colors.white, size: 26),
          ),
          onDismissed: (_) => ref.read(stockProvider.notifier).remove(item.id),
          child: GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: borderWidth),
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
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (isWarn)
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.warning,
                          size: 18,
                        ),
                      ),
                  ],
                ),
                subtitle: item.status == StockStatus.opened &&
                        item.expiresAt != null
                    ? Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Истекает: ${_fmtDateTime(item.expiresAt!)}',
                          style: TextStyle(
                            color: isWarn
                                ? AppColors.warning
                                : Colors.grey.shade600,
                            fontWeight: isWarn
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      )
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${item.quantity} шт.',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
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

              // Раскрывающаяся панель
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: _expanded
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 12, 12),
                        child: isClosed
                            ? _ClosedExpansion(item: item)
                            : _OpenedExpansion(item: item),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),        // GestureDetector
        ),      // Dismissible
      ),        // ClipRRect
    );          // Padding
  }

  static String _fmtDateTime(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// Раскрытое состояние для закрытого продукта: изменение кол-ва + удаление
class _ClosedExpansion extends ConsumerWidget {
  final StockItem item;

  const _ClosedExpansion({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        const Text(
          'Кол-во:',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(width: 6),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, size: 22),
          color: AppColors.primary,
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(4),
          onPressed: item.quantity > 1
              ? () => ref
                  .read(stockProvider.notifier)
                  .update(item.copyWith(quantity: item.quantity - 1))
              : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            '${item.quantity}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 22),
          color: AppColors.primary,
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(4),
          onPressed: () => ref
              .read(stockProvider.notifier)
              .update(item.copyWith(quantity: item.quantity + 1)),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: () =>
              ref.read(stockProvider.notifier).remove(item.id),
          icon: const Icon(Icons.delete_outline, size: 16),
          label: const Text('Удалить'),
          style: TextButton.styleFrom(foregroundColor: AppColors.warning),
        ),
      ],
    );
  }
}

// Раскрытое состояние для вскрытого продукта: только удаление
class _OpenedExpansion extends ConsumerWidget {
  final StockItem item;

  const _OpenedExpansion({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          onPressed: () =>
              ref.read(stockProvider.notifier).remove(item.id),
          icon: const Icon(Icons.delete_outline, size: 16),
          label: const Text('Удалить'),
          style: TextButton.styleFrom(foregroundColor: AppColors.warning),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Speed-dial FAB
// ---------------------------------------------------------------------------

class _SpeedDialFab extends ConsumerStatefulWidget {
  const _SpeedDialFab();

  @override
  ConsumerState<_SpeedDialFab> createState() => _SpeedDialFabState();
}

class _SpeedDialFabState extends ConsumerState<_SpeedDialFab>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    _open ? _ctrl.forward() : _ctrl.reverse();
  }

  void _close() {
    if (_open) _toggle();
  }

  void _onManual() {
    _close();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddManualSheet(
        onAdd: (item) => ref.read(stockProvider.notifier).add(item),
      ),
    );
  }

  void _onScan() {
    _close();
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const QRScannerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Опции выше кнопки
        ScaleTransition(
          scale: _anim,
          child: FadeTransition(
            opacity: _anim,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _FabOption(
                  label: 'Сканировать код',
                  icon: Icons.qr_code_scanner,
                  onTap: _onScan,
                ),
                const SizedBox(height: 8),
                _FabOption(
                  label: 'Из списка',
                  icon: Icons.list_alt_rounded,
                  onTap: _onManual,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        FloatingActionButton(
          onPressed: _toggle,
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          child: AnimatedRotation(
            turns: _open ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.add, size: 30),
          ),
        ),
      ],
    );
  }
}

class _FabOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _FabOption({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(30),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Шторка ручного добавления продукта
// ---------------------------------------------------------------------------

class _AddManualSheet extends StatefulWidget {
  final void Function(StockItem) onAdd;

  const _AddManualSheet({required this.onAdd});

  @override
  State<_AddManualSheet> createState() => _AddManualSheetState();
}

class _AddManualSheetState extends State<_AddManualSheet> {
  Product? _product;
  int _qty = 1;
  StockStatus _status = StockStatus.closed;

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
            'Добавить продукт',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Выбор продукта из каталога
          ProductPickerField(
            value: _product,
            onChanged: (p) => setState(() => _product = p),
          ),
          const SizedBox(height: 16),

          // Количество
          Row(
            children: [
              const Text('Количество:', style: TextStyle(fontSize: 16)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                color: AppColors.primary,
                onPressed: () =>
                    setState(() => _qty = (_qty - 1).clamp(1, 99)),
              ),
              SizedBox(
                width: 32,
                child: Text(
                  '$_qty',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                color: AppColors.primary,
                onPressed: () =>
                    setState(() => _qty = (_qty + 1).clamp(1, 99)),
              ),
              const Text('шт.',
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 12),

          // Статус: вскрыто / закрыто
          Row(
            children: [
              const Text('Статус:', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 16),
              ChoiceChip(
                label: const Text('Закрыто'),
                selected: _status == StockStatus.closed,
                selectedColor: AppColors.primary.withAlpha(60),
                onSelected: (_) =>
                    setState(() => _status = StockStatus.closed),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Вскрыто'),
                selected: _status == StockStatus.opened,
                selectedColor: AppColors.warning.withAlpha(60),
                onSelected: (_) =>
                    setState(() => _status = StockStatus.opened),
              ),
            ],
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _product == null
                ? null
                : () {
                    final now = DateTime.now();
                    widget.onAdd(
                      StockItem(
                        id: 'user_${now.millisecondsSinceEpoch}',
                        product: _product!,
                        quantity: _qty,
                        status: _status,
                        openedAt: _status == StockStatus.opened ? now : null,
                        expiresAt: _status == StockStatus.opened
                            ? now.add(
                                Duration(hours: _product!.shelfLifeHours))
                            : null,
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

