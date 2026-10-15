import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/product_variant.dart';
import '../models/review.dart';
import '../providers/cart_provider.dart';
import '../providers/currency_provider.dart';
import '../providers/favorites_provider.dart';
import '../routes/app_routes.dart';
import '../services/api_exception.dart';
import '../services/catalog_repository.dart';
import '../services/reviews_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/auth_ui.dart' show Reveal, HoverScale, GlowButton;
import '../widgets/currency_toggle.dart';
import '../widgets/placeholder_image.dart';
import '../widgets/product_card.dart';
import '../widgets/review_card.dart';
import '../widgets/star_rating.dart';

/// Карточка товара: галерея со свайпом и полноэкранным зумом, оптовые ступени цены
/// (нажатие ставит нужное количество), размеры/цвета с учётом остатков, быстрый выбор
/// количества, вес партии, похожие товары и добавление в корзину без ухода со страницы.
class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _qtyController = TextEditingController();
  final _scroll = ScrollController();
  final _reviewsKey = GlobalKey();

  String? _selectedSize;
  String? _selectedColor;
  int _quantity = 1;
  bool _loading = true;
  bool _adding = false;
  bool _added = false;
  String? _error;
  Product? _product;
  List<Review> _reviews = [];
  List<Product> _similar = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final product = await CatalogRepository.getProduct(widget.productId);
      if (!mounted) return;
      setState(() {
        _product = product;
        final firstInStock = product.variants.where((v) => v.stockQuantity > 0).toList();
        final v = firstInStock.isNotEmpty ? firstInStock.first : (product.variants.isNotEmpty ? product.variants.first : null);
        _selectedSize = v?.size;
        _selectedColor = v?.color;
        _setQty(product.priceTiers.isNotEmpty ? product.priceTiers.first.minQuantity : 1, notify: false);
        _loading = false;
      });
      unawaited(_loadExtras(product));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Не удалось загрузить товар';
      });
    }
  }

  Future<void> _loadExtras(Product product) async {
    try {
      final reviews = await ReviewsRepository.getByProduct(product.id);
      if (mounted) setState(() => _reviews = reviews);
    } catch (_) {}
    try {
      final page = await CatalogRepository.getProducts(categoryId: product.categoryId, pageSize: 12);
      if (mounted) setState(() => _similar = page.items.where((p) => p.id != product.id).take(10).toList());
    } catch (_) {}
  }

  // ─────────────────────────── Логика ───────────────────────────

  double _priceFor(Product p, int qty) {
    if (p.priceTiers.isEmpty) return p.minPrice;
    final tiers = [...p.priceTiers]..sort((a, b) => a.minQuantity.compareTo(b.minQuantity));
    var price = tiers.first.pricePerUnit;
    for (final t in tiers) {
      if (qty >= t.minQuantity) price = t.pricePerUnit;
    }
    return price;
  }

  ProductVariant? _variant(Product p) {
    if (p.variants.isEmpty) return null;
    for (final v in p.variants) {
      if (v.size == _selectedSize && v.color == _selectedColor) return v;
    }
    for (final v in p.variants) {
      if (v.size == _selectedSize || v.color == _selectedColor) return v;
    }
    return p.variants.first;
  }

  int _stockFor({String? size, String? color, required Product p}) {
    var sum = 0;
    for (final v in p.variants) {
      if ((size == null || v.size == size) && (color == null || v.color == color)) sum += v.stockQuantity;
    }
    return sum;
  }

  int get _minQty {
    final p = _product;
    if (p == null || p.priceTiers.isEmpty) return 1;
    return p.priceTiers.map((t) => t.minQuantity).reduce((a, b) => a < b ? a : b).clamp(1, 1 << 30);
  }

  void _setQty(int v, {bool notify = true}) {
    final max = _maxQty;
    var q = v < _minQty ? _minQty : v;
    if (max != null && max > 0 && q > max) q = max;
    void apply() {
      _quantity = q;
      final text = '$q';
      if (_qtyController.text != text) {
        _qtyController.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
      }
    }

    if (notify) {
      setState(apply);
    } else {
      apply();
    }
  }

  int? get _maxQty {
    final p = _product;
    if (p == null || p.variants.isEmpty) return null;
    final v = _variant(p);
    return v?.stockQuantity;
  }

  Future<void> _addToCart(Product product) async {
    final variant = _variant(product);
    if (variant == null) {
      _toast('Для этого товара нет доступных вариантов', error: true);
      return;
    }
    if (variant.stockQuantity <= 0) {
      _toast('Этого варианта нет в наличии', error: true);
      return;
    }
    setState(() => _adding = true);
    try {
      await context.read<CartProvider>().addVariant(variant.id, quantity: _quantity);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _adding = false;
        _added = true;
      });
      _toast('Добавлено в корзину: $_quantity шт', action: 'Корзина', onAction: () => Navigator.pushNamed(context, AppRoutes.cart));
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted) setState(() => _added = false);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _adding = false);
      _toast(e.isUnauthorized ? 'Войдите в аккаунт, чтобы добавить в корзину' : e.message, error: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _adding = false);
      _toast('Не удалось добавить товар в корзину', error: true);
    }
  }

  void _toast(String text, {bool error = false, String? action, VoidCallback? onAction}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        backgroundColor: error ? AppColors.danger : AppColors.text,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(children: [
          Icon(error ? Icons.error_outline_rounded : Icons.check_circle_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppTextStyles.body(size: 13.5, weight: FontWeight.w700, color: Colors.white))),
        ]),
        action: action == null ? null : SnackBarAction(label: action, textColor: AppColors.g200, onPressed: onAction ?? () {}),
      ));
  }

  void _scrollToReviews() {
    final ctx = _reviewsKey.currentContext;
    if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 600), curve: Curves.easeInOutCubic);
  }

  // ─────────────────────────── UI ───────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _DetailSkeleton();
    final product = _product;
    if (product == null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.wifi_off_rounded, size: 44, color: AppColors.g200),
              const SizedBox(height: 12),
              Text(_error ?? 'Товар не найден', style: AppTextStyles.display(size: 15, weight: FontWeight.w800)),
              const SizedBox(height: 16),
              Row(mainAxisSize: MainAxisSize.min, children: [
                HoverScale(onTap: () => Navigator.maybePop(context), child: _pillButton('Назад', outlined: true)),
                const SizedBox(width: 10),
                HoverScale(onTap: _load, child: _pillButton('Повторить')),
              ]),
            ]),
          ),
        ),
      );
    }

    final currency = context.watch<CurrencyProvider>();
    final unitPrice = _priceFor(product, _quantity);
    final basePrice = product.priceTiers.isEmpty ? product.minPrice : _priceFor(product, 0);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: LayoutBuilder(builder: (context, box) {
        final wide = box.maxWidth >= 900;
        final gallery = _Gallery(product: product);
        final info = _info(product, currency, unitPrice, basePrice);
        return Stack(children: [
          if (wide)
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 76, 12, 24),
                        child: ClipRRect(borderRadius: BorderRadius.circular(28), child: AspectRatio(aspectRatio: 0.95, child: gallery)),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(12, 80, 24, 120),
                      child: info,
                    ),
                  ),
                ]),
              ),
            )
          else
            SingleChildScrollView(
              controller: _scroll,
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(children: [
                AspectRatio(aspectRatio: 1, child: gallery),
                Transform.translate(
                  offset: const Offset(0, -22),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                    child: info,
                  ),
                ),
              ]),
            ),
          // плавающая шапка
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(children: [
                _CircleBtn(icon: Icons.arrow_back_rounded, onTap: () => Navigator.maybePop(context)),
                const Spacer(),
                const _GlassBox(child: CurrencyToggle()),
                const SizedBox(width: 8),
                _FavCircle(product: product),
                const SizedBox(width: 8),
                _CartCircle(),
              ]),
            ),
          ),
        ]);
      }),
      bottomNavigationBar: _bottomBar(product, currency, unitPrice),
    );
  }

  Widget _info(Product product, CurrencyProvider currency, double unitPrice, double basePrice) {
    final sizes = product.variants.map((v) => v.size).whereType<String>().toSet().toList();
    final colors = product.variants.map((v) => v.color).whereType<String>().toSet().toList();
    final variant = _variant(product);
    final stock = variant?.stockQuantity;
    final savingPct = basePrice > 0 && unitPrice < basePrice ? ((1 - unitPrice / basePrice) * 100).round() : 0;
    final tiers = [...product.priceTiers]..sort((a, b) => a.minQuantity.compareTo(b.minQuantity));
    final nextTier = tiers.where((t) => t.minQuantity > _quantity).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Reveal(
        child: Row(children: [
          if (product.brandName != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.g50, borderRadius: BorderRadius.circular(8)),
              child: Text(product.brandName!.toUpperCase(),
                  style: AppTextStyles.body(size: 11, weight: FontWeight.w800, color: AppColors.g700).copyWith(letterSpacing: 0.6)),
            ),
          if (product.brandName != null) const SizedBox(width: 8),
          BadgeRowInline(labels: product.badges),
        ]),
      ),
      const SizedBox(height: 10),
      Reveal(delayMs: 40, child: Text(product.name, style: AppTextStyles.display(size: 21, weight: FontWeight.w800))),
      const SizedBox(height: 10),
      Reveal(
        delayMs: 80,
        child: HoverScale(
          hover: 1.02,
          onTap: _scrollToReviews,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            StarRating(rating: product.rating, size: 17),
            const SizedBox(width: 6),
            Text(product.rating.toStringAsFixed(1), style: AppTextStyles.body(size: 13, weight: FontWeight.w800)),
            Text('  ·  ${product.reviewsCount} отзывов', style: AppTextStyles.body(size: 12.5, weight: FontWeight.w700, color: AppColors.g600)),
          ]),
        ),
      ),
      const SizedBox(height: 16),
      // ── Цена ──
      Reveal(
        delayMs: 120,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.borderSoft, width: 1.3),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (c, a) => SlideTransition(
                  position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(a),
                  child: FadeTransition(opacity: a, child: c),
                ),
                child: Text(currency.format(unitPrice), key: ValueKey(unitPrice), style: AppTextStyles.mono(size: 28, weight: FontWeight.w800)),
              ),
              const SizedBox(width: 6),
              Padding(padding: const EdgeInsets.only(bottom: 5), child: Text('/ шт', style: AppTextStyles.body(size: 12.5, color: AppColors.text3))),
              if (product.hasDiscount) ...[
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(currency.format(product.oldPrice!),
                      style: AppTextStyles.mono(size: 14, weight: FontWeight.w600, color: AppColors.text3).copyWith(decoration: TextDecoration.lineThrough)),
                ),
              ],
              const Spacer(),
              AnimatedScale(
                scale: savingPct > 0 ? 1 : 0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: const Color(0xFFE8F7EE), borderRadius: BorderRadius.circular(10)),
                  child: Text('−$savingPct%', style: AppTextStyles.body(size: 12.5, weight: FontWeight.w800, color: const Color(0xFF16A34A))),
                ),
              ),
            ]),
            if (nextTier.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.trending_down_rounded, size: 16, color: AppColors.g600),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Ещё ${nextTier.first.minQuantity - _quantity} шт — и цена ${currency.format(nextTier.first.pricePerUnit)}/шт',
                    style: AppTextStyles.body(size: 12.3, weight: FontWeight.w700, color: AppColors.g700),
                  ),
                ),
              ]),
            ],
          ]),
        ),
      ),
      // ── Оптовые ступени ──
      if (tiers.isNotEmpty) ...[
        const SizedBox(height: 20),
        _label('Оптовая шкала цен', Icons.stacked_bar_chart_rounded),
        Reveal(
          delayMs: 160,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(children: [
              for (var i = 0; i < tiers.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _TierCard(
                    qty: tiers[i].minQuantity,
                    price: currency.format(tiers[i].pricePerUnit),
                    active: _quantity >= tiers[i].minQuantity && (i == tiers.length - 1 || _quantity < tiers[i + 1].minQuantity),
                    onTap: () => _setQty(tiers[i].minQuantity),
                  ),
                ),
            ]),
          ),
        ),
      ],
      // ── Размер ──
      if (sizes.isNotEmpty) ...[
        const SizedBox(height: 20),
        _label('Размер', Icons.straighten_rounded),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final s in sizes)
            _OptionChip(
              label: s,
              active: s == _selectedSize,
              disabled: _stockFor(size: s, color: colors.isEmpty ? null : _selectedColor, p: product) <= 0,
              onTap: () {
                setState(() => _selectedSize = s);
                _setQty(_quantity);
              },
            ),
        ]),
      ],
      // ── Цвет ──
      if (colors.isNotEmpty) ...[
        const SizedBox(height: 20),
        _label('Цвет', Icons.palette_outlined),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final c in colors)
            _OptionChip(
              label: c,
              active: c == _selectedColor,
              disabled: _stockFor(color: c, size: sizes.isEmpty ? null : _selectedSize, p: product) <= 0,
              onTap: () {
                setState(() => _selectedColor = c);
                _setQty(_quantity);
              },
            ),
        ]),
      ],
      if (stock != null) ...[
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Row(key: ValueKey(stock), children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: stock > 0 ? const Color(0xFF16A34A) : AppColors.danger),
            ),
            const SizedBox(width: 8),
            Text(
              stock > 0 ? 'В наличии: $stock шт${variant!.sku.isNotEmpty ? '  ·  арт. ${variant.sku}' : ''}' : 'Нет в наличии',
              style: AppTextStyles.body(size: 12.5, weight: FontWeight.w700, color: stock > 0 ? AppColors.text2 : AppColors.danger),
            ),
          ]),
        ),
      ],
      // ── Количество ──
      const SizedBox(height: 20),
      _label('Количество', Icons.inventory_2_outlined),
      Row(children: [
        _QtyStepper(
          controller: _qtyController,
          onMinus: () => _setQty(_quantity - (_quantity > 100 ? 10 : 1)),
          onPlus: () => _setQty(_quantity + (_quantity >= 100 ? 10 : 1)),
          onTyped: (v) {
            final n = int.tryParse(v);
            if (n != null) setState(() => _quantity = n < 1 ? 1 : n);
          },
          onDone: () => _setQty(_quantity),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final add in const [10, 50, 100])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _OptionChip(label: '+$add', active: false, small: true, onTap: () => _setQty(_quantity + add)),
                ),
            ]),
          ),
        ),
      ]),
      if (product.weightGrams > 0) ...[
        const SizedBox(height: 10),
        Text(
          'Вес партии: ${((product.weightGrams * _quantity) / 1000).toStringAsFixed(1)} кг',
          style: AppTextStyles.body(size: 12.3, weight: FontWeight.w700, color: AppColors.text3),
        ),
      ],
      // ── Доставка ──
      const SizedBox(height: 20),
      HoverScale(
        hover: 1.01,
        onTap: () => Navigator.pushNamed(context, AppRoutes.cargoCalculator),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFFF4EA), Color(0xFFFFE8D3)]),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(13)),
              child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Доставка карго в РФ и Таджикистан', style: AppTextStyles.body(size: 13.5, weight: FontWeight.w800)),
                Text('Рассчитать стоимость доставки', style: AppTextStyles.body(size: 12, weight: FontWeight.w600, color: AppColors.g700)),
              ]),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.g600),
          ]),
        ),
      ),
      // ── Описание ──
      if ((product.description ?? '').isNotEmpty || (product.composition ?? '').isNotEmpty || product.weightGrams > 0) ...[
        const SizedBox(height: 22),
        _label('О товаре', Icons.description_outlined),
        _ExpandableText(text: product.description ?? ''),
        const SizedBox(height: 10),
        if ((product.composition ?? '').isNotEmpty) _specRow('Состав', product.composition!),
        if (product.weightGrams > 0) _specRow('Вес', '${product.weightGrams} г / шт'),
        if (variant != null && variant.sku.isNotEmpty) _specRow('Артикул', variant.sku),
      ],
      // ── Отзывы ──
      const SizedBox(height: 22),
      Container(key: _reviewsKey, child: _label('Отзывы · ${_reviews.length}', Icons.forum_outlined)),
      if (_reviews.isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.borderSoft)),
          child: Column(children: [
            const Icon(Icons.rate_review_outlined, color: AppColors.g200, size: 32),
            const SizedBox(height: 6),
            Text('Пока нет отзывов', style: AppTextStyles.body(size: 13, weight: FontWeight.w800)),
            Text('Отзыв можно оставить после получения заказа', style: AppTextStyles.body(size: 11.5, weight: FontWeight.w600, color: AppColors.text3)),
          ]),
        )
      else
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: _reviews.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) => ReviewCard(review: _reviews[i]),
          ),
        ),
      // ── Похожие ──
      if (_similar.isNotEmpty) ...[
        const SizedBox(height: 24),
        _label('Похожие товары', Icons.auto_awesome_mosaic_outlined),
        SizedBox(
          height: 280,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.only(top: 6, bottom: 10),
            itemCount: _similar.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) => SizedBox(width: 168, child: Reveal(delayMs: 60 * i, child: ProductCard(product: _similar[i]))),
          ),
        ),
      ],
    ]);
  }

  Widget _bottomBar(Product product, CurrencyProvider currency, double unitPrice) {
    final variant = _variant(product);
    final noStock = variant != null && variant.stockQuantity <= 0;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.borderSoft)),
        boxShadow: [BoxShadow(color: AppColors.g900.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, -6))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Row(children: [
                Expanded(
                  flex: 2,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text('Итого · $_quantity шт', style: AppTextStyles.body(size: 11.5, weight: FontWeight.w700, color: AppColors.text3)),
                    TweenAnimationBuilder<double>(
                      tween: Tween(end: unitPrice * _quantity),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(currency.format(v), style: AppTextStyles.mono(size: 19, weight: FontWeight.w800)),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: GlowButton(
                    text: noStock ? 'Нет в наличии' : (_added ? 'Добавлено!' : 'В корзину'),
                    icon: _added ? Icons.check_circle_rounded : Icons.add_shopping_cart_rounded,
                    loading: _adding,
                    gradient: _added ? const LinearGradient(colors: [Color(0xFF22C55E), Color(0xFF16A34A)]) : AppColors.brandGradient,
                    onPressed: noStock ? null : () => _addToCart(product),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text, IconData icon) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Icon(icon, size: 17, color: AppColors.g600),
          const SizedBox(width: 7),
          Text(text, style: AppTextStyles.body(size: 14, weight: FontWeight.w800)),
        ]),
      );

  Widget _specRow(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 90, child: Text(k, style: AppTextStyles.body(size: 12.8, weight: FontWeight.w600, color: AppColors.text3))),
          Expanded(child: Text(v, style: AppTextStyles.body(size: 12.8, weight: FontWeight.w700))),
        ]),
      );

  Widget _pillButton(String text, {bool outlined = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: outlined ? null : AppColors.brandGradient,
          color: outlined ? AppColors.surface : null,
          border: outlined ? Border.all(color: AppColors.border, width: 1.4) : null,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(text, style: AppTextStyles.body(size: 14, weight: FontWeight.w800, color: outlined ? AppColors.text : Colors.white)),
      );
}

