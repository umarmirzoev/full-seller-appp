import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../routes/app_routes.dart';
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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final products = MockData.products;
    final reviews = MockData.reviewsFor('pr1');

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
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                SearchRow(onFilterTap: () => Navigator.pushNamed(context, AppRoutes.filters)),
                CategoryStrip(
                  categories: MockData.categories,
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.66,
                    children: products.map((p) => ProductCard(product: p)).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                const AdvantagesGrid(),
                SectionTitle(title: 'Отзывы покупателей'),
                SizedBox(
                  height: 150,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: reviews.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) => ReviewCard(review: reviews[i]),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ]),
      ),
      bottomNavigationBar: const AppBottomNav(current: AppTab.home),
    );
  }
}
