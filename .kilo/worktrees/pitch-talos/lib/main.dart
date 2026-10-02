import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/cart_provider.dart';
import 'providers/currency_provider.dart';
import 'providers/favorites_provider.dart';
import 'routes/app_routes.dart';
import 'screens/admin/admin_add_product_screen.dart';
import 'screens/admin/admin_calculator_screen.dart';
import 'screens/admin/admin_catalog_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_orders_screen.dart';
import 'screens/admin/admin_settings_screen.dart';
import 'screens/add_listing_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/cargo_calculator_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/filters_screen.dart';
import 'screens/full_ai_screen.dart';
import 'screens/home_screen.dart';
import 'screens/my_listings_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/order_detail_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/quick_order_screen.dart';
import 'screens/register_screen.dart';
import 'screens/seller_profile_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const FullSellerApp());
}

class FullSellerApp extends StatelessWidget {
  const FullSellerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => CurrencyProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
      ],
      child: MaterialApp(
        title: 'FULL SELLER',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (_) => const SplashScreen(),
          AppRoutes.onboarding: (_) => const OnboardingScreen(),
          AppRoutes.auth: (_) => const AuthScreen(),
          AppRoutes.register: (_) => const RegisterScreen(),
          AppRoutes.home: (_) => const HomeScreen(),
          AppRoutes.categories: (_) => const CategoriesScreen(),
          AppRoutes.filters: (_) => const FiltersScreen(),
          AppRoutes.cart: (_) => const CartScreen(),
          AppRoutes.checkout: (_) => const CheckoutScreen(),
          AppRoutes.cargoCalculator: (_) => const CargoCalculatorScreen(),
          AppRoutes.fullAi: (_) => const FullAiScreen(),
          AppRoutes.sellerProfile: (_) => const SellerProfileScreen(),
          AppRoutes.favorites: (_) => const FavoritesScreen(),
          AppRoutes.orders: (_) => const OrdersScreen(),
          AppRoutes.chat: (_) => const ChatScreen(),
          AppRoutes.profile: (_) => const ProfileScreen(),
          AppRoutes.myListings: (_) => const MyListingsScreen(),
          AppRoutes.notifications: (_) => const NotificationsScreen(),
          AppRoutes.dashboard: (_) => const DashboardScreen(),
          AppRoutes.quickOrder: (_) => const QuickOrderScreen(),
          AppRoutes.adminDashboard: (_) => const AdminDashboardScreen(),
          AppRoutes.adminCatalog: (_) => const AdminCatalogScreen(),
          AppRoutes.adminOrders: (_) => const AdminOrdersScreen(),
          AppRoutes.adminCalculator: (_) => const AdminCalculatorScreen(),
          AppRoutes.adminSettings: (_) => const AdminSettingsScreen(),
        },
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case AppRoutes.productDetail:
              return MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: settings.arguments as String), settings: settings);
            case AppRoutes.orderDetail:
              return MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: settings.arguments as String), settings: settings);
            case AppRoutes.addListing:
              return MaterialPageRoute(builder: (_) => AddListingScreen(productId: settings.arguments as String?), settings: settings);
            case AppRoutes.adminAddProduct:
              return MaterialPageRoute(builder: (_) => AdminAddProductScreen(productId: settings.arguments as String?), settings: settings);
          }
          return null;
        },
      ),
    );
  }
}
