import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';
import '../theme/app_colors.dart';

class CurrencyToggle extends StatelessWidget {
  const CurrencyToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<CurrencyProvider>();
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _btn(context, '₽', currency.isRub, () => currency.toggle(AppCurrency.rub)),
        _btn(context, '\$', !currency.isRub, () => currency.toggle(AppCurrency.usd)),
      ]),
    );
  }

  Widget _btn(BuildContext context, String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: active ? [const BoxShadow(color: Color(0x1F4A1D02), blurRadius: 4, offset: Offset(0, 1))] : null,
        ),
        child: Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: active ? AppColors.primaryDark : AppColors.text3)),
      ),
    );
  }
}
