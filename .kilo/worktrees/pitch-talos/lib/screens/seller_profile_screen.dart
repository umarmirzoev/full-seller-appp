import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';
import '../widgets/star_rating.dart';

class SellerProfileScreen extends StatelessWidget {
  const SellerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = MockData.currentUser;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text('Профиль поставщика', style: AppTextStyles.display(size: 17))),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(AppRadius.lg)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  CircleAvatar(radius: 28, backgroundColor: Colors.white.withOpacity(0.25),
                      child: Text(user.initials, style: AppTextStyles.display(size: 18, color: Colors.white))),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(user.legalName ?? user.fullName, style: AppTextStyles.display(size: 16, color: Colors.white)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(999)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.verified_rounded, size: 13, color: Colors.white),
                          const SizedBox(width: 4),
                          Text('Проверенный поставщик', style: AppTextStyles.body(size: 10.5, weight: FontWeight.w800, color: Colors.white)),
                        ]),
                      ),
                    ]),
                  ),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  const StarRating(rating: 4.8, size: 15),
                  const SizedBox(width: 6),
                  Text('4.8 · 214 отзывов', style: AppTextStyles.body(size: 12.5, weight: FontWeight.w700, color: Colors.white)),
                ]),
              ]),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: _stat('${MockData.products.length}', 'Товаров в каталоге')),
              const SizedBox(width: 12),
              Expanded(child: _stat('${MockData.orders.length}', 'Заказов выполнено')),
            ]),
            const SizedBox(height: 20),
            Text('Контакты', style: AppTextStyles.display(size: 15)),
            const SizedBox(height: 10),
            _contactTile(Icons.call_outlined, MockData.appSettings.contactPhone ?? '—'),
            _contactTile(Icons.location_on_outlined, MockData.appSettings.contactAddress ?? '—'),
            _contactTile(Icons.chat_outlined, MockData.appSettings.telegramUrl ?? '—'),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.borderSoft), borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: AppTextStyles.display(size: 20)),
        Text(label, style: AppTextStyles.body(size: 11, weight: FontWeight.w600, color: AppColors.text3)),
      ]),
    );
  }

  Widget _contactTile(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Icon(icon, size: 18, color: AppColors.primaryDark),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: AppTextStyles.body(size: 13, weight: FontWeight.w600))),
      ]),
    );
  }
}
