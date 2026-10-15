import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_banner.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/review.dart';
import '../providers/cart_provider.dart';
import '../providers/currency_provider.dart';
import '../routes/app_routes.dart';
import '../services/banners_repository.dart';
import '../services/catalog_repository.dart';
import '../services/profile_repository.dart';
import '../services/reviews_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/auth_ui.dart' show Reveal, HoverScale;
import '../widgets/category_strip.dart';
import '../widgets/currency_toggle.dart';
import '../widgets/product_card.dart';
import '../widgets/review_card.dart';
import '../widgets/search_row.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  List<Category> _categories = [];
  List<Product> _products = [];
  List<Review> _reviews = [];
  List<AppBanner> _banners = [];
  String? _name;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    unawaited(context.read<CartProvider>().load());
    unawaited(context.read<CurrencyProvider>().loadRate());
    unawaited(_loadExtras());
    try {
      final results = await Future.wait<Object>([
        CatalogRepository.getCategories(),
        CatalogRepository.getProducts(pageSize: 12),
      ]);
      final page = results[1] as ProductPage;
      if (!mounted) return;
      setState(() {
        _categories = results[0] as List<Category>;
        _products = page.items;
        _loading = false;
      });
      if (page.items.isNotEmpty) {
        try {
          final reviews = await ReviewsRepository.getByProduct(page.items.first.id);
          if (mounted) setState(() => _reviews = reviews);
        } catch (_) {}
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  /// Имя для приветствия и баннеры — необязательны, ошибки не мешают главной.
  Future<void> _loadExtras() async {
    try {
      final user = await ProfileRepository.getProfile();
      final first = user.fullName.trim().split(RegExp(r'\s+')).first;
      if (mounted && first.isNotEmpty) setState(() => _name = first);
    } catch (_) {}
    try {
      final banners = await BannersRepository.getActive();
      if (mounted) setState(() => _banners = banners.where((b) => b.isActive && b.title.trim().isNotEmpty).toList());
    } catch (_) {}
  }

  void _search(String q) {
    final query = q.trim();
    Navigator.pushNamed(context, AppRoutes.categories, arguments: query.isEmpty ? null : {'query': query});
  }

  Future<void> _openFilters() async {
    final result = await Navigator.pushNamed(context, AppRoutes.filters);
    if (!mounted || result is! Map) return;
    Navigator.pushNamed(context, AppRoutes.categories, arguments: {'filters': result});
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 5) return 'Доброй ночи';
    if (h < 12) return 'Доброе утро';
    if (h < 18) return 'Добрый день';
    return 'Добрый вечер';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(children: [
              const AppTopBar(),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 28),
                    children: [
                      Reveal(child: _header()),
                      Reveal(
                        delayMs: 60,
                        child: SearchRow(
                          controller: _searchController,
                          hint: 'Поиск: носки, футболки, бельё…',
                          onSubmitted: _search,
                          onFilterTap: _openFilters,
                        ),
                      ),
                      if (_loading)
                        const _HomeSkeleton()
                      else if (_failed && _products.isEmpty)
                        _ErrorState(onRetry: _load)
                      else ...[
                        CategoryStrip(
                          categories: _categories,
                          onAll: () => Navigator.pushNamed(context, AppRoutes.categories),
                          onTap: (c) => Navigator.pushNamed(context, AppRoutes.categories, arguments: c.id),
                        ),
                        const SizedBox(height: 10),
                        Reveal(delayMs: 120, child: _PromoCarousel(banners: _banners)),
                        const SizedBox(height: 20),
                        Reveal(delayMs: 180, child: const _QuickActions()),
                        const SizedBox(height: 24),
                        _SectionHeader(
                          title: 'Хиты продаж',
                          icon: Icons.local_fire_department_rounded,
                          action: 'Смотреть все',
                          onAction: () => Navigator.pushNamed(context, AppRoutes.categories),
                        ),
                        _productsGrid(),
                        const SizedBox(height: 26),
                        const _SectionHeader(title: 'Почему FULL SELLER', icon: Icons.verified_rounded),
                        const _Advantages(),
                        if (_reviews.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const _SectionHeader(title: 'Отзывы покупателей', icon: Icons.forum_rounded),
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
                      ],
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(current: AppTab.home),
    );
  }

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                _name == null ? '$_greeting! 👋' : '$_greeting, $_name! 👋',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.display(size: 19, weight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text('Оптовые цены напрямую от фабрики', style: AppTextStyles.body(size: 12.8, weight: FontWeight.w600, color: AppColors.text3)),
            ]),
          ),
          const SizedBox(width: 10),
          const CurrencyToggle(),
        ]),
      );

  Widget _productsGrid() {
    if (_products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(children: [
          const Icon(Icons.inventory_2_outlined, size: 44, color: AppColors.g200),
          const SizedBox(height: 8),
          Text('Товары пока не добавлены', style: AppTextStyles.body(size: 13.5, weight: FontWeight.w700, color: AppColors.text3)),
        ]),
      );
    }
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      final cols = w < 560 ? 2 : (w < 860 ? 3 : 4);
      return GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _products.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: 14,
          mainAxisSpacing: 16,
          childAspectRatio: 0.64,
        ),
        itemBuilder: (context, i) => Reveal(delayMs: 60 * (i % 8), dy: 26, child: ProductCard(product: _products[i])),
      );
    });
  }
}

