import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/brand.dart';
import '../models/category.dart';
import '../services/catalog_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/auth_ui.dart' show Reveal, HoverScale, GlowButton;
import '../widgets/category_strip.dart' show categoryIcon;

/// Фильтры каталога. Принимает текущие значения (arguments: Map) и возвращает выбранные
/// через Navigator.pop: {categoryId, brandId, minPrice, maxPrice, sortBy}.
class FiltersScreen extends StatefulWidget {
  const FiltersScreen({super.key});

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  String? _categoryId;
  String? _brandId;
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  String _sort = 'popular';
  List<Category> _categories = [];
  List<Brand> _brands = [];
  bool _loading = true;
  bool _failed = false;
  bool _argsRead = false;

  static const _sorts = [
    ('popular', 'По популярности', Icons.local_fire_department_rounded),
    ('price_asc', 'Сначала дешевле', Icons.trending_down_rounded),
    ('price_desc', 'Сначала дороже', Icons.trending_up_rounded),
    ('rating', 'По рейтингу', Icons.star_rounded),
  ];

  static const List<(String, double?, double?)> _pricePresets = [
    ('до 50', null, 50.0),
    ('50–100', 50.0, 100.0),
    ('100–300', 100.0, 300.0),
    ('от 300', 300.0, null),
  ];

  @override
  void initState() {
    super.initState();
    _fromController.addListener(() => setState(() {}));
    _toController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsRead) return;
    _argsRead = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _categoryId = args['categoryId'] as String?;
      _brandId = args['brandId'] as String?;
      final min = args['minPrice'], max = args['maxPrice'];
      if (min is num) _fromController.text = _fmt(min.toDouble());
      if (max is num) _toController.text = _fmt(max.toDouble());
      if (args['sortBy'] is String) _sort = args['sortBy'] as String;
    }
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  static String _fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final results = await Future.wait([CatalogRepository.getCategories(), CatalogRepository.getBrands()]);
      if (!mounted) return;
      setState(() {
        _categories = results[0] as List<Category>;
        _brands = results[1] as List<Brand>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  double? get _min => double.tryParse(_fromController.text.replaceAll(',', '.'));
  double? get _max => double.tryParse(_toController.text.replaceAll(',', '.'));

  int get _activeCount =>
      (_categoryId != null ? 1 : 0) + (_brandId != null ? 1 : 0) + ((_min != null || _max != null) ? 1 : 0) + (_sort != 'popular' ? 1 : 0);

  void _reset() => setState(() {
        _categoryId = null;
        _brandId = null;
        _fromController.clear();
        _toController.clear();
        _sort = 'popular';
      });

  void _apply() {
    var min = _min, max = _max;
    if (min != null && max != null && min > max) {
      final t = min;
      min = max;
      max = t;
    }
    Navigator.pop(context, {
      'categoryId': _categoryId,
      'brandId': _brandId,
      'minPrice': min,
      'maxPrice': max,
      'sortBy': _sort,
    });
  }

  @override
  Widget build(BuildContext context) {
    final count = _activeCount;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(children: [
              // ── Шапка ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(children: [
                  HoverScale(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border, width: 1.4),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: AppColors.text),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Фильтры', style: AppTextStyles.display(size: 19, weight: FontWeight.w800)),
                  const SizedBox(width: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                    child: count == 0
                        ? const SizedBox(key: ValueKey(0))
                        : Container(
                            key: ValueKey(count),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(10)),
                            child: Text('$count', style: AppTextStyles.body(size: 12, weight: FontWeight.w800, color: Colors.white)),
                          ),
                  ),
                  const Spacer(),
                  AnimatedOpacity(
                    opacity: count > 0 ? 1 : 0.4,
                    duration: const Duration(milliseconds: 200),
                    child: HoverScale(
                      onTap: count > 0 ? _reset : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.refresh_rounded, size: 18, color: AppColors.g600),
                          const SizedBox(width: 4),
                          Text('Сбросить', style: AppTextStyles.body(size: 13.5, weight: FontWeight.w800, color: AppColors.g600)),
                        ]),
                      ),
                    ),
                  ),
                ]),
              ),
              Expanded(child: _body()),
            ]),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: GlowButton(
              text: count == 0 ? 'Показать товары' : 'Показать товары · $count',
              icon: Icons.check_rounded,
              onPressed: _loading ? null : _apply,
            ),
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_failed) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.g200),
          const SizedBox(height: 10),
          Text('Не удалось загрузить фильтры', style: AppTextStyles.body(size: 14, weight: FontWeight.w800)),
          const SizedBox(height: 12),
          HoverScale(
            onTap: _load,
            child: Text('Повторить', style: AppTextStyles.body(size: 14, weight: FontWeight.w800, color: AppColors.g600)),
          ),
        ]),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      children: [
        Reveal(
          child: _Section(
            icon: Icons.category_rounded,
            title: 'Категория',
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              for (final c in _categories)
                _Chip(
                  label: c.name,
                  icon: categoryIcon(c.name),
                  active: _categoryId == c.id,
                  onTap: () => setState(() => _categoryId = _categoryId == c.id ? null : c.id),
                ),
            ]),
          ),
        ),
        Reveal(
          delayMs: 80,
          child: _Section(
            icon: Icons.verified_rounded,
            title: 'Бренд',
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              for (final b in _brands)
                _Chip(
                  label: b.name,
                  active: _brandId == b.id,
                  onTap: () => setState(() => _brandId = _brandId == b.id ? null : b.id),
                ),
            ]),
          ),
        ),
        Reveal(
          delayMs: 160,
          child: _Section(
            icon: Icons.payments_rounded,
            title: 'Цена за единицу, ₽',
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: _PriceField(controller: _fromController, label: 'От')),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Container(width: 14, height: 2, color: AppColors.border),
                ),
                Expanded(child: _PriceField(controller: _toController, label: 'До')),
              ]),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final p in _pricePresets)
                  _Chip(
                    label: p.$1,
                    small: true,
                    active: _min == p.$2 && _max == p.$3,
                    onTap: () => setState(() {
                      final already = _min == p.$2 && _max == p.$3;
                      _fromController.text = already || p.$2 == null ? '' : _fmt(p.$2!);
                      _toController.text = already || p.$3 == null ? '' : _fmt(p.$3!);
                    }),
                  ),
              ]),
            ]),
          ),
        ),
        Reveal(
          delayMs: 240,
          child: _Section(
            icon: Icons.sort_rounded,
            title: 'Сортировка',
            child: Column(children: [
              for (final s in _sorts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _SortTile(
                    label: s.$2,
                    icon: s.$3,
                    active: _sort == s.$1,
                    onTap: () => setState(() => _sort = s.$1),
                  ),
                ),
            ]),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────── Блоки ───────────────────────────

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const _Section({required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.borderSoft, width: 1.3),
          boxShadow: [BoxShadow(color: AppColors.g900.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(color: AppColors.g50, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 17, color: AppColors.g600),
            ),
            const SizedBox(width: 10),
            Text(title, style: AppTextStyles.body(size: 14.5, weight: FontWeight.w800)),
          ]),
          const SizedBox(height: 14),
          child,
        ]),
      );
}

