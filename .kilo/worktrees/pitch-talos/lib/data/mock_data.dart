import '../models/address.dart';
import '../models/app_banner.dart';
import '../models/app_notification.dart';
import '../models/app_settings_data.dart';
import '../models/app_user.dart';
import '../models/brand.dart';
import '../models/cargo_rate.dart';
import '../models/category.dart';
import '../models/chat_message.dart';
import '../models/order.dart';
import '../models/price_tier.dart';
import '../models/product.dart';
import '../models/product_variant.dart';
import '../models/promo_code.dart';
import '../models/review.dart';

/// Демо-данные для UI-фазы (бэкенд подключим следующим шагом — см. README).
class MockData {
  MockData._();

  static const currentUser = AppUser(
    id: 'u1',
    phone: '+992 90 123 45 67',
    fullName: 'Умар Митзоев',
    isLegalEntity: true,
    legalName: 'ИП Митзоев У.',
    loyaltyPoints: 1280,
    role: UserRole.manager,
  );

  static const categories = <Category>[
    Category(id: 'c1', name: 'Носки', slug: 'socks', iconName: 'box'),
    Category(id: 'c2', name: 'Футболки', slug: 't-shirts', iconName: 'grid'),
    Category(id: 'c3', name: 'Трусы', slug: 'underwear', iconName: 'archive'),
    Category(id: 'c4', name: 'Шорты', slug: 'shorts', iconName: 'layers'),
    Category(id: 'c5', name: 'Штаны', slug: 'pants', iconName: 'package'),
  ];

  static const brands = <Brand>[
    Brand(id: 'b1', name: 'ComfortLine'),
    Brand(id: 'b2', name: 'ProCotton'),
    Brand(id: 'b3', name: 'BaseWear'),
  ];

  static final addresses = <Address>[
    const Address(id: 'a1', title: 'Склад Душанбе', country: DeliveryCountry.tajikistan, city: 'Душанбе', street: 'ул. Рудаки, 45', isDefault: true),
    const Address(id: 'a2', title: 'Офис Москва', country: DeliveryCountry.russia, city: 'Москва', street: 'Складской пр-д, 3'),
  ];

  static final cargoRates = <CargoRate>[
    const CargoRate(country: DeliveryCountry.russia, pricePerKg: 420, currency: 'RUB'),
    const CargoRate(country: DeliveryCountry.tajikistan, pricePerKg: 260, currency: 'RUB'),
  ];

  static final appSettings = AppSettingsData(
    usdToRubRate: 92.4,
    rateUpdatedAt: DateTime.now().subtract(const Duration(hours: 3)),
    minOrderAmount: 15000,
    contactPhone: '+992 90 123 45 67',
    contactAddress: 'г. Душанбе, ул. Рудаки, 45',
    whatsAppUrl: 'https://wa.me/992901234567',
    telegramUrl: 'https://t.me/fullseller',
  );

  static final promoCodes = <PromoCode>[
    PromoCode(id: 'p1', code: 'WELCOME10', discountType: DiscountType.percent, discountValue: 10, usageLimit: 500, timesUsed: 128),
    PromoCode(id: 'p2', code: 'OPT2000', discountType: DiscountType.fixed, discountValue: 2000, expiresAt: DateTime.now().add(const Duration(days: 14)), timesUsed: 34),
  ];

  static final banners = <AppBanner>[
    const AppBanner(id: 'bn1', title: 'Скидка 15% на первую партию', subtitle: 'При заказе от 500 единиц товара', sortOrder: 0),
    const AppBanner(id: 'bn2', title: 'Новая коллекция носков', subtitle: 'Уже в каталоге — 12 новых моделей', sortOrder: 1),
  ];

