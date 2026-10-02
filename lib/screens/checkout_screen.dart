import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/address.dart';
import '../models/order.dart' as order_model;
import '../providers/cart_provider.dart';
import '../providers/currency_provider.dart';
import '../routes/app_routes.dart';
import '../services/api_exception.dart';
import '../services/delivery_repository.dart';
import '../services/orders_repository.dart';
import '../services/profile_repository.dart';
import '../services/promo_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  List<Address> _addresses = [];
  Address? _address;
  order_model.PaymentMethod _payment = order_model.PaymentMethod.card;
  final _promoController = TextEditingController();
  String? _promoResult;
  double _discount = 0;
  bool _loadingAddresses = true;
  bool _loadingDelivery = false;
  bool _submitting = false;
  String? _error;
  DeliveryCalculation? _delivery;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() => _loadingAddresses = true);
    try {
      final addresses = await ProfileRepository.getAddresses();
      if (!mounted) return;
      setState(() {
        _addresses = addresses;
        _address = addresses.isEmpty ? null : addresses.firstWhere((a) => a.isDefault, orElse: () => addresses.first);
        _loadingAddresses = false;
      });
      _loadDelivery();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingAddresses = false);
    }
  }

  Future<void> _loadDelivery() async {
    final address = _address;
    final cart = context.read<CartProvider>();
    if (address == null) return;
    setState(() => _loadingDelivery = true);
    try {
      final calc = await DeliveryRepository.calculate(country: address.country, totalWeightGrams: cart.totalWeightGrams);
      if (!mounted) return;
      setState(() {
        _delivery = calc;
        _loadingDelivery = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingDelivery = false);
    }
  }

  Future<void> _addAddress() async {
    final result = await showModalBottomSheet<Address>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddAddressSheet(),
    );
    if (result != null && mounted) {
      setState(() {
        _addresses = [..._addresses, result];
        _address = result;
      });
      _loadDelivery();
    }
  }

  Future<void> _applyPromo() async {
    final code = _promoController.text.trim();
    if (code.isEmpty) return;
    final cart = context.read<CartProvider>();
    try {
      final result = await PromoRepository.validate(code, cart.totalAmount);
      if (!mounted) return;
      setState(() {
        if (result.isValid) {
          _discount = result.discountAmount;
          _promoResult = 'Промокод применён: −${_discount.round()} ₽';
        } else {
          _discount = 0;
          _promoResult = result.error ?? 'Промокод не найден';
        }
      });
    } on ApiException catch (e) {
      setState(() {
        _discount = 0;
        _promoResult = e.message;
      });
    } catch (_) {
      setState(() {
        _discount = 0;
        _promoResult = 'Не удалось проверить промокод';
      });
    }
  }

  Future<void> _submitOrder() async {
    if (_address == null) {
      setState(() => _error = 'Выберите адрес доставки');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await OrdersRepository.createOrder(addressId: _address!.id, country: _address!.country, paymentMethod: _payment);
      await context.read<CartProvider>().clear();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.orders, (route) => route.settings.name == AppRoutes.home || route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Заказ оформлен!')));
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
        _error = 'Не удалось оформить заказ. Попробуйте ещё раз.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final currency = context.watch<CurrencyProvider>();
    final deliveryCost = _delivery?.totalCost ?? 0;
    final total = (cart.totalAmount + deliveryCost - _discount).clamp(0, double.infinity);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text('Оформление заказа', style: AppTextStyles.display(size: 17))),
      body: _loadingAddresses
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    _sectionLabel('АДРЕС ДОСТАВКИ'),
                    TextButton.icon(onPressed: _addAddress, icon: const Icon(Icons.add_rounded, size: 16), label: const Text('Добавить')),
                  ]),
                  if (_addresses.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(AppRadius.md)),
                      child: Text('У вас пока нет сохранённых адресов — добавьте адрес доставки',
                          style: AppTextStyles.body(size: 12.5, weight: FontWeight.w600, color: AppColors.text3)),
                    )
                  else
                    ..._addresses.map((a) => _addressTile(a)),
                  const SizedBox(height: 20),
                  _sectionLabel('СПОСОБ ОПЛАТЫ'),
                  _paymentTile(order_model.PaymentMethod.card, 'Оплата картой', Icons.credit_card_rounded),
                  _paymentTile(order_model.PaymentMethod.invoice, 'По счёту (юр. лицо)', Icons.account_balance_outlined),
                  const SizedBox(height: 20),
                  _sectionLabel('ПРОМОКОД'),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _promoController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(hintText: 'Введите код'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(height: 52, child: OutlinedButton(onPressed: _applyPromo, child: const Text('Применить'))),
                  ]),
                  if (_promoResult != null) ...[
                    const SizedBox(height: 8),
                    Text(_promoResult!, style: AppTextStyles.body(size: 12, weight: FontWeight.w700, color: _discount > 0 ? const Color(0xFF15803D) : AppColors.danger)),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: const Color(0xFFFDECEC), borderRadius: BorderRadius.circular(12)),
                      child: Text(_error!, style: AppTextStyles.body(size: 12.5, weight: FontWeight.w600, color: const Color(0xFFD64545))),
                    ),
                  ],
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(AppRadius.lg)),
                    child: Column(children: [
                      _row('Товары (${cart.itemsCount} шт)', currency.format(cart.totalAmount)),
                      _row('Доставка', _loadingDelivery ? '…' : currency.format(deliveryCost)),
                      if (_discount > 0) _row('Скидка', '−${currency.format(_discount)}'),
                      const Divider(height: 20),
                      _row('Итого', currency.format(total.toDouble()), bold: true),
                    ]),
                  ),
                ]),
              ),
            ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: ElevatedButton(
          onPressed: (_submitting || _address == null) ? null : _submitOrder,
          child: _submitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
              : const Text('Подтвердить заказ'),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 4),
        child: Text(text, style: AppTextStyles.body(size: 11.5, weight: FontWeight.w800, color: AppColors.text3).copyWith(letterSpacing: 0.4)),
      );

  Widget _addressTile(Address a) {
    final selected = _address?.id == a.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () {
          setState(() => _address = a);
          _loadDelivery();
        },
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.5 : 1),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(children: [
            Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, size: 20, color: selected ? AppColors.primary : AppColors.text3),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a.title, style: AppTextStyles.body(size: 13, weight: FontWeight.w700)),
                Text('${a.country.label}, ${a.city}, ${a.street}', style: AppTextStyles.body(size: 11.5, weight: FontWeight.w600, color: AppColors.text3)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _paymentTile(order_model.PaymentMethod method, String label, IconData icon) {
    final selected = _payment == method;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => setState(() => _payment = method),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.5 : 1),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(children: [
            Icon(icon, size: 18, color: AppColors.text2),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: AppTextStyles.body(size: 13, weight: FontWeight.w700))),
            Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, size: 20, color: selected ? AppColors.primary : AppColors.text3),
          ]),
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: AppTextStyles.body(size: bold ? 14 : 12.5, weight: FontWeight.w600, color: bold ? AppColors.text : AppColors.text3)),
        Text(value, style: bold ? AppTextStyles.mono(size: 16) : AppTextStyles.body(size: 12.5, weight: FontWeight.w700)),
      ]),
    );
  }
}

