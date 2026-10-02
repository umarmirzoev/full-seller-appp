import 'package:flutter/material.dart';
import '../models/order.dart';
import '../theme/app_colors.dart';

class OrderStatusPill extends StatelessWidget {
  final OrderStatus status;
  const OrderStatusPill({super.key, required this.status});

  (Color, Color) get _colors => switch (status) {
        OrderStatus.novyy => (const Color(0xFFEFF3FF), const Color(0xFF2563EB)),
        OrderStatus.podtverzhden => (AppColors.g50, AppColors.primaryDark),
        OrderStatus.vObrabotke => (const Color(0xFFFFF3E0), const Color(0xFF9A5B12)),
        OrderStatus.otpravlen => (const Color(0xFFE8F5FF), const Color(0xFF0369A1)),
        OrderStatus.zavershen => (const Color(0xFFE9F9EE), const Color(0xFF15803D)),
        OrderStatus.otmenen => (const Color(0xFFFDECEB), AppColors.danger),
      };

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(status.label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: fg)),
    );
  }
}

class StockPill extends StatelessWidget {
  final int quantity;
  const StockPill({super.key, required this.quantity});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = quantity <= 0
        ? (const Color(0xFFFDECEB), AppColors.danger, 'Нет в наличии')
        : quantity < 100
            ? (const Color(0xFFFFF3E0), const Color(0xFF9A5B12), 'Мало: $quantity')
            : (AppColors.g50, AppColors.primaryDark, 'В наличии: $quantity');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: fg)),
    );
  }
}
