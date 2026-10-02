import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/currency_provider.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';
import '../widgets/placeholder_image.dart';
import '../widgets/quantity_stepper.dart';

const _minBatchUnits = 50;

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CartProvider>().load();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final currency = context.watch<CurrencyProvider>();
    final underMinBatch = cart.itemsCount > 0 && cart.itemsCount < _minBatchUnits;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text('Корзина', style: AppTextStyles.display(size: 17))),
      body: cart.isLoading && cart.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : cart.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.shopping_cart_outlined, size: 48, color: AppColors.g200),
                    const SizedBox(height: 12),
                    Text('Корзина пуста', style: AppTextStyles.body(size: 14, weight: FontWeight.w700, color: AppColors.text3)),
                    if (cart.error != null) ...[
                      const SizedBox(height: 8),
                      Text(cart.error!, style: AppTextStyles.body(size: 12, weight: FontWeight.w600, color: AppColors.danger)),
                    ],
                  ]),
                )
              : SafeArea(
                  top: false,
                  child: RefreshIndicator(
                    onRefresh: () => context.read<CartProvider>().load(),
                    child: Column(children: [
                      if (underMinBatch)
                        Container(
                          margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(AppRadius.md)),
                          child: Row(children: [
                            const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF9A5B12)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text('Минимальная партия — $_minBatchUnits ед. Добавьте ещё ${_minBatchUnits - cart.itemsCount} шт., чтобы оформить заказ.',
                                  style: AppTextStyles.body(size: 12, weight: FontWeight.w600, color: const Color(0xFF9A5B12))),
                            ),
                          ]),
                        ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: cart.items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final item = cart.items[i];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.borderSoft), borderRadius: BorderRadius.circular(AppRadius.lg)),
                              child: Row(children: [
                                PlaceholderImage(width: 64, height: 64, borderRadius: BorderRadius.circular(AppRadius.md)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(item.productName, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.body(size: 12.5, weight: FontWeight.w700)),
                                    if (item.variantLabel != null && item.variantLabel!.isNotEmpty)
                                      Text(item.variantLabel!, style: AppTextStyles.body(size: 11, weight: FontWeight.w600, color: AppColors.text3)),
                                    const SizedBox(height: 6),
                                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                      Text(currency.format(item.unitPrice), style: AppTextStyles.mono(size: 13)),
                                      QuantityStepper(value: item.quantity, step: 10, onChanged: (v) => context.read<CartProvider>().updateQuantity(i, v)),
                                    ]),
                                  ]),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.text3),
                                  onPressed: () => context.read<CartProvider>().remove(i),
                                ),
                              ]),
                            );
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
                        decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.borderSoft))),
                        child: Column(children: [
                          _row('Товаров', '${cart.itemsCount} шт'),
                          _row('Общий вес', '${(cart.totalWeightGrams / 1000).toStringAsFixed(1)} кг'),
                          _row('Сумма', currency.format(cart.totalAmount), bold: true),
                          const SizedBox(height: 14),
                          ElevatedButton(
                            onPressed: underMinBatch ? null : () => Navigator.pushNamed(context, AppRoutes.checkout),
                            child: const Text('Оформить заказ'),
                          ),
                        ]),
                      ),
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
        Text(value, style: bold ? AppTextStyles.mono(size: 17) : AppTextStyles.body(size: 12.5, weight: FontWeight.w700)),
      ]),
    );
  }
}
