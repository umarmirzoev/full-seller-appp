import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/mock_data.dart';
import '../../providers/currency_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/admin/admin_card.dart';
import '../../widgets/admin/admin_sidebar.dart';
import '../../widgets/admin/admin_top_bar.dart';
import '../../widgets/admin/stat_card.dart';
import '../../widgets/status_pill.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<CurrencyProvider>();
    final orders = MockData.orders;
    final revenue = orders.fold(0.0, (sum, o) => sum + o.totalAmount);
    final statuses = {for (final o in orders) o.status: 0}.keys.toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Row(children: [
        const AdminSidebar(active: 'Дашборд'),
        Expanded(
          child: Column(children: [
            const AdminTopBar(title: 'Дашборд'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(36),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: StatCard(label: 'Выручка', value: currency.format(revenue), delta: '+12.4%', icon: Icons.payments_outlined)),
                    const SizedBox(width: 16),
                    Expanded(child: StatCard(label: 'Заказы', value: '${orders.length}', delta: '+3', icon: Icons.inventory_2_outlined)),
                    const SizedBox(width: 16),
                    Expanded(child: StatCard(label: 'Товаров в каталоге', value: '${MockData.products.length}', icon: Icons.archive_outlined)),
                    const SizedBox(width: 16),
                    Expanded(child: StatCard(label: 'Пользователей', value: '1 284', delta: '+48', icon: Icons.people_outline_rounded)),
                  ]),
                  const SizedBox(height: 24),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      flex: 3,
                      child: AdminCard(
                        title: 'Последние заказы',
                        child: Table(
                          columnWidths: const {0: FlexColumnWidth(1.3), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1), 3: FlexColumnWidth(1)},
                          children: [
                            _headerRow(['Заказ', 'Дата', 'Сумма', 'Статус']),
                            for (final o in orders)
                              TableRow(children: [
                                _cell(o.orderNumber, bold: true),
                                _cell('${o.createdAt.day}.${o.createdAt.month}.${o.createdAt.year}'),
                                _cell(currency.format(o.totalAmount)),
                                Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: OrderStatusPill(status: o.status)),
                              ]),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: AdminCard(
                        title: 'Заказы по статусам',
                        child: Column(
                          children: statuses.map((s) {
                            final count = orders.where((o) => o.status == s).length;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(children: [
                                SizedBox(width: 110, child: OrderStatusPill(status: s)),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: orders.isEmpty ? 0 : count / orders.length,
                                      minHeight: 8,
                                      backgroundColor: AppColors.surface2,
                                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text('$count', style: AppTextStyles.mono(size: 12.5)),
                              ]),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ]),
                ]),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  TableRow _headerRow(List<String> labels) => TableRow(
        children: labels
            .map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(l, style: AppTextStyles.body(size: 10.5, weight: FontWeight.w800, color: AppColors.text3).copyWith(letterSpacing: 0.4)),
                ))
            .toList(),
      );

  Widget _cell(String text, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text, style: AppTextStyles.body(size: 13, weight: bold ? FontWeight.w700 : FontWeight.w600)),
      );
}
