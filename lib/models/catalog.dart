// lib/models/catalog.dart
//
// Каталог продуктов бара — составлен по документу
// «Сроки хранения БАР БК 12.05.2026».
// Срок хранения указан в часах после вскрытия/приготовления.
// «Согласно аннотации» и закрытые упаковки без конкретного срока — не включены.
// Когда появится бэкенд — этот файл заменяется запросом к БД.
library;

import 'product.dart';

// ---------------------------------------------------------------------------
// Категории
// ---------------------------------------------------------------------------

abstract class ProductCategory {
  static const frukty       = 'Фрукты и зелень';
  static const molochka     = 'Молочные';
  static const kofe         = 'Кофе и чай';
  static const siropy       = 'Сиропы и топпинги';
  static const zagotovki    = 'Заготовки';
  static const sypuchie     = 'Сыпучие и прочее';
}

// ---------------------------------------------------------------------------
// Каталог
// ---------------------------------------------------------------------------

const List<Product> kProductCatalog = [

  // ── Фрукты и зелень ──────────────────────────────────────────────────────
  Product(
    name: 'Лимон обработанный',
    shelfLifeHours: 24,
    category: ProductCategory.frukty,
  ),
   Product(
    name: 'Лайм обработанный',
    shelfLifeHours: 24,
    category: ProductCategory.frukty,
  ),
    Product(
    name: 'Грейпфрут обработанный',
    shelfLifeHours: 24,
    category: ProductCategory.frukty,
  ),
  Product(
    name: 'Груша нарезка',
    shelfLifeHours: 24,
    category: ProductCategory.frukty,
  ),
  Product(
    name: 'Авокадо очищенный',
    shelfLifeHours: 12,
    category: ProductCategory.frukty,
  ),
  Product(
    name: 'Банан очищенный',
    shelfLifeHours: 12,
    category: ProductCategory.frukty,
  ),
  Product(
    name: 'Мята обработанная',
    shelfLifeHours: 24,
    category: ProductCategory.frukty,
  ),

  // ── Молочные ─────────────────────────────────────────────────────────────
  Product(
    name: 'Молоко 3,2% (упаковка)',
    shelfLifeHours: 72,
    category: ProductCategory.molochka,
  ),
  Product(
    name: 'Молоко кокосовое/миндальное 5yes',
    shelfLifeHours: 72,
    category: ProductCategory.molochka,
  ),
  Product(
    name: 'Сливки 20%',
    shelfLifeHours: 72,
    category: ProductCategory.molochka,
  ),
  Product(
    name: 'Сливки 10%',
    shelfLifeHours: 48,
    category: ProductCategory.molochka,
  ),

  // ── Кофе и чай ───────────────────────────────────────────────────────────
  Product(
    name: 'Эспрессо смесь',
    shelfLifeHours: 48,
    category: ProductCategory.kofe,
  ),
  Product(
    name: 'Кофе фильтр Эфиопия',
    shelfLifeHours: 1440, // 60 суток
    category: ProductCategory.kofe,
  ),
  Product(
    name: 'Фильтр-кофе готовый (термос)',
    shelfLifeHours: 4,
    category: ProductCategory.kofe,
  ),
  Product(
    name: 'Чай Москва',
    shelfLifeHours: 13140, // 18 месяцев
    category: ProductCategory.kofe,
  ),

  // ── Сиропы и топпинги ────────────────────────────────────────────────────
  Product(
    name: 'Сироп ванильный',
    shelfLifeHours: 2160, // 90 суток
    category: ProductCategory.siropy,
  ),
  Product(
    name: 'Сироп карамельный',
    shelfLifeHours: 2160,
    category: ProductCategory.siropy,
  ),
  Product(
    name: 'Сироп фундук',
    shelfLifeHours: 2160,
    category: ProductCategory.siropy,
  ),
  Product(
    name: 'Сироп миндаль',
    shelfLifeHours: 2160,
    category: ProductCategory.siropy,
  ),
  Product(
    name: 'Сироп фисташка',
    shelfLifeHours: 2160,
    category: ProductCategory.siropy,
  ),
  Product(
    name: 'Сироп соленая карамель',
    shelfLifeHours: 2160,
    category: ProductCategory.siropy,
  ),
  Product(
    name: 'Основа Щавель-лайм Pinch&Drop',
    shelfLifeHours: 720, // 30 суток
    category: ProductCategory.siropy,
  ),
  Product(
    name: 'Основа Q (груша/манго-жасмин/мандарин и др.)',
    shelfLifeHours: 720,
    category: ProductCategory.siropy,
  ),
  Product(
    name: 'Топпинг Фисташка ICE DREAM (упаковка)',
    shelfLifeHours: 1440, // 60 дней
    category: ProductCategory.siropy,
  ),
  Product(
    name: 'Топпинг Фисташка ICE DREAM (соусник)',
    shelfLifeHours: 336, // 14 суток
    category: ProductCategory.siropy,
  ),
  Product(
    name: 'Мед (соусник)',
    shelfLifeHours: 336,
    category: ProductCategory.siropy,
  ),
  Product(
    name: 'Мед (упаковка)',
    shelfLifeHours: 4320, // 6 месяцев
    category: ProductCategory.siropy,
  ),
  Product(
    name: 'Шоколад Golden Cioc',
    shelfLifeHours: 96,
    category: ProductCategory.siropy,
  ),

  // ── Заготовки ────────────────────────────────────────────────────────────
  Product(
    name: 'Сырная пена (сифон)',
    shelfLifeHours: 36,
    category: ProductCategory.zagotovki,
  ),

  // ── Сыпучие и прочее ─────────────────────────────────────────────────────
  Product(
    name: 'Джус боллы яблочные',
    shelfLifeHours: 240, // 10 суток
    category: ProductCategory.sypuchie,
  ),
  Product(
    name: 'Маршмеллоу',
    shelfLifeHours: 168, // 7 суток
    category: ProductCategory.sypuchie,
  ),
  Product(
    name: 'Посыпка шоколад Кросби',
    shelfLifeHours: 2160, // 90 суток
    category: ProductCategory.sypuchie,
  ),
  Product(
    name: 'Какао Мокко Кросби',
    shelfLifeHours: 8760, // 12 месяцев
    category: ProductCategory.sypuchie,
  ),
  Product(
    name: 'Протеин Bombbar Pro Isolate',
    shelfLifeHours: 1440, // 60 дней
    category: ProductCategory.sypuchie,
  ),
  Product(
    name: 'Фисташка фракция',
    shelfLifeHours: 8760,
    category: ProductCategory.sypuchie,
  ),
  Product(
    name: 'Вода минеральная Jevea',
    shelfLifeHours: 72,
    category: ProductCategory.sypuchie,
  ),
  Product(
    name: 'Матча зеленая',
    shelfLifeHours: 8760, // «согласно аннотации» — ставим 1 год
    category: ProductCategory.sypuchie,
  ),
  Product(
    name: 'Ходзича',
    shelfLifeHours: 8760,
    category: ProductCategory.sypuchie,
  ),
];

// ---------------------------------------------------------------------------
// Вспомогательные данные
// ---------------------------------------------------------------------------

/// Все уникальные категории в порядке отображения.
final List<String> kProductCategories = kProductCatalog
    .map((p) => p.category)
    .where((c) => c.isNotEmpty)
    .toSet()
    .toList();

/// Продукты, сгруппированные по категории.
final Map<String, List<Product>> kProductsByCategory = {
  for (final cat in kProductCategories)
    cat: kProductCatalog.where((p) => p.category == cat).toList(),
};

/// Минимальный остаток для попадания в список заказа.
/// Ключ — точное имя продукта из [kProductCatalog].
const Map<String, int> kMinStock = {
  'Молоко 3,2% (упаковка)':           3,
  'Молоко кокосовое/миндальное 5yes': 2,
  'Сливки 20%':                        2,
  'Сливки 10%':                        2,
  'Эспрессо смесь':                      1,
  'Сироп ванильный':                   2,
  'Сироп карамельный':                 2,
  'Сироп фундук':                      1,
  'Сироп миндаль':                     1,
  'Сироп фисташка':                    1,
  'Сироп соленая карамель':            1,
  'Маршмеллоу':                        1,
  'Шоколад Golden Cioc':               2,
};
