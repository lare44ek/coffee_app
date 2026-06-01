// lib/label_generator_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import 'package:dotted_border/dotted_border.dart';

import 'models/product.dart';
import 'models/marking.dart';
import 'models/stock_item.dart';

import 'widgets/app_header.dart';
import 'widgets/product_picker_field.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'providers/app_providers.dart';
import 'qr_scanner_screen.dart';
import 'jumpscare_overlay.dart';

// ConsumerStatefulWidget — как StatefulWidget, но с доступом к ref.
// Используем его, а не ConsumerWidget, потому что у экрана есть
// локальный стейт: выбранный продукт и последняя маркировка.
class LabelGeneratorPage extends ConsumerStatefulWidget {
  const LabelGeneratorPage({super.key});

  @override
  ConsumerState<LabelGeneratorPage> createState() => _LabelGeneratorPageState();
}

// Карточка с тенью — общий контейнер для блоков на экране.
class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _LabelGeneratorPageState extends ConsumerState<LabelGeneratorPage> {
  // Локальный стейт — нужен только этому экрану, в провайдер не идёт.
  Product? _selectedProduct;
  Marking? _lastMarking;


  void _calculateExpiration() {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Выберите продукт из списка!')),
      );
      return;
    }

    final now = DateTime.now();
    final expiration = now.add(Duration(hours: _selectedProduct!.shelfLifeHours));
    final marking = Marking(
      product: _selectedProduct!,
      openedAt: now,
      expiresAt: expiration,
    );

    setState(() {
      _lastMarking = marking;
    });

    final user = ref.read(displayNameProvider) ?? ref.read(currentUserProvider);
    // Пишем маркировку в историю.
    ref.read(markingsProvider.notifier).add(marking, author: user);

    // Добавляем вскрытый продукт в остатки (1 шт., статус opened).
    ref.read(stockProvider.notifier).add(
          StockItem(
            id: 'marking_${now.millisecondsSinceEpoch}',
            product: _selectedProduct!,
            quantity: 1,
            status: StockStatus.opened,
            openedAt: now,
            expiresAt: expiration,
          ),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Маркировка добавлена в историю!')),
    );
  }


  void _checkForJumpscare() {
    final chance = Random().nextInt(100);
    if (chance == 0) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const JumpscareOverlay(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final resultText = _lastMarking != null
        ? '${_lastMarking!.openedLine}\n${_lastMarking!.expiresLine}'
        : 'Нажмите "Вскрыто" для расчёта';

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppHeader(
        title: 'Маркировка',
        actions: [
          IconButton(
            icon: const Icon(Icons.barcode_reader, color: Colors.white),
            tooltip: 'Сканировать штрих-код',
            onPressed: () async {
              // Сканер возвращает найденный по штрих-коду продукт (или null).
              final scanned = await Navigator.push<Product>(
                context,
                MaterialPageRoute(builder: (context) => const QRScannerScreen()),
              );
              if (scanned == null || !context.mounted) return;
              setState(() => _selectedProduct = scanned);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Выбрано: ${scanned.name}')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [

          // ── Карточка выбора продукта ──────────────────────────────────────
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Продукт',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 10),
                ProductPickerField(
                  value: _selectedProduct,
                  onChanged: (p) => setState(() => _selectedProduct = p),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    _calculateExpiration();
                    _checkForJumpscare();
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  child: const Text('📦 ВСКРЫТО'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Карточка результата ───────────────────────────────────────────
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Маркировка',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: DottedBorder(
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(12),
                    color: AppColors.primary,
                    strokeWidth: 2,
                    dashPattern: const [8, 4],
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 24, horizontal: 20),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        resultText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          color: AppTheme.onCard(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }
}
