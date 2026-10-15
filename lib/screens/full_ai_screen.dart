import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/address.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../providers/currency_provider.dart';
import '../routes/app_routes.dart';
import '../services/ai_repository.dart';
import '../services/api_exception.dart';
import '../services/catalog_repository.dart';
import '../services/chat_repository.dart';
import '../services/delivery_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/auth_ui.dart' show Reveal, HoverScale;
import '../widgets/placeholder_image.dart';

class _Msg {
  final String text;
  final bool mine;
  final List<Product> products;
  final String? action; // 'chat' — кнопка «Написать менеджеру»
  _Msg(this.text, this.mine, {this.products = const [], this.action});
}

/// FULL AI: настоящий ИИ на сервере (знает каталог, цены, тарифы карго). Если сервер недоступен —
/// локальный умный режим: подбор по цене/категории, расчёт доставки по весу, акции; иначе — передача менеджеру.
class FullAiScreen extends StatefulWidget {
  const FullAiScreen({super.key});

  @override
  State<FullAiScreen> createState() => _FullAiScreenState();
}

class _FullAiScreenState extends State<FullAiScreen> {
  // Переписка живёт, пока открыто приложение.
  static final List<_Msg> _history = [];

  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();
  bool _sending = false;
  List<Category>? _categories;

  static const _suggestions = [
    (Icons.search_rounded, 'Подбери носки до 40 ₽/шт'),
    (Icons.local_shipping_rounded, 'Сколько стоит доставка 80 кг в Россию?'),
    (Icons.calculate_rounded, 'Посчитай партию 500 футболок'),
    (Icons.local_offer_rounded, 'Какие сейчас акции?'),
  ];

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent + 200, duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
      }
    });
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty || _sending) return;
    HapticFeedback.selectionClick();
    setState(() {
      _history.add(_Msg(text, true));
      _controller.clear();
      _sending = true;
    });
    _toBottom();

    _Msg reply;
    try {
      final convo = _history
          .where((m) => m.action == null)
          .map((m) => {'role': m.mine ? 'user' : 'assistant', 'content': m.text})
          .toList();
      final r = await AiRepository.chat(convo);
      final products = await _loadProducts(r.productIds);
      reply = _Msg(r.text.isEmpty ? 'Не понял вопрос, переформулируйте, пожалуйста.' : r.text, false, products: products);
    } catch (_) {
      // ИИ на сервере недоступен — отвечаем сами.
      reply = await _localAnswer(text);
    }
    if (!mounted) return;
    setState(() {
      _history.add(reply);
      _sending = false;
    });
    _toBottom();
  }

  Future<List<Product>> _loadProducts(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final res = await Future.wait(ids.map((id) => CatalogRepository.getProduct(id).then<Product?>((p) => p).catchError((_) => null)));
    return res.whereType<Product>().toList();
  }

  // ─────────────────────────── Локальный режим ───────────────────────────

  Future<_Msg> _localAnswer(String q) async {
    final t = q.toLowerCase();
    final currency = context.read<CurrencyProvider>();
    try {
      // 1) Доставка: «80 кг в Россию»
      final kg = RegExp(r'(\d+[.,]?\d*)\s*(кг|kg|килограмм)').firstMatch(t);
      if (kg != null || t.contains('доставк')) {
        if (kg == null) {
          return _Msg('Подскажите вес партии в кг и страну (Россия или Таджикистан) — посчитаю доставку. Например: «80 кг в Россию».', false);
        }
        final weight = double.parse(kg.group(1)!.replaceAll(',', '.'));
        final country = t.contains('таджик') || t.contains('душанбе') ? DeliveryCountry.tajikistan : DeliveryCountry.russia;
        final calc = await DeliveryRepository.calculate(country: country, totalWeightGrams: (weight * 1000).round());
        return _Msg(
          'Доставка карго ${weight.toStringAsFixed(weight == weight.roundToDouble() ? 0 : 1)} кг в ${country.label}:\n'
          '• тариф — ${calc.pricePerKg.toStringAsFixed(0)} ${calc.currency}/кг\n'
          '• итого — ${calc.totalCost.toStringAsFixed(0)} ${calc.currency}\n'
          'Точный расчёт по вашей корзине — в «Калькуляторе доставки».',
          false,
        );
      }

      // 2) Акции
      if (t.contains('акци') || t.contains('скидк') || t.contains('промо')) {
        return _Msg('Сейчас действует скидка 15% на первую партию при заказе от 500 единиц. '
            'Ещё в каждом товаре есть оптовая шкала: чем больше берёте — тем ниже цена за штуку. Промокод можно ввести при оформлении заказа.', false);
      }

      // 3) Подбор товара: цена «до N», категория, количество
      _categories ??= await CatalogRepository.getCategories();
      Category? cat;
      for (final c in _categories!) {
        final stem = c.name.toLowerCase().substring(0, min(4, c.name.length));
        if (t.contains(stem)) cat = c;
      }
      final maxPrice = RegExp(r'до\s*(\d+[.,]?\d*)').firstMatch(t);
      final qty = RegExp(r'(\d+)\s*(шт|штук|пар|единиц|футболок|носков|трусов|шорт|штанов)').firstMatch(t);
      final wantsGoods = cat != null || maxPrice != null || t.contains('подбер') || t.contains('найди') || t.contains('покажи') || qty != null;

      if (wantsGoods) {
        final page = await CatalogRepository.getProducts(
          categoryId: cat?.id,
          maxPrice: maxPrice == null ? null : double.parse(maxPrice.group(1)!.replaceAll(',', '.')),
          sortBy: 'price_asc',
          pageSize: 6,
        );
        if (page.items.isEmpty) {
          return _Msg('По таким условиям ничего не нашёл. Попробуйте увеличить цену или выбрать другую категорию — или спросите менеджера.', false,
              action: 'chat');
        }
        final buf = StringBuffer();
        buf.write(cat != null ? 'Вот что есть в категории «${cat.name}»' : 'Вот подходящие товары');
        if (maxPrice != null) buf.write(' до ${maxPrice.group(1)} ₽/шт');
        buf.write(' (сначала дешевле):');
        if (qty != null) {
          final n = int.parse(qty.group(1)!);
          final p = page.items.first;
          buf.write('\n\nПартия $n шт «${p.name}» — примерно ${currency.format(p.minPrice * n)} '
              '(по ${currency.format(p.minPrice)}/шт; при большем объёме цена ниже — смотрите шкалу в карточке).');
        }
        return _Msg(buf.toString(), false, products: page.items);
      }

      // 4) Поиск по тексту
      final words = t.replaceAll(RegExp(r'[^a-zа-яё0-9 ]'), ' ').split(' ').where((w) => w.length > 3).toList();
      if (words.isNotEmpty) {
        final page = await CatalogRepository.search(words.join(' '), pageSize: 6);
        if (page.items.isNotEmpty) return _Msg('Нашёл в каталоге:', false, products: page.items);
      }
    } on ApiException catch (_) {
    } catch (_) {}

    // 5) Передаём менеджеру
    try {
      await ChatRepository.send('[FULL AI] $q');
      return _Msg('Этот вопрос лучше решит менеджер — я уже передал его. Ответ придёт в «Чат с менеджером».', false, action: 'chat');
    } catch (_) {
      return _Msg('Не смог ответить. Напишите менеджеру — он поможет с подбором и расчётом.', false, action: 'chat');
    }
  }

  // ─────────────────────────── UI ───────────────────────────

  @override
  Widget build(BuildContext context) {
    final empty = _history.isEmpty;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(children: [
              _header(),
              Expanded(
                child: ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    if (empty) _welcome(),
                    for (var i = 0; i < _history.length; i++) _bubble(_history[i], key: ValueKey(i)),
                    if (_sending) const _Typing(),
                  ],
                ),
              ),
              if (!empty) _quickRow(),
              _input(),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _header() => Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 12, 10),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderSoft))),
        child: Row(children: [
          HoverScale(
            onTap: () => Navigator.maybePop(context),
            child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.arrow_back_rounded, color: AppColors.text)),
          ),
          const SizedBox(width: 4),
          const _Orb(size: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('FULL AI', style: AppTextStyles.display(size: 16, weight: FontWeight.w800)),
              Row(children: [
                Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text(_sending ? 'печатает…' : 'онлайн · знает весь каталог',
                    style: AppTextStyles.body(size: 11.5, weight: FontWeight.w700, color: AppColors.text3)),
              ]),
            ]),
          ),
          if (_history.isNotEmpty)
            HoverScale(
              onTap: _sending ? null : () => setState(_history.clear),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(12)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.refresh_rounded, size: 16, color: AppColors.g700),
                  const SizedBox(width: 4),
                  Text('Новый чат', style: AppTextStyles.body(size: 12, weight: FontWeight.w800, color: AppColors.g700)),
                ]),
              ),
            ),
        ]),
      );

  Widget _welcome() => Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Column(children: [
          const Reveal(child: _Orb(size: 84)),
          const SizedBox(height: 16),
          Reveal(
            delayMs: 80,
            child: Text('Чем помочь?', style: AppTextStyles.display(size: 22, weight: FontWeight.w800)),
          ),
          const SizedBox(height: 6),
          Reveal(
            delayMs: 120,
            child: Text(
              'Подберу товар под бюджет, посчитаю партию и доставку карго, расскажу об акциях.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body(size: 13.5, weight: FontWeight.w600, color: AppColors.text3),
            ),
          ),
          const SizedBox(height: 22),
          LayoutBuilder(builder: (context, box) {
            final two = box.maxWidth > 520;
            final w = two ? (box.maxWidth - 10) / 2 : box.maxWidth;
            return Wrap(spacing: 10, runSpacing: 10, children: [
              for (var i = 0; i < _suggestions.length; i++)
                SizedBox(
                  width: w,
                  child: Reveal(
                    delayMs: 160 + i * 70,
                    child: _SuggestionCard(icon: _suggestions[i].$1, text: _suggestions[i].$2, onTap: () => _send(_suggestions[i].$2)),
                  ),
                ),
            ]);
          }),
        ]),
      );

  Widget _bubble(_Msg m, {Key? key}) {
    final currency = context.watch<CurrencyProvider>();
    return TweenAnimationBuilder<double>(
      key: key,
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(m.mine ? 20 * (1 - v) : -20 * (1 - v), 8 * (1 - v)), child: child),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: m.mine ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
          Row(
            mainAxisAlignment: m.mine ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!m.mine) ...[const _Orb(size: 28), const SizedBox(width: 8)],
              Flexible(
                child: GestureDetector(
                  onLongPress: () {
                    Clipboard.setData(ClipboardData(text: m.text));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Текст скопирован'), behavior: SnackBarBehavior.floating));
                  },
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 560),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      gradient: m.mine ? AppColors.brandGradient : null,
                      color: m.mine ? null : AppColors.surface,
                      border: m.mine ? null : Border.all(color: AppColors.borderSoft, width: 1.3),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(m.mine ? 18 : 6),
                        bottomRight: Radius.circular(m.mine ? 6 : 18),
                      ),
                      boxShadow: [BoxShadow(color: (m.mine ? AppColors.g500 : AppColors.g900).withValues(alpha: m.mine ? 0.22 : 0.04), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: SelectableText(
                      m.text,
                      style: AppTextStyles.body(size: 14, weight: FontWeight.w600, color: m.mine ? Colors.white : AppColors.text).copyWith(height: 1.45),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (m.products.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 196,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 36),
                itemCount: m.products.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) => Reveal(
                  delayMs: 80 * i,
                  child: _MiniProduct(product: m.products[i], price: currency.format(m.products[i].minPrice)),
                ),
              ),
            ),
          ],
          if (m.action == 'chat') ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: HoverScale(
                onTap: () => Navigator.pushNamed(context, AppRoutes.chat),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(color: AppColors.g50, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.g200)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.support_agent_rounded, size: 18, color: AppColors.g700),
                    const SizedBox(width: 6),
                    Text('Открыть чат с менеджером', style: AppTextStyles.body(size: 12.8, weight: FontWeight.w800, color: AppColors.g700)),
                  ]),
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _quickRow() => SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          itemCount: _suggestions.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) => HoverScale(
            onTap: _sending ? null : () => _send(_suggestions[i].$2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.g50, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.g100)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(_suggestions[i].$1, size: 15, color: AppColors.g600),
                const SizedBox(width: 6),
                Text(_suggestions[i].$2, style: AppTextStyles.body(size: 12, weight: FontWeight.w800, color: AppColors.g700)),
              ]),
            ),
          ),
        ),
      );

  Widget _input() {
    final f = _focus.hasFocus;
    final canSend = _controller.text.trim().isNotEmpty && !_sending;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: Row(children: [
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: f ? AppColors.primary : AppColors.border, width: f ? 1.8 : 1.3),
              boxShadow: f ? [BoxShadow(color: AppColors.g500.withValues(alpha: 0.15), blurRadius: 18, offset: const Offset(0, 6))] : null,
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _send(),
              style: AppTextStyles.body(size: 14.5, weight: FontWeight.w600),
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                hintText: 'Спросите FULL AI…',
                hintStyle: AppTextStyles.body(size: 14.5, weight: FontWeight.w600, color: AppColors.text3),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        HoverScale(
          hover: 1.08,
          onTap: canSend ? () => _send() : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: canSend ? AppColors.brandGradient : null,
              color: canSend ? null : AppColors.surface2,
              shape: BoxShape.circle,
              boxShadow: canSend ? [BoxShadow(color: AppColors.g500.withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 6))] : null,
            ),
            child: AnimatedRotation(
              turns: canSend ? 0 : -0.125,
              duration: const Duration(milliseconds: 250),
              child: Icon(Icons.send_rounded, size: 21, color: canSend ? Colors.white : AppColors.text3),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────── Виджеты ───────────────────────────

/// Пульсирующий «шар» ИИ.
class _Orb extends StatefulWidget {
  final double size;
  const _Orb({required this.size});

  @override
  State<_Orb> createState() => _OrbState();
}

class _OrbState extends State<_Orb> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final v = sin(_c.value * 2 * pi) * 0.5 + 0.5;
          return Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                transform: GradientRotation(_c.value * 2 * pi),
                colors: const [Color(0xFFFFB15C), AppColors.g500, Color(0xFFFF3D00), Color(0xFFFFB15C)],
              ),
              boxShadow: [BoxShadow(color: AppColors.g500.withValues(alpha: 0.25 + 0.2 * v), blurRadius: widget.size * (0.25 + 0.2 * v), spreadRadius: widget.size * 0.02 * v)],
            ),
            child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: widget.size * 0.45),
          );
        },
      );
}

