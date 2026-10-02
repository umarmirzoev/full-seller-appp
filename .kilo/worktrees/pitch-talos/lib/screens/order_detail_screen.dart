import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/mock_data.dart';
import '../models/order.dart';
import '../providers/cart_provider.dart';
import '../providers/currency_provider.dart';
import '../models/cart_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';
import '../widgets/placeholder_image.dart';
import '../widgets/status_pill.dart';

const _timelineStatuses = [
  OrderStatus.novyy,
  OrderStatus.podtverzhden,
  OrderStatus.vObrabotke,
  OrderStatus.otpravlen,
  OrderStatus.zavershen,
];

class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final order = MockData.orderById(orderId);
    final currency = context.watch<CurrencyProvider>();
    final currentIndex = order.status == OrderStatus.otmenen ? -1 : _timelineStatuses.indexOf(order.status);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(order.orderNumber, style: AppTextStyles.display(size: 17))),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              OrderStatusPill(status: order.status),
              if (order.cargoTrackingNumber != null)
                Text('Трек: ${order.cargoTrackingNumber}', style: AppTextStyles.body(size: 12, weight: FontWeight.w700, color: AppColors.text3)),
            ]),
            const SizedBox(height: 20),
            if (order.status != OrderStatus.otmenen)
              Column(
                children: List.generate(_timelineStatuses.length, (i) {
                  final done = i <= currentIndex;
                  final isLast = i == _timelineStatuses.length - 1;
                  return IntrinsicHeight(
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Column(children: [
                        Container(
                          width: 22, height: 22,
                          decoration: BoxDecoration(
                            color: done ? AppColors.primary : AppColors.surface,
                            border: Border.all(color: done ? AppColors.primary : AppColors.border, width: 2),
                            shape: BoxShape.circle,
                          ),
                          child: done ? const Icon(Icons.check_rounded, size: 13, color: Colors.white) : null,
                        ),
                        if (!isLast) Expanded(child: Container(width: 2, color: i < currentIndex ? AppColors.primary : AppColors.border)),
                      ]),
                      const SizedBox(width: 14),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 22),
                        child: Text(_timelineStatuses[i].label,
                            style: AppTextStyles.body(size: 13.5, weight: FontWeight.w700, color: done ? AppColors.text : AppColors.text3)),
                      ),
                    ]),
                  );
                }),
              ),
            const SizedBox(height: 8),
            Text('Товары', style: AppTextStyles.display(size: 15)),
            const SizedBox(height: 12),
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    PlaceholderImage(width: 52, height: 52, borderRadius: BorderRadius.circular(AppRadius.sm)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(item.productName, style: AppTextStyles.body(size: 12.5, weight: FontWeight.w700)),
                        Text('${item.quantity} шт × ${currency.format(item.unitPrice)}', style: AppTextStyles.body(size: 11.5, weight: FontWeight.w600, color: AppColors.text3)),
                      ]),
                    ),
                    Text(currency.format(item.unitPrice * item.quantity), style: AppTextStyles.mono(size: 13)),
                  ]),
                )),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(AppRadius.lg)),
              child: Column(children: [
                _row('Доставка', currency.format(order.deliveryCost)),
                const Divider(height: 20),
                _row('Итого', currency.format(order.totalAmount), bold: true),
              ]),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              icon: const Icon(Icons.replay_rounded, size: 18),
              label: const Text('Повторить заказ'),
              onPressed: () {
                final cart = context.read<CartProvider>();
                for (final item in order.items) {
                  cart.add(CartItem(productId: item.productId, productName: item.productName, imageUrl: item.imageUrl, unitPrice: item.unitPrice, quantity: item.quantity));
                }
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Товары добавлены в корзину')));
              },
            ),
          ]),
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: AppTextStyles.body(size: bold ? 14 : 12.5, weight: FontWeight.w600, color: bold ? AppColors.text : AppColors.text3)),
      Text(value, style: bold ? AppTextStyles.mono(size: 16) : AppTextStyles.body(size: 12.5, weight: FontWeight.w700)),
    ]);
  }
}
