import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/mock_data.dart';
import '../../models/order.dart';
import '../../providers/currency_provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/admin/admin_card.dart';
import '../../widgets/admin/admin_sidebar.dart';
import '../../widgets/admin/admin_top_bar.dart';
import '../../widgets/admin/mini_line_chart.dart';
import '../../widgets/admin/stat_card.dart';
import '../../widgets/status_pill.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _refreshTick = 0;

  List<double> _series(double base, double amplitude, double trend) {
    return List.generate(14, (i) {
      final wobble = amplitude * math.sin((i + _refreshTick) * 0.55) + amplitude * 0.35 * math.cos(i * 0.9);
      return math.max(0.0, base + wobble + trend * i);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<CurrencyProvider>();
    final orders = MockData.orders;
    final suppliers = MockData.suppliers;
    final chats = MockData.adminChatThreads;

    final completed = orders.where((o) => o.status == OrderStatus.zavershen).length;
    final cancelled = orders.where((o) => o.status == OrderStatus.otmenen).length;
    final inProgress = orders.length - completed - cancelled;
    final revenue = orders.fold(0.0, (sum, o) => sum + o.totalAmount);
    final deliveryTotal = orders.fold(0.0, (sum, o) => sum + o.deliveryCost);
    final avgCheck = orders.isEmpty ? 0.0 : revenue / orders.length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Row(children: [
        const AdminSidebar(active: 'Дашборд'),
        Expanded(
          child: Column(children: [
            AdminTopBar(title: 'Дашборд', onRefresh: () => setState(() => _refreshTick++)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: StatCard(label: 'Заказы', value: '${orders.length}', icon: Icons.inventory_2_outlined)),
                    const SizedBox(width: 14),
                    Expanded(child: StatCard(label: 'Выполнено', value: '$completed', delta: orders.isEmpty ? null : '${(completed / orders.length * 100).round()}%', icon: Icons.check_circle_outline_rounded)),
                    const SizedBox(width: 14),
                    Expanded(child: StatCard(label: 'В работе', value: '$inProgress', icon: Icons.access_time_rounded)),
                    const SizedBox(width: 14),
                    Expanded(child: StatCard(label: 'Отменено', value: '$cancelled', deltaUp: false, delta: orders.isEmpty ? null : '${(cancelled / orders.length * 100).round()}%', icon: Icons.cancel_outlined)),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: AdminCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text('Доход платформы', style: AppTextStyles.body(size: 12.5, weight: FontWeight.w700, color: AppColors.text3)),
                            Text('за всё время', style: AppTextStyles.body(size: 10.5, weight: FontWeight.w600, color: AppColors.text3)),
                          ]),
                          const SizedBox(height: 12),
                          _incomeRow('Выручка', currency.format(revenue)),
                          const SizedBox(height: 8),
                          _incomeRow('Доставка', currency.format(deliveryTotal)),
                          const SizedBox(height: 8),
                          _incomeRow('Средний чек', currency.format(avgCheck), bold: true),
                        ]),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: AdminCard(title: 'Заказы по дням', child: MiniLineChart(values: _series(4, 3, 0.15), color: AppColors.primary))),
                    const SizedBox(width: 14),
                    Expanded(child: AdminCard(title: 'Выручка', child: MiniLineChart(values: _series(38000, 14000, 900), color: const Color(0xFF7C3AED)))),
                    const SizedBox(width: 14),
                    Expanded(child: AdminCard(title: 'Новые поставщики', child: MiniLineChart(values: _series(1.5, 1.2, 0.05), color: const Color(0xFF0369A1)))),
                    const SizedBox(width: 14),
                    Expanded(child: AdminCard(title: 'Средний чек', child: MiniLineChart(values: _series(avgCheck == 0 ? 20000 : avgCheck, 6000, -150), color: const Color(0xFF15803D)))),
                  ]),
                  const SizedBox(height: 16),
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
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: AdminCard(
                        title: 'Поставщики',
                        padding: const EdgeInsets.fromLTRB(0, 14, 0, 6),
                        child: Column(
                          children: suppliers.take(4).map((s) {
                            return InkWell(
                              onTap: () => Navigator.pushNamed(context, AppRoutes.adminSuppliers),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                child: Row(children: [
                                  CircleAvatar(radius: 16, backgroundColor: AppColors.g100,
                                      child: Text(s.initials, style: AppTextStyles.display(size: 11, color: AppColors.primaryDark))),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                                      Text(s.companyName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.body(size: 12.5, weight: FontWeight.w700)),
                                      Text(s.categoryName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.body(size: 10.5, weight: FontWeight.w600, color: AppColors.text3)),
                                    ]),
                                  ),
                                  SupplierStatusPill(status: s.status),
                                ]),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: AdminCard(
                        title: 'Чаты',
                        padding: const EdgeInsets.fromLTRB(0, 14, 0, 6),
                        child: Column(
                          children: chats.take(4).map((c) {
                            return InkWell(
                              onTap: () => Navigator.pushNamed(context, AppRoutes.adminChats),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                child: Row(children: [
                                  CircleAvatar(radius: 16, backgroundColor: AppColors.g100,
                                      child: Text(c.clientName.isNotEmpty ? c.clientName[0] : '?', style: AppTextStyles.display(size: 11, color: AppColors.primaryDark))),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                                      Text(c.clientName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.body(size: 12.5, weight: FontWeight.w700)),
                                      Text(c.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.body(size: 10.5, weight: FontWeight.w600, color: AppColors.text3)),
                                    ]),
                                  ),
                                  if (c.unread > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: const BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.all(Radius.circular(999))),
                                      child: Text('${c.unread}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                                    ),
                                ]),
                              ),
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

  Widget _incomeRow(String label, String value, {bool bold = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: AppTextStyles.body(size: 12, weight: FontWeight.w600, color: AppColors.text2)),
      Text(value, style: AppTextStyles.mono(size: bold ? 15 : 13, weight: bold ? FontWeight.w800 : FontWeight.w600)),
    ]);
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