// ─────────────────────────── Заголовок секции ───────────────────────────

class _SectionHeader extends StatefulWidget {
  final String title;
  final IconData icon;
  final String? action;
  final VoidCallback? onAction;
  const _SectionHeader({required this.title, required this.icon, this.action, this.onAction});

  @override
  State<_SectionHeader> createState() => _SectionHeaderState();
}

class _SectionHeaderState extends State<_SectionHeader> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Row(children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(color: AppColors.g50, borderRadius: BorderRadius.circular(10)),
          child: Icon(widget.icon, size: 18, color: AppColors.g600),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(widget.title, style: AppTextStyles.display(size: 16.5, weight: FontWeight.w800))),
        if (widget.action != null)
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _h = true),
            onExit: (_) => setState(() => _h = false),
            child: GestureDetector(
              onTap: widget.onAction,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(color: _h ? AppColors.g50 : Colors.transparent, borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(widget.action!, style: AppTextStyles.body(size: 12.5, weight: FontWeight.w800, color: AppColors.g700)),
                  AnimatedPadding(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.only(left: _h ? 8 : 4),
                    child: const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.g700),
                  ),
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}

// ─────────────────────────── Промо-карусель ───────────────────────────

class _Promo {
  final String title;
  final String subtitle;
  final String cta;
  final IconData icon;
  final List<Color> colors;
  final void Function(BuildContext) onTap;
  const _Promo(this.title, this.subtitle, this.cta, this.icon, this.colors, this.onTap);
}

class _PromoCarousel extends StatefulWidget {
  final List<AppBanner> banners;
  const _PromoCarousel({required this.banners});

