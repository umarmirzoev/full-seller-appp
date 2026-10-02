import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/mock_data.dart';
import '../providers/currency_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';
import '../widgets/admin/stat_card.dart';
import '../widgets/status_pill.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<CurrencyProvider>();
    final orders = MockData.orders;
    final revenue = orders.fold(0.0, (sum, o) => sum + o.totalAmount);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text('Дашборд', style: AppTextStyles.display(size: 17))),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                StatCard(label: 'Выручка', value: currency.format(revenue), delta: '+12.4%', icon: Icons.payments_outlined),
                StatCard(label: 'Заказы', value: '${orders.length}', delta: '+3', icon: Icons.inventory_2_outlined),
                StatCard(label: 'Товаров', value: '${MockData.products.length}', icon: Icons.archive_outlined),
                const StatCard(label: 'Рейтинг', value: '4.8', delta: '+0.1', icon: Icons.star_rounded),
              ],
            ),
            const SizedBox(height: 22),
            Text('Заказы по статусам', style: AppTextStyles.display(size: 15)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.borderSoft), borderRadius: BorderRadius.circular(AppRadius.lg)),
              child: Column(
                children: {for (final o in orders) o.status: 0}.keys.map((status) {
                  final count = orders.where((o) => o.status == status).length;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      SizedBox(width: 120, child: OrderStatusPill(status: status)),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: LinearProgressIndicator(
                            value: orders.isEmpty ? 0 : count / orders.length,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                            backgroundColor: AppColors.surface2,
                            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                          ),
                        ),
                      ),
                      Text('$count', style: AppTextStyles.mono(size: 12.5)),
                    ]),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 22),
            Text('Последние заказы', style: AppTextStyles.display(size: 15)),
            const SizedBox(height: 12),
            ...orders.take(4).map((o) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.borderSoft), borderRadius: BorderRadius.circular(AppRadius.md)),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(o.orderNumber, style: AppTextStyles.body(size: 13, weight: FontWeight.w800)),
                        Text(currency.format(o.totalAmount), style: AppTextStyles.body(size: 11.5, weight: FontWeight.w600, color: AppColors.text3)),
                      ]),
                    ),
                    OrderStatusPill(status: o.status),
                  ]),
                )),
          ],
        ),
      ),
    );
  }
}