class _Chip extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool active;
  final bool small;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.active, required this.onTap, this.icon, this.small = false});

  @override
  State<_Chip> createState() => _ChipState();
}

class _ChipState extends State<_Chip> {
  bool _h = false, _d = false;

  @override
  Widget build(BuildContext context) {
    final on = widget.active;
    final fg = on ? Colors.white : (_h ? AppColors.g700 : AppColors.text2);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _d = true),
        onTapUp: (_) => setState(() => _d = false),
        onTapCancel: () => setState(() => _d = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _d ? 0.93 : (_h ? 1.04 : 1),
          duration: const Duration(milliseconds: 150),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: EdgeInsets.symmetric(horizontal: widget.small ? 12 : 14, vertical: widget.small ? 8 : 10),
            decoration: BoxDecoration(
              gradient: on ? AppColors.brandGradient : null,
              color: on ? null : (_h ? AppColors.g50 : AppColors.bg),
              border: Border.all(color: on ? Colors.transparent : (_h ? AppColors.g200 : AppColors.border), width: 1.3),
              borderRadius: BorderRadius.circular(999),
              boxShadow: on ? [BoxShadow(color: AppColors.g500.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 5))] : null,
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: on
                    ? const Padding(padding: EdgeInsets.only(right: 6), child: Icon(Icons.check_rounded, size: 16, color: Colors.white))
                    : (widget.icon != null
                        ? Padding(padding: const EdgeInsets.only(right: 6), child: Icon(widget.icon, size: 16, color: fg))
                        : const SizedBox.shrink()),
              ),
              Text(widget.label, style: AppTextStyles.body(size: widget.small ? 12 : 13, weight: FontWeight.w800, color: fg)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _PriceField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  const _PriceField({required this.controller, required this.label});

  @override
  State<_PriceField> createState() => _PriceFieldState();
}

class _PriceFieldState extends State<_PriceField> {
  final _focus = FocusNode();
  bool _h = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = _focus.hasFocus;
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: f ? AppColors.primary : (_h ? AppColors.g200 : AppColors.border), width: f ? 1.8 : 1.3),
          boxShadow: f ? [BoxShadow(color: AppColors.g500.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 6))] : null,
        ),
        child: Row(children: [
          Text(widget.label, style: AppTextStyles.body(size: 12.5, weight: FontWeight.w800, color: f ? AppColors.g600 : AppColors.text3)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')), LengthLimitingTextInputFormatter(8)],
              style: AppTextStyles.mono(size: 15),
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                hintText: '0',
                hintStyle: AppTextStyles.mono(size: 15, weight: FontWeight.w500, color: AppColors.text3),
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          Text('₽', style: AppTextStyles.body(size: 14, weight: FontWeight.w800, color: AppColors.text3)),
        ]),
      ),
    );
  }
}

class _SortTile extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _SortTile({required this.label, required this.icon, required this.active, required this.onTap});

  @override
  State<_SortTile> createState() => _SortTileState();
}

class _SortTileState extends State<_SortTile> {
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
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: on ? AppColors.g50 : (_h ? AppColors.bg : Colors.transparent),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: on ? AppColors.g200 : (_h ? AppColors.border : Colors.transparent), width: 1.3),
          ),
          child: Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: on ? AppColors.brandGradient : null,
                color: on ? null : AppColors.surface2,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(widget.icon, size: 18, color: on ? Colors.white : AppColors.g600),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(widget.label, style: AppTextStyles.body(size: 14, weight: on ? FontWeight.w800 : FontWeight.w700))),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: on ? AppColors.primary : Colors.transparent,
                border: Border.all(color: on ? AppColors.primary : AppColors.text3, width: 2),
              ),
              child: AnimatedScale(
                scale: on ? 1 : 0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
