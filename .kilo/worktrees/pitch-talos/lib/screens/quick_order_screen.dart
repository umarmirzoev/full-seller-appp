import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/mock_data.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/currency_provider.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';

class _QuickRow {
  Product? product;
  int quantity = 50;
}

class QuickOrderScreen extends StatefulWidget {
  const QuickOrderScreen({super.key});

  @override
  State<QuickOrderScreen> createState() => _QuickOrderScreenState();
}

class _QuickOrderScreenState extends State<QuickOrderScreen> {
  final List<_QuickRow> _rows = [_QuickRow()];

  void _addToCart() {
    final cart = context.read<CartProvider>();
    var added = 0;
    for (final row in _rows) {
      if (row.product == null) continue;
      cart.add(CartItem(
        productId: row.product!.id,
        productName: row.product!.name,
        imageUrl: row.product!.imageUrls.isNotEmpty ? row.product!.imageUrls.first : '',
        unitPrice: row.product!.minPrice,
        weightGrams: row.product!.weightGrams,
        quantity: row.quantity,
      ));
      added++;
    }
    if (added == 0) return;
    Navigator.pushNamed(context, AppRoutes.cart);
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<CurrencyProvider>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text('Быстрый заказ', style: AppTextStyles.display(size: 17))),
      body: SafeArea(
        top: false,
        child: Column(children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _rows.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final row = _rows[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.borderSoft), borderRadius: BorderRadius.circular(AppRadius.lg)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    DropdownButtonFormField<Product>(
                      value: row.product,
                      isExpanded: true,
                      items: MockData.products.map((p) => DropdownMenuItem(value: p, child: Text(p.name, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (v) => setState(() => row.product = v),
                      decoration: const InputDecoration(labelText: 'Товар / артикул'),
                    ),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: row.quantity.toString(),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Количество'),
                          onChanged: (v) => row.quantity = int.tryParse(v) ?? row.quantity,
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (row.product != null)
                        Text(currency.format(row.product!.minPrice * row.quantity), style: AppTextStyles.mono(size: 14)),
                      IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: () => setState(() => _rows.removeAt(i))),
                    ]),
                  ]),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _rows.add(_QuickRow())),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Добавить позицию'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: ElevatedButton(onPressed: _addToCart, child: const Text('Добавить в корзину')),
          ),
        ]),
      ),
    );
  }
}
