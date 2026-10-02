import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/mock_data.dart';
import '../models/address.dart';
import '../models/promo_code.dart';
import '../providers/cart_provider.dart';
import '../providers/currency_provider.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';

enum PaymentMethod { cash, card, transfer }

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  Address? _address = MockData.addresses.first;
  PaymentMethod _payment = PaymentMethod.transfer;
  final _promoController = TextEditingController();
  String? _promoResult;
  double _discount = 0;
  bool _submitting = false;

  double get _deliveryCost => _address?.country == DeliveryCountry.russia ? 3200 : 1800;

  void _applyPromo() {
    final code = MockData.promoCodes.where((p) => p.code.toUpperCase() == _promoController.text.trim().toUpperCase());
    if (code.isEmpty) {
      setState(() {
        _promoResult = 'Промокод не найден';
        _discount = 0;
      });
      return;
    }
    final promo = code.first;
    final cart = context.read<CartProvider>();
    setState(() {
      _discount = promo.discountType == DiscountType.percent ? cart.totalAmount * promo.discountValue / 100 : promo.discountValue;
      _promoResult = 'Промокод применён: −${_discount.round()} ₽';
    });
  }

  void _submitOrder() async {
    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    context.read<CartProvider>().clear();
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.orders, (route) => route.settings.name == AppRoutes.home || route.isFirst);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Заказ оформлен!')));
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final currency = context.watch<CurrencyProvider>();
    final total = (cart.totalAmount + _deliveryCost - _discount).clamp(0, double.infinity);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text('Оформление заказа', style: AppTextStyles.display(size: 17))),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionLabel('АДРЕС ДОСТАВКИ'),
            ...MockData.addresses.map((a) => _addressTile(a)),
            const SizedBox(height: 20),
            _sectionLabel('СПОСОБ ОПЛАТЫ'),
            _paymentTile(PaymentMethod.transfer, 'Безналичный расчёт', Icons.account_balance_outlined),
            _paymentTile(PaymentMethod.card, 'Банковская карта', Icons.credit_card_rounded),
            _paymentTile(PaymentMethod.cash, 'Наличными при получении', Icons.payments_outlined),
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
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(AppRadius.lg)),
              child: Column(children: [
                _row('Товары (${cart.itemsCount} шт)', currency.format(cart.totalAmount)),
                _row('Доставка', currency.format(_deliveryCost)),
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
          onPressed: _submitting ? null : _submitOrder,
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
        onTap: () => setState(() => _address = a),
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

  Widget _paymentTile(PaymentMethod method, String label, IconData icon) {
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
