import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/brand.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../providers/currency_provider.dart';
import '../providers/favorites_provider.dart';
import '../routes/app_routes.dart';
import '../services/catalog_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/auth_ui.dart' show Reveal, HoverScale;
import '../widgets/category_strip.dart' show categoryIcon;
import '../widgets/placeholder_image.dart';
import '../widgets/product_card.dart';
import '../widgets/search_row.dart';

/// Каталог: поиск, категории, активные фильтры (снимаются одним нажатием), сортировка,
/// сетка/список, подгрузка следующих страниц при прокрутке.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  static const _pageSize = 20;
  static const _sorts = [
    ('popular', 'По популярности', Icons.local_fire_department_rounded),
    ('price_asc', 'Сначала дешевле', Icons.trending_down_rounded),
    ('price_desc', 'Сначала дороже', Icons.trending_up_rounded),
    ('rating', 'По рейтингу', Icons.star_rounded),
  ];

  String? _selectedCategoryId;
  String? _brandId;
  double? _minPrice;
  double? _maxPrice;
  String? _sortBy;
  bool _argsApplied = false;

  List<Category> _categories = [];
  List<Brand> _brands = [];
  List<Product> _products = [];
  int _total = 0;
  int _page = 1;
  bool _hasMore = false;
  bool _loadingCategories = true;
  bool _loadingProducts = true;
  bool _loadingMore = false;
  bool _failed = false;
  bool _grid = true;
  int _req = 0;

  String _query = '';
  final _searchController = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 600) _loadMore();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsApplied) return;
    _argsApplied = true;
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is String) _selectedCategoryId = arg;
    if (arg is Map && arg['filters'] is Map) {
      final f = arg['filters'] as Map;
      _selectedCategoryId = f['categoryId'] as String?;
      _brandId = f['brandId'] as String?;
      _minPrice = (f['minPrice'] as num?)?.toDouble();
      _maxPrice = (f['maxPrice'] as num?)?.toDouble();
      _sortBy = f['sortBy'] as String?;
    }
    if (arg is Map && arg['query'] is String) {
      _query = (arg['query'] as String).trim();
      _searchController.text = _query;
    }
    _loadProducts();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ─────────────────────────── Данные ───────────────────────────

  Future<void> _loadCategories() async {
    try {
      final r = await Future.wait([CatalogRepository.getCategories(), CatalogRepository.getBrands()]);
      if (!mounted) return;
      setState(() {
        _categories = r[0] as List<Category>;
        _brands = r[1] as List<Brand>;
        _loadingCategories = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<ProductPage> _fetch(int page) => _query.isNotEmpty
      ? CatalogRepository.search(_query, page: page, pageSize: _pageSize)
      : CatalogRepository.getProducts(
          categoryId: _selectedCategoryId,
          brandId: _brandId,
          minPrice: _minPrice,
          maxPrice: _maxPrice,
          sortBy: _sortBy,
          page: page,
          pageSize: _pageSize,
        );

  Future<void> _loadProducts() async {
    final req = ++_req;
    setState(() {
      _loadingProducts = true;
      _failed = false;
    });
    try {
      final page = await _fetch(1);
      if (!mounted || req != _req) return;
      setState(() {
        _products = page.items;
        _total = page.totalCount;
        _page = 1;
        _hasMore = page.hasMore;
        _loadingProducts = false;
      });
    } catch (_) {
      if (!mounted || req != _req) return;
      setState(() {
        _loadingProducts = false;
        _failed = true;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _loadingProducts || !_hasMore) return;
    final req = _req;
    setState(() => _loadingMore = true);
    try {
      final page = await _fetch(_page + 1);
      if (!mounted || req != _req) return;
      setState(() {
        _products = [..._products, ...page.items];
        _page = page.page;
        _hasMore = page.hasMore;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  // ─────────────────────────── Действия ───────────────────────────

  Future<void> _openFilters() async {
    final result = await Navigator.pushNamed(context, AppRoutes.filters, arguments: {
      'categoryId': _selectedCategoryId,
      'brandId': _brandId,
      'minPrice': _minPrice,
      'maxPrice': _maxPrice,
      'sortBy': _sortBy,
    });
    if (result is! Map) return;
    setState(() {
      _selectedCategoryId = result['categoryId'] as String?;
      _brandId = result['brandId'] as String?;
      _minPrice = (result['minPrice'] as num?)?.toDouble();
      _maxPrice = (result['maxPrice'] as num?)?.toDouble();
      _sortBy = result['sortBy'] as String?;
      _clearSearch(reload: false);
    });
    _loadProducts();
  }

  void _clearSearch({bool reload = true}) {
    _query = '';
    _searchController.clear();
    if (reload) _loadProducts();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _query = value.trim();
      _loadProducts();
    });
  }

  void _selectCategory(String? id) {
    if (_selectedCategoryId == id && _query.isEmpty) return;
    setState(() {
      _selectedCategoryId = id;
      _clearSearch(reload: false);
    });
    _loadProducts();
  }

  void _resetAll() {
    setState(() {
      _selectedCategoryId = null;
      _brandId = null;
      _minPrice = null;
      _maxPrice = null;
      _sortBy = null;
      _clearSearch(reload: false);
    });
    _loadProducts();
  }

  Future<void> _pickSort() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SortSheet(current: _sortBy ?? 'popular', sorts: _sorts),
    );
    if (picked == null || picked == (_sortBy ?? 'popular')) return;
    setState(() => _sortBy = picked);
    _loadProducts();
  }

  String get _sortLabel => _sorts.firstWhere((s) => s.$1 == (_sortBy ?? 'popular'), orElse: () => _sorts.first).$2;

  String _fmtPrice(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  List<(String, VoidCallback)> get _activeFilters {
    final list = <(String, VoidCallback)>[];
    if (_query.isNotEmpty) list.add(('«$_query»', () => _clearSearch()));
    if (_brandId != null) {
      var name = 'Бренд';
      for (final b in _brands) {
        if (b.id == _brandId) name = b.name;
      }
      list.add((name, () {
        setState(() => _brandId = null);
        _loadProducts();
      }));
    }
    if (_minPrice != null || _maxPrice != null) {
      final label = _minPrice != null && _maxPrice != null
          ? '${_fmtPrice(_minPrice!)}–${_fmtPrice(_maxPrice!)} ₽'
          : (_minPrice != null ? 'от ${_fmtPrice(_minPrice!)} ₽' : 'до ${_fmtPrice(_maxPrice!)} ₽');
      list.add((label, () {
        setState(() {
          _minPrice = null;
          _maxPrice = null;
        });
        _loadProducts();
      }));
    }
    return list;
  }

  String _plural(int n) {
    final m10 = n % 10, m100 = n % 100;
    if (m10 == 1 && m100 != 11) return 'товар';
    if (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)) return 'товара';
    return 'товаров';
  }

  // ─────────────────────────── UI ───────────────────────────

  @override
  Widget build(BuildContext context) {
    final filters = _activeFilters;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(children: [
              const AppTopBar(),
              Reveal(
                child: SearchRow(
                  controller: _searchController,
                  onFilterTap: _openFilters,
                  hint: 'Поиск: носки, футболки, бельё…',
                  onChanged: _onSearchChanged,
                  onSubmitted: (v) {
                    _debounce?.cancel();
                    _query = v.trim();
                    _loadProducts();
                  },
                ),
              ),
              _categoryChips(),
              const SizedBox(height: 10),
              _toolbar(),
              AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: filters.isEmpty
                    ? const SizedBox(width: double.infinity)
                    : SizedBox(
                        height: 46,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
                          children: [
                            for (final f in filters) Padding(padding: const EdgeInsets.only(right: 8), child: _RemovableChip(label: f.$1, onRemove: f.$2)),
                            HoverScale(
                              onTap: _resetAll,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                child: Text('Сбросить всё', style: AppTextStyles.body(size: 12.5, weight: FontWeight.w800, color: AppColors.danger)),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 6),
              Expanded(child: _content()),
            ]),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(current: AppTab.categories),
    );
  }

  Widget _categoryChips() {
    if (_loadingCategories) {
      return const SizedBox(height: 44, child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))));
    }
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final isAll = i == 0;
          final c = isAll ? null : _categories[i - 1];
          return _CatChip(
            index: i,
            label: isAll ? 'Все' : c!.name,
            icon: isAll ? Icons.apps_rounded : categoryIcon(c!.name),
            active: _query.isEmpty && _selectedCategoryId == c?.id,
            onTap: () => _selectCategory(c?.id),
          );
        },
      ),
    );
  }

  Widget _toolbar() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
        child: Row(children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                _loadingProducts ? 'Загрузка…' : '$_total ${_plural(_total)}',
                key: ValueKey('$_loadingProducts$_total'),
                style: AppTextStyles.display(size: 15, weight: FontWeight.w800),
              ),
            ),
          ),
          HoverScale(
            onTap: _query.isEmpty ? _pickSort : null,
            child: AnimatedOpacity(
              opacity: _query.isEmpty ? 1 : 0.4,
              duration: const Duration(milliseconds: 200),
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 1.3),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.swap_vert_rounded, size: 18, color: AppColors.g600),
                  const SizedBox(width: 6),
                  Text(_sortLabel, style: AppTextStyles.body(size: 12.5, weight: FontWeight.w800)),
                ]),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _ViewToggle(grid: _grid, onChanged: (g) => setState(() => _grid = g)),
        ]),
      );

  Widget _content() {
    if (_loadingProducts) return _Skeleton(grid: _grid);
    if (_failed) {
      return _EmptyState(
        icon: Icons.wifi_off_rounded,
        title: 'Не удалось загрузить товары',
        subtitle: 'Проверьте интернет и попробуйте снова',
        action: 'Повторить',
        onAction: _loadProducts,
      );
    }
    if (_products.isEmpty) {
      final hasFilters = _query.isNotEmpty || _selectedCategoryId != null || _brandId != null || _minPrice != null || _maxPrice != null;
      return _EmptyState(
        icon: Icons.search_off_rounded,
        title: 'Ничего не нашлось',
        subtitle: hasFilters ? 'Попробуйте изменить запрос или снять фильтры' : 'Товары скоро появятся',
        action: hasFilters ? 'Сбросить фильтры' : null,
        onAction: hasFilters ? _resetAll : null,
      );
    }

    final footer = _loadingMore
        ? const Padding(
            padding: EdgeInsets.all(18),
            child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.primary))),
          )
        : (!_hasMore && _products.length > 6
            ? Padding(
                padding: const EdgeInsets.all(18),
                child: Center(child: Text('Это все товары 🎉', style: AppTextStyles.body(size: 12.5, weight: FontWeight.w700, color: AppColors.text3))),
              )
            : const SizedBox(height: 12));

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadProducts,
      child: TweenAnimationBuilder<double>(
        key: ValueKey(_grid),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 320),
        builder: (context, v, child) => Opacity(opacity: v, child: child),
        child: _grid
            ? LayoutBuilder(
                key: const ValueKey('grid'),
                builder: (context, box) {
                  final w = box.maxWidth;
                  final cols = w < 560 ? 2 : (w < 860 ? 3 : 4);
                  return CustomScrollView(
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                        sliver: SliverGrid(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.64,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => Reveal(delayMs: 50 * (i % _pageSize % 8), dy: 24, child: ProductCard(product: _products[i])),
                            childCount: _products.length,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(child: footer),
                    ],
                  );
                },
              )
            : ListView.separated(
                key: const ValueKey('list'),
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                itemCount: _products.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) => i == _products.length
                    ? footer
                    : Reveal(delayMs: 50 * (i % 8), child: _ProductRow(product: _products[i])),
              ),
      ),
    );
  }
}

