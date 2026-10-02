import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../models/app_notification.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _iconFor(NotificationType t) => switch (t) {
        NotificationType.order => Icons.inventory_2_outlined,
        NotificationType.promo => Icons.local_offer_outlined,
        NotificationType.system => Icons.info_outline_rounded,
        NotificationType.chat => Icons.chat_bubble_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text('Уведомления', style: AppTextStyles.display(size: 17))),
      body: SafeArea(
        top: false,
        child: ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: MockData.notifications.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final n = MockData.notifications[i];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: n.isRead ? AppColors.surface : AppColors.g50,
                border: Border.all(color: AppColors.borderSoft),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
                  child: Icon(_iconFor(n.type), size: 17, color: AppColors.primaryDark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(n.title, style: AppTextStyles.body(size: 13, weight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(n.body, style: AppTextStyles.body(size: 12, weight: FontWeight.w600, color: AppColors.text2)),
                  ]),
                ),
                if (!n.isRead) Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 4), decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle)),
              ]),
            );
          },
        ),
      ),
    );
  }
}
