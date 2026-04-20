// lib/label_generator_page.dart
import 'package:flutter/material.dart';
import 'qr_scanner_screen.dart'; 
import 'package:flutter/services.dart';
import 'dart:math';
import 'jumpscare_overlay.dart';
import 'package:dotted_border/dotted_border.dart';


// Определяем тип для передачи метода добавления в историю
typedef AddToHistoryCallback = void Function(String label);

class LabelGeneratorPage extends StatefulWidget {
  final AddToHistoryCallback addToHistory; // Получаем callback из родителя

  const LabelGeneratorPage({super.key, required this.addToHistory});

  @override
  State<LabelGeneratorPage> createState() => _LabelGeneratorPageState();
}

class _LabelGeneratorPageState extends State<LabelGeneratorPage> {
  String? _selectedProduct;
  String _resultText = 'Нажмите "Вскрыто" для расчёта';

  final Map<String, int> _products = {
    'Молоко 3.2%': 48,
    'Сливки 10%': 48,
    'Сливки 20%': 72,
    'Сироп ванильный': 720,
    'Сироп карамельный': 720,
    'Кофе в зернах': 720,
    'Матча': 168,
    'Шоколадный соус': 336,
  };

  void _calculateExpiration() {
    if (_selectedProduct == null) {
      setState(() {
        _resultText = '⚠️ Выберите продукт из списка!';
      });
      return;
    }

    int shelfLifeHours = _products[_selectedProduct]!;
    DateTime now = DateTime.now();
    DateTime expiration = now.add(Duration(hours: shelfLifeHours));
    

  setState(() {
  _resultText = '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}\n'
      '${expiration.day.toString().padLeft(2, '0')}.${expiration.month.toString().padLeft(2, '0')}.${expiration.hour.toString().padLeft(2, '0')}:${expiration.minute.toString().padLeft(2, '0')}';
});
  }

    void _copyToClipboard() async {
    if (_resultText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нечего копировать.')),
      );
      return;
    }

    try {
      await Clipboard.setData(ClipboardData(text: _resultText));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Текст скопирован в буфер обмена!')),
      );
    } catch (e) {
      print("Ошибка копирования: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Ошибка: $e')),
      );
    }
  }

  void _saveToHistory() {
    if (_resultText.isNotEmpty && !_resultText.contains('⚠️')) {
      widget.addToHistory(_resultText);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Маркировка добавлена в историю!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Нечего добавлять в историю.')),
      );
    }
  }

  // --- НОВАЯ ФУНКЦИЯ ---
void _checkForJumpscare() {
  final random = Random();
  final chance = random.nextInt(100);
  print("DEBUG: Random chance = $chance");
  if (chance == 0) { // Проверяем 0 для отладки
    print("DEBUG: Showing jumpscare!");
    showDialog(
      context: context,
      barrierDismissible: false, // Важно: запрещаем закрытие по клику вне
      builder: (context) => const JumpscareOverlay(
        // onDismiss можно передать, если хочешь выполнить код после закрытия
        // onDismiss: () => print("Jumpscare closed!"),
      ),
    ).then((_) {
      print("DEBUG: Jumpscare dialog closed.");
    });
  } else {
    print("DEBUG: No jumpscare this time.");
  }
}
  // --- /НОВАЯ ФУНКЦИЯ ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('☕ Кофейный Учёт'),
        backgroundColor: Color.fromRGBO(175, 146, 133, 1),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
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
              'Генератор маркировки',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            Container(
              height: 56,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.brown),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedProduct,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
                hint: const Text('Выберите продукт'),
                items: _products.keys.map((String product) {
                  return DropdownMenuItem<String>(
                    value: product,
                    child: Text(product),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedProduct = newValue;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () { // <-- Изменили onPressed
                _calculateExpiration();
                _checkForJumpscare(); // Вызываем проверку после расчёта
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              child: const Text('📦 ВСКРЫТО'),
            ),
            const SizedBox(height: 20),

            OutlinedButton(
              onPressed: _saveToHistory,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.brown),
                foregroundColor: Colors.brown,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text('💾 Сохранить в историю'),
            ),
            const SizedBox(height: 20),

            const SizedBox(height: 20),

            // Контейнер с результатом (плотно облегает текст + пунктир)
            Center(
              child: DottedBorder(
                borderType: BorderType.RRect,
                radius: const Radius.circular(12),
                color: Colors.brown,
                strokeWidth: 2,
                dashPattern: [8, 4], // Длина штриха и пробела
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.brown.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IntrinsicWidth(  // ← Заставляет контейнер обнимать текст
                    child: Text(
                      _resultText,
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
              onPressed: () { // <-- Изменили onPressed и тут
                _copyToClipboard();
                _checkForJumpscare(); // Или вызвать и тут, если хочешь
              },
              icon: const Icon(Icons.copy),
              label: const Text('Копировать текст'),
            ),
          ],
        ),
      ),
    );
  }
}