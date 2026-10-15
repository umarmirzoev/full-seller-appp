import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/address.dart';
import '../models/app_user.dart';
import '../models/order.dart' as order_model;
import '../providers/cart_provider.dart';
import '../providers/currency_provider.dart';
import '../routes/app_routes.dart';
import '../services/api_exception.dart';
import '../services/delivery_repository.dart';
import '../services/orders_repository.dart';
import '../services/profile_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';
import '../widgets/auth_ui.dart' show Reveal, HoverScale;

/// Минимальная сумма заказа — такая же, как на backend (OrderService.MinimumOrderAmount), в рублях.
const double kMinOrderAmount = 2000;

const Color _waColor = Color(0xFF25D366);
const Color _tgColor = Color(0xFF229ED9);
const Color _okColor = Color(0xFF15803D);

/// Оформление заказа: контакты (номер берётся из аккаунта), выбор сохранённого или нового адреса,
/// способ оплаты, мессенджер (WhatsApp / Telegram), в который заказ уходит автоматически.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  AppUser? _user;
  List<Address> _addresses = [];
  Address? _address;
  bool _loading = true;

  bool _showForm = false;
  bool _savingAddress = false;
  String? _addressError;
  DeliveryCountry _newCountry = DeliveryCountry.uzbekistan;

  final _nameC = TextEditingController();
  final _cityC = TextEditingController();
  final _lineC = TextEditingController();
  final _commentC = TextEditingController();

  order_model.PaymentMethod _payment = order_model.PaymentMethod.card;
  order_model.NotifyChannel _channel = order_model.NotifyChannel.whatsapp;

  DeliveryCalculation? _delivery;
  bool _loadingDelivery = false;

  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameC.dispose();
    _cityC.dispose();
    _lineC.dispose();
    _commentC.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    AppUser? user;
    var addresses = <Address>[];
    String? err;
    try {
      user = await ProfileRepository.getProfile();
    } catch (_) {}
    try {
      addresses = await ProfileRepository.getAddresses();
    } on ApiException catch (e) {
      err = e.message;
    } catch (_) {
      err = 'Не удалось загрузить адреса';
    }
    if (!mounted) return;
    // «Ваш адрес» — адрес по умолчанию (последний сохранённый) — идёт первым.
    addresses.sort((a, b) => (b.isDefault ? 1 : 0) - (a.isDefault ? 1 : 0));
    setState(() {
      _user = user;
      _newCountry = DeliveryCountryX.fromPhone(user?.phone);
      if (user != null && user.fullName.trim().isNotEmpty && _nameC.text.isEmpty) _nameC.text = user.fullName.trim();
      _addresses = addresses;
      _address = addresses.isEmpty ? null : addresses.first;
      _showForm = addresses.isEmpty;
      _error = err;
      _loading = false;
    });
    _loadDelivery();
  }

  Future<void> _loadDelivery() async {
    final address = _address;
    if (address == null) {
      if (mounted) setState(() => _delivery = null);
      return;
    }
    final weight = context.read<CartProvider>().totalWeightGrams;
    setState(() => _loadingDelivery = true);
    try {
      final calc = await DeliveryRepository.calculate(country: address.country, totalWeightGrams: weight);
      if (!mounted || _address?.id != address.id) return;
      setState(() {
        _delivery = calc;
        _loadingDelivery = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingDelivery = false);
    }
  }

  Future<void> _saveAddress() async {
    final city = _cityC.text.trim();
    final line = _lineC.text.trim();
    if (city.isEmpty || line.isEmpty) {
      setState(() => _addressError = 'Заполните город и адрес');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _savingAddress = true;
      _addressError = null;
    });
    try {
      final created = await ProfileRepository.createAddress(country: _newCountry, city: city, line: line);
      // Следующий раз этот адрес будет предложен первым («Ваш адрес»).
      try {
        await ProfileRepository.setDefaultAddress(created.id);
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _addresses = [created, ..._addresses];
        _address = created;
        _showForm = false;
        _savingAddress = false;
        _error = null;
        _cityC.clear();
        _lineC.clear();
      });
      _loadDelivery();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _savingAddress = false;
        _addressError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _savingAddress = false;
        _addressError = 'Не удалось сохранить адрес';
      });
    }
  }

  void _fail(String message) => setState(() => _error = message);

  Future<void> _submit() async {
    final cart = context.read<CartProvider>();
    FocusScope.of(context).unfocus();

    if (cart.isEmpty) return _fail('Корзина пуста');
    if (cart.totalAmount < kMinOrderAmount) return _fail('Минимальная сумма заказа — ${kMinOrderAmount.round()} ₽');
    final name = _nameC.text.trim();
    if (name.isEmpty) return _fail('Введите ваше имя');
    final address = _address;
    if (address == null) return _fail(_showForm ? 'Сохраните адрес доставки' : 'Выберите адрес доставки');

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final order = await OrdersRepository.createOrder(
        addressId: address.id,
        country: address.country,
        paymentMethod: _payment,
        contactName: name,
        comment: _commentC.text.trim().isEmpty ? null : _commentC.text.trim(),
        notifyChannel: _channel,
      );
      // Имя запоминаем в профиле, чтобы в следующий раз оно подставилось само.
      if (_user == null || _user!.fullName.trim() != name) {
        unawaited(ProfileRepository.updateProfile(fullName: name).then((_) {}).catchError((_) {}));
      }
      // Backend уже очистил корзину — просто перечитываем её.
      await cart.load();
      if (!mounted) return;
      setState(() => _submitting = false);
      await _showSuccess(order);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Не удалось оформить заказ. Проверьте интернет и попробуйте ещё раз.';
      });
    }
  }

  Future<void> _showSuccess(order_model.Order order) async {
    final toOrders = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Заказ оформлен',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (_, __, ___) => _SuccessDialog(orderNumber: order.orderNumber, channel: _channel),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack), child: child),
      ),
    );
    if (!mounted) return;
    if (toOrders == true) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.orders, (route) => route.settings.name == AppRoutes.home || route.isFirst);
    } else {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  // ───────────────────────────── build ─────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final currency = context.watch<CurrencyProvider>();
    final deliveryCost = _delivery?.totalCost ?? 0;
    final total = cart.totalAmount + deliveryCost;
    final belowMin = !cart.isEmpty && cart.totalAmount < kMinOrderAmount;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text('Оформление заказа', style: AppTextStyles.display(size: 17))),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Reveal(child: _summaryCard(cart, currency, total, deliveryCost)),
            const SizedBox(height: 24),
            Reveal(delayMs: 70, child: _section('КОНТАКТЫ', Icons.person_rounded, _contactsBlock())),
            const SizedBox(height: 24),
            Reveal(delayMs: 140, child: _section('АДРЕС ДОСТАВКИ', Icons.location_on_rounded, _addressBlock())),
            const SizedBox(height: 24),
            Reveal(delayMs: 210, child: _section('СПОСОБ ОПЛАТЫ', Icons.payments_rounded, _paymentBlock())),
            const SizedBox(height: 24),
            Reveal(delayMs: 280, child: _section('КУДА ОТПРАВИТЬ ЗАКАЗ', Icons.send_rounded, _channelBlock())),
            const SizedBox(height: 24),
            Reveal(
              delayMs: 350,
              child: _section(
                'КОММЕНТАРИЙ',
                Icons.chat_bubble_outline_rounded,
                TextField(
                  controller: _commentC,
                  minLines: 2,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(hintText: 'Пожелания к заказу (необязательно)'),
                ),
              ),
            ),
          ]),
        ),
      ),
      bottomNavigationBar: _bottomBar(cart, currency, total, belowMin),
    );
  }

  Widget _bottomBar(CartProvider cart, CurrencyProvider currency, double total, bool belowMin) {
    final message = _error ?? (belowMin ? 'Минимальная сумма заказа — ${kMinOrderAmount.round()} ₽' : null);
    final disabled = _submitting || cart.isEmpty || belowMin;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: const Border(top: BorderSide(color: AppColors.borderSoft)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 12, 20, 14),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: message == null
                ? const SizedBox(width: double.infinity)
                : Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: const Color(0xFFFDECEC), borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      const Icon(Icons.error_outline_rounded, size: 18, color: Color(0xFFD64545)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(message, style: AppTextStyles.body(size: 12.5, weight: FontWeight.w700, color: const Color(0xFFD64545)))),
                    ]),
                  ),
          ),
          _PrimaryButton(
            onTap: disabled ? null : _submit,
            loading: _submitting,
            label: 'Подтвердить заказ · ${currency.format(total)}',
          ),
        ]),
      ),
    );
  }

  // ───────────────────────────── блоки ─────────────────────────────

  Widget _section(String title, IconData icon, Widget child) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(color: AppColors.g50, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 15, color: AppColors.g600),
          ),
          const SizedBox(width: 9),
          Text(title, style: AppTextStyles.body(size: 11.5, weight: FontWeight.w800, color: AppColors.text3).copyWith(letterSpacing: 0.5)),
        ]),
      ),
      child,
    ]);
  }

  Widget _summaryCard(CartProvider cart, CurrencyProvider currency, double total, double deliveryCost) {
    final items = cart.items;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: [BoxShadow(color: AppColors.g500.withOpacity(0.10), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          color: AppColors.surface,
          child: Column(children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.g400, AppColors.g600], begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('К ОПЛАТЕ', style: AppTextStyles.body(size: 11.5, weight: FontWeight.w800, color: Colors.white70).copyWith(letterSpacing: 0.6)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.22), borderRadius: BorderRadius.circular(99)),
                    child: Text('${cart.itemsCount} шт', style: AppTextStyles.body(size: 12, weight: FontWeight.w800, color: Colors.white)),
                  ),
                ]),
                const SizedBox(height: 6),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(anim), child: child),
                  ),
                  child: Text(currency.format(total), key: ValueKey(currency.format(total)), style: AppTextStyles.mono(size: 30, color: Colors.white)),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
              child: Column(children: [
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text('Корзина пуста', style: AppTextStyles.body(size: 13, weight: FontWeight.w600, color: AppColors.text3)),
                  ),
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(
                            '${items[i].productName}${(items[i].variantLabel == null || items[i].variantLabel!.isEmpty) ? '' : ' · ${items[i].variantLabel}'}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body(size: 13, weight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text('${items[i].quantity} шт × ${currency.format(items[i].unitPrice)}',
                              style: AppTextStyles.body(size: 11.5, weight: FontWeight.w600, color: AppColors.text3)),
                        ]),
                      ),
                      const SizedBox(width: 12),
                      Text(currency.format(items[i].total), style: AppTextStyles.body(size: 13, weight: FontWeight.w800)),
                    ]),
                  ),
                ],
                const Divider(height: 1),
                const SizedBox(height: 8),
                _row('Товары', currency.format(cart.totalAmount)),
                _row('Доставка', _loadingDelivery ? '…' : (_address == null ? 'после выбора адреса' : currency.format(deliveryCost))),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: AppTextStyles.body(size: 12.5, weight: FontWeight.w600, color: AppColors.text3)),
          Text(value, style: AppTextStyles.body(size: 12.5, weight: FontWeight.w700)),
        ]),
      );

  Widget _contactsBlock() {
    final phone = _user?.phone ?? '';
    final hasPhone = phone.startsWith('+');
    return Column(children: [
      if (hasPhone) ...[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Row(children: [
            const Icon(Icons.phone_rounded, size: 18, color: AppColors.g600),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(phone, style: AppTextStyles.body(size: 14, weight: FontWeight.w800)),
                Text('Номер из вашего аккаунта', style: AppTextStyles.body(size: 11.5, weight: FontWeight.w600, color: AppColors.text3)),
              ]),
            ),
            const Icon(Icons.verified_rounded, size: 20, color: _okColor),
          ]),
        ),
        const SizedBox(height: 12),
      ],
      TextField(
        controller: _nameC,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.next,
        decoration: const InputDecoration(hintText: 'Ваше имя', prefixIcon: Icon(Icons.badge_outlined, size: 20)),
      ),
    ]);
  }

  Widget _addressBlock() {
    if (_loading) {
      return const Column(children: [_Pulse(height: 70), SizedBox(height: 10), _Pulse(height: 52)]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (var i = 0; i < _addresses.length; i++) _addressTile(_addresses[i], isMain: i == 0),
      if (_addresses.isNotEmpty)
        _SelectCard(
          selected: _showForm,
          accent: AppColors.g500,
          onTap: () => setState(() {
            _showForm = !_showForm;
            _addressError = null;
          }),
          child: Row(children: [
            AnimatedRotation(
              turns: _showForm ? 0.125 : 0,
              duration: const Duration(milliseconds: 260),
              child: const Icon(Icons.add_circle_outline_rounded, size: 22, color: AppColors.g600),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(_showForm ? 'Отменить новый адрес' : 'Добавить новый адрес', style: AppTextStyles.body(size: 13.5, weight: FontWeight.w700))),
          ]),
        ),
      AnimatedSize(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: _showForm ? _addressForm() : const SizedBox(width: double.infinity),
      ),
    ]);
  }

  Widget _addressTile(Address a, {required bool isMain}) {
    final selected = _address?.id == a.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _SelectCard(
        selected: selected,
        accent: AppColors.g500,
        onTap: () {
          if (_address?.id == a.id) return;
          setState(() => _address = a);
          _loadDelivery();
        },
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: selected ? AppColors.g500 : AppColors.g50, borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.home_rounded, size: 20, color: selected ? Colors.white : AppColors.g600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                  child: Text(isMain ? 'Ваш адрес' : a.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.body(size: 13.5, weight: FontWeight.w800)),
                ),
                if (isMain) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.g50, borderRadius: BorderRadius.circular(99)),
                    child: Text('прошлый', style: AppTextStyles.body(size: 10.5, weight: FontWeight.w800, color: AppColors.g600)),
                  ),
                ],
              ]),
              const SizedBox(height: 2),
              Text('${a.country.label}, ${a.city}, ${a.street}',
                  maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.body(size: 12, weight: FontWeight.w600, color: AppColors.text3)),
            ]),
          ),
          const SizedBox(width: 10),
          _RadioDot(selected: selected, accent: AppColors.g500),
        ]),
      ),
    );
  }

  Widget _addressForm() {
    return Padding(
      padding: EdgeInsets.only(top: _addresses.isEmpty ? 0 : 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_addresses.isEmpty ? 'Введите адрес доставки' : 'Новый адрес', style: AppTextStyles.display(size: 14)),
          if (_addresses.isEmpty) ...[
            const SizedBox(height: 4),
            Text('Мы сохраним его — в следующий раз вам останется только выбрать.',
                style: AppTextStyles.body(size: 12, weight: FontWeight.w600, color: AppColors.text3)),
          ],
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final c in DeliveryCountry.values) _countryChip(c.label, c),
          ]),
          const SizedBox(height: 12),
          TextField(
            controller: _cityC,
            enabled: !_savingAddress,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(hintText: 'Город', prefixIcon: Icon(Icons.location_city_rounded, size: 20)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _lineC,
            enabled: !_savingAddress,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _saveAddress(),
            decoration: const InputDecoration(hintText: 'Улица, дом, квартира', prefixIcon: Icon(Icons.home_outlined, size: 20)),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            alignment: Alignment.topCenter,
            child: _addressError == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(_addressError!, style: AppTextStyles.body(size: 12, weight: FontWeight.w700, color: AppColors.danger)),
                  ),
          ),
          const SizedBox(height: 14),
          _PrimaryButton(onTap: _savingAddress ? null : _saveAddress, loading: _savingAddress, label: 'Сохранить адрес', height: 48),
        ]),
      ),
    );
  }

  Widget _countryChip(String label, DeliveryCountry country) {
    final selected = _newCountry == country;
    return _SelectCard(
      selected: selected,
      accent: AppColors.g500,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      fit: false,
      onTap: () => setState(() => _newCountry = country),
      child: Center(widthFactor: 1, child: Text(label, style: AppTextStyles.body(size: 13, weight: FontWeight.w800, color: selected ? AppColors.g700 : AppColors.text2))),
    );
  }

  Widget _paymentBlock() {
    Widget tile(order_model.PaymentMethod method, String label, IconData icon) {
      final selected = _payment == method;
      return Expanded(
        child: _SelectCard(
          selected: selected,
          accent: AppColors.g500,
          onTap: () => setState(() => _payment = method),
          child: Column(children: [
            AnimatedScale(
              scale: selected ? 1.12 : 1,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: Icon(icon, size: 24, color: selected ? AppColors.g600 : AppColors.text2),
            ),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: AppTextStyles.body(size: 12.5, weight: FontWeight.w800, color: selected ? AppColors.g700 : AppColors.text2)),
          ]),
        ),
      );
    }

    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        tile(order_model.PaymentMethod.card, 'Картой', Icons.credit_card_rounded),
        const SizedBox(width: 12),
        tile(order_model.PaymentMethod.invoice, 'По счёту (юр. лицо)', Icons.account_balance_rounded),
      ]),
    );
  }

  Widget _channelBlock() {
    Widget tile(order_model.NotifyChannel channel, String label, IconData icon, Color color) {
      final selected = _channel == channel;
      return Expanded(
        child: _SelectCard(
          selected: selected,
          accent: color,
          onTap: () => setState(() => _channel = channel),
          child: Column(children: [
            Stack(clipBehavior: Clip.none, children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: selected ? color : color.withOpacity(0.12),
                  shape: BoxShape.circle,
                  boxShadow: selected ? [BoxShadow(color: color.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 5))] : const [],
                ),
                child: Icon(icon, size: 22, color: selected ? Colors.white : color),
              ),
              Positioned(
                right: -4,
                top: -4,
                child: AnimatedScale(
                  scale: selected ? 1 : 0,
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutBack,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(color: _okColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                    child: const Icon(Icons.check_rounded, size: 12, color: Colors.white),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            Text(label, style: AppTextStyles.body(size: 14, weight: FontWeight.w800)),
          ]),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          tile(order_model.NotifyChannel.whatsapp, 'WhatsApp', Icons.chat_rounded, _waColor),
          const SizedBox(width: 12),
          tile(order_model.NotifyChannel.telegram, 'Telegram', Icons.send_rounded, _tgColor),
        ]),
      ),
      const SizedBox(height: 10),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.bolt_rounded, size: 16, color: AppColors.g600),
        const SizedBox(width: 6),
        Expanded(
          child: Text('Заказ уйдёт продавцу автоматически — открывать мессенджер и писать самому не нужно.',
              style: AppTextStyles.body(size: 12, weight: FontWeight.w600, color: AppColors.text3)),
        ),
      ]),
    ]);
  }
}

