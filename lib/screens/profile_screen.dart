import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_user.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import '../routes/app_routes.dart';
import '../services/api_exception.dart';
import '../services/auth_repository.dart';
import '../services/notifications_repository.dart';
import '../services/orders_repository.dart';
import '../services/profile_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/auth_ui.dart' show Reveal, HoverScale, GlowButton, AuthTextField;

/// Профиль покупателя: шапка с аватаром и редактированием имени, статистика
/// (заказы / избранное / баллы), меню по группам, выход с подтверждением.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AppUser? _user;
  bool _loading = true;
  int _orders = 0;
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    context.read<FavoritesProvider>().load();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = _user == null);
    unawaited(_loadCounters());
    try {
      final user = await ProfileRepository.getProfile();
      if (!mounted) return;
      setState(() {
        _user = user;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.isUnauthorized) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.auth, (r) => false);
        return;
      }
      setState(() => _loading = false);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadCounters() async {
    try {
      final page = await OrdersRepository.getMyOrders(pageSize: 1);
      if (mounted) setState(() => _orders = page.totalCount);
    } catch (_) {}
    try {
      final list = await NotificationsRepository.getMy();
      if (mounted) setState(() => _unread = list.where((n) => !n.isRead).length);
    } catch (_) {}
  }

  Future<void> _editName() async {
    final user = _user;
    if (user == null) return;
    final updated = await showModalBottomSheet<AppUser>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditNameSheet(user: user),
    );
    if (updated != null && mounted) {
      setState(() => _user = updated);
      _toast('Имя сохранено');
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black45,
      builder: (ctx) => const _LogoutDialog(),
    );
    if (ok != true) return;
    await AuthRepository.logout();
    if (!mounted) return;
    unawaited(context.read<CartProvider>().load());
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.auth, (r) => false);
  }

  void _toast(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.text,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      content: Row(children: [
        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Text(text, style: AppTextStyles.body(size: 13.5, weight: FontWeight.w700, color: Colors.white)),
      ]),
    ));

  void _go(String route) => Navigator.pushNamed(context, route).then((_) {
        if (mounted) _loadCounters();
      });

  @override
  Widget build(BuildContext context) {
    final favCount = context.watch<FavoritesProvider>().count;
    final user = _user;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : user == null
                ? _error()
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _load,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                          children: [
                            Reveal(child: _Header(user: user, onEdit: _editName)),
                            const SizedBox(height: 16),
                            Reveal(
                              delayMs: 80,
                              child: Row(children: [
                                Expanded(child: _Stat(icon: Icons.inventory_2_rounded, value: _orders, label: 'Заказов', onTap: () => _go(AppRoutes.orders))),
                                const SizedBox(width: 10),
                                Expanded(child: _Stat(icon: Icons.favorite_rounded, value: favCount, label: 'Избранное', onTap: () => _go(AppRoutes.favorites))),
                                const SizedBox(width: 10),
                                Expanded(child: _Stat(icon: Icons.stars_rounded, value: user.loyaltyPoints, label: 'Баллов', onTap: null)),
                              ]),
                            ),
                            const SizedBox(height: 20),
                            Reveal(
                              delayMs: 140,
                              child: _Group(title: 'Покупки', items: [
                                _Item(Icons.inventory_2_outlined, 'Мои заказы', 'История и статусы', () => _go(AppRoutes.orders), badge: _orders > 0 ? '$_orders' : null),
                                _Item(Icons.favorite_border_rounded, 'Избранное', 'Сохранённые товары', () => _go(AppRoutes.favorites), badge: favCount > 0 ? '$favCount' : null),
                                _Item(Icons.shopping_cart_outlined, 'Корзина', 'Товары к заказу', () => _go(AppRoutes.cart)),
                                _Item(Icons.bolt_rounded, 'Быстрый заказ', 'Заказ по артикулам', () => _go(AppRoutes.quickOrder)),
                                _Item(Icons.local_shipping_outlined, 'Калькулятор доставки', 'Карго в РФ и Таджикистан', () => _go(AppRoutes.cargoCalculator)),
                              ]),
                            ),
                            Reveal(
                              delayMs: 200,
                              child: _Group(title: 'Помощь', items: [
                                _Item(Icons.chat_bubble_outline_rounded, 'Чат с менеджером', 'Ответим в течение дня', () => _go(AppRoutes.chat)),
                                _Item(Icons.auto_awesome_outlined, 'FULL AI', 'Подбор товара и расчёт партии', () => _go(AppRoutes.fullAi)),
                                _Item(Icons.notifications_none_rounded, 'Уведомления', 'Заказы и акции', () => _go(AppRoutes.notifications), badge: _unread > 0 ? '$_unread' : null),
                              ]),
                            ),
                            Reveal(
                              delayMs: 260,
                              child: _Group(title: 'Аккаунт', items: [
                                _Item(Icons.edit_outlined, 'Изменить имя', user.fullName.isEmpty ? 'Не указано' : user.fullName, _editName),
                                _Item(Icons.settings_outlined, 'Настройки', 'Язык, конфиденциальность', () => _go(AppRoutes.settings)),
                              ]),
                            ),
                            const SizedBox(height: 6),
                            Reveal(delayMs: 320, child: _LogoutButton(onTap: _logout)),
                            const SizedBox(height: 18),
                            Center(child: Text('FULL SELLER · оптовый маркетплейс', style: AppTextStyles.body(size: 11.5, weight: FontWeight.w600, color: AppColors.text3))),
                          ],
                        ),
                      ),
                    ),
                  ),
      ),
      bottomNavigationBar: const AppBottomNav(current: AppTab.profile),
    );
  }

  Widget _error() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off_rounded, size: 44, color: AppColors.g200),
          const SizedBox(height: 10),
          Text('Не удалось загрузить профиль', style: AppTextStyles.display(size: 15, weight: FontWeight.w800)),
          const SizedBox(height: 14),
          SizedBox(width: 200, child: GlowButton(text: 'Повторить', icon: Icons.refresh_rounded, onPressed: _load)),
          const SizedBox(height: 10),
          HoverScale(
            onTap: _logout,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text('Выйти из аккаунта', style: AppTextStyles.body(size: 13, weight: FontWeight.w800, color: AppColors.danger)),
            ),
          ),
        ]),
      );
}

