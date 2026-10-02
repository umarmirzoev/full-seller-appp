import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../models/app_banner.dart';
import '../../models/promo_code.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/admin/admin_card.dart';
import '../../widgets/admin/admin_sidebar.dart';
import '../../widgets/admin/admin_top_bar.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  late final _rateController = TextEditingController(text: MockData.appSettings.usdToRubRate.toString());
  late final _minOrderController = TextEditingController(text: MockData.appSettings.minOrderAmount.toString());
  late final _phoneController = TextEditingController(text: MockData.appSettings.contactPhone ?? '');
  late final _addressController = TextEditingController(text: MockData.appSettings.contactAddress ?? '');
  late final _whatsAppController = TextEditingController(text: MockData.appSettings.whatsAppUrl ?? '');
  late final _telegramController = TextEditingController(text: MockData.appSettings.telegramUrl ?? '');
  late final _promoCodes = List<PromoCode>.from(MockData.promoCodes);
  late final _banners = List<AppBanner>.from(MockData.banners);

  void _save() => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Настройки сохранены')));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Row(children: [
        const AdminSidebar(active: 'Настройки'),
        Expanded(
          child: Column(children: [
            AdminTopBar(title: 'Настройки магазина', action: ElevatedButton(onPressed: _save, child: const Text('Сохранить'))),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(36),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    AdminCard(
                      title: 'Валюта и минимальный заказ',
                      child: Row(children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            _label('Курс USD → RUB'),
                            TextField(controller: _rateController, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                          ]),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            _label('Минимальная сумма заказа, ₽'),
                            TextField(controller: _minOrderController, keyboardType: TextInputType.number),
                          ]),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 20),
                    AdminCard(
                      title: 'Контакты',
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              _label('Телефон'),
                              TextField(controller: _phoneController),
                            ]),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              _label('Адрес'),
                              TextField(controller: _addressController),
                            ]),
                          ),
                        ]),
                        const SizedBox(height: 14),
                        Row(children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              _label('WhatsApp'),
                              TextField(controller: _whatsAppController),
                            ]),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              _label('Telegram'),
                              TextField(controller: _telegramController),
                            ]),
                          ),
                        ]),
                      ]),
                    ),
                    const SizedBox(height: 20),
                    AdminCard(
                      title: 'Баннеры главной страницы',
                      child: Column(
                        children: [
                          for (final b in _banners)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(children: [
                                Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(AppRadius.sm)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(b.title, style: AppTextStyles.body(size: 13, weight: FontWeight.w700)),
                                    if (b.subtitle != null) Text(b.subtitle!, style: AppTextStyles.body(size: 11.5, weight: FontWeight.w600, color: AppColors.text3)),
                                  ]),
                                ),
                                Switch(value: b.isActive, activeColor: AppColors.primary, onChanged: (_) {}),
                              ]),
                            ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(onPressed: () {}, icon: const Icon(Icons.add_rounded, size: 16), label: const Text('Добавить баннер')),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    AdminCard(
                      title: 'Промокоды',
                      child: Column(
                        children: [
                          Table(
                            columnWidths: const {0: FlexColumnWidth(1.2), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1), 3: FlexColumnWidth(1), 4: FlexColumnWidth(0.6)},
                            children: [
                              TableRow(children: [_th('Код'), _th('Тип'), _th('Значение'), _th('Использовано'), _th('')]),
                              for (final p in _promoCodes)
                                TableRow(children: [
                                  _td(p.code, mono: true),
                                  _td(p.discountType == DiscountType.percent ? 'Процент' : 'Фикс. сумма'),
                                  _td(p.discountType == DiscountType.percent ? '${p.discountValue.toStringAsFixed(0)}%' : '${p.discountValue.toStringAsFixed(0)} ₽'),
                                  _td('${p.timesUsed}${p.usageLimit != null ? ' / ${p.usageLimit}' : ''}'),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 17, color: AppColors.danger), onPressed: () => setState(() => _promoCodes.remove(p))),
                                  ),
                                ]),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(onPressed: () {}, icon: const Icon(Icons.add_rounded, size: 16), label: const Text('Новый промокод')),
                          ),
                        ],
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
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: AppTextStyles.body(size: 11.5, weight: FontWeight.w800, color: AppColors.text3).copyWith(letterSpacing: 0.3)),
      );

  Widget _th(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(label, style: AppTextStyles.body(size: 10.5, weight: FontWeight.w800, color: AppColors.text3).copyWith(letterSpacing: 0.4)),
      );

  Widget _td(String text, {bool mono = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: mono ? Text(text, style: AppTextStyles.mono(size: 12.5)) : Text(text, style: AppTextStyles.body(size: 13, weight: FontWeight.w600)),
      );
}
