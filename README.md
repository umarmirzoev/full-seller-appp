# FULL SELLER — Flutter-приложение

Полный UI-слой приложения FULL SELLER (оптовый маркетплейс: носки, футболки, бельё, шорты, штаны),
собранный по дизайну ([артефакт-канвас](https://claude.ai) с 29 экранами, включая десктопную
админ-панель «режим ноутбука»). Экраны работают на моковых данных — бэкенд (ASP.NET Core API,
проект `full-seller-back`) подключим следующим шагом.

## Структура

```
lib/
  theme/       — цвета, радиусы, шрифты (Unbounded/Manrope/JetBrains Mono), ThemeData
  models/      — Product, Order, CartItem, AppUser, Category, Brand, PromoCode, AppBanner и т.д.
                 (поля 1-в-1 с DTO бэкенда — см. FullSeller.WebApi/Contracts/*)
  data/        — mock_data.dart: демо-каталог, заказы, отзывы, настройки (замена на API — см. ниже)
  providers/   — CartProvider, CurrencyProvider (₽/$), FavoritesProvider (package:provider)
  widgets/     — переиспользуемые компоненты (карточка товара, бейджи, нижняя навигация,
                 admin/ — сайдбар и виджеты десктопной админки)
  screens/     — все 23 мобильных экрана + screens/admin/ — 6 экранов «режима ноутбука»
  routes/      — именованные роуты (app_routes.dart), таблица маршрутов в main.dart
```

## Экраны

Онбординг и вход: Splash, Onboarding, Auth (SMS/Telegram), Register.
Покупки: Home, Categories, ProductDetail, Filters, Cart, Checkout, CargoCalculator.
Аккаунт: Orders, OrderDetail, Favorites, Profile, Notifications, Chat.
Поставщик: SellerProfile, MyListings, AddListing, Dashboard, QuickOrder, FullAI.
Админ-панель (десктоп/веб, широкий layout с сайдбаром): AdminDashboard, AdminCatalog,
AdminAddProduct, AdminOrders, AdminCalculator, AdminSettings.

## Запуск

```
flutter pub get
flutter run            # мобильное устройство/эмулятор
flutter run -d chrome   # для проверки десктопных admin-экранов в браузере
```

Экраны админ-панели рассчитаны на широкий экран — удобнее смотреть через `flutter run -d chrome`
или `flutter run -d windows/macos` (десктоп-таргеты можно включить через `flutter create --platforms=windows,macos,linux .`
в этой же папке, если понадобится нативная десктопная сборка).

## Следующий шаг — подключение к бэкенду

Сейчас все данные идут из `lib/data/mock_data.dart`. Бэкенд (`full-seller-back`) уже отдаёт
все нужные эндпоинты (`/api/catalog`, `/api/orders`, `/api/settings`, `/api/banners`,
`/api/promocodes`, `/api/delivery`, `/api/admin/catalog/**` и т.д.). План интеграции:

1. Добавить `http` или `dio` в `pubspec.yaml`, создать `lib/api/api_client.dart` с базовым URL
   и JWT-интерцептором (access/refresh токены — см. `AuthController` на бэкенде).
2. Один репозиторий на каждую группу эндпоинтов (`CatalogRepository`, `OrderRepository`, …),
   с маппингом JSON → модели из `lib/models/*` (поля уже совпадают с DTO бэкенда 1:1).
3. Заменить обращения к `MockData.*` на вызовы репозиториев внутри `FutureBuilder`/провайдеров
   (сами `CartProvider`/`CurrencyProvider` менять не обязательно — только источник данных).
4. `AuthScreen`/`RegisterScreen` — подключить реальный OTP-флоу и сохранение JWT (`flutter_secure_storage`).

## Важно

- Это UI-фаза: данные не сохраняются между запусками, изображения — плейсхолдеры (замена на
  `Image.network(url)` при интеграции).
- Статусы заказа (`lib/models/order.dart`) сейчас 6 штук на русском — под дизайн; на бэкенде
  сейчас 5 (`New/Processing/InTransit/Delivered/Cancelled`) — этот момент нужно свести перед
  интеграцией (обсуждали в бэкенд-сессии).
