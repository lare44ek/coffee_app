import 'package:flutter/material.dart';

void main() {
  runApp(const CoffeeApp());
}

class CoffeeApp extends StatelessWidget {
  const CoffeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Убирает надпись "DEBUG" в углу
      theme: ThemeData(
        primarySwatch: Colors.brown, // Коричневая тема (кофейная!)
        useMaterial3: true,
      ),
      home: const LabelGeneratorPage(),
    );
  }
}

class LabelGeneratorPage extends StatefulWidget {
  const LabelGeneratorPage({super.key});

  @override
  State<LabelGeneratorPage> createState() => _LabelGeneratorPageState();
}

class _LabelGeneratorPageState extends State<LabelGeneratorPage> {
  // Выбранный продукт
  String? _selectedProduct;

  // Результат расчёта
  String _resultText = 'Нажмите "Вскрыто" для расчёта';

  // Список продуктов с их сроками годности (в часах после вскрытия)
  final Map<String, int> _products = {
    'Молоко 3.2%': 48,
    'Сливки 10%': 48,
    'Сливки 20%': 72,
    'Сироп ванильный': 720, // 30 дней
    'Сироп карамельный': 720,
    'Кофе в зернах': 720,
    'Матча': 168, // 7 дней
    'Шоколадный соус': 336, // 14 дней
  };

  // Функция расчёта даты окончания
  void _calculateExpiration() {
    if (_selectedProduct == null) {
      setState(() {
        _resultText = '⚠️ Выберите продукт из списка!';
      });
      return;
    }

    // Получаем срок годности выбранного продукта
    int shelfLifeHours = _products[_selectedProduct]!;

    // Текущее время
    DateTime now = DateTime.now();

    // Дата окончания = сейчас + срок годности
    DateTime expiration = now.add(Duration(hours: shelfLifeHours));

    // Форматируем дату в красивый вид
    String expirationString = 
        '${expiration.day.toString().padLeft(2, '0')}.${expiration.month.toString().padLeft(2, '0')} '
        '${expiration.hour.toString().padLeft(2, '0')}:${expiration.minute.toString().padLeft(2, '0')}';

    // Формируем текст для маркировки
    setState(() {
      _resultText = '''
✅ ПРОДУКТ: $_selectedProduct
 ВСКРЫТО: ${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}
⏳ ГОДЕН ДО: $expirationString
      ''';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('☕ Кофейный Учёт'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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

            // Выпадающий список продуктов
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.brown),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedProduct,
                  hint: const Text('Выберите продукт'),
                  isExpanded: true,
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
            ),
            const SizedBox(height: 20),

            // Кнопка "Вскрыто"
            ElevatedButton(
              onPressed: _calculateExpiration,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              child: const Text('📦 ВСКРЫТО'),
            ),
            const SizedBox(height: 30),

            // Блок с результатом
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.brown.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.brown, width: 2),
              ),
              child: Text(
                _resultText,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'monospace', // Моноширинный шрифт как на этикетке
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Кнопка копирования текста
            OutlinedButton.icon(
              onPressed: () {
                // Копирование в буфер обмена
                // Для этого нужно будет добавить пакет flutter/services
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Функция копирования будет добавлена!')),
                );
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