import 'dart:async';

import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/review.dart';
import '../routes/app_routes.dart';
import '../services/catalog_repository.dart';
import '../providers/cart_provider.dart';
import '../providers/currency_provider.dart';
import '../services/reviews_repository.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';
import '../widgets/advantages_grid.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/category_strip.dart';
import '../widgets/currency_toggle.dart';
import '../widgets/product_card.dart';
import '../widgets/review_card.dart';
import '../widgets/search_row.dart';
import '../widgets/section_title.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Category> _categories = [];
  List<Product> _products = [];
  List<Review> _reviews = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    unawaited(context.read<CartProvider>().load());
    unawaited(context.read<CurrencyProvider>().loadRate());
    try {
      final categories = await CatalogRepository.getCategories();
      final page = await CatalogRepository.getProducts(pageSize: 12);
      var reviews = <Review>[];
      if (page.items.isNotEmpty) {
        reviews = await ReviewsRepository.getByProduct(page.items.first.id);
      }
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _products = page.items;
        _reviews = reviews;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(children: [
          const AppTopBar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Каталог FULL SELLER', style: AppTextStyles.body(size: 12.5, weight: FontWeight.w700, color: AppColors.text3)),
              const CurrencyToggle(),
            ]),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        SearchRow(onFilterTap: () => Navigator.pushNamed(context, AppRoutes.filters)),
                        CategoryStrip(
                          categories: _categories,
                          onTap: (c) => Navigator.pushNamed(context, AppRoutes.categories, arguments: c.id),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(AppRadius.lg)),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Скидка 15% на первую партию', style: AppTextStyles.display(size: 16.5, color: Colors.white)),
                              const SizedBox(height: 6),
                              Text('При заказе от 500 единиц товара', style: AppTextStyles.body(size: 12.5, weight: FontWeight.w600, color: Colors.white.withOpacity(0.85))),
                            ]),
                          ),
                        ),
                        SectionTitle(title: 'Хиты продаж', actionLabel: 'Смотреть все', onAction: () => Navigator.pushNamed(context, AppRoutes.categories)),
                        if (_products.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text('Товары пока не добавлены', style: AppTextStyles.body(size: 12.5, weight: FontWeight.w600, color: AppColors.text3)),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 0.66,
                              children: _products.map((p) => ProductCard(product: p)).toList(),
                            ),
                          ),
                        const SizedBox(height: 12),
                        const AdvantagesGrid(),
                        if (_reviews.isNotEmpty) ...[
                          SectionTitle(title: 'Отзывы покупателей'),
                          SizedBox(
                            height: 150,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: _reviews.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemBuilder: (context, i) => ReviewCard(review: _reviews[i]),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
          ),
        ]),
      ),
      bottomNavigationBar: const AppBottomNav(current: AppTab.home),
    );
  }
}
