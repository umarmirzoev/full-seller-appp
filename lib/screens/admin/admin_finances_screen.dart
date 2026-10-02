import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/mock_data.dart';
import '../../providers/currency_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/admin/admin_card.dart';
import '../../widgets/admin/admin_sidebar.dart';
import '../../widgets/admin/admin_top_bar.dart';
import '../../widgets/admin/mini_line_chart.dart';
import '../../widgets/admin/stat_card.dart';

class AdminFinancesScreen extends StatefulWidget {
  const AdminFinancesScreen({super.key});

  @override
  State<AdminFinancesScreen> createState() => _AdminFinancesScreenState();
}

class _AdminFinancesScreenState extends State<AdminFinancesScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<CurrencyProvider>();
    final all = MockData.adminTransactions;
    final income = all.where((t) => t.amount > 0).fold(0.0, (sum, t) => sum + t.amount);
    final outcome = all.where((t) => t.amount < 0).fold(0.0, (sum, t) => sum + t.amount);
    final balance = income + outcome;
    final tx = all.where((t) {
      if (_filter == 'in') return t.amount > 0;
      if (_filter == 'out') return t.amount < 0;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Row(children: [
        const AdminSidebar(active: 'Финансы'),
        Expanded(
          child: Column(children: [
            const AdminTopBar(title: 'Финансы'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: StatCard(label: 'Поступления', value: currency.format(income), icon: Icons.south_west_rounded)),
                    const SizedBox(width: 14),
                    Expanded(child: StatCard(label: 'Списания', value: currency.format(outcome.abs()), deltaUp: false, icon: Icons.north_east_rounded)),
                    const SizedBox(width: 14),
                    Expanded(child: StatCard(label: 'Чистый баланс', value: currency.format(balance), icon: Icons.account_balance_wallet_outlined)),
                  ]),
                  const SizedBox(height: 16),
                  AdminCard(title: 'Движение средств', child: MiniLineChart(values: const [12, 18, 9, 22, 30, 21, 26, 33, 24, 29, 35, 31, 40, 38], color: AppColors.primary, height: 120)),
                  const SizedBox(height: 16),
                  Wrap(spacing: 8, children: [
                    _chip('Все операции', _filter == 'all', () => setState(() => _filter = 'all')),
                    _chip('Поступления', _filter == 'in', () => setState(() => _filter = 'in')),
                    _chip('Списания', _filter == 'out', () => setState(() => _filter = 'out')),
                  ]),
                  const SizedBox(height: 14),
                  AdminCard(
                    child: Table(
                      columnWidths: const {0: FlexColumnWidth(1.2), 1: FlexColumnWidth(1.2), 2: FlexColumnWidth(1), 3: FlexColumnWidth(1), 4: FlexColumnWidth(1)},
                      children: [
                        _headerRow(['Тип', 'Заказ', 'Сумма', 'Дата', 'Статус']),
                        for (final t in tx)
                          TableRow(children: [
                            _cell(t.type, bold: true),
                            _cell(t.orderNumber),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text('${t.amount > 0 ? '+' : ''}${currency.format(t.amount)}',
                                  style: AppTextStyles.mono(size: 13, weight: FontWeight.w700, color: t.amount > 0 ? const Color(0xFF15803D) : AppColors.danger)),
                            ),
                            _cell('${t.date.day}.${t.date.month}.${t.date.year}'),
                            _cell(t.status),
                          ]),
                      ],
                    ),
                  ),
                ]),
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

  TableRow _headerRow(List<String> labels) => TableRow(
        children: labels
            .map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(l, style: AppTextStyles.body(size: 10.5, weight: FontWeight.w800, color: AppColors.text3).copyWith(letterSpacing: 0.4)),
                ))
            .toList(),
      );

  Widget _cell(String text, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(text, style: AppTextStyles.body(size: 12.5, weight: bold ? FontWeight.w700 : FontWeight.w600)),
      );
}
