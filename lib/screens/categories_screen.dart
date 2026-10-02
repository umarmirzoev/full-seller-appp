import 'dart:async';
import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../routes/app_routes.dart';
import '../services/catalog_repository.dart';
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
  String? _brandId;
  double? _minPrice;
  double? _maxPrice;
  String? _sortBy;
  bool _argsApplied = false;
  List<Category> _categories = [];
  List<Product> _products = [];
  bool _loadingCategories = true;
  bool _loadingProducts = true;
  String _query = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsApplied) {
      _argsApplied = true;
      final arg = ModalRoute.of(context)?.settings.arguments;
      if (arg is String) _selectedCategoryId = arg;
      _loadProducts();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await CatalogRepository.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _loadingCategories = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingCategories = false);
    }
  }

  Future<void> _loadProducts() async {
    setState(() => _loadingProducts = true);
    try {
      final page = _query.isNotEmpty
          ? await CatalogRepository.search(_query, pageSize: 40)
          : await CatalogRepository.getProducts(
              categoryId: _selectedCategoryId,
              brandId: _brandId,
              minPrice: _minPrice,
              maxPrice: _maxPrice,
              sortBy: _sortBy,
              pageSize: 40,
            );
      if (!mounted) return;
      setState(() {
        _products = page.items;
        _loadingProducts = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingProducts = false);
    }
  }

  Future<void> _openFilters() async {
    final result = await Navigator.pushNamed(context, AppRoutes.filters) as Map<String, dynamic>?;
    if (result == null) return;
    setState(() {
      _selectedCategoryId = result['categoryId'] as String?;
      _brandId = result['brandId'] as String?;
      _minPrice = result['minPrice'] as double?;
      _maxPrice = result['maxPrice'] as double?;
      _sortBy = result['sortBy'] as String?;
    });
    _loadProducts();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _query = value.trim();
      _loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(children: [
          const AppTopBar(),
          SearchRow(onFilterTap: _openFilters, hint: 'Поиск товара', onChanged: _onSearchChanged),
          if (_loadingCategories)
            const SizedBox(height: 40, child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))))
          else
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _categories.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return _chip('Все', _selectedCategoryId == null, () {
                      setState(() => _selectedCategoryId = null);
                      _loadProducts();
                    });
                  }
                  final c = _categories[i - 1];
                  return _chip(c.name, _selectedCategoryId == c.id, () {
                    setState(() => _selectedCategoryId = c.id);
                    _loadProducts();
                  });
                },
              ),
            ),
          const SizedBox(height: 14),
          Expanded(
            child: _loadingProducts
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? Center(child: Text('Товары не найдены', style: AppTextStyles.body(color: AppColors.text3)))
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 0.66,
                        ),
                        itemCount: _products.length,
                        itemBuilder: (context, i) => ProductCard(product: _products[i]),
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