// ─────────────────────────── Шапка ───────────────────────────

class _Header extends StatefulWidget {
  final AppUser user;
  final VoidCallback onEdit;
  const _Header({required this.user, required this.onEdit});

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: AppColors.g500.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final t = _c.value * 6.283;
              return Stack(clipBehavior: Clip.none, children: [
                Positioned(right: -40 + 10 * _sin(t), top: -50 + 8 * _cos(t), child: _bubble(170, 0.12)),
                Positioned(left: -30 + 8 * _cos(t), bottom: -60 + 10 * _sin(t), child: _bubble(150, 0.08)),
              ]);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(children: [
            AnimatedBuilder(
              animation: _c,
              builder: (context, child) => Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    transform: GradientRotation(_c.value * 6.283),
                    colors: [Colors.white, Colors.white.withValues(alpha: 0.2), Colors.white],
                  ),
                ),
                child: child,
              ),
              child: Container(
                width: 68,
                height: 68,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: ShaderMask(
                  shaderCallback: (r) => AppColors.brandGradient.createShader(r),
                  child: Text(u.initials.toUpperCase(), style: AppTextStyles.display(size: 24, weight: FontWeight.w800, color: Colors.white)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(u.fullName.isEmpty ? 'Покупатель' : u.fullName,
                    maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.display(size: 18, weight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.phone_rounded, size: 14, color: Colors.white70),
                  const SizedBox(width: 5),
                  Flexible(child: Text(u.phone, style: AppTextStyles.body(size: 13, weight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.9)))),
                ]),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(u.isLegalEntity ? Icons.business_rounded : Icons.person_rounded, size: 13, color: Colors.white),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        u.isLegalEntity ? (u.legalName?.isNotEmpty == true ? u.legalName! : 'Юридическое лицо') : 'Оптовый покупатель',
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body(size: 11.5, weight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
            HoverScale(
              hover: 1.1,
              onTap: widget.onEdit,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(13)),
                child: const Icon(Icons.edit_rounded, color: Colors.white, size: 19),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  static double _sin(double x) => _s(x);
  static double _cos(double x) => _s(x + 1.5708);
  static double _s(double x) {
    // быстрый синус без dart:math, чтобы не тянуть импорт ради двух кругов
    x = x % 6.283185;
    if (x > 3.141593) x -= 6.283185;
    return 1.27323954 * x - 0.405284735 * x * x.abs();
  }

  Widget _bubble(double s, double a) => Container(
        width: s,
        height: s,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: a)),
      );
}

