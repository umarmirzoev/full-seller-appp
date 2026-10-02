import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/mock_data.dart';
import '../providers/currency_provider.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';
import '../widgets/placeholder_image.dart';
import '../widgets/status_pill.dart';

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<CurrencyProvider>();
    final products = MockData.products;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text('Мои товары', style: AppTextStyles.display(size: 17))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addListing),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Добавить'),
      ),
      body: SafeArea(
        top: false,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
          itemCount: products.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final p = products[i];
            final stock = p.variants.fold(0, (sum, v) => sum + v.stockQuantity);
            return InkWell(
              onTap: () => Navigator.pushNamed(context, AppRoutes.addListing, arguments: p.id),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.borderSoft), borderRadius: BorderRadius.circular(AppRadius.lg)),
                child: Row(children: [
                  PlaceholderImage(width: 60, height: 60, borderRadius: BorderRadius.circular(AppRadius.md)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.body(size: 13, weight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(currency.format(p.minPrice), style: AppTextStyles.mono(size: 13)),
                      const SizedBox(height: 6),
                      StockPill(quantity: stock),
                    ]),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.text3),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }
}
