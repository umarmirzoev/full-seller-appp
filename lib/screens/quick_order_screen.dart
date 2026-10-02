import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/currency_provider.dart';
import '../routes/app_routes.dart';
import '../services/catalog_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';

class _QuickRow {
  Product? product;
  String? variantId;
  int quantity = 50;
  bool resolving = false;
}

class QuickOrderScreen extends StatefulWidget {
  const QuickOrderScreen({super.key});

  @override
  State<QuickOrderScreen> createState() => _QuickOrderScreenState();
}

class _QuickOrderScreenState extends State<QuickOrderScreen> {
  final List<_QuickRow> _rows = [_QuickRow()];
  List<Product> _catalog = [];
  bool _loadingCatalog = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    try {
      final page = await CatalogRepository.getProducts(pageSize: 100);
      if (!mounted) return;
      setState(() {
        _catalog = page.items;
        _loadingCatalog = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingCatalog = false);
    }
  }

  Future<void> _selectProduct(_QuickRow row, Product? product) async {
    setState(() {
      row.product = product;
      row.variantId = null;
      row.resolving = product != null;
    });
    if (product == null) return;
    try {
      final details = await CatalogRepository.getProduct(product.id);
      if (!mounted) return;
      setState(() {
        row.variantId = details.variants.isNotEmpty ? details.variants.first.id : null;
        row.resolving = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => row.resolving = false);
    }
  }

  Future<void> _addToCart() async {
    setState(() => _submitting = true);
    final cart = context.read<CartProvider>();
    var added = 0;
    var skipped = 0;
    for (final row in _rows) {
      if (row.product == null) continue;
      if (row.variantId == null) {
        skipped++;
        continue;
      }
      try {
        await cart.addVariant(row.variantId!, quantity: row.quantity);
        added++;
      } catch (_) {
        skipped++;
      }
    }
    if (!mounted) return;
    setState(() => _submitting = false);
    if (skipped > 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$skipped позиций не удалось добавить (нет вариантов или ошибка сети)')));
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
        child: _loadingCatalog
            ? const Center(child: CircularProgressIndicator())
            : Column(children: [
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
                            items: _catalog.map((p) => DropdownMenuItem(value: p, child: Text(p.name, overflow: TextOverflow.ellipsis))).toList(),
                            onChanged: (v) => _selectProduct(row, v),
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
                            if (row.resolving)
                              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            else if (row.product != null)
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
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _addToCart,
                    child: _submitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                        : const Text('Добавить в корзину'),
                  ),
                ),
              ]),
      ),
    );
  }
}
