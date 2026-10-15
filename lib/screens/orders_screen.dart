import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/address.dart';
import '../models/order.dart';
import '../providers/cart_provider.dart';
import '../providers/currency_provider.dart';
import '../routes/app_routes.dart';
import '../services/api_exception.dart';
import '../services/orders_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/auth_ui.dart' show Reveal, HoverScale;

/// Мои заказы: сводка, фильтр по статусам со счётчиками, поиск по номеру,
/// карточки с прогрессом доставки, трек-номером и кнопкой «Повторить заказ».
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  static const _pageSize = 30;

  OrderStatus? _filter;
  String _query = '';
  List<Order> _orders = [];
  int _total = 0;
  int _page = 1;
  bool _hasMore = false;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 400) _loadMore();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _orders.isEmpty;
      _error = null;
    });
    try {
      final page = await OrdersRepository.getMyOrders(pageSize: _pageSize);
      if (!mounted) return;
      setState(() {
        _orders = page.items;
        _total = page.totalCount;
        _page = 1;
        _hasMore = page.page * page.pageSize < page.totalCount;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.isUnauthorized) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.auth, (r) => false);
        return;
      }
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Не удалось загрузить заказы';
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _loading || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final page = await OrdersRepository.getMyOrders(page: _page + 1, pageSize: _pageSize);
      if (!mounted) return;
      setState(() {
        _orders = [..._orders, ...page.items];
        _page = page.page;
        _hasMore = page.page * page.pageSize < page.totalCount;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _repeat(Order o) async {
    try {
      await OrdersRepository.repeatOrder(o.id);
      if (!mounted) return;
      await context.read<CartProvider>().load();
      if (!mounted) return;
      _toast('Товары из ${o.orderNumber} добавлены в корзину', action: 'Корзина', onAction: () => Navigator.pushNamed(context, AppRoutes.cart));
    } on ApiException catch (e) {
      if (mounted) _toast(e.message, error: true);
    } catch (_) {
      if (mounted) _toast('Не удалось повторить заказ', error: true);
    }
  }

  void _toast(String text, {bool error = false, String? action, VoidCallback? onAction}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
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

  int _count(OrderStatus? s) => s == null ? _orders.length : _orders.where((o) => o.status == s).length;

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<CurrencyProvider>();
    final q = _query.trim().toLowerCase();
    final orders = _orders
        .where((o) => _filter == null || o.status == _filter)
        .where((o) => q.isEmpty || o.orderNumber.toLowerCase().contains(q) || o.items.any((i) => i.productName.toLowerCase().contains(q)))
        .toList();
    final active = _orders.where((o) => o.status != OrderStatus.zavershen && o.status != OrderStatus.otmenen).length;
    final spent = _orders.where((o) => o.status != OrderStatus.otmenen).fold<double>(0, (s, o) => s + o.totalAmount);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(children: [
              const AppTopBar(showCart: true),
              Expanded(
                child: _loading
                    ? const _Skeleton()
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _load,
                        child: ListView(
                          controller: _scroll,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 24),
                          children: [
                            Reveal(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                                child: Text('Мои заказы', style: AppTextStyles.display(size: 21, weight: FontWeight.w800)),
                              ),
                            ),
                            if (_error != null && _orders.isEmpty)
                              _Empty(
                                icon: Icons.wifi_off_rounded,
                                title: 'Не удалось загрузить заказы',
                                subtitle: _error!,
                                action: 'Повторить',
                                onAction: _load,
                              )
                            else if (_orders.isEmpty)
                              _Empty(
                                icon: Icons.shopping_bag_outlined,
                                title: 'Заказов пока нет',
                                subtitle: 'Оформите первую партию — история появится здесь',
                                action: 'Перейти в каталог',
                                onAction: () => Navigator.pushReplacementNamed(context, AppRoutes.categories),
                              )
                            else ...[
                              Reveal(
                                delayMs: 60,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: _Summary(total: _total, active: active, spent: currency.format(spent)),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Reveal(delayMs: 110, child: _SearchBox(onChanged: (v) => setState(() => _query = v))),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 42,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  children: [
                                    _StatusChip(label: 'Все', icon: Icons.apps_rounded, count: _count(null), active: _filter == null, onTap: () => setState(() => _filter = null)),
                                    for (final s in OrderStatus.values)
                                      _StatusChip(
                                        label: s.label,
                                        icon: _statusIcon(s),
                                        count: _count(s),
                                        active: _filter == s,
                                        onTap: () => setState(() => _filter = _filter == s ? null : s),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              if (orders.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(30),
                                  child: Column(children: [
                                    const Icon(Icons.filter_alt_off_outlined, size: 38, color: AppColors.g200),
                                    const SizedBox(height: 8),
                                    Text('Нет заказов с таким фильтром', style: AppTextStyles.body(size: 13.5, weight: FontWeight.w800, color: AppColors.text3)),
                                  ]),
                                )
                              else
                                for (var i = 0; i < orders.length; i++)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                                    child: Reveal(
                                      key: ValueKey(orders[i].id),
                                      delayMs: 50 * (i % 8),
                                      child: _OrderCard(
                                        order: orders[i],
                                        price: currency.format,
                                        onOpen: () => Navigator.pushNamed(context, AppRoutes.orderDetail, arguments: orders[i].id).then((_) => _load()),
                                        onRepeat: () => _repeat(orders[i]),
                                        onCopy: (t) {
                                          Clipboard.setData(ClipboardData(text: t));
                                          _toast('Трек-номер скопирован');
                                        },
                                      ),
                                    ),
                                  ),
                              if (_loadingMore)
                                const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.primary))),
                                ),
                            ],
                          ],
                        ),
                      ),
              ),
            ]),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(current: AppTab.orders),
    );
  }
}