// ─────────────────────────── Статистика ───────────────────────────

class _Stat extends StatefulWidget {
  final IconData icon;
  final int value;
  final String label;
  final VoidCallback? onTap;
  const _Stat({required this.icon, required this.value, required this.label, required this.onTap});

  @override
  State<_Stat> createState() => _StatState();
}

class _StatState extends State<_Stat> {
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
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          transform: Matrix4.translationValues(0, _h && widget.onTap != null ? -3 : 0, 0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _h ? AppColors.g200 : AppColors.borderSoft, width: 1.3),
            boxShadow: [BoxShadow(color: AppColors.g900.withValues(alpha: _h ? 0.1 : 0.04), blurRadius: _h ? 16 : 8, offset: const Offset(0, 5))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: _h ? AppColors.brandGradient : null,
                color: _h ? null : AppColors.g50,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(widget.icon, size: 18, color: _h ? Colors.white : AppColors.g600),
            ),
            const SizedBox(height: 10),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: widget.value.toDouble()),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => Text('${v.round()}', style: AppTextStyles.display(size: 20, weight: FontWeight.w800)),
            ),
            Text(widget.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.body(size: 11.5, weight: FontWeight.w700, color: AppColors.text3)),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────── Меню ───────────────────────────

class _Item {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;
  const _Item(this.icon, this.title, this.subtitle, this.onTap, {this.badge});
}

class _Group extends StatelessWidget {
  final String title;
  final List<_Item> items;
  const _Group({required this.title, required this.items});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(title.toUpperCase(), style: AppTextStyles.body(size: 11.5, weight: FontWeight.w800, color: AppColors.text3).copyWith(letterSpacing: 0.6)),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.borderSoft, width: 1.3),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 64, color: AppColors.borderSoft),
                _MenuTile(item: items[i]),
              ],
            ]),
          ),
        ]),
      );
}

class _MenuTile extends StatefulWidget {
  final _Item item;
  const _MenuTile({required this.item});

  @override
  State<_MenuTile> createState() => _MenuTileState();
}

class _MenuTileState extends State<_MenuTile> {
  bool _h = false, _d = false;