class _Typing extends StatefulWidget {
  const _Typing();

  @override
  State<_Typing> createState() => _TypingState();
}

class _TypingState extends State<_Typing> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          const _Orb(size: 28),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.borderSoft, width: 1.3),
              borderRadius: BorderRadius.circular(18),
            ),
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) => Row(
                children: List.generate(3, (i) {
                  final t = (_c.value - i * 0.18) % 1.0;
                  final lift = sin(t * pi).clamp(0.0, 1.0);
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 8,
                    height: 8,
                    transform: Matrix4.translationValues(0, -5 * lift, 0),
                    decoration: BoxDecoration(color: AppColors.g500.withValues(alpha: 0.4 + 0.6 * lift), shape: BoxShape.circle),
                  );
                }),
              ),
            ),
          ),
        ]),
      );
}

class _SuggestionCard extends StatefulWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  const _SuggestionCard({required this.icon, required this.text, required this.onTap});

  @override
  State<_SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends State<_SuggestionCard> {
  bool _h = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _h = true),
        onExit: (_) => setState(() => _h = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.all(14),
            transform: Matrix4.translationValues(0, _h ? -3 : 0, 0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _h ? AppColors.g200 : AppColors.borderSoft, width: 1.3),
              boxShadow: [BoxShadow(color: AppColors.g900.withValues(alpha: _h ? 0.1 : 0.03), blurRadius: _h ? 18 : 8, offset: const Offset(0, 6))],
            ),
            child: Row(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: _h ? AppColors.brandGradient : null,
                  color: _h ? null : AppColors.g50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, size: 19, color: _h ? Colors.white : AppColors.g600),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(widget.text, style: AppTextStyles.body(size: 13.5, weight: FontWeight.w800))),
              AnimatedSlide(
                offset: Offset(_h ? 0.2 : 0, 0),
                duration: const Duration(milliseconds: 200),
                child: Icon(Icons.north_east_rounded, size: 18, color: _h ? AppColors.g600 : AppColors.text3),
              ),
            ]),
          ),
        ),
      );
}

class _MiniProduct extends StatefulWidget {
  final Product product;
  final String price;
  const _MiniProduct({required this.product, required this.price});

  @override
  State<_MiniProduct> createState() => _MiniProductState();
}

class _MiniProductState extends State<_MiniProduct> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, AppRoutes.productDetail, arguments: p.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 144,
          transform: Matrix4.translationValues(0, _h ? -4 : 0, 0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _h ? AppColors.g200 : AppColors.borderSoft, width: 1.3),
            boxShadow: [BoxShadow(color: AppColors.g900.withValues(alpha: _h ? 0.12 : 0.04), blurRadius: _h ? 16 : 8, offset: const Offset(0, 6))],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: AnimatedScale(
                scale: _h ? 1.06 : 1,
                duration: const Duration(milliseconds: 350),
                child: PlaceholderImage(width: double.infinity, height: double.infinity, imageUrl: p.imageUrls.isNotEmpty ? p.imageUrls.first : null),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.price, style: AppTextStyles.mono(size: 14, weight: FontWeight.w800, color: _h ? AppColors.g700 : AppColors.text)),
                Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.body(size: 11.5, weight: FontWeight.w700, color: AppColors.text2)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