IconData _statusIcon(OrderStatus s) => switch (s) {
      OrderStatus.novyy => Icons.fiber_new_rounded,
      OrderStatus.vObrabotke => Icons.inventory_rounded,
      OrderStatus.otpravlen => Icons.local_shipping_rounded,
      OrderStatus.zavershen => Icons.check_circle_rounded,
      OrderStatus.otmenen => Icons.cancel_rounded,
    };

(Color, Color) _statusColors(OrderStatus s) => switch (s) {
      OrderStatus.novyy => (const Color(0xFFEFF3FF), const Color(0xFF2563EB)),
      OrderStatus.vObrabotke => (const Color(0xFFFFF3E0), const Color(0xFFC2410C)),
      OrderStatus.otpravlen => (const Color(0xFFE8F5FF), const Color(0xFF0369A1)),
      OrderStatus.zavershen => (const Color(0xFFE9F9EE), const Color(0xFF15803D)),
      OrderStatus.otmenen => (const Color(0xFFFDECEB), AppColors.danger),
    };

String _date(DateTime d) {
  const m = ['янв', 'фев', 'мар', 'апр', 'мая', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];
  final l = d.toLocal();
  return '${l.day} ${m[l.month - 1]} ${l.year}, ${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}

// ─────────────────────────── Сводка ───────────────────────────

class _Summary extends StatelessWidget {
  final int total;
  final int active;
  final String spent;
  const _Summary({required this.total, required this.active, required this.spent});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: AppColors.g500.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Row(children: [
          Expanded(child: _cell('$total', 'всего заказов', Icons.receipt_long_rounded)),
          _divider(),
          Expanded(child: _cell('$active', 'в пути / в работе', Icons.local_shipping_rounded)),
          _divider(),
          Expanded(child: _cell(spent, 'сумма покупок', Icons.payments_rounded)),
        ]),
      );

  Widget _divider() => Container(width: 1, height: 44, margin: const EdgeInsets.symmetric(horizontal: 8), color: Colors.white24);

  Widget _cell(String v, String l, IconData i) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(i, color: Colors.white70, size: 18),
        const SizedBox(height: 6),
        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(v, style: AppTextStyles.display(size: 18, weight: FontWeight.w800, color: Colors.white))),
        Text(l, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.body(size: 11, weight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.85))),
      ]);
}

class _SearchBox extends StatefulWidget {
  final ValueChanged<String> onChanged;
  const _SearchBox({required this.onChanged});

