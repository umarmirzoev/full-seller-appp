import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';
import '../logo_mark.dart';

class _AdminSubItem {
  final String label;
  final dynamic arguments;
  const _AdminSubItem(this.label, [this.arguments]);
}

class _AdminNavItem {
  final String label;
  final IconData icon;
  final String route;
  final List<_AdminSubItem> children;
  const _AdminNavItem(this.label, this.icon, this.route, {this.children = const []});
}

class AdminSidebar extends StatefulWidget {
  final String active;
  const AdminSidebar({super.key, required this.active});

  @override
  State<AdminSidebar> createState() => _AdminSidebarState();
}

class _AdminSidebarState extends State<AdminSidebar> {
  bool _collapsed = false;
  late final Set<String> _expanded = {widget.active};

  static final List<_AdminNavItem> _items = [
    const _AdminNavItem('Дашборд', Icons.grid_view_rounded, AppRoutes.adminDashboard),
    _AdminNavItem('Заказы', Icons.inventory_2_outlined, AppRoutes.adminOrders, children: const [
      _AdminSubItem('Все заказы'),
      _AdminSubItem('Новые', 'novyy'),
      _AdminSubItem('В обработке', 'vObrabotke'),
      _AdminSubItem('Завершено', 'zavershen'),
      _AdminSubItem('Отменено', 'otmenen'),
    ]),
    _AdminNavItem('Поставщики', Icons.local_shipping_outlined, AppRoutes.adminSuppliers, children: const [
      _AdminSubItem('Все поставщики'),
      _AdminSubItem('На модерации', 'moderation'),
      _AdminSubItem('Топ поставщики', 'top'),
      _AdminSubItem('Заблокированные', 'blocked'),
    ]),
    const _AdminNavItem('Каталог', Icons.archive_outlined, AppRoutes.adminCatalog),
    const _AdminNavItem('Клиенты', Icons.people_outline_rounded, AppRoutes.adminClients),
    const _AdminNavItem('Чаты', Icons.chat_bubble_outline_rounded, AppRoutes.adminChats),
    const _AdminNavItem('Отзывы', Icons.star_border_rounded, AppRoutes.adminReviews),
    const _AdminNavItem('Финансы', Icons.account_balance_wallet_outlined, AppRoutes.adminFinances),
    const _AdminNavItem('Аналитика', Icons.bar_chart_rounded, AppRoutes.adminAnalytics),
    const _AdminNavItem('Калькулятор доставки', Icons.calculate_outlined, AppRoutes.adminCalculator),
    const _AdminNavItem('Настройки', Icons.settings_outlined, AppRoutes.adminSettings),
  ];

  int get _chatBadge => MockData.adminChatThreads.fold(0, (sum, c) => sum + c.unread);

  void _open(String route, [dynamic arguments]) {
    Navigator.pushReplacementNamed(context, route, arguments: arguments);
  }

  @override
  Widget build(BuildContext context) {
    final width = _collapsed ? 78.0 : 248.0;
    final user = MockData.currentUser;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: width,
      decoration: const BoxDecoration(color: AppColors.surface, border: Border(right: BorderSide(color: AppColors.borderSoft))),
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(_collapsed ? 16 : 22, 24, _collapsed ? 16 : 14, 20),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderSoft))),
          child: Row(children: [
            Expanded(child: LogoMark(withText: !_collapsed)),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _collapsed = !_collapsed),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(_collapsed ? Icons.chevron_right_rounded : Icons.chevron_left_rounded, size: 18, color: AppColors.text3),
              ),
            ),
          ]),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(10),
            children: _items.map((item) {
              final isActive = item.label == widget.active;
              final hasChildren = item.children.isNotEmpty;
              final isExpanded = _expanded.contains(item.label);

              final tile = Material(
                color: isActive ? AppColors.g50 : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  onTap: () {
                    if (hasChildren && !_collapsed) {
                      setState(() => isExpanded ? _expanded.remove(item.label) : _expanded.add(item.label));
                      if (!isActive) _open(item.route);
                    } else {
                      _open(item.route);
                    }
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: _collapsed ? 0 : 14, vertical: 11),
                    child: Row(mainAxisAlignment: _collapsed ? MainAxisAlignment.center : MainAxisAlignment.start, children: [
                      Icon(item.icon, size: 18, color: isActive ? AppColors.primaryDark : AppColors.text2),
                      if (!_collapsed) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(item.label,
                              style: AppTextStyles.body(size: 13.5, weight: FontWeight.w700, color: isActive ? AppColors.primaryDark : AppColors.text2)),
                        ),
                        if (item.label == 'Чаты' && _chatBadge > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: const BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.all(Radius.circular(999))),
                            child: Text('$_chatBadge', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                          ),
                        if (hasChildren)
                          Icon(isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded, size: 16, color: AppColors.text3),
                      ],
                    ]),
                  ),
                ),
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Column(children: [
                  _collapsed ? Tooltip(message: item.label, child: tile) : tile,
                  if (hasChildren && isExpanded && !_collapsed)
                    Padding(
                      padding: const EdgeInsets.only(left: 30, top: 2, bottom: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: item.children.map((sub) {
                          return InkWell(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            onTap: () => _open(item.route, sub.arguments),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
                              child: Text(sub.label, style: AppTextStyles.body(size: 12.5, weight: FontWeight.w600, color: AppColors.text3)),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ]),
              );
            }).toList(),
          ),
        ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: _collapsed ? 10 : 18, vertical: 16),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.borderSoft))),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(mainAxisAlignment: _collapsed ? MainAxisAlignment.center : MainAxisAlignment.start, children: [
                CircleAvatar(radius: 19, backgroundColor: AppColors.g100,
                    child: Text(user.initials, style: AppTextStyles.display(size: 13, color: AppColors.primaryDark))),
                if (!_collapsed) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Text(user.fullName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.body(size: 12.5, weight: FontWeight.w700)),
                      Text('Менеджер', style: AppTextStyles.body(size: 10.5, weight: FontWeight.w600, color: AppColors.text3)),
                    ]),
                  ),
                  const Icon(Icons.settings_outlined, size: 16, color: AppColors.text3),
                ],
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}
