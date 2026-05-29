// lib/widgets/product_picker_field.dart
//
// Поле выбора продукта из каталога.
// Вместо дропдауна на весь экран — шторка (~75% высоты) с поиском.
// Каталог загружается с сервера через productsProvider.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../providers/app_providers.dart';
import '../theme/app_colors.dart';

/// Кнопка-поле, которая при тапе открывает шторку с поиском по каталогу.
///
/// Использование (аналогично DropdownButtonFormField):
///   ProductPickerField(
///     value: _selectedProduct,
///     onChanged: (p) => setState(() => _selectedProduct = p),
///   )
class ProductPickerField extends StatelessWidget {
  final Product? value;
  final ValueChanged<Product?> onChanged;
  final String hint;

  const ProductPickerField({
    super.key,
    required this.value,
    required this.onChanged,
    this.hint = 'Выберите продукт',
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value?.name ?? hint,
                style: TextStyle(
                  fontSize: 16,
                  color: value != null ? AppColors.text : Colors.grey.shade500,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 22),
          ],
        ),
      ),
    );
  }

  void _openPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductPickerSheet(
        selected: value,
        onSelect: (p) {
          Navigator.pop(context);
          onChanged(p);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Шторка с поиском
// ---------------------------------------------------------------------------

class _ProductPickerSheet extends ConsumerStatefulWidget {
  final Product? selected;
  final ValueChanged<Product> onSelect;

  const _ProductPickerSheet({required this.selected, required this.onSelect});

  @override
  ConsumerState<_ProductPickerSheet> createState() =>
      _ProductPickerSheetState();
}

class _ProductPickerSheetState extends ConsumerState<_ProductPickerSheet> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Откладываем фокус до окончания анимации шторки (~300 мс),
    // чтобы клавиатура не поднималась одновременно со slide-up.
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  /// Группирует продукты по категории, применяя поисковый фильтр.
  Map<String, List<Product>> _group(List<Product> products) {
    final q = _query.toLowerCase();
    final result = <String, List<Product>>{};
    for (final p in products) {
      if (q.isNotEmpty && !p.name.toLowerCase().contains(q)) continue;
      final cat = p.category.isEmpty ? 'Прочее' : p.category;
      (result[cat] ??= []).add(p);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      snap: true,
      snapSizes: const [0.75, 0.95],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Ручка шторки
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Поисковая строка
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  focusNode: _searchFocus,
                  decoration: InputDecoration(
                    hintText: 'Поиск...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            color: Colors.grey,
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),

              const Divider(height: 1),

              // Список продуктов — зависит от загрузки каталога
              Expanded(
                child: ref.watch(productsProvider).when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => _ErrorState(
                        onRetry: () => ref.invalidate(productsProvider),
                      ),
                      data: (products) =>
                          _buildList(_group(products), scrollController),
                    ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildList(
      Map<String, List<Product>> filtered, ScrollController scrollController) {
    if (filtered.isEmpty) {
      return const Center(
        child: Text(
          'Ничего не найдено',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        for (final cat in filtered.keys) ...[
          // Заголовок категории
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              cat,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary.withAlpha(180),
                letterSpacing: 0.5,
              ),
            ),
          ),
          // Строки продуктов
          for (final p in filtered[cat]!)
            ListTile(
              dense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
              title: Text(p.name, style: const TextStyle(fontSize: 15)),
              trailing: widget.selected?.name == p.name
                  ? const Icon(Icons.check_rounded,
                      color: AppColors.primary, size: 20)
                  : null,
              onTap: () => widget.onSelect(p),
            ),
        ],
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, color: Colors.grey, size: 40),
          const SizedBox(height: 12),
          const Text('Не удалось загрузить каталог',
              style: TextStyle(color: Colors.grey, fontSize: 15)),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Повторить')),
        ],
      ),
    );
  }
}
