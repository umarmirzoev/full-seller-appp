import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/favorites_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/product_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<FavoritesProvider>().load();
  }

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>();
    final products = favorites.products;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(children: [
          const AppTopBar(showNotifications: false),
          Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 14), child: Text('Избранное', style: AppTextStyles.display(size: 19))),
          Expanded(
            child: favorites.isLoading && products.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : products.isEmpty
                    ? Center(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.favorite_border_rounded, size: 44, color: AppColors.g200),
                          const SizedBox(height: 10),
                          Text('Пока нет избранных товаров', style: AppTextStyles.body(size: 13, weight: FontWeight.w700, color: AppColors.text3)),
                        ]),
                      )
                    : RefreshIndicator(
                        onRefresh: () => context.read<FavoritesProvider>().load(),
                        child: GridView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 0.66),
                          itemCount: products.length,
                          itemBuilder: (context, i) => ProductCard(product: products[i]),
                        ),
                      ),
          ),
        ]),
      ),
    );
  }
}
