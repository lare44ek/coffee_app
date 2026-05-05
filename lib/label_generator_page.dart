// lib/label_generator_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import 'package:dotted_border/dotted_border.dart';

import 'models/product.dart';
import 'models/marking.dart';
import 'widgets/app_header.dart';
import 'theme/app_colors.dart';
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

class _LabelGeneratorPageState extends ConsumerState<LabelGeneratorPage> {
  // Локальный стейт — нужен только этому экрану, в провайдер не идёт.
  Product? _selectedProduct;
  Marking? _lastMarking;

  // Каталог продуктов — пока хардкод, потом заменим на ProductsRepository
  static const List<Product> _products = [
    Product(name: 'Молоко 3.2%',      shelfLifeHours: 48),
    Product(name: 'Сливки 10%',        shelfLifeHours: 48),
    Product(name: 'Сливки 20%',        shelfLifeHours: 72),
    Product(name: 'Сироп ванильный',   shelfLifeHours: 720),
    Product(name: 'Сироп карамельный', shelfLifeHours: 720),
    Product(name: 'Кофе в зернах',     shelfLifeHours: 720),
    Product(name: 'Матча',             shelfLifeHours: 168),
    Product(name: 'Шоколадный соус',   shelfLifeHours: 336),
  ];

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

    // Пишем в глобальный провайдер — callback больше не нужен.
    ref.read(markingsProvider.notifier).add(marking);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Маркировка добавлена в историю!')),
    );
  }

  void _copyToClipboard() async {
    if (_lastMarking == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нечего копировать.')),
      );
      return;
    }

    try {
      final text = '${_lastMarking!.openedLine}\n${_lastMarking!.expiresLine}';
      await Clipboard.setData(ClipboardData(text: text));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Текст скопирован в буфер обмена!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Ошибка: $e')),
      );
    }
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
      appBar: AppHeader(
        title: 'Маркировка',
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
            tooltip: 'Сканировать QR-код',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const QRScannerScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Выберите продукт',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 30),

            Container(
              height: 56,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonFormField<Product>(
                value: _selectedProduct,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
                hint: const Text('Выберите продукт'),
                items: _products.map((product) {
                  return DropdownMenuItem<Product>(
                    value: product,
                    child: Text(product.name),
                  );
                }).toList(),
                onChanged: (Product? newValue) {
                  setState(() {
                    _selectedProduct = newValue;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),

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
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              child: const Text('📦 ВСКРЫТО'),
            ),
            const SizedBox(height: 20),

            Center(
              child: DottedBorder(
                borderType: BorderType.RRect,
                radius: const Radius.circular(12),
                color: AppColors.primary,
                strokeWidth: 2,
                dashPattern: const [8, 4],
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IntrinsicWidth(
                    child: Text(
                      resultText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 25,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            OutlinedButton.icon(
              onPressed: () {
                _copyToClipboard();
                _checkForJumpscare();
              },
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.copy),
              label: const Text('Копировать текст'),
            ),
          ],
        ),
      ),
    );
  }
}