// ─────────────────────────── Виджеты ───────────────────────────

class _CatChip extends StatefulWidget {
  final int index;
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _CatChip({required this.index, required this.label, required this.icon, required this.active, required this.onTap});

  @override
  State<_CatChip> createState() => _CatChipState();
}

class _CatChipState extends State<_CatChip> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    final on = widget.active;
    final fg = on ? Colors.white : (_h ? AppColors.g700 : AppColors.text2);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + widget.index * 60),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(12 * (1 - v), 0), child: child)),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _h = true),
        onExit: (_) => setState(() => _h = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              gradient: on ? AppColors.brandGradient : null,
              color: on ? null : (_h ? AppColors.g50 : AppColors.surface),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: on ? Colors.transparent : (_h ? AppColors.g200 : AppColors.border), width: 1.3),
              boxShadow: on ? [BoxShadow(color: AppColors.g500.withValues(alpha: 0.32), blurRadius: 12, offset: const Offset(0, 5))] : null,
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              AnimatedRotation(
                turns: _h && !on ? -0.05 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(widget.icon, size: 17, color: on ? Colors.white : AppColors.g600),
              ),
              const SizedBox(width: 7),
              Text(widget.label, style: AppTextStyles.body(size: 13, weight: FontWeight.w800, color: fg)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _RemovableChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _RemovableChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) => HoverScale(
        onTap: onRemove,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 0, 6, 0),
          decoration: BoxDecoration(
            color: AppColors.g50,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.g200),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(label, style: AppTextStyles.body(size: 12.5, weight: FontWeight.w800, color: AppColors.g700)),
            const SizedBox(width: 4),
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(color: AppColors.g500, shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded, size: 13, color: Colors.white),
            ),
          ]),
        ),
      );
}

