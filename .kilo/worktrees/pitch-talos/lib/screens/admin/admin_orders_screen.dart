import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/mock_data.dart';
import '../../models/order.dart';
import '../../providers/currency_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/admin/admin_card.dart';
import '../../widgets/admin/admin_sidebar.dart';
import '../../widgets/admin/admin_top_bar.dart';
import '../../widgets/status_pill.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  OrderStatus? _filter;
  final Map<String, OrderStatus> _overrides = {};

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<CurrencyProvider>();
    final orders = MockData.orders.where((o) => _filter == null || (_overrides[o.id] ?? o.status) == _filter).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Row(children: [
        const AdminSidebar(active: 'Заказы'),
        Expanded(
          child: Column(children: [
            const AdminTopBar(title: 'Заказы'),
            Padding(
              padding: const EdgeInsets.fromLTRB(36, 20, 36, 0),
              child: Wrap(spacing: 8, children: [
                _chip('Все', _filter == null, () => setState(() => _filter = null)),
                ...OrderStatus.values.map((s) => _chip(s.label, _filter == s, () => setState(() => _filter = s))),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(36),
                child: AdminCard(
                  child: Table(
                    columnWidths: const {0: FlexColumnWidth(1.2), 1: FlexColumnWidth(1.6), 2: FlexColumnWidth(1), 3: FlexColumnWidth(1), 4: FlexColumnWidth(1.4)},
                    children: [
                      TableRow(children: [_th('Заказ'), _th('Покупатель'), _th('Дата'), _th('Сумма'), _th('Статус')]),
                      for (final o in orders)
                        TableRow(children: [
                          _td(o.orderNumber, bold: true),
                          _td(MockData.currentUser.fullName),
                          _td('${o.createdAt.day}.${o.createdAt.month}.${o.createdAt.year}'),
                          _td(currency.format(o.totalAmount)),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: DropdownButton<OrderStatus>(
                              value: _overrides[o.id] ?? o.status,
                              underline: const SizedBox.shrink(),
                              items: OrderStatus.values.map((s) => DropdownMenuItem(value: s, child: OrderStatusPill(status: s))).toList(),
                              onChanged: (v) => setState(() => _overrides[o.id] = v!),
                            ),
                          ),
                        ]),
                    ],
                  ),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surface,
          border: Border.all(color: active ? AppColors.primary : AppColors.border),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: active ? Colors.white : AppColors.text2)),
      ),
    );
  }

  Widget _th(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(label, style: AppTextStyles.body(size: 10.5, weight: FontWeight.w800, color: AppColors.text3).copyWith(letterSpacing: 0.4)),
      );

  Widget _td(String text, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(text, style: AppTextStyles.body(size: 13, weight: bold ? FontWeight.w700 : FontWeight.w600)),
      );
}