  @override
  State<_SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<_SearchBox> {
  final _focus = FocusNode();

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: f ? AppColors.primary : AppColors.border, width: f ? 1.8 : 1.3),
          boxShadow: f ? [BoxShadow(color: AppColors.g500.withValues(alpha: 0.14), blurRadius: 16, offset: const Offset(0, 6))] : null,
        ),
        child: Row(children: [
          Icon(Icons.search_rounded, size: 20, color: f ? AppColors.primary : AppColors.text3),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              focusNode: _focus,
              onChanged: widget.onChanged,
              style: AppTextStyles.body(size: 14, weight: FontWeight.w600),
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                hintText: 'Номер заказа или товар',
                hintStyle: AppTextStyles.body(size: 14, weight: FontWeight.w600, color: AppColors.text3),
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _StatusChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final int count;
  final bool active;
  final VoidCallback onTap;
  const _StatusChip({required this.label, required this.icon, required this.count, required this.active, required this.onTap});

  @override
  State<_StatusChip> createState() => _StatusChipState();
}

class _StatusChipState extends State<_StatusChip> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    final on = widget.active;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _h = true),
        onExit: (_) => setState(() => _h = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              gradient: on ? AppColors.brandGradient : null,
              color: on ? null : (_h ? AppColors.g50 : AppColors.surface),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: on ? Colors.transparent : (_h ? AppColors.g200 : AppColors.border), width: 1.3),
              boxShadow: on ? [BoxShadow(color: AppColors.g500.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 5))] : null,
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(widget.icon, size: 16, color: on ? Colors.white : AppColors.g600),
              const SizedBox(width: 6),
              Text(widget.label, style: AppTextStyles.body(size: 12.8, weight: FontWeight.w800, color: on ? Colors.white : AppColors.text2)),
              const SizedBox(width: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: on ? Colors.white24 : AppColors.surface2, borderRadius: BorderRadius.circular(8)),
                child: Text('${widget.count}', style: AppTextStyles.body(size: 11, weight: FontWeight.w800, color: on ? Colors.white : AppColors.text3)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Карточка заказа ───────────────────────────

class _OrderCard extends StatefulWidget {
  final Order order;
  final String Function(double) price;
  final VoidCallback onOpen;
  final VoidCallback onRepeat;
  final ValueChanged<String> onCopy;
  const _OrderCard({required this.order, required this.price, required this.onOpen, required this.onRepeat, required this.onCopy});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _h = false;
  bool _repeating = false;

  Future<void> _doRepeat() async {
    setState(() => _repeating = true);
    widget.onRepeat();
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) setState(() => _repeating = false);
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final (bg, fg) = _statusColors(o.status);
    final names = o.items.map((i) => i.productName).toList();
    final preview = names.take(2).join(', ') + (names.length > 2 ? ' и ещё ${names.length - 2}' : '');

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onOpen,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 230),
          transform: Matrix4.translationValues(0, _h ? -3 : 0, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _h ? AppColors.g200 : AppColors.borderSoft, width: 1.3),
            boxShadow: [BoxShadow(color: AppColors.g900.withValues(alpha: _h ? 0.1 : 0.04), blurRadius: _h ? 22 : 10, offset: Offset(0, _h ? 10 : 4))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(13)),
                child: Icon(_statusIcon(o.status), color: fg, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(o.orderNumber, style: AppTextStyles.display(size: 15, weight: FontWeight.w800)),
                  Text(_date(o.createdAt), style: AppTextStyles.body(size: 11.8, weight: FontWeight.w600, color: AppColors.text3)),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
                child: Text(o.status.label, style: AppTextStyles.body(size: 11.5, weight: FontWeight.w800, color: fg)),
              ),
            ]),
            if (o.status != OrderStatus.otmenen) ...[
              const SizedBox(height: 14),
              _Progress(status: o.status),
            ],
            if (preview.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(preview, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.body(size: 12.8, weight: FontWeight.w700, color: AppColors.text2)),
            ],
            if ((o.cargoTrackingNumber ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              HoverScale(
                hover: 1.02,
                onTap: () => widget.onCopy(o.cargoTrackingNumber!),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(color: const Color(0xFFE8F5FF), borderRadius: BorderRadius.circular(10)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.qr_code_2_rounded, size: 16, color: Color(0xFF0369A1)),
                    const SizedBox(width: 6),
                    Text('Трек: ${o.cargoTrackingNumber}', style: AppTextStyles.mono(size: 12.5, color: const Color(0xFF0369A1))),
                    const SizedBox(width: 6),
                    const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF0369A1)),
                  ]),
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.borderSoft),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${o.itemsCount} шт · ${o.deliveryCountry.label}', style: AppTextStyles.body(size: 11.8, weight: FontWeight.w700, color: AppColors.text3)),
                  Text(widget.price(o.totalAmount), style: AppTextStyles.mono(size: 17, weight: FontWeight.w800, color: _h ? AppColors.g700 : AppColors.text)),
                ]),
              ),
              HoverScale(
                onTap: _repeating ? null : _doRepeat,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: AppColors.g50, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.g100)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    _repeating
                        ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.g600))
                        : const Icon(Icons.replay_rounded, size: 17, color: AppColors.g700),
                    const SizedBox(width: 6),
                    Text('Повторить', style: AppTextStyles.body(size: 12.5, weight: FontWeight.w800, color: AppColors.g700)),
                  ]),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: _h ? AppColors.brandGradient : null,
                  color: _h ? null : AppColors.surface2,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.arrow_forward_rounded, size: 19, color: _h ? Colors.white : AppColors.g600),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

