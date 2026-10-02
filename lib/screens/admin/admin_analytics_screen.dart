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

class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<CurrencyProvider>();

    // Реальная агрегация продаж по товарам на основе моковых заказов.
    final salesByProduct = <String, double>{};
    final qtyByProduct = <String, int>{};
    for (final o in MockData.orders) {
      for (final item in o.items) {
        salesByProduct[item.productName] = (salesByProduct[item.productName] ?? 0) + item.quantity * item.unitPrice;
        qtyByProduct[item.productName] = (qtyByProduct[item.productName] ?? 0) + item.quantity;
      }
    }
    final topProducts = salesByProduct.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxSale = topProducts.isEmpty ? 1.0 : topProducts.first.value;

    final salesByCategory = <String, double>{};
    for (final p in MockData.products) {
      final catName = MockData.categories.firstWhere((c) => c.id == p.categoryId, orElse: () => MockData.categories.first).name;
      salesByCategory[catName] = (salesByCategory[catName] ?? 0) + (salesByProduct[p.name] ?? 0);
    }
    final topCategories = salesByCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxCategory = topCategories.isEmpty ? 1.0 : topCategories.first.value;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Row(children: [
        const AdminSidebar(active: 'Аналитика'),
        Expanded(
          child: Column(children: [
            const AdminTopBar(title: 'Аналитика'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: AdminCard(title: 'Выручка по неделям', child: MiniLineChart(values: const [21, 26, 19, 30, 38, 34, 41, 46, 39, 44, 52, 48, 55, 60], color: AppColors.primary, height: 130))),
                    const SizedBox(width: 14),
                    Expanded(child: AdminCard(title: 'Средний рейтинг товаров', child: MiniLineChart(values: const [4.5, 4.6, 4.6, 4.7, 4.7, 4.8, 4.7, 4.8, 4.9, 4.8, 4.9, 4.9, 4.8, 4.9], color: const Color(0xFF15803D), height: 130))),
                  ]),
                  const SizedBox(height: 16),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: AdminCard(
                        title: 'Топ товаров по выручке',
                        child: Column(
                          children: topProducts.take(6).map((e) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(children: [
                                SizedBox(width: 170, child: Text(e.key, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.body(size: 12, weight: FontWeight.w700))),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: e.value / maxSale,
                                      minHeight: 8,
                                      backgroundColor: AppColors.surface2,
                                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(width: 78, child: Text(currency.format(e.value), textAlign: TextAlign.right, style: AppTextStyles.mono(size: 11.5))),
                              ]),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: AdminCard(
                        title: 'Продажи по категориям',
                        child: Column(
                          children: topCategories.map((e) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(children: [
                                SizedBox(width: 110, child: Text(e.key, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.body(size: 12, weight: FontWeight.w700))),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: e.value / maxCategory,
                                      minHeight: 8,
                                      backgroundColor: AppColors.surface2,
                                      valueColor: const AlwaysStoppedAnimation(Color(0xFF7C3AED)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(width: 78, child: Text(currency.format(e.value), textAlign: TextAlign.right, style: AppTextStyles.mono(size: 11.5))),
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
}
