import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';

class AdminTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? action;
  final VoidCallback? onRefresh;
  final ValueChanged<String>? onSearch;
  const AdminTopBar({super.key, required this.title, this.action, this.onRefresh, this.onSearch});

  int get _unreadNotifications => MockData.notifications.where((n) => !n.isRead).length;
  int get _unreadChats => MockData.adminChatThreads.fold(0, (sum, c) => sum + c.unread);

  @override
  Size get preferredSize => const Size.fromHeight(76);

  @override
  Widget build(BuildContext context) {
    final user = MockData.currentUser;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: const BoxDecoration(color: AppColors.surface, border: Border(bottom: BorderSide(color: AppColors.borderSoft))),
      child: Row(children: [
        Text(title, style: AppTextStyles.display(size: 19)),
        const SizedBox(width: 24),
        Expanded(
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Row(children: [
              const Icon(Icons.search_rounded, size: 17, color: AppColors.text3),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  onChanged: onSearch,
                  decoration: InputDecoration.collapsed(hintText: 'Поиск по заказам, товарам, поставщикам…', hintStyle: AppTextStyles.body(size: 13, color: AppColors.text3)),
                  style: AppTextStyles.body(size: 13),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(width: 16),
        if (action != null) ...[action!, const SizedBox(width: 10)],
        _iconBtn(context, Icons.notifications_none_rounded, badge: _unreadNotifications, onTap: () => Navigator.pushNamed(context, AppRoutes.notifications)),
        const SizedBox(width: 8),
        _iconBtn(context, Icons.chat_bubble_outline_rounded, badge: _unreadChats, onTap: () => Navigator.pushNamed(context, AppRoutes.adminChats)),
        const SizedBox(width: 8),
        _iconBtn(context, Icons.refresh_rounded, onTap: () {
          onRefresh?.call();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Данные обновлены'), duration: Duration(seconds: 1)));
        }),
        const SizedBox(width: 8),
        _iconBtn(context, Icons.logout_rounded, onTap: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.auth, (r) => false)),
        const SizedBox(width: 14),
        PopupMenuButton<String>(
          offset: const Offset(0, 46),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          onSelected: (value) {
            if (value == 'profile') Navigator.pushNamed(context, AppRoutes.profile);
            if (value == 'settings') Navigator.pushNamed(context, AppRoutes.adminSettings);
            if (value == 'logout') Navigator.pushNamedAndRemoveUntil(context, AppRoutes.auth, (r) => false);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'profile', child: Text('Профиль')),
            const PopupMenuItem(value: 'settings', child: Text('Настройки')),
            const PopupMenuItem(value: 'logout', child: Text('Выйти')),
          ],
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            CircleAvatar(radius: 18, backgroundColor: AppColors.g100,
                child: Text(user.initials, style: AppTextStyles.display(size: 12.5, color: AppColors.primaryDark))),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(user.fullName, style: AppTextStyles.body(size: 12.5, weight: FontWeight.w700)),
              Text('Администратор', style: AppTextStyles.body(size: 10.5, weight: FontWeight.w600, color: AppColors.text3)),
            ]),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.text3),
          ]),
        ),
      ]),
    );
  }

  Widget _iconBtn(BuildContext context, IconData icon, {int badge = 0, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.border), shape: BoxShape.circle),
        child: Stack(clipBehavior: Clip.none, children: [
          Center(child: Icon(icon, size: 17, color: AppColors.text2)),
          if (badge > 0)
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text('$badge', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
        ]),
      ),
    );
  }
}