// ─────────────────────────── Галерея ───────────────────────────

class _Gallery extends StatefulWidget {
  final Product product;
  const _Gallery({required this.product});

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  final _page = PageController();
  int _index = 0;
  bool _h = false;

  List<String?> get _images => widget.product.imageUrls.isEmpty ? [null] : widget.product.imageUrls;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _go(int i) => _page.animateToPage(i, duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);

  @override
  Widget build(BuildContext context) {
    final images = _images;
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: Stack(fit: StackFit.expand, children: [
        Container(color: AppColors.surface2),
        PageView.builder(
          controller: _page,
          itemCount: images.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (context, i) => GestureDetector(
            onTap: images[i] == null
                ? null
                : () => Navigator.of(context).push(PageRouteBuilder(
                      opaque: false,
                      barrierColor: Colors.black,
                      pageBuilder: (_, __, ___) => _FullscreenGallery(images: images.whereType<String>().toList(), initial: i),
                      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
                    )),
            child: Hero(
              tag: 'img-${widget.product.id}-$i',
              child: AnimatedScale(
                scale: _h && i == _index ? 1.04 : 1,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                child: PlaceholderImage(width: double.infinity, height: double.infinity, imageUrl: images[i]),
              ),
            ),
          ),
        ),
        if (images.length > 1) ...[
          Positioned(
            left: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: AnimatedOpacity(
                opacity: _h && _index > 0 ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: _CircleBtn(icon: Icons.chevron_left_rounded, onTap: _index > 0 ? () => _go(_index - 1) : null),
              ),
            ),
          ),
          Positioned(
            right: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: AnimatedOpacity(
                opacity: _h && _index < images.length - 1 ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: _CircleBtn(icon: Icons.chevron_right_rounded, onTap: _index < images.length - 1 ? () => _go(_index + 1) : null),
              ),
            ),
          ),
        ],
        Positioned(
          left: 0,
          right: 0,
          bottom: 34,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (images.length > 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(images.length, (i) {
                    final on = i == _index;
                    return GestureDetector(
                      onTap: () => _go(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: on ? 20 : 7,
                        height: 7,
                        decoration: BoxDecoration(color: on ? Colors.white : Colors.white54, borderRadius: BorderRadius.circular(4)),
                      ),
                    );
                  }),
                ),
              ),
          ]),
        ),
        if (images.first != null)
          Positioned(
            right: 14,
            bottom: 34,
            child: AnimatedOpacity(
              opacity: _h ? 1 : 0.85,
              duration: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 15),
                  const SizedBox(width: 4),
                  Text('${_index + 1}/${images.length}', style: AppTextStyles.body(size: 11.5, weight: FontWeight.w800, color: Colors.white)),
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}

