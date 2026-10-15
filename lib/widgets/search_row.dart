import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';

/// Поиск: без внутренней линии, со свечением при фокусе и hover, кнопка фильтров.
class SearchRow extends StatefulWidget {
  final VoidCallback? onFilterTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextEditingController? controller;
  final String hint;
  const SearchRow({
    super.key,
    this.onFilterTap,
    this.onChanged,
    this.onSubmitted,
    this.controller,
    this.hint = 'Поиск по каталогу',
  });

  @override
  State<SearchRow> createState() => _SearchRowState();
}

class _SearchRowState extends State<SearchRow> {
  final _focus = FocusNode();
  bool _hover = false;
  bool _filterHover = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = _focus.hasFocus;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Row(children: [
        Expanded(
          child: MouseRegion(
            onEnter: (_) => setState(() => _hover = true),
            onExit: (_) => setState(() => _hover = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: f ? AppColors.primary : (_hover ? AppColors.g200 : AppColors.border), width: f ? 1.8 : 1.4),
                borderRadius: BorderRadius.circular(AppRadius.md),
                boxShadow: [
                  BoxShadow(color: AppColors.g500.withValues(alpha: f ? 0.16 : (_hover ? 0.07 : 0)), blurRadius: f ? 20 : 12, offset: const Offset(0, 6)),
                ],
              ),
              child: Row(children: [
                AnimatedScale(
                  scale: f ? 1.15 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.search_rounded, size: 20, color: f ? AppColors.primary : AppColors.text3),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focus,
                    onChanged: widget.onChanged,
                    onSubmitted: widget.onSubmitted,
                    textInputAction: TextInputAction.search,
                    style: AppTextStyles.body(size: 14, weight: FontWeight.w600),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: false,
                      hintText: widget.hint,
                      hintStyle: AppTextStyles.body(size: 14, weight: FontWeight.w600, color: AppColors.text3),
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
        if (widget.onFilterTap != null) ...[
          const SizedBox(width: 10),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _filterHover = true),
            onExit: (_) => setState(() => _filterHover = false),
            child: GestureDetector(
              onTap: widget.onFilterTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: _filterHover ? AppColors.brandGradient : null,
                  color: _filterHover ? null : AppColors.surface,
                  border: Border.all(color: _filterHover ? Colors.transparent : AppColors.border, width: 1.4),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: _filterHover ? [BoxShadow(color: AppColors.g500.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 6))] : null,
                ),
                child: AnimatedRotation(
                  turns: _filterHover ? 0.25 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(Icons.tune_rounded, size: 20, color: _filterHover ? Colors.white : AppColors.text2),
                ),
              ),
            ),
          ),
        ],
      ]),
    );
  }
}
