import 'dart:async';
import 'package:flutter/material.dart';
import '../models/address.dart';
import '../providers/currency_provider.dart';
import '../services/delivery_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';
import 'package:provider/provider.dart';

class CargoCalculatorScreen extends StatefulWidget {
  const CargoCalculatorScreen({super.key});

  @override
  State<CargoCalculatorScreen> createState() => _CargoCalculatorScreenState();
}

class _CargoCalculatorScreenState extends State<CargoCalculatorScreen> {
  DeliveryCountry _country = DeliveryCountry.russia;
  final _weightController = TextEditingController(text: '50');
  DeliveryCalculation? _result;
  bool _loading = false;
  int _requestToken = 0;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _scheduleCalculate() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _calculate);
  }

  Future<void> _calculate() async {
    final weightKg = double.tryParse(_weightController.text.replaceAll(',', '.')) ?? 0;
    final token = ++_requestToken;
    setState(() => _loading = true);
    try {
      final calc = await DeliveryRepository.calculate(country: _country, totalWeightGrams: (weightKg * 1000).round());
      if (!mounted || token != _requestToken) return;
      setState(() {
        _result = calc;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || token != _requestToken) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<CurrencyProvider>();
    final pricePerKg = _result?.pricePerKg ?? 0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text('Калькулятор доставки', style: AppTextStyles.display(size: 17))),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('СТРАНА НАЗНАЧЕНИЯ', style: AppTextStyles.body(size: 11.5, weight: FontWeight.w800, color: AppColors.text3).copyWith(letterSpacing: 0.4)),
            const SizedBox(height: 10),
            Row(children: DeliveryCountry.values.map((c) {
              final active = c == _country;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: InkWell(
                    onTap: () {
                      setState(() => _country = c);
                      _calculate();
                    },
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: active ? AppColors.primary : AppColors.surface,
                        border: Border.all(color: active ? AppColors.primary : AppColors.border),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Text(c.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: active ? Colors.white : AppColors.text2)),
                    ),
                  ),
                ),
              );
            }).toList()),
            const SizedBox(height: 22),
            Text('ВЕС ГРУЗА, КГ', style: AppTextStyles.body(size: 11.5, weight: FontWeight.w800, color: AppColors.text3).copyWith(letterSpacing: 0.4)),
            const SizedBox(height: 10),
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => _scheduleCalculate(),
              decoration: const InputDecoration(hintText: 'Например, 50', suffixText: 'кг'),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(AppRadius.lg)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Стоимость доставки', style: AppTextStyles.body(size: 12.5, weight: FontWeight.w700, color: Colors.white.withOpacity(0.85))),
                const SizedBox(height: 6),
                _loading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : Text(currency.format(_result?.totalCost ?? 0), style: AppTextStyles.display(size: 28, color: Colors.white)),
                const SizedBox(height: 6),
                Text('${pricePerKg.round()} ₽ / кг · ${_country.label}', style: AppTextStyles.body(size: 12, weight: FontWeight.w600, color: Colors.white.withOpacity(0.85))),
              ]),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primaryDark),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Итоговая стоимость доставки рассчитывается автоматически при оформлении заказа, исходя из фактического веса позиций в корзине.',
                      style: AppTextStyles.body(size: 12, weight: FontWeight.w600, color: AppColors.text2)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
