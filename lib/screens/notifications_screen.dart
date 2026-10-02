import 'package:flutter/material.dart';
import '../models/app_notification.dart';
import '../services/notifications_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await NotificationsRepository.getMy();
      if (!mounted) return;
      setState(() {
        _notifications = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _markRead(int index) async {
    final n = _notifications[index];
    if (n.isRead) return;
    setState(() => _notifications[index] = AppNotification(id: n.id, type: n.type, title: n.title, body: n.body, createdAt: n.createdAt, isRead: true));
    try {
      await NotificationsRepository.markRead(n.id);
    } catch (_) {
      // не откатываем — прочитанность локально не критична при недоступности backend
    }
  }

  IconData _iconFor(NotificationType t) => switch (t) {
        NotificationType.orderStatusChanged => Icons.inventory_2_outlined,
        NotificationType.newMessage => Icons.chat_bubble_outline_rounded,
        NotificationType.bonusAccrued => Icons.stars_outlined,
        NotificationType.backInStock => Icons.inventory_outlined,
        NotificationType.reviewRequest => Icons.rate_review_outlined,
        NotificationType.promo => Icons.local_offer_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text('Уведомления', style: AppTextStyles.display(size: 17))),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _notifications.isEmpty
                ? Center(child: Text('Уведомлений пока нет', style: AppTextStyles.body(color: AppColors.text3)))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: _notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final n = _notifications[i];
                        return InkWell(
                          onTap: () => _markRead(i),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          child: Container(
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
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
