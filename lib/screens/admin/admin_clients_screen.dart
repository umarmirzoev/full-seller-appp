import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/mock_data.dart';
import '../../providers/currency_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/admin/admin_card.dart';
import '../../widgets/admin/admin_sidebar.dart';
import '../../widgets/admin/admin_top_bar.dart';

class AdminClientsScreen extends StatefulWidget {
  const AdminClientsScreen({super.key});

  @override
  State<AdminClientsScreen> createState() => _AdminClientsScreenState();
}

class _AdminClientsScreenState extends State<AdminClientsScreen> {
  String _query = '';
  bool _onlyLegal = false;

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<CurrencyProvider>();
    final clients = MockData.adminClients
        .where((c) => c.name.toLowerCase().contains(_query.toLowerCase()))
        .where((c) => !_onlyLegal || c.isLegalEntity)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Row(children: [
        const AdminSidebar(active: 'Клиенты'),
        Expanded(
          child: Column(children: [
            AdminTopBar(title: 'Клиенты', onSearch: (v) => setState(() => _query = v)),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 20, 32, 0),
              child: Row(children: [
                FilterChip(
                  label: const Text('Только юр. лица'),
                  selected: _onlyLegal,
                  onSelected: (v) => setState(() => _onlyLegal = v),
                  selectedColor: AppColors.g50,
                  labelStyle: AppTextStyles.body(size: 12, weight: FontWeight.w700, color: _onlyLegal ? AppColors.primaryDark : AppColors.text2),
                ),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: AdminCard(
                  child: Table(
                    columnWidths: const {0: FlexColumnWidth(1.6), 1: FlexColumnWidth(1.2), 2: FlexColumnWidth(0.9), 3: FlexColumnWidth(1), 4: FlexColumnWidth(1)},
                    children: [
                      _headerRow(['Клиент', 'Телефон', 'Заказов', 'Сумма покупок', 'С нами']),
                      for (final c in clients)
                        TableRow(children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(children: [
                              CircleAvatar(radius: 15, backgroundColor: AppColors.g100,
                                  child: Text(c.name.isNotEmpty ? c.name[0] : '?', style: AppTextStyles.display(size: 11, color: AppColors.primaryDark))),
                              const SizedBox(width: 10),
                              Expanded(child: Text(c.name, style: AppTextStyles.body(size: 13, weight: FontWeight.w700))),
                              if (c.isLegalEntity)
                                Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(color: AppColors.g50, borderRadius: BorderRadius.circular(999)),
                                  child: Text('юр.лицо', style: AppTextStyles.body(size: 9.5, weight: FontWeight.w800, color: AppColors.primaryDark)),
                                ),
                            ]),
                          ),
                          _cell(c.phone),
                          _cell('${c.ordersCount}'),
                          _cell(currency.format(c.totalSpent), bold: true),
                          _cell('${c.joinedAt.day}.${c.joinedAt.month}.${c.joinedAt.year}'),
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
        child: Text(text, style: AppTextStyles.body(size: 12.5, weight: bold ? FontWeight.w800 : FontWeight.w600, color: bold ? AppColors.text : AppColors.text2)),
      );
}