  @override
  State<_PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<_PromoCarousel> with SingleTickerProviderStateMixin {
  final _page = PageController();
  late final AnimationController _float = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  Timer? _timer;
  int _index = 0;

  static const _palettes = [
    [Color(0xFFFFB15C), Color(0xFFFF6A00), Color(0xFFFF3D00)],
    [Color(0xFF2B2B3A), Color(0xFF4A2A12), Color(0xFFC2410C)],
    [Color(0xFFFF8A3D), Color(0xFFE85D00), Color(0xFF9A3412)],
  ];

  List<_Promo> get _promos {
    if (widget.banners.isNotEmpty) {
      return [
        for (var i = 0; i < widget.banners.length; i++)
          _Promo(
            widget.banners[i].title,
            widget.banners[i].subtitle ?? '',
            'Подробнее',
            Icons.local_offer_rounded,
            _palettes[i % _palettes.length],
            (ctx) => _openBanner(ctx, widget.banners[i]),
          ),
      ];
    }
    return [
      _Promo('Скидка 15% на первую партию', 'При заказе от 500 единиц товара', 'В каталог', Icons.percent_rounded, _palettes[0],
          (ctx) => Navigator.pushNamed(ctx, AppRoutes.categories)),
      _Promo('Доставка карго в РФ и Таджикистан', 'Посчитайте стоимость за 10 секунд', 'Рассчитать', Icons.local_shipping_rounded, _palettes[1],
          (ctx) => Navigator.pushNamed(ctx, AppRoutes.cargoCalculator)),
      _Promo('FULL AI подберёт товар', 'Опишите, что нужно — ассистент соберёт партию', 'Спросить AI', Icons.auto_awesome_rounded, _palettes[2],
          (ctx) => Navigator.pushNamed(ctx, AppRoutes.fullAi)),
    ];
  }

  static Future<void> _openBanner(BuildContext ctx, AppBanner b) async {
    final link = b.linkUrl?.trim() ?? '';
    if (link.startsWith('http')) {
      await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
    } else {
      Navigator.pushNamed(ctx, AppRoutes.categories);
    }
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_page.hasClients) return;
      final next = (_index + 1) % _promos.length;
      _page.animateToPage(next, duration: const Duration(milliseconds: 650), curve: Curves.easeInOutCubic);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _page.dispose();
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final promos = _promos;
    return Column(children: [
      SizedBox(
        height: 176,
        child: PageView.builder(
          controller: _page,
          itemCount: promos.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (context, i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _PromoCard(promo: promos[i], float: _float),
          ),
        ),
      ),
      const SizedBox(height: 10),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(promos.length, (i) {
          final on = i == _index;
          return GestureDetector(
            onTap: () => _page.animateToPage(i, duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: on ? 22 : 7,
              height: 7,
              decoration: BoxDecoration(
                gradient: on ? AppColors.brandGradient : null,
                color: on ? null : AppColors.g100,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }),
      ),
    ]);
  }
}

class _PromoCard extends StatefulWidget {
  final _Promo promo;
  final AnimationController float;
  const _PromoCard({required this.promo, required this.float});

  @override
  State<_PromoCard> createState() => _PromoCardState();
}

class _PromoCardState extends State<_PromoCard> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.promo;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: () => p.onTap(context),
        child: AnimatedScale(
          scale: _h ? 1.015 : 1,
          duration: const Duration(milliseconds: 240),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: p.colors),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: p.colors[1].withValues(alpha: _h ? 0.45 : 0.28), blurRadius: _h ? 26 : 16, offset: const Offset(0, 10))],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(children: [
              // плавающие декоративные круги + иконка
              AnimatedBuilder(
                animation: widget.float,
                builder: (context, _) {
                  final t = widget.float.value * 2 * pi;
                  return Stack(children: [
                    Positioned(right: -30 + sin(t) * 8, top: -40 + cos(t) * 6, child: _circle(150, 0.12)),
                    Positioned(right: 60 + cos(t) * 10, bottom: -50 + sin(t) * 8, child: _circle(110, 0.08)),
                    Positioned(
                      right: 22,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Transform.translate(
                          offset: Offset(0, sin(t) * 5),
                          child: Transform.rotate(
                            angle: _h ? -0.12 : sin(t) * 0.05,
                            child: Icon(p.icon, size: 62, color: Colors.white.withValues(alpha: 0.9)),
                          ),
                        ),
                      ),
                    ),
                  ]);
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 96, 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.display(size: 16, weight: FontWeight.w800, color: Colors.white)),
                  if (p.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Flexible(
                      child: Text(p.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body(size: 12, weight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.88))),
                    ),
                  ],
                  const SizedBox(height: 10),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: _h ? 1 : 0.92), borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(p.cta, style: AppTextStyles.body(size: 12, weight: FontWeight.w800, color: p.colors[1])),
                      AnimatedPadding(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.only(left: _h ? 8 : 4),
                        child: Icon(Icons.arrow_forward_rounded, size: 15, color: p.colors[1]),
                      ),
                    ]),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _circle(double s, double a) => Container(
        width: s,
        height: s,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: a)),
      );
}

