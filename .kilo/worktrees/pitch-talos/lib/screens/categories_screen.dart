import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../models/category.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/product_card.dart';
import '../widgets/search_row.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  String? _selectedCategoryId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is String) _selectedCategoryId = arg;
  }

  @override
  Widget build(BuildContext context) {
    final extra = <Category>[
      const Category(id: 'new', name: 'Новинки', slug: 'new', iconName: 'spark'),
      const Category(id: 'sale', name: 'Распродажа', slug: 'sale', iconName: 'tag'),
    ];
    final allCategories = [...MockData.categories, ...extra];
    final products = _selectedCategoryId == null || _selectedCategoryId == 'new' || _selectedCategoryId == 'sale'
        ? MockData.products
        : MockData.products.where((p) => p.categoryId == _selectedCategoryId).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(children: [
          const AppTopBar(),
          SearchRow(onFilterTap: () => Navigator.pushNamed(context, AppRoutes.filters), hint: 'Поиск товара'),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: allCategories.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                if (i == 0) return _chip('Все', _selectedCategoryId == null, () => setState(() => _selectedCategoryId = null));
                final c = allCategories[i - 1];
                return _chip(c.name, _selectedCategoryId == c.id, () => setState(() => _selectedCategoryId = c.id));
              },
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: products.isEmpty
                ? Center(child: Text('Товары не найдены', style: AppTextStyles.body(color: AppColors.text3)))
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 0.66,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, i) => ProductCard(product: products[i]),
                  ),
          ),
        ]),
      ),
      bottomNavigationBar: const AppBottomNav(current: AppTab.categories),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surface,
          border: Border.all(color: active ? AppColors.primary : AppColors.border),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: active ? Colors.white : AppColors.text2)),
      ),
    );
  }
}
