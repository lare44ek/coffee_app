// lib/qr_scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; 

class QRScannerScreen extends StatelessWidget {
  const QRScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сканировать QR-код'),
        backgroundColor: Color.fromRGBO(175, 146, 133, 1),
        foregroundColor: Color.fromRGBO(255, 255, 255, 1),
      ),
      // MobileScanner отвечает за отображение камеры и сканирование
      body: Stack(
        children: [
          MobileScanner(
            // onDetect можно использовать для обработки распознанного QR-кода
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final Barcode barcode in barcodes) {
                // Получаем текст из QR-кода
                final String code = barcode.rawValue ?? 'Не удалось распознать';
                // Показываем Snackbar с результатом
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('QR-код: $code')),
                );
                // Пример: можно сразу вернуть результат в предыдущий экран
                // Navigator.pop(context, code);
                // Но пока просто покажем snackbar и продолжим сканировать
              }
            },
            // Если хочешь, можно отключить автоспуск затвера
            controller: MobileScannerController(
              detectionSpeed: DetectionSpeed.noDuplicates, // Пример настройки
              // torchEnabled: true, // Включить/выключить вспышку
            ),
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
                  'Отсканируйте QR-код на упаковке',
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

// Виджет для отображения "рамки" сканирования и текста поверх камеры
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