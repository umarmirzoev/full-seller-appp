import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../models/address.dart';
import '../../models/cargo_rate.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/admin/admin_card.dart';
import '../../widgets/admin/admin_sidebar.dart';
import '../../widgets/admin/admin_top_bar.dart';

class AdminCalculatorScreen extends StatefulWidget {
  const AdminCalculatorScreen({super.key});

  @override
  State<AdminCalculatorScreen> createState() => _AdminCalculatorScreenState();
}

class _AdminCalculatorScreenState extends State<AdminCalculatorScreen> {
  late List<CargoRate> _rates;
  late Map<DeliveryCountry, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _rates = List.from(MockData.cargoRates);
    _controllers = {for (final r in _rates) r.country: TextEditingController(text: r.pricePerKg.toString())};
  }

  void _save() {
    setState(() {
      _rates = _rates.map((r) => CargoRate(country: r.country, pricePerKg: double.tryParse(_controllers[r.country]!.text) ?? r.pricePerKg, currency: r.currency)).toList();
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Тарифы обновлены')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Row(children: [
        const AdminSidebar(active: 'Калькулятор доставки'),
        Expanded(
          child: Column(children: [
            AdminTopBar(title: 'Тарифы карго', action: ElevatedButton(onPressed: _save, child: const Text('Сохранить'))),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(36),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: AdminCard(
                    title: 'Цена за килограмм по странам',
                    child: Column(
                      children: _rates.map((r) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(children: [
                            SizedBox(width: 150, child: Text(r.country.label, style: AppTextStyles.body(size: 13.5, weight: FontWeight.w700))),
                            Expanded(
                              child: TextField(
                                controller: _controllers[r.country],
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(suffixText: '₽ / кг'),
                              ),
                            ),
                          ]),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