  static final products = <Product>[
    Product(
      id: 'pr1', name: 'Носки мужские хлопковые, набор 12 пар', categoryId: 'c1', brandId: 'b1', brandName: 'ComfortLine',
      description: 'Классические мужские носки из хлопка с усиленной пяткой и носком. Оптовая поставка наборами по 12 пар.',
      composition: '80% хлопок, 15% полиэстер, 5% эластан', weightGrams: 480,
      imageUrls: const ['socks_1'], rating: 4.7, reviewsCount: 86, minPrice: 38, oldPrice: 46, isHit: true,
      priceTiers: const [PriceTier(minQuantity: 50, pricePerUnit: 46), PriceTier(minQuantity: 200, pricePerUnit: 42), PriceTier(minQuantity: 500, pricePerUnit: 38)],
      variants: const [
        ProductVariant(id: 'v1', productId: 'pr1', size: '39-42', color: 'Чёрный', sku: 'SK-BL-M', stockQuantity: 3400),
        ProductVariant(id: 'v2', productId: 'pr1', size: '39-42', color: 'Серый', sku: 'SK-GR-M', stockQuantity: 2100),
        ProductVariant(id: 'v3', productId: 'pr1', size: '43-46', color: 'Чёрный', sku: 'SK-BL-L', stockQuantity: 1800),
      ],
    ),
    Product(
      id: 'pr2', name: 'Футболка базовая унисекс, кулирка 180г', categoryId: 'c2', brandId: 'b2', brandName: 'ProCotton',
      description: 'Плотная футболка из кулирного полотна, не деформируется после стирки. Подходит под нанесение принтов.',
      composition: '100% хлопок (кулирка)', weightGrams: 160,
      imageUrls: const ['tshirt_1'], rating: 4.9, reviewsCount: 214, minPrice: 210, isNew: true,
      priceTiers: const [PriceTier(minQuantity: 20, pricePerUnit: 260), PriceTier(minQuantity: 100, pricePerUnit: 230), PriceTier(minQuantity: 300, pricePerUnit: 210)],
      variants: const [
        ProductVariant(id: 'v4', productId: 'pr2', size: 'M', color: 'Белый', sku: 'TS-WH-M', stockQuantity: 900),
        ProductVariant(id: 'v5', productId: 'pr2', size: 'L', color: 'Белый', sku: 'TS-WH-L', stockQuantity: 760),
        ProductVariant(id: 'v6', productId: 'pr2', size: 'L', color: 'Чёрный', sku: 'TS-BL-L', stockQuantity: 640),
      ],
    ),
    Product(
      id: 'pr3', name: 'Трусы мужские боксеры, набор 5 шт', categoryId: 'c3', brandId: 'b3', brandName: 'BaseWear',
      description: 'Мягкий трикотаж, широкая резинка без натирания. Набор из 5 пар в разных цветах.',
      composition: '95% хлопок, 5% эластан', weightGrams: 320,
      imageUrls: const ['underwear_1'], rating: 4.6, reviewsCount: 57, minPrice: 96, oldPrice: 118,
      priceTiers: const [PriceTier(minQuantity: 30, pricePerUnit: 118), PriceTier(minQuantity: 150, pricePerUnit: 104), PriceTier(minQuantity: 400, pricePerUnit: 96)],
      variants: const [
        ProductVariant(id: 'v7', productId: 'pr3', size: 'M', color: 'Микс', sku: 'UW-MX-M', stockQuantity: 1200),
        ProductVariant(id: 'v8', productId: 'pr3', size: 'L', color: 'Микс', sku: 'UW-MX-L', stockQuantity: 980),
      ],
    ),
    Product(
      id: 'pr4', name: 'Шорты спортивные трикотажные', categoryId: 'c4', brandId: 'b2', brandName: 'ProCotton',
      description: 'Лёгкие шорты на резинке со шнурком, боковые карманы.', composition: '95% хлопок, 5% эластан',
      weightGrams: 210, imageUrls: const ['shorts_1'], rating: 4.5, reviewsCount: 41, minPrice: 175,
      priceTiers: const [PriceTier(minQuantity: 20, pricePerUnit: 210), PriceTier(minQuantity: 100, pricePerUnit: 190), PriceTier(minQuantity: 250, pricePerUnit: 175)],
      variants: const [
        ProductVariant(id: 'v9', productId: 'pr4', size: 'M', color: 'Синий', sku: 'SH-BL-M', stockQuantity: 540),
        ProductVariant(id: 'v10', productId: 'pr4', size: 'L', color: 'Синий', sku: 'SH-BL-L', stockQuantity: 430),
      ],
    ),
    Product(
      id: 'pr5', name: 'Штаны спортивные на манжете', categoryId: 'c5', brandId: 'b1', brandName: 'ComfortLine',
      description: 'Плотный футер трёхнитка, манжеты на штанинах, карманы на молнии.', composition: '80% хлопок, 20% полиэстер',
      weightGrams: 420, imageUrls: const ['pants_1'], rating: 4.8, reviewsCount: 132, minPrice: 395, oldPrice: 460, isHit: true,
      priceTiers: const [PriceTier(minQuantity: 15, pricePerUnit: 460), PriceTier(minQuantity: 60, pricePerUnit: 420), PriceTier(minQuantity: 150, pricePerUnit: 395)],
      variants: const [
        ProductVariant(id: 'v11', productId: 'pr5', size: 'L', color: 'Чёрный', sku: 'PN-BL-L', stockQuantity: 310),
        ProductVariant(id: 'v12', productId: 'pr5', size: 'XL', color: 'Серый', sku: 'PN-GR-XL', stockQuantity: 260),
      ],
    ),
    Product(
      id: 'pr6', name: 'Носки детские хлопковые, набор 10 пар', categoryId: 'c1', brandId: 'b1', brandName: 'ComfortLine',
      description: 'Детские носки с мягкой резинкой, без натирания.', composition: '85% хлопок, 10% полиэстер, 5% эластан',
      weightGrams: 260, imageUrls: const ['socks_2'], rating: 4.9, reviewsCount: 63, minPrice: 29, isNew: true,
      priceTiers: const [PriceTier(minQuantity: 50, pricePerUnit: 34), PriceTier(minQuantity: 200, pricePerUnit: 31), PriceTier(minQuantity: 500, pricePerUnit: 29)],
      variants: const [ProductVariant(id: 'v13', productId: 'pr6', size: '26-30', color: 'Микс', sku: 'SK-KID-M', stockQuantity: 2600)],
    ),
  ];

