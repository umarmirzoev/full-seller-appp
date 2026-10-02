import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../models/supplier.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/admin/admin_card.dart';
import '../../widgets/admin/admin_sidebar.dart';
import '../../widgets/admin/admin_top_bar.dart';
import '../../widgets/status_pill.dart';

class AdminSuppliersScreen extends StatefulWidget {
  const AdminSuppliersScreen({super.key});

  @override
  State<AdminSuppliersScreen> createState() => _AdminSuppliersScreenState();
}

class _AdminSuppliersScreenState extends State<AdminSuppliersScreen> {
  String _mode = 'all';
  String _query = '';
  bool _argsApplied = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsApplied) return;
    _argsApplied = true;
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is String && const ['all', 'moderation', 'top', 'blocked'].contains(arg)) {
      _mode = arg;
    }
  }

  List<Supplier> get _filtered {
    var list = MockData.suppliers.where((s) => s.companyName.toLowerCase().contains(_query.toLowerCase())).toList();
    if (_mode == 'moderation') {
      list = list.where((s) => s.status == SupplierStatus.moderation).toList();
    } else if (_mode == 'blocked') {
      list = list.where((s) => s.status == SupplierStatus.blocked).toList();
    } else if (_mode == 'top') {
      list = list.where((s) => s.status == SupplierStatus.active).toList()..sort((a, b) => b.rating.compareTo(a.rating));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = _filtered;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Row(children: [
        const AdminSidebar(active: 'Поставщики'),
        Expanded(
          child: Column(children: [
            AdminTopBar(title: 'Поставщики', onSearch: (v) => setState(() => _query = v)),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 20, 32, 0),
              child: Wrap(spacing: 8, children: [
                _chip('Все поставщики', _mode == 'all', () => setState(() => _mode = 'all')),
                _chip('На модерации', _mode == 'moderation', () => setState(() => _mode = 'moderation')),
                _chip('Топ поставщики', _mode == 'top', () => setState(() => _mode = 'top')),
                _chip('Заблокированные', _mode == 'blocked', () => setState(() => _mode = 'blocked')),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: AdminCard(
                  child: Table(
                    columnWidths: const {0: FlexColumnWidth(1.8), 1: FlexColumnWidth(1.3), 2: FlexColumnWidth(1.2), 3: FlexColumnWidth(0.8), 4: FlexColumnWidth(0.8), 5: FlexColumnWidth(1)},
                    children: [
                      _headerRow(['Поставщик', 'Контакт', 'Категория', 'Товаров', 'Рейтинг', 'Статус']),
                      for (final s in suppliers)
                        TableRow(children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(children: [
                              CircleAvatar(radius: 15, backgroundColor: AppColors.g100,
                                  child: Text(s.initials, style: AppTextStyles.display(size: 11, color: AppColors.primaryDark))),
                              const SizedBox(width: 10),
                              Text(s.companyName, style: AppTextStyles.body(size: 13, weight: FontWeight.w700)),
                            ]),
                          ),
                          _cell('${s.contactName}\n${s.phone}'),
                          _cell(s.categoryName),
                          _cell('${s.productsCount}'),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.star_rounded, size: 14, color: AppColors.star),
                              const SizedBox(width: 3),
                              Text(s.rating.toStringAsFixed(1), style: AppTextStyles.body(size: 12.5, weight: FontWeight.w700)),
                            ]),
                          ),
                          Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: SupplierStatusPill(status: s.status)),
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

  TableRow _headerRow(List<String> labels) => TableRow(
        children: labels
            .map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(l, style: AppTextStyles.body(size: 10.5, weight: FontWeight.w800, color: AppColors.text3).copyWith(letterSpacing: 0.4)),
                ))
            .toList(),
      );

  Widget _cell(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(text, style: AppTextStyles.body(size: 12.5, weight: FontWeight.w600, color: AppColors.text2)),
      );
}
