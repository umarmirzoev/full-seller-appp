import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../models/price_tier.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/admin/admin_card.dart';
import '../../widgets/admin/admin_sidebar.dart';
import '../../widgets/admin/admin_top_bar.dart';

class AdminAddProductScreen extends StatefulWidget {
  final String? productId;
  const AdminAddProductScreen({super.key, this.productId});

  @override
  State<AdminAddProductScreen> createState() => _AdminAddProductScreenState();
}

class _AdminAddProductScreenState extends State<AdminAddProductScreen> {
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _descController = TextEditingController();
  final _weightController = TextEditingController();
  final _oldPriceController = TextEditingController();
  String? _categoryId;
  String? _brandId;
  bool _isNew = false;
  bool _isHit = false;
  bool _isActive = true;
  final List<PriceTier> _tiers = [];

  bool get _isEdit => widget.productId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final p = MockData.productById(widget.productId!);
      _nameController.text = p.name;
      _descController.text = p.description ?? '';
      _weightController.text = p.weightGrams.toString();
      _oldPriceController.text = p.oldPrice?.toString() ?? '';
      _categoryId = p.categoryId;
      _brandId = p.brandId;
      _isNew = p.isNew;
      _isHit = p.isHit;
      _tiers.addAll(p.priceTiers);
    } else {
      _tiers.add(const PriceTier(minQuantity: 50, pricePerUnit: 0));
    }
  }

  void _save() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isEdit ? 'Товар обновлён' : 'Товар добавлен')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Row(children: [
        const AdminSidebar(active: 'Каталог'),
        Expanded(
          child: Column(children: [
            AdminTopBar(
              title: _isEdit ? 'Редактировать товар' : 'Новый товар',
              action: ElevatedButton(onPressed: _save, child: Text(_isEdit ? 'Сохранить' : 'Опубликовать')),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(36),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      flex: 2,
                      child: AdminCard(
                        title: 'Основная информация',
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _label('Название'),
                          TextField(controller: _nameController),
                          const SizedBox(height: 14),
                          Row(children: [
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                _label('Категория'),
                                DropdownButtonFormField<String>(
                                  value: _categoryId,
                                  items: MockData.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                                  onChanged: (v) => setState(() => _categoryId = v),
                                ),
                              ]),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                _label('Бренд'),
                                DropdownButtonFormField<String>(
                                  value: _brandId,
                                  items: MockData.brands.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))).toList(),
                                  onChanged: (v) => setState(() => _brandId = v),
                                ),
                              ]),
                            ),
                          ]),
                          const SizedBox(height: 14),
                          _label('Артикул (base SKU)'),
                          TextField(controller: _skuController),
                          const SizedBox(height: 14),
                          _label('Описание'),
                          TextField(controller: _descController, maxLines: 4),
                          const SizedBox(height: 14),
                          Row(children: [
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                _label('Вес, г'),
                                TextField(controller: _weightController, keyboardType: TextInputType.number),
                              ]),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                _label('Старая цена, ₽ (для бейджа «Скидка»)'),
                                TextField(controller: _oldPriceController, keyboardType: TextInputType.number),
                              ]),
                            ),
                          ]),
                          const SizedBox(height: 8),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            _label('Оптовая шкала цен'),
                            TextButton.icon(
                              onPressed: () => setState(() => _tiers.add(const PriceTier(minQuantity: 0, pricePerUnit: 0))),
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: const Text('Добавить'),
                            ),
                          ]),
                          ..._tiers.asMap().entries.map((e) {
                            final i = e.key;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(children: [
                                Expanded(
                                    child: TextFormField(
                                        initialValue: e.value.minQuantity == 0 ? '' : '${e.value.minQuantity}',
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(labelText: 'От, шт'),
                                        onChanged: (v) => _tiers[i] = PriceTier(minQuantity: int.tryParse(v) ?? 0, pricePerUnit: _tiers[i].pricePerUnit))),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: TextFormField(
                                        initialValue: e.value.pricePerUnit == 0 ? '' : '${e.value.pricePerUnit}',
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(labelText: 'Цена, ₽'),
                                        onChanged: (v) => _tiers[i] = PriceTier(minQuantity: _tiers[i].minQuantity, pricePerUnit: double.tryParse(v) ?? 0))),
                                IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: () => setState(() => _tiers.removeAt(i))),
                              ]),
                            );
                          }),
                        ]),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 1,
                      child: AdminCard(
                        title: 'Видимость',
                        child: Column(children: [
                          _switchTile('Новинка', _isNew, (v) => setState(() => _isNew = v)),
                          _switchTile('Хит продаж', _isHit, (v) => setState(() => _isHit = v)),
                          _switchTile('Активен в каталоге', _isActive, (v) => setState(() => _isActive = v)),
                        ]),
                      ),
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

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 4),
        child: Text(text, style: AppTextStyles.body(size: 11.5, weight: FontWeight.w800, color: AppColors.text3).copyWith(letterSpacing: 0.3)),
      );

  Widget _switchTile(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      activeColor: AppColors.primary,
      onChanged: onChanged,
      title: Text(label, style: AppTextStyles.body(size: 13, weight: FontWeight.w700)),
    );
  }
}