/// Шкала: Новый → В обработке → Отправлен → Доставлен (анимированно заполняется).
class _Progress extends StatelessWidget {
  final OrderStatus status;
  const _Progress({required this.status});

  @override
  Widget build(BuildContext context) {
    const steps = [OrderStatus.novyy, OrderStatus.vObrabotke, OrderStatus.otpravlen, OrderStatus.zavershen];
    final idx = steps.indexOf(status).clamp(0, 3);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: idx / 3),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Column(children: [
        LayoutBuilder(builder: (context, box) {
          final w = box.maxWidth;
          return SizedBox(
            height: 18,
            child: Stack(alignment: Alignment.centerLeft, children: [
              Container(height: 4, margin: const EdgeInsets.symmetric(horizontal: 9), decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(2))),
              Container(
                height: 4,
                width: 9 + (w - 18) * v,
                margin: const EdgeInsets.only(left: 9),
                decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(2)),
              ),
              for (var i = 0; i < 4; i++)
                Positioned(
                  left: (w - 18) * i / 3,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: v >= i / 3 - 0.001 ? AppColors.brandGradient : null,
                      color: v >= i / 3 - 0.001 ? null : AppColors.surface,
                      border: Border.all(color: v >= i / 3 - 0.001 ? Colors.white : AppColors.border, width: 2),
                    ),
                    child: v >= i / 3 - 0.001 ? const Icon(Icons.check_rounded, size: 10, color: Colors.white) : null,
                  ),
                ),
            ]),
          );
        }),
        const SizedBox(height: 5),
        Row(children: [
          for (var i = 0; i < 4; i++)
            Expanded(
              child: Text(
                const ['Принят', 'Сборка', 'В пути', 'Доставлен'][i],
                textAlign: i == 0 ? TextAlign.left : (i == 3 ? TextAlign.right : TextAlign.center),
                style: AppTextStyles.body(size: 10.5, weight: FontWeight.w700, color: i <= idx ? AppColors.g700 : AppColors.text3),
              ),
            ),
        ]),
      ]),
    );
  }
}

// ─────────────────────────── Пусто / загрузка ───────────────────────────

class _Empty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String action;
  final VoidCallback onAction;
  const _Empty({required this.icon, required this.title, required this.subtitle, required this.action, required this.onAction});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(30, 40, 30, 20),
        child: Reveal(
          child: Column(children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.elasticOut,
              builder: (context, s, child) => Transform.scale(scale: s, child: child),
              child: Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(color: AppColors.g50, shape: BoxShape.circle),
                child: Icon(icon, size: 44, color: AppColors.g500),
              ),
            ),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: AppTextStyles.display(size: 17, weight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: AppTextStyles.body(size: 13, weight: FontWeight.w600, color: AppColors.text3)),
            const SizedBox(height: 18),
            HoverScale(
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: AppColors.g500.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 6))],
                ),
                child: Text(action, style: AppTextStyles.body(size: 14, weight: FontWeight.w800, color: Colors.white)),
              ),
            ),
          ]),
        ),
      );
}

class _Skeleton extends StatefulWidget {
  const _Skeleton();

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

  Widget _box(double h, double r) => AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Container(
          height: h,
          margin: const EdgeInsets.only(bottom: 12),
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
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        children: [_box(28, 8), _box(96, 24), _box(48, 16), _box(190, 22), _box(190, 22)],
      );
}