class _FullscreenGallery extends StatefulWidget {
  final List<String> images;
  final int initial;
  const _FullscreenGallery({required this.images, required this.initial});

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late final PageController _page = PageController(initialPage: widget.initial);
  late int _index = widget.initial;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        PageView.builder(
          controller: _page,
          itemCount: widget.images.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (context, i) => InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Center(
              child: Image.network(
                widget.images[i],
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              _CircleBtn(icon: Icons.close_rounded, onTap: () => Navigator.pop(context)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: Text('${_index + 1} / ${widget.images.length}', style: AppTextStyles.body(size: 13, weight: FontWeight.w800, color: Colors.white)),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────── Мелкие виджеты ───────────────────────────

class _GlassBox extends StatelessWidget {
  final Widget child;
  const _GlassBox({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: child,
      );
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  const _CircleBtn({required this.icon, this.onTap, this.color = AppColors.text});

  @override
  Widget build(BuildContext context) => HoverScale(
        hover: 1.08,
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Icon(icon, size: 22, color: color),
        ),
      );
}

class _FavCircle extends StatefulWidget {
  final Product product;
  const _FavCircle({required this.product});

  @override
  State<_FavCircle> createState() => _FavCircleState();
}

class _FavCircleState extends State<_FavCircle> {
  @override
  Widget build(BuildContext context) {
    final isFav = context.watch<FavoritesProvider>().isFavorite(widget.product.id);
    return HoverScale(
      hover: 1.08,
      onTap: () {
        HapticFeedback.lightImpact();
        context.read<FavoritesProvider>().toggle(widget.product);
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          transitionBuilder: (c, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.elasticOut), child: c),
          child: Icon(
            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            key: ValueKey(isFav),
            size: 22,
            color: isFav ? AppColors.danger : AppColors.text,
          ),
        ),
      ),
    );
  }
}

class _CartCircle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final count = context.watch<CartProvider>().itemsCount;
    return Stack(clipBehavior: Clip.none, children: [
      _CircleBtn(icon: Icons.shopping_cart_outlined, onTap: () => Navigator.pushNamed(context, AppRoutes.cart)),
      if (count > 0)
        Positioned(
          top: -3,
          right: -3,
          child: TweenAnimationBuilder<double>(
            key: ValueKey(count),
            tween: Tween(begin: 0.3, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (context, s, child) => Transform.scale(scale: s, child: child),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(count > 999 ? '999+' : '$count', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ),
        ),
    ]);
  }
}

/// Бейджи в строку (Новинка / Хит / Скидка).
class BadgeRowInline extends StatelessWidget {
  final List<String> labels;
  const BadgeRowInline({super.key, required this.labels});

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 6,
        children: [
          for (final l in labels)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: l == 'Новинка' ? AppColors.badgeNew : (l == 'Скидка' ? AppColors.badgeSale : AppColors.g600),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(l, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
        ],
      );
}

class _TierCard extends StatefulWidget {
  final int qty;
  final String price;
  final bool active;
  final VoidCallback onTap;
  const _TierCard({required this.qty, required this.price, required this.active, required this.onTap});

  @override
  State<_TierCard> createState() => _TierCardState();
}

class _TierCardState extends State<_TierCard> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    final on = widget.active;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          width: 112,
          padding: const EdgeInsets.all(12),
          transform: Matrix4.translationValues(0, _h ? -3 : 0, 0),
          decoration: BoxDecoration(
            gradient: on ? AppColors.brandGradient : null,
            color: on ? null : AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: on ? Colors.transparent : (_h ? AppColors.g200 : AppColors.borderSoft), width: 1.3),
            boxShadow: on || _h ? [BoxShadow(color: AppColors.g500.withValues(alpha: on ? 0.32 : 0.12), blurRadius: 14, offset: const Offset(0, 6))] : null,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('от ${widget.qty} шт', style: AppTextStyles.body(size: 11.5, weight: FontWeight.w700, color: on ? Colors.white70 : AppColors.text3)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(widget.price, style: AppTextStyles.mono(size: 16, weight: FontWeight.w800, color: on ? Colors.white : AppColors.text)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _OptionChip extends StatefulWidget {
  final String label;
  final bool active;
  final bool disabled;
  final bool small;
  final VoidCallback onTap;
  const _OptionChip({required this.label, required this.active, required this.onTap, this.disabled = false, this.small = false});

  @override
  State<_OptionChip> createState() => _OptionChipState();
}

class _OptionChipState extends State<_OptionChip> {
  bool _h = false, _d = false;

  @override
  Widget build(BuildContext context) {
    final on = widget.active;
    final off = widget.disabled;
    return MouseRegion(
      cursor: off ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTapDown: off ? null : (_) => setState(() => _d = true),
        onTapUp: off ? null : (_) => setState(() => _d = false),
        onTapCancel: () => setState(() => _d = false),
        onTap: off ? null : widget.onTap,
        child: AnimatedScale(
          scale: _d ? 0.92 : (_h && !off ? 1.05 : 1),
          duration: const Duration(milliseconds: 140),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: widget.small ? 40 : 42,
            constraints: BoxConstraints(minWidth: widget.small ? 0 : 52),
            padding: EdgeInsets.symmetric(horizontal: widget.small ? 12 : 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: on ? AppColors.brandGradient : null,
              color: on ? null : (off ? AppColors.surface2 : (_h ? AppColors.g50 : AppColors.surface)),
              border: Border.all(color: on ? Colors.transparent : (_h && !off ? AppColors.g200 : AppColors.border), width: 1.3),
              borderRadius: BorderRadius.circular(14),
              boxShadow: on ? [BoxShadow(color: AppColors.g500.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 5))] : null,
            ),
            child: Text(
              widget.label,
              style: AppTextStyles.body(size: 13, weight: FontWeight.w800, color: on ? Colors.white : (off ? AppColors.text3 : AppColors.text)).copyWith(
                decoration: off ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final ValueChanged<String> onTyped;
  final VoidCallback onDone;
  const _QtyStepper({required this.controller, required this.onMinus, required this.onPlus, required this.onTyped, required this.onDone});

  @override
  Widget build(BuildContext context) => Container(
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border, width: 1.4),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _btn(Icons.remove_rounded, onMinus),
          SizedBox(
            width: 64,
            child: Focus(
              onFocusChange: (f) {
                if (!f) onDone();
              },
              child: TextField(
                controller: controller,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                onChanged: onTyped,
                onSubmitted: (_) => onDone(),
                style: AppTextStyles.mono(size: 16, weight: FontWeight.w800),
                decoration: const InputDecoration(
                  isDense: true,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ),
          _btn(Icons.add_rounded, onPlus),
        ]),
      );

  Widget _btn(IconData icon, VoidCallback onTap) => HoverScale(
        hover: 1.1,
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(color: AppColors.g50, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 20, color: AppColors.g700),
        ),
      );
}

class _ExpandableText extends StatefulWidget {
  final String text;
  const _ExpandableText({required this.text});

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    if (widget.text.trim().isEmpty) return const SizedBox.shrink();
    final long = widget.text.length > 180;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: Text(
          widget.text,
          maxLines: _open || !long ? null : 4,
          overflow: _open || !long ? TextOverflow.visible : TextOverflow.ellipsis,
          style: AppTextStyles.body(size: 13.5, weight: FontWeight.w500, color: AppColors.text2).copyWith(height: 1.5),
        ),
      ),
      if (long)
        HoverScale(
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(_open ? 'Свернуть' : 'Читать полностью', style: AppTextStyles.body(size: 12.8, weight: FontWeight.w800, color: AppColors.g600)),
          ),
        ),
    ]);
  }
}

class _DetailSkeleton extends StatefulWidget {
  const _DetailSkeleton();

  @override
  State<_DetailSkeleton> createState() => _DetailSkeletonState();
}

class _DetailSkeletonState extends State<_DetailSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _box(double? w, double h, double r) => AnimatedBuilder(
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
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: ListView(padding: EdgeInsets.zero, children: [
            _box(double.infinity, 360, 0),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _box(80, 18, 8),
                const SizedBox(height: 12),
                _box(260, 26, 10),
                const SizedBox(height: 12),
                _box(160, 16, 8),
                const SizedBox(height: 20),
                _box(double.infinity, 90, 20),
                const SizedBox(height: 20),
                Row(children: [_box(110, 64, 16), const SizedBox(width: 10), _box(110, 64, 16), const SizedBox(width: 10), _box(110, 64, 16)]),
              ]),
            ),
          ]),
        ),
      );
}