// ─────────────────────────── Быстрые действия ───────────────────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.local_shipping_rounded, 'Карго', 'расчёт', AppRoutes.cargoCalculator),
      (Icons.bolt_rounded, 'Быстрый', 'заказ', AppRoutes.quickOrder),
      (Icons.auto_awesome_rounded, 'FULL AI', 'подбор', AppRoutes.fullAi),
      (Icons.favorite_rounded, 'Избранное', 'товары', AppRoutes.favorites),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: _QuickTile(
                icon: items[i].$1,
                title: items[i].$2,
                subtitle: items[i].$3,
                onTap: () => Navigator.pushNamed(context, items[i].$4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _QuickTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  State<_QuickTile> createState() => _QuickTileState();
}

class _QuickTileState extends State<_QuickTile> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: HoverScale(
        hover: 1.0,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          transform: Matrix4.translationValues(0, _h ? -4 : 0, 0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _h ? AppColors.g200 : AppColors.borderSoft, width: 1.3),
            boxShadow: [BoxShadow(color: AppColors.g900.withValues(alpha: _h ? 0.1 : 0.04), blurRadius: _h ? 18 : 8, offset: Offset(0, _h ? 10 : 3))],
          ),
          child: Column(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: _h ? AppColors.brandGradient : null,
                color: _h ? null : AppColors.g50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: AnimatedRotation(
                turns: _h ? -0.04 : 0,
                duration: const Duration(milliseconds: 220),
                child: Icon(widget.icon, size: 22, color: _h ? Colors.white : AppColors.g600),
              ),
            ),
            const SizedBox(height: 8),
            Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.body(size: 12, weight: FontWeight.w800)),
            Text(widget.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.body(size: 10.5, weight: FontWeight.w600, color: AppColors.text3)),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────── Преимущества ───────────────────────────

class _Advantages extends StatelessWidget {
  const _Advantages();

  static const _items = [
    (Icons.local_shipping_rounded, 'Доставка от 1 дня', 'РФ и Таджикистан'),
    (Icons.verified_user_rounded, 'Гарантия качества', 'Проверка перед отправкой'),
    (Icons.trending_down_rounded, 'Оптовые цены', 'Чем больше — тем дешевле'),
    (Icons.support_agent_rounded, 'Поддержка 24/7', 'Онлайн-чат с менеджером'),
  ];

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.6).toDouble();
    return LayoutBuilder(builder: (context, box) {
      final cols = box.maxWidth < 640 ? 2 : 4;
      return GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          mainAxisExtent: 104 * textScale,
        ),
        itemBuilder: (context, i) => Reveal(delayMs: 80 * i, child: _AdvantageTile(item: _items[i])),
      );
    });
  }
}

class _AdvantageTile extends StatefulWidget {
  final (IconData, String, String) item;
  const _AdvantageTile({required this.item});

  @override
  State<_AdvantageTile> createState() => _AdvantageTileState();
}

class _AdvantageTileState extends State<_AdvantageTile> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    final (icon, title, sub) = widget.item;
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _h ? AppColors.surface : AppColors.surface2,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _h ? AppColors.g200 : Colors.transparent, width: 1.3),
          boxShadow: _h ? [BoxShadow(color: AppColors.g500.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 8))] : null,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedScale(
            scale: _h ? 1.15 : 1,
            duration: const Duration(milliseconds: 220),
            alignment: Alignment.centerLeft,
            child: Icon(icon, size: 22, color: AppColors.g600),
          ),
          const SizedBox(height: 8),
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.body(size: 12.5, weight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.body(size: 10.8, weight: FontWeight.w600, color: AppColors.text3)),
        ]),
      ),
    );
  }
}

// ─────────────────────────── Загрузка / ошибка ───────────────────────────

class _HomeSkeleton extends StatefulWidget {
  const _HomeSkeleton();

  @override
  State<_HomeSkeleton> createState() => _HomeSkeletonState();
}

class _HomeSkeletonState extends State<_HomeSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _box(double w, double h, double r) => AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Container(
          width: w,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: List.generate(5, (i) => Padding(padding: const EdgeInsets.only(right: 12), child: _box(62, 62, 20)))),
        const SizedBox(height: 20),
        _box(double.infinity, 150, 24),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: _box(double.infinity, 230, 24)),
          const SizedBox(width: 14),
          Expanded(child: _box(double.infinity, 230, 24)),
        ]),
      ]),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
        child: Column(children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(color: AppColors.g50, shape: BoxShape.circle),
            child: const Icon(Icons.wifi_off_rounded, color: AppColors.g600, size: 32),
          ),
          const SizedBox(height: 14),
          Text('Не удалось загрузить каталог', style: AppTextStyles.display(size: 15, weight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('Проверьте интернет и попробуйте снова', style: AppTextStyles.body(size: 12.8, weight: FontWeight.w600, color: AppColors.text3)),
          const SizedBox(height: 16),
          HoverScale(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(16)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('Повторить', style: AppTextStyles.body(size: 14, weight: FontWeight.w800, color: Colors.white)),
              ]),
            ),
          ),
        ]),
      );
}