class _ViewToggle extends StatelessWidget {
  final bool grid;
  final ValueChanged<bool> onChanged;
  const _ViewToggle({required this.grid, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
        height: 38,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _btn(Icons.grid_view_rounded, grid, () => onChanged(true)),
          _btn(Icons.view_agenda_rounded, !grid, () => onChanged(false)),
        ]),
      );

  Widget _btn(IconData icon, bool on, VoidCallback onTap) => HoverScale(
        hover: 1.08,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 36,
          decoration: BoxDecoration(
            color: on ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: on ? [BoxShadow(color: AppColors.g900.withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(0, 2))] : null,
          ),
          child: Icon(icon, size: 17, color: on ? AppColors.g600 : AppColors.text3),
        ),
      );
}

/// Товар строкой (режим «список»).
class _ProductRow extends StatefulWidget {
  final Product product;
  const _ProductRow({required this.product});

  @override
  State<_ProductRow> createState() => _ProductRowState();
}

class _ProductRowState extends State<_ProductRow> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final currency = context.watch<CurrencyProvider>();
    final isFav = context.watch<FavoritesProvider>().isFavorite(p.id);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, AppRoutes.productDetail, arguments: p.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 124,
          transform: Matrix4.translationValues(_h ? 4 : 0, 0, 0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _h ? AppColors.g200 : AppColors.borderSoft, width: 1.3),
            boxShadow: [BoxShadow(color: AppColors.g900.withValues(alpha: _h ? 0.1 : 0.04), blurRadius: _h ? 20 : 10, offset: const Offset(0, 6))],
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(children: [
            SizedBox(
              width: 116,
              height: double.infinity,
              child: AnimatedScale(
                scale: _h ? 1.08 : 1,
                duration: const Duration(milliseconds: 400),
                child: PlaceholderImage(width: 116, height: 124, imageUrl: p.imageUrls.isNotEmpty ? p.imageUrls.first : null),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (p.brandName != null)
                    Text(p.brandName!.toUpperCase(), style: AppTextStyles.body(size: 10.5, weight: FontWeight.w800, color: AppColors.g600).copyWith(letterSpacing: 0.5)),
                  Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.body(size: 13.5, weight: FontWeight.w800)),
                  const Spacer(),
                  Row(children: [
                    const Icon(Icons.star_rounded, size: 15, color: AppColors.star),
                    const SizedBox(width: 3),
                    Text(p.rating.toStringAsFixed(1), style: AppTextStyles.body(size: 11.5, weight: FontWeight.w800)),
                    const SizedBox(width: 8),
                    Text('${p.reviewsCount} отз.', style: AppTextStyles.body(size: 11, weight: FontWeight.w600, color: AppColors.text3)),
                  ]),
                  const SizedBox(height: 4),
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(currency.format(p.minPrice), style: AppTextStyles.mono(size: 16, color: _h ? AppColors.g700 : AppColors.text)),
                    const SizedBox(width: 4),
                    Text('/шт', style: AppTextStyles.body(size: 10.5, weight: FontWeight.w600, color: AppColors.text3)),
                  ]),
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const SizedBox(height: 4),
                HoverScale(
                  hover: 1.15,
                  onTap: () => context.read<FavoritesProvider>().toggle(p),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                    child: Icon(
                      isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      key: ValueKey(isFav),
                      color: isFav ? AppColors.danger : AppColors.text3,
                      size: 22,
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 34,
                  height: 34,
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    gradient: _h ? AppColors.brandGradient : null,
                    color: _h ? null : AppColors.g50,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(Icons.arrow_forward_rounded, size: 18, color: _h ? Colors.white : AppColors.g600),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _SortSheet extends StatelessWidget {
  final String current;
  final List<(String, String, IconData)> sorts;
  const _SortSheet({required this.current, required this.sorts});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        decoration: const BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: SafeArea(
          top: false,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 42, height: 5, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(3)))),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 16, 6, 12),
              child: Text('Сортировка', style: AppTextStyles.display(size: 18, weight: FontWeight.w800)),
            ),
            for (var i = 0; i < sorts.length; i++)
              Reveal(
                delayMs: 50 * i,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: HoverScale(
                    hover: 1.01,
                    onTap: () => Navigator.pop(context, sorts[i].$1),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: sorts[i].$1 == current ? AppColors.g50 : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: sorts[i].$1 == current ? AppColors.g200 : AppColors.borderSoft, width: 1.3),
                      ),
                      child: Row(children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: sorts[i].$1 == current ? AppColors.brandGradient : null,
                            color: sorts[i].$1 == current ? null : AppColors.surface2,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(sorts[i].$3, size: 18, color: sorts[i].$1 == current ? Colors.white : AppColors.g600),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(sorts[i].$2, style: AppTextStyles.body(size: 14, weight: FontWeight.w800))),
                        if (sorts[i].$1 == current) const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22),
                      ]),
                    ),
                  ),
                ),
              ),
          ]),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? action;
  final VoidCallback? onAction;
  const _EmptyState({required this.icon, required this.title, required this.subtitle, this.action, this.onAction});

  @override
  Widget build(BuildContext context) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(30, 50, 30, 30),
        children: [
          Reveal(
            child: Column(children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.6, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, s, child) => Transform.scale(scale: s, child: child),
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: const BoxDecoration(color: AppColors.g50, shape: BoxShape.circle),
                  child: Icon(icon, size: 40, color: AppColors.g500),
                ),
              ),
              const SizedBox(height: 16),
              Text(title, textAlign: TextAlign.center, style: AppTextStyles.display(size: 16, weight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(subtitle, textAlign: TextAlign.center, style: AppTextStyles.body(size: 13, weight: FontWeight.w600, color: AppColors.text3)),
              if (action != null) ...[
                const SizedBox(height: 18),
                HoverScale(
                  onTap: onAction,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(16)),
                    child: Text(action!, style: AppTextStyles.body(size: 14, weight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
              ],
            ]),
          ),
        ],
      );
}

class _Skeleton extends StatefulWidget {
  final bool grid;
  const _Skeleton({required this.grid});

  @override
  State<_Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<_Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _box({double? h, double r = 20}) => AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Container(
          height: h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(r),
            gradient: LinearGradient(
              begin: Alignment(-1.5 + _c.value * 3, 0),
              end: Alignment(-0.5 + _c.value * 3, 0),
              colors: const [AppColors.surface2, AppColors.surface3, AppColors.surface2],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (!widget.grid) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => _box(h: 124),
      );
    }
    return LayoutBuilder(builder: (context, box) {
      final cols = box.maxWidth < 560 ? 2 : (box.maxWidth < 860 ? 3 : 4);
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
        itemCount: cols * 3,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, crossAxisSpacing: 14, mainAxisSpacing: 16, childAspectRatio: 0.64),
        itemBuilder: (_, __) => _box(r: 24),
      );
    });
  }
}