// ═════════════════════════ вспомогательные виджеты ═════════════════════════

/// Карточка-выбор: подсветка при наведении, лёгкое «нажатие», плавная смена состояния.
class _SelectCard extends StatefulWidget {
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsets padding;
  final bool fit;
  const _SelectCard({
    this.fit = true,
    required this.selected,
    required this.accent,
    required this.onTap,
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  State<_SelectCard> createState() => _SelectCardState();
}

class _SelectCardState extends State<_SelectCard> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;
    final selected = widget.selected;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.975 : 1,
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: widget.fit ? double.infinity : null,
            padding: widget.padding,
            decoration: BoxDecoration(
              color: selected ? accent.withOpacity(0.07) : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: selected ? accent : (_hover ? accent.withOpacity(0.55) : AppColors.border),
                width: selected ? 1.8 : 1.3,
              ),
              boxShadow: (_hover || selected) ? [BoxShadow(color: accent.withOpacity(0.16), blurRadius: 18, offset: const Offset(0, 6))] : const [],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  final bool selected;
  final Color accent;
  const _RadioDot({required this.selected, required this.accent});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: selected ? accent : AppColors.border, width: 2),
      ),
      child: Center(
        child: AnimatedScale(
          scale: selected ? 1 : 0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          child: Container(width: 10, height: 10, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
        ),
      ),
    );
  }
}

