import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';

class FiltersScreen extends StatefulWidget {
  const FiltersScreen({super.key});

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  final Set<String> _categories = {};
  final Set<String> _brands = {};
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  String _sort = 'popular';

  static const _sorts = [
    ('popular', 'По популярности'),
    ('price_asc', 'Сначала дешевле'),
    ('price_desc', 'Сначала дороже'),
    ('rating', 'По рейтингу'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Фильтры', style: AppTextStyles.display(size: 17)),
        actions: [
          TextButton(
            onPressed: () => setState(() {
              _categories.clear();
              _brands.clear();
              _fromController.clear();
              _toController.clear();
              _sort = 'popular';
            }),
            child: const Text('Сбросить'),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionLabel('КАТЕГОРИИ'),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: MockData.categories.map((c) => _chip(c.name, _categories.contains(c.id), () {
                    setState(() => _categories.contains(c.id) ? _categories.remove(c.id) : _categories.add(c.id));
                  })).toList(),
            ),
            const SizedBox(height: 22),
            _sectionLabel('БРЕНДЫ'),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: MockData.brands.map((b) => _chip(b.name, _brands.contains(b.id), () {
                    setState(() => _brands.contains(b.id) ? _brands.remove(b.id) : _brands.add(b.id));
                  })).toList(),
            ),
            const SizedBox(height: 22),
            _sectionLabel('ЦЕНА ЗА ЕДИНИЦУ, ₽'),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _fromController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'От', labelText: 'От'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _toController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'До', labelText: 'До'),
                ),
              ),
            ]),
            const SizedBox(height: 22),
            _sectionLabel('СОРТИРОВКА'),
            Column(
              children: _sorts.map((s) => RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    value: s.$1,
                    groupValue: _sort,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _sort = v!),
                    title: Text(s.$2, style: AppTextStyles.body(size: 13.5, weight: FontWeight.w600)),
                  )).toList(),
            ),
          ]),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Показать товары')),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text, style: AppTextStyles.body(size: 11.5, weight: FontWeight.w800, color: AppColors.text3).copyWith(letterSpacing: 0.4)),
      );

  Widget _chip(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surface,
          border: Border.all(color: active ? AppColors.primary : AppColors.border),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: active ? Colors.white : AppColors.text2)),
      ),
    );
  }
}