  @override
  Widget build(BuildContext context) {
    final it = widget.item;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _d = true),
        onTapUp: (_) => setState(() => _d = false),
        onTapCancel: () => setState(() => _d = false),
        onTap: it.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          color: _d ? AppColors.g100.withValues(alpha: 0.5) : (_h ? AppColors.g50 : Colors.transparent),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              child: AnimatedRotation(
                turns: _h ? -0.03 : 0,
                duration: const Duration(milliseconds: 220),
                child: Icon(it.icon, size: 19, color: _h ? Colors.white : AppColors.g600),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(it.title, style: AppTextStyles.body(size: 14, weight: FontWeight.w800)),
                Text(it.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.body(size: 11.5, weight: FontWeight.w600, color: AppColors.text3)),
              ]),
            ),
            if (it.badge != null)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(10)),
                child: Text(it.badge!, style: AppTextStyles.body(size: 11, weight: FontWeight.w800, color: Colors.white)),
              ),
            AnimatedSlide(
              offset: Offset(_h ? 0.25 : 0, 0),
              duration: const Duration(milliseconds: 200),
              child: Icon(Icons.chevron_right_rounded, color: _h ? AppColors.g600 : AppColors.text3),
            ),
          ]),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatefulWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
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
            height: 54,
            decoration: BoxDecoration(
              color: _h ? AppColors.danger : const Color(0xFFFDECEC),
              borderRadius: BorderRadius.circular(18),
              boxShadow: _h ? [BoxShadow(color: AppColors.danger.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))] : null,
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.logout_rounded, color: _h ? Colors.white : AppColors.danger, size: 20),
              const SizedBox(width: 8),
              Text('Выйти из аккаунта', style: AppTextStyles.body(size: 14.5, weight: FontWeight.w800, color: _h ? Colors.white : AppColors.danger)),
            ]),
          ),
        ),
      );
}

// ─────────────────────────── Диалоги ───────────────────────────

class _LogoutDialog extends StatelessWidget {
  const _LogoutDialog();

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.85, end: 1),
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutBack,
        builder: (context, s, child) => Transform.scale(scale: s, child: child),
        child: Dialog(
          backgroundColor: AppColors.bg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: const BoxDecoration(color: Color(0xFFFDECEC), shape: BoxShape.circle),
                  child: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 30),
                ),
                const SizedBox(height: 14),
                Text('Выйти из аккаунта?', style: AppTextStyles.display(size: 17, weight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('Корзина и избранное сохранятся — они привязаны к аккаунту.',
                    textAlign: TextAlign.center, style: AppTextStyles.body(size: 13, weight: FontWeight.w600, color: AppColors.text3)),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                    child: HoverScale(
                      onTap: () => Navigator.pop(context, false),
                      child: Container(
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border, width: 1.4),
                        ),
                        child: Text('Отмена', style: AppTextStyles.body(size: 14, weight: FontWeight.w800)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: HoverScale(
                      onTap: () => Navigator.pop(context, true),
                      child: Container(
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(16)),
                        child: Text('Выйти', style: AppTextStyles.body(size: 14, weight: FontWeight.w800, color: Colors.white)),
                      ),
                    ),
                  ),
                ]),
              ]),
            ),
          ),
        ),
      );
}

class _EditNameSheet extends StatefulWidget {
  final AppUser user;
  const _EditNameSheet({required this.user});

  @override
  State<_EditNameSheet> createState() => _EditNameSheetState();
}

class _EditNameSheetState extends State<_EditNameSheet> {
  late final _c = TextEditingController(text: widget.user.fullName);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _c.text.trim();
    if (name.length < 2) {
      setState(() => _error = 'Введите имя');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final u = await ProfileRepository.updateProfile(fullName: name);
      if (mounted) Navigator.pop(context, u);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Не удалось сохранить';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          decoration: const BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: SafeArea(
            top: false,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Center(child: Container(width: 42, height: 5, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(3)))),
              const SizedBox(height: 16),
              Text('Как к вам обращаться?', style: AppTextStyles.display(size: 18, weight: FontWeight.w800)),
              const SizedBox(height: 14),
              AuthTextField(
                controller: _c,
                label: 'ФИО',
                hint: 'Иван Иванов',
                icon: Icons.person_outline_rounded,
                enabled: !_saving,
                onSubmitted: (_) => _save(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: AppTextStyles.body(size: 12.5, weight: FontWeight.w700, color: AppColors.danger)),
              ],
              const SizedBox(height: 16),
              GlowButton(text: 'Сохранить', icon: Icons.check_rounded, loading: _saving, onPressed: _save),
            ]),
          ),
        ),
      );
}