class _AddAddressSheet extends StatefulWidget {
  const _AddAddressSheet();

  @override
  State<_AddAddressSheet> createState() => _AddAddressSheetState();
}

class _AddAddressSheetState extends State<_AddAddressSheet> {
  DeliveryCountry _country = DeliveryCountry.tajikistan;
  final _cityController = TextEditingController();
  final _lineController = TextEditingController();
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    if (_cityController.text.trim().isEmpty || _lineController.text.trim().isEmpty) {
      setState(() => _error = 'Заполните город и адрес');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final address = await ProfileRepository.createAddress(
        country: _country,
        city: _cityController.text.trim(),
        line: _lineController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, address);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Не удалось сохранить адрес';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Новый адрес', style: AppTextStyles.display(size: 18)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: ChoiceChip(
                label: const Text('Таджикистан'),
                selected: _country == DeliveryCountry.tajikistan,
                onSelected: (_) => setState(() => _country = DeliveryCountry.tajikistan),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ChoiceChip(
                label: const Text('Россия'),
                selected: _country == DeliveryCountry.russia,
                onSelected: (_) => setState(() => _country = DeliveryCountry.russia),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          TextField(controller: _cityController, decoration: const InputDecoration(hintText: 'Город'), enabled: !_saving),
          const SizedBox(height: 12),
          TextField(controller: _lineController, decoration: const InputDecoration(hintText: 'Улица, дом'), enabled: !_saving),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: AppTextStyles.body(size: 12, weight: FontWeight.w600, color: AppColors.danger)),
          ],
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                : const Text('Сохранить адрес'),
          ),
        ]),
      ),
    );
  }
}