/// Главная кнопка: градиент, наведение/нажатие, плавный переход в состояние загрузки.
class _PrimaryButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool loading;
  final String label;
  final double height;
  const _PrimaryButton({required this.onTap, required this.label, this.loading = false, this.height = 54});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return HoverScale(
      onTap: onTap,
      hover: 1.015,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        height: height,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: enabled || loading
              ? const LinearGradient(colors: [AppColors.g400, AppColors.g600], begin: Alignment.topLeft, end: Alignment.bottomRight)
              : null,
          color: enabled || loading ? null : const Color(0xFFE4DDD6),
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: enabled ? [BoxShadow(color: AppColors.g500.withOpacity(0.32), blurRadius: 18, offset: const Offset(0, 8))] : const [],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: loading
              ? const SizedBox(key: ValueKey('l'), width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
              : Text(
                  label,
                  key: ValueKey(label),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: enabled ? Colors.white : const Color(0xFF9C8F80)),
                ),
        ),
      ),
    );
  }
}

/// Пульсирующая заглушка на время загрузки.
class _Pulse extends StatefulWidget {
  final double height;
  const _Pulse({required this.height});

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Container(
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Color.lerp(AppColors.surface2, AppColors.surface3, _c.value),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }
}

class _SuccessDialog extends StatelessWidget {
  final String orderNumber;
  final order_model.NotifyChannel channel;
  const _SuccessDialog({required this.orderNumber, required this.channel});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          constraints: const BoxConstraints(maxWidth: 380),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 40, offset: const Offset(0, 16))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.elasticOut,
                builder: (_, v, child) => Transform.scale(scale: v, child: child),
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [Color(0xFF22C55E), _okColor], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    boxShadow: [BoxShadow(color: _okColor.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 10))],
                  ),
                  child: const Icon(Icons.check_rounded, size: 46, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Заказ оформлен!', textAlign: TextAlign.center, style: AppTextStyles.display(size: 20)),
            const SizedBox(height: 8),
            Text('Номер заказа: $orderNumber', textAlign: TextAlign.center, style: AppTextStyles.mono(size: 14, color: AppColors.g600)),
            const SizedBox(height: 10),
            Text(
              'Мы отправили его продавцу в ${channel == order_model.NotifyChannel.whatsapp ? 'WhatsApp' : 'Telegram'}. Скоро с вами свяжутся.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body(size: 13, weight: FontWeight.w600, color: AppColors.text3),
            ),
            const SizedBox(height: 22),
            _PrimaryButton(onTap: () => Navigator.pop(context, true), label: 'Мои заказы'),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('На главную', style: AppTextStyles.body(size: 13.5, weight: FontWeight.w800, color: AppColors.text2)),
            ),
          ]),
        ),
      ),
    );
  }
}
