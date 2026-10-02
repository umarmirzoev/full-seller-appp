import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/mock_data.dart';
import '../models/order.dart';
import '../providers/currency_provider.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/status_pill.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  OrderStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<CurrencyProvider>();
    final orders = _filter == null ? MockData.orders : MockData.orders.where((o) => o.status == _filter).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(children: [
          const AppTopBar(showCart: false),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text('Мои заказы', style: AppTextStyles.display(size: 19)),
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: OrderStatus.values.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                if (i == 0) return _chip('Все', _filter == null, () => setState(() => _filter = null));
                final status = OrderStatus.values[i - 1];
                return _chip(status.label, _filter == status, () => setState(() => _filter = status));
              },
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: orders.isEmpty
                ? Center(child: Text('Заказов не найдено', style: AppTextStyles.body(color: AppColors.text3)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final o = orders[i];
                      return InkWell(
                        onTap: () => Navigator.pushNamed(context, AppRoutes.orderDetail, arguments: o.id),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.borderSoft), borderRadius: BorderRadius.circular(AppRadius.lg)),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Text(o.orderNumber, style: AppTextStyles.display(size: 14)),
                              OrderStatusPill(status: o.status),
                            ]),
                            const SizedBox(height: 8),
                            Text('${o.itemsCount} товар(ов) · ${_formatDate(o.createdAt)}', style: AppTextStyles.body(size: 12, weight: FontWeight.w600, color: AppColors.text3)),
                            const SizedBox(height: 10),
                            const Divider(height: 1),
                            const SizedBox(height: 10),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Text('Сумма заказа', style: AppTextStyles.body(size: 12.5, weight: FontWeight.w600, color: AppColors.text3)),
                              Text(currency.format(o.totalAmount), style: AppTextStyles.mono(size: 15)),
                            ]),
                          ]),
                        ),
                      );
                    },
                  ),
          ),
        ]),
      ),
      bottomNavigationBar: const AppBottomNav(current: AppTab.orders),
    );
  }

  String _formatDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  Widget _chip(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surface,
          border: Border.all(color: active ? AppColors.primary : AppColors.border),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: active ? Colors.white : AppColors.text2)),
      ),
    );
  }
}
