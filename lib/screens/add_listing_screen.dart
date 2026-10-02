import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../models/price_tier.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';

class AddListingScreen extends StatefulWidget {
  final String? productId;
  const AddListingScreen({super.key, this.productId});

  @override
  State<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _weightController = TextEditingController();
  String? _categoryId;
  String? _brandId;
  bool _isNew = false;
  bool _isHit = false;
  bool _isActive = true;
  final List<PriceTier> _tiers = [];
  final Set<String> _sizes = {};
  final Set<String> _colors = {};

  static const _sizeOptions = ['S', 'M', 'L', 'XL', '39-42', '43-46', '26-30'];
  static const _colorOptions = ['Чёрный', 'Белый', 'Серый', 'Синий', 'Микс'];

  bool get _isEdit => widget.productId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final p = MockData.productById(widget.productId!);
      _nameController.text = p.name;
      _descController.text = p.description ?? '';
      _weightController.text = p.weightGrams.toString();
      _categoryId = p.categoryId;
      _brandId = p.brandId;
      _isNew = p.isNew;
      _isHit = p.isHit;
      _tiers.addAll(p.priceTiers);
      _sizes.addAll(p.variants.map((v) => v.size).whereType<String>());
      _colors.addAll(p.variants.map((v) => v.color).whereType<String>());
    } else {
      _tiers.add(const PriceTier(minQuantity: 50, pricePerUnit: 0));
    }
  }

  void _addTier() => setState(() => _tiers.add(const PriceTier(minQuantity: 0, pricePerUnit: 0)));

  void _save() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isEdit ? 'Товар обновлён' : 'Товар добавлен в каталог')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(_isEdit ? 'Редактировать товар' : 'Новый товар', style: AppTextStyles.display(size: 16))),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                height: 120,
                decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border, style: BorderStyle.solid)),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.add_photo_alternate_outlined, size: 26, color: AppColors.text3),
                  const SizedBox(height: 6),
                  Text('Добавить фото', style: AppTextStyles.body(size: 12.5, weight: FontWeight.w700, color: AppColors.text3)),
                ]),
              ),
            ),
            const SizedBox(height: 20),
            _label('НАЗВАНИЕ ТОВАРА'),
            TextField(controller: _nameController),
            const SizedBox(height: 16),
            _label('КАТЕГОРИЯ'),
            DropdownButtonFormField<String>(
              value: _categoryId,
              items: MockData.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
              onChanged: (v) => setState(() => _categoryId = v),
              decoration: const InputDecoration(hintText: 'Выберите категорию'),
            ),
            const SizedBox(height: 16),
            _label('БРЕНД'),
            DropdownButtonFormField<String>(
              value: _brandId,
              items: MockData.brands.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))).toList(),
              onChanged: (v) => setState(() => _brandId = v),
              decoration: const InputDecoration(hintText: 'Выберите бренд'),
            ),
            const SizedBox(height: 16),
            _label('ОПИСАНИЕ'),
            TextField(controller: _descController, maxLines: 4),
            const SizedBox(height: 16),
            _label('ВЕС ЗА ЕДИНИЦУ, Г'),
            TextField(controller: _weightController, keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            _label('РАЗМЕРЫ'),
            Wrap(spacing: 8, runSpacing: 8, children: _sizeOptions.map((s) => _toggleChip(s, _sizes)).toList()),
            const SizedBox(height: 20),
            _label('ЦВЕТА'),
            Wrap(spacing: 8, runSpacing: 8, children: _colorOptions.map((c) => _toggleChip(c, _colors)).toList()),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _label('ОПТОВАЯ ШКАЛА ЦЕН'),
              TextButton.icon(onPressed: _addTier, icon: const Icon(Icons.add_rounded, size: 16), label: const Text('Добавить')),
            ]),
            ..._tiers.asMap().entries.map((e) {
              final i = e.key;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: e.value.minQuantity == 0 ? '' : e.value.minQuantity.toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'От, шт'),
                      onChanged: (v) => _tiers[i] = PriceTier(minQuantity: int.tryParse(v) ?? 0, pricePerUnit: _tiers[i].pricePerUnit),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      initialValue: e.value.pricePerUnit == 0 ? '' : e.value.pricePerUnit.toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Цена, ₽'),
                      onChanged: (v) => _tiers[i] = PriceTier(minQuantity: _tiers[i].minQuantity, pricePerUnit: double.tryParse(v) ?? 0),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: () => setState(() => _tiers.removeAt(i))),
                ]),
              );
            }),
            const SizedBox(height: 12),
            _switchTile('Новинка', _isNew, (v) => setState(() => _isNew = v)),
            _switchTile('Хит продаж', _isHit, (v) => setState(() => _isHit = v)),
            _switchTile('Товар активен (виден в каталоге)', _isActive, (v) => setState(() => _isActive = v)),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _save, child: Text(_isEdit ? 'Сохранить изменения' : 'Опубликовать товар')),
            if (_isEdit) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                label: const Text('Удалить товар', style: TextStyle(color: AppColors.danger)),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: AppTextStyles.body(size: 11.5, weight: FontWeight.w800, color: AppColors.text3).copyWith(letterSpacing: 0.4)),
      );

  Widget _toggleChip(String label, Set<String> set) {
    final active = set.contains(label);
    return InkWell(
      onTap: () => setState(() => active ? set.remove(label) : set.add(label)),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surface,
          border: Border.all(color: active ? AppColors.primary : AppColors.border),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: active ? Colors.white : AppColors.text2)),
      ),
    );
  }

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
