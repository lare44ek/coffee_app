// lib/qr_scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'models/product.dart';
import 'providers/app_providers.dart';

/// Экран сканера штрих-кодов (EAN-13) и QR.
///
/// При совпадении отсканированного кода с товаром из каталога экран
/// закрывается и возвращает найденный [Product] через [Navigator.pop].
/// Если код не найден — показывает сообщение и продолжает сканировать.
class QRScannerScreen extends ConsumerStatefulWidget {
  const QRScannerScreen({super.key});

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen> {
  // noDuplicates — один и тот же код подряд не вызывает onDetect повторно.
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  // После первого совпадения экран закрывается; флаг защищает от
  // повторного pop, если onDetect успеет сработать ещё раз.
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;

    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue;
      if (code == null || code.isEmpty) continue;

      // Каталог уже загружен через productsProvider (FutureProvider).
      final products = ref.read(productsProvider).valueOrNull ?? const [];

      Product? match;
      for (final p in products) {
        if (p.barcode != null && p.barcode == code) {
          match = p;
          break;
        }
      }

      if (match != null) {
        _handled = true;
        Navigator.pop<Product>(context, match);
        return;
      }

      // Код прочитан, но в каталоге не найден.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Код $code не привязан к продукту')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сканировать код'),
        backgroundColor: const Color.fromRGBO(175, 146, 133, 1),
        foregroundColor: const Color.fromRGBO(255, 255, 255, 1),
      ),
      // MobileScanner отвечает за отображение камеры и распознавание.
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.topCenter,
              child: const _ScannerOverlay(),
            ),
          ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Наведите на штрих-код или QR на упаковке',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Виджет для отображения "рамки" сканирования поверх камеры.
class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8, // 80% ширины экрана
      height: MediaQuery.of(context).size.width * 0.8, // Квадрат
      decoration: BoxDecoration(
        // Прозрачный фон
        color: Colors.transparent,
        // Рамка
        border: Border.all(color: Colors.green, width: 3),
        // Скругления
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
