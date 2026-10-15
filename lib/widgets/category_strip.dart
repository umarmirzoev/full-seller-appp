import 'package:flutter/material.dart';
import '../models/category.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Иконка категории по названию (носки, трусы, футболки, шорты, штаны …).
IconData categoryIcon(String name) {
  final n = name.toLowerCase();
  if (n.contains('носк')) return Icons.ice_skating_rounded;
  if (n.contains('трус') || n.contains('бель')) return Icons.dry_cleaning_rounded;
  if (n.contains('футбол') || n.contains('майк')) return Icons.checkroom_rounded;
  if (n.contains('шорт')) return Icons.sports_handball_rounded;
  if (n.contains('штан') || n.contains('брюк') || n.contains('джинс')) return Icons.accessibility_new_rounded;
  if (n.contains('кофт') || n.contains('свитер') || n.contains('худи')) return Icons.style_rounded;
  if (n.contains('куртк')) return Icons.ac_unit_rounded;
  if (n.contains('обув')) return Icons.directions_walk_rounded;
  if (n.contains('дет')) return Icons.child_care_rounded;
  return Icons.inventory_2_rounded;
}

/// Лента категорий: появляются по очереди, приподнимаются при наведении.
class CategoryStrip extends StatelessWidget {
  final List<Category> categories;
  final ValueChanged<Category> onTap;
  final VoidCallback? onAll;
  const CategoryStrip({super.key, required this.categories, required this.onTap, this.onAll});

  @override
  Widget build(BuildContext context) {
    final count = categories.length + (onAll != null ? 1 : 0);
    return SizedBox(
      height: 102,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          if (onAll != null && i == 0) {
            return _CategoryChip(index: i, name: 'Все', icon: Icons.apps_rounded, highlighted: true, onTap: onAll!);
          }
          final c = categories[i - (onAll != null ? 1 : 0)];
          return _CategoryChip(index: i, name: c.name, icon: categoryIcon(c.name), onTap: () => onTap(c));
        },
      ),
    );
  }
}

class _CategoryChip extends StatefulWidget {
  final int index;
  final String name;
  final IconData icon;
  final bool highlighted;
  final VoidCallback onTap;
  const _CategoryChip({required this.index, required this.name, required this.icon, required this.onTap, this.highlighted = false});

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip> {
  bool _h = false, _d = false;

  @override
  Widget build(BuildContext context) {
    final active = _h || widget.highlighted;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + widget.index * 70),
      curve: Curves.easeOutBack,
      builder: (context, v, child) => Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: child),
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _h = true),
        onExit: (_) => setState(() => _h = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _d = true),
          onTapUp: (_) => setState(() => _d = false),
          onTapCancel: () => setState(() => _d = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _d ? 0.92 : 1,
            duration: const Duration(milliseconds: 130),
            child: SizedBox(
              width: 70,
              child: Column(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 62,
                  height: 62,
                  transform: Matrix4.translationValues(0, _h ? -4 : 0, 0),
                  decoration: BoxDecoration(
                    gradient: active ? AppColors.brandGradient : null,
                    color: active ? null : AppColors.g50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: active ? Colors.transparent : AppColors.g100),
                    boxShadow: active ? [BoxShadow(color: AppColors.g500.withValues(alpha: 0.32), blurRadius: 14, offset: const Offset(0, 6))] : null,
                  ),
                  child: Icon(widget.icon, color: active ? Colors.white : AppColors.g600, size: 26),
                ),
                const SizedBox(height: 7),
                Text(
                  widget.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body(size: 11.5, weight: FontWeight.w800, color: _h ? AppColors.g700 : AppColors.text2),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
