import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/mock_data.dart';
import '../../providers/currency_provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/admin/admin_card.dart';
import '../../widgets/admin/admin_sidebar.dart';
import '../../widgets/admin/admin_top_bar.dart';
import '../../widgets/placeholder_image.dart';
import '../../widgets/status_pill.dart';

class AdminCatalogScreen extends StatefulWidget {
  const AdminCatalogScreen({super.key});

  @override
  State<AdminCatalogScreen> createState() => _AdminCatalogScreenState();
}

class _AdminCatalogScreenState extends State<AdminCatalogScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<CurrencyProvider>();
    final products = MockData.products.where((p) => p.name.toLowerCase().contains(_query.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Row(children: [
        const AdminSidebar(active: 'Каталог'),
        Expanded(
          child: Column(children: [
            AdminTopBar(
              title: 'Каталог товаров',
              action: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.adminAddProduct),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Добавить товар'),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(36),
                child: AdminCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(
                      width: 320,
                      height: 44,
                      child: TextField(
                        onChanged: (v) => setState(() => _query = v),
                        decoration: const InputDecoration(hintText: 'Поиск по названию', prefixIcon: Icon(Icons.search_rounded, size: 18)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Table(
                      columnWidths: const {0: FlexColumnWidth(2.6), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1), 3: FlexColumnWidth(1.3), 4: FlexColumnWidth(1)},
                      children: [
                        TableRow(children: [
                          _th('Товар'), _th('Категория'), _th('Цена'), _th('Остаток'), _th(''),
                        ]),
                        for (final p in products)
                          TableRow(children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(children: [
                                PlaceholderImage(width: 40, height: 40, borderRadius: BorderRadius.circular(8)),
                                const SizedBox(width: 10),
                                Expanded(child: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.body(size: 13, weight: FontWeight.w700))),
                              ]),
                            ),
                            _td(MockData.categories.firstWhere((c) => c.id == p.categoryId, orElse: () => MockData.categories.first).name),
                            _td(currency.format(p.minPrice)),
                            Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: StockPill(quantity: p.variants.fold(0, (s, v) => s + v.stockQuantity))),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 17),
                                  onPressed: () => Navigator.pushNamed(context, AppRoutes.adminAddProduct, arguments: p.id),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 17, color: AppColors.danger),
                                  onPressed: () {},
                                ),
                              ]),
                            ),
                          ]),
                      ],
                    ),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _th(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(label, style: AppTextStyles.body(size: 10.5, weight: FontWeight.w800, color: AppColors.text3).copyWith(letterSpacing: 0.4)),
      );

  Widget _td(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(text, style: AppTextStyles.body(size: 13, weight: FontWeight.w600)),
      );
}