  static List<Review> reviewsFor(String productId) => [
        Review(id: 'r1-$productId', productId: productId, userName: 'Алишер Р.', rating: 5, comment: 'Отличное качество за эти деньги, заказываем уже третью партию.', createdAt: DateTime.now().subtract(const Duration(days: 4))),
        Review(id: 'r2-$productId', productId: productId, userName: 'Фарход Н.', rating: 4, comment: 'Размерная сетка соответствует, упаковка аккуратная.', createdAt: DateTime.now().subtract(const Duration(days: 11))),
        Review(id: 'r3-$productId', productId: productId, userName: 'Мадина С.', rating: 5, comment: 'Доставили быстро, брак не обнаружен.', createdAt: DateTime.now().subtract(const Duration(days: 19))),
      ];

  static final orders = <Order>[
    Order(
      id: 'o1', orderNumber: 'FS-10245', status: OrderStatus.vObrabotke, totalAmount: 48600, deliveryCost: 3200,
      cargoTrackingNumber: 'TJ-77213', createdAt: DateTime.now().subtract(const Duration(days: 1)),
      items: [
        OrderItem(productId: 'pr1', productName: 'Носки мужские хлопковые', imageUrl: 'socks_1', quantity: 500, unitPrice: 38),
        OrderItem(productId: 'pr2', productName: 'Футболка базовая унисекс', imageUrl: 'tshirt_1', quantity: 100, unitPrice: 230),
      ],
    ),
    Order(
      id: 'o2', orderNumber: 'FS-10198', status: OrderStatus.otpravlen, totalAmount: 96500, deliveryCost: 5400,
      cargoTrackingNumber: 'TJ-76890', createdAt: DateTime.now().subtract(const Duration(days: 6)),
      items: [OrderItem(productId: 'pr5', productName: 'Штаны спортивные на манжете', imageUrl: 'pants_1', quantity: 150, unitPrice: 395)],
    ),
    Order(
      id: 'o3', orderNumber: 'FS-10102', status: OrderStatus.zavershen, totalAmount: 21400, deliveryCost: 1800,
      createdAt: DateTime.now().subtract(const Duration(days: 22)),
      items: [OrderItem(productId: 'pr3', productName: 'Трусы мужские боксеры', imageUrl: 'underwear_1', quantity: 200, unitPrice: 96)],
    ),
    Order(
      id: 'o4', orderNumber: 'FS-10055', status: OrderStatus.otmenen, totalAmount: 12300, deliveryCost: 0,
      createdAt: DateTime.now().subtract(const Duration(days: 40)),
      items: [OrderItem(productId: 'pr4', productName: 'Шорты спортивные трикотажные', imageUrl: 'shorts_1', quantity: 60, unitPrice: 175)],
    ),
    Order(
      id: 'o5', orderNumber: 'FS-10018', status: OrderStatus.novyy, totalAmount: 34000, deliveryCost: 2600,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      items: [OrderItem(productId: 'pr6', productName: 'Носки детские хлопковые', imageUrl: 'socks_2', quantity: 1000, unitPrice: 29)],
    ),
  ];

  static final notifications = <AppNotification>[
    AppNotification(id: 'n1', type: NotificationType.order, title: 'Заказ FS-10245 в обработке', body: 'Менеджер начал сборку вашего заказа.', createdAt: DateTime.now().subtract(const Duration(hours: 2))),
    AppNotification(id: 'n2', type: NotificationType.promo, title: 'Промокод WELCOME10', body: 'Скидка 10% на первую партию — успейте оформить.', createdAt: DateTime.now().subtract(const Duration(days: 1)), isRead: true),
    AppNotification(id: 'n3', type: NotificationType.order, title: 'Заказ FS-10198 отправлен', body: 'Трек-номер: TJ-76890.', createdAt: DateTime.now().subtract(const Duration(days: 6)), isRead: true),
    AppNotification(id: 'n4', type: NotificationType.system, title: 'Обновление каталога', body: 'Добавлено 12 новых моделей носков.', createdAt: DateTime.now().subtract(const Duration(days: 9)), isRead: true),
  ];

  static final chatMessages = <ChatMessage>[
    ChatMessage(id: 'm1', text: 'Здравствуйте! Подскажите остаток по футболкам ProCotton, размер L.', isMine: true, createdAt: DateTime.now().subtract(const Duration(minutes: 40))),
    ChatMessage(id: 'm2', text: 'Добрый день! На складе 760 шт, белый цвет.', isMine: false, createdAt: DateTime.now().subtract(const Duration(minutes: 35))),
    ChatMessage(id: 'm3', text: 'Отлично, оформляю заказ на 200 штук.', isMine: true, createdAt: DateTime.now().subtract(const Duration(minutes: 30))),
    ChatMessage(id: 'm4', text: 'Приняли, ждите подтверждение в течение часа.', isMine: false, createdAt: DateTime.now().subtract(const Duration(minutes: 28))),
  ];

  static Product productById(String id) => products.firstWhere((p) => p.id == id, orElse: () => products.first);
  static Order orderById(String id) => orders.firstWhere((o) => o.id == id, orElse: () => orders.first);
}
