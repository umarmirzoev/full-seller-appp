import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/countries.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Общие «живые» элементы экранов входа / регистрации / восстановления пароля:
/// анимированный фон, появление блоков по очереди, поля со свечением, кнопка с бликом,
/// выбор страны для номера телефона.

// ─────────────────────────── Фон ───────────────────────────

class AuthBackdrop extends StatefulWidget {
  final Widget child;
  const AuthBackdrop({super.key, required this.child});

  @override
  State<AuthBackdrop> createState() => _AuthBackdropState();
}

class _AuthBackdropState extends State<AuthBackdrop> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _blob(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      const Positioned.fill(child: ColoredBox(color: AppColors.bg)),
      Positioned.fill(
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final t = _c.value * 2 * pi;
              return LayoutBuilder(builder: (context, box) {
                final w = box.maxWidth, h = box.maxHeight;
                return Stack(children: [
                  Positioned(left: w * 0.55 + sin(t) * 40, top: -120 + cos(t) * 30, child: _blob(360, AppColors.g200.withValues(alpha: 0.55))),
                  Positioned(left: -140 + cos(t * 0.8) * 30, top: h * 0.35 + sin(t * 0.8) * 50, child: _blob(320, AppColors.g100.withValues(alpha: 0.7))),
                  Positioned(left: w * 0.4 + sin(t * 1.3) * 60, top: h * 0.78 + cos(t) * 20, child: _blob(280, AppColors.g200.withValues(alpha: 0.35))),
                ]);
              });
            },
          ),
        ),
      ),
      Positioned.fill(child: widget.child),
    ]);
  }
}

// ─────────────────────────── Появление ───────────────────────────

/// Плавное появление снизу с задержкой (для «лесенки» блоков).
class Reveal extends StatefulWidget {
  final Widget child;
  final int delayMs;
  final double dy;
  const Reveal({super.key, required this.child, this.delayMs = 0, this.dy = 18});

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 560));
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _a,
        builder: (context, child) => Opacity(
          opacity: _a.value,
          child: Transform.translate(offset: Offset(0, widget.dy * (1 - _a.value)), child: child),
        ),
        child: widget.child,
      );
}

// ─────────────────────────── Шапка ───────────────────────────

class AuthHero extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const AuthHero({super.key, required this.icon, required this.title, required this.subtitle});

  @override
  State<AuthHero> createState() => _AuthHeroState();
}

class _AuthHeroState extends State<AuthHero> with SingleTickerProviderStateMixin {
  late final AnimationController _p = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat(reverse: true);

  @override
  void dispose() {
    _p.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      AnimatedBuilder(
        animation: _p,
        builder: (context, child) {
          final v = Curves.easeInOut.transform(_p.value);
          return Transform.translate(
            offset: Offset(0, -4 * v),
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(color: AppColors.g500.withValues(alpha: 0.25 + 0.2 * v), blurRadius: 22 + 16 * v, spreadRadius: 1 + 4 * v, offset: const Offset(0, 10)),
                ],
              ),
              child: child,
            ),
          );
        },
        child: Icon(widget.icon, color: Colors.white, size: 38),
      ),
      const SizedBox(height: 22),
      Text(widget.title, textAlign: TextAlign.center, style: AppTextStyles.display(size: 25, weight: FontWeight.w800)),
      const SizedBox(height: 8),
      Text(widget.subtitle, textAlign: TextAlign.center, style: AppTextStyles.body(size: 13.5, weight: FontWeight.w600, color: AppColors.text2)),
    ]);
  }
}

/// Небольшой логотип FULL SELLER сверху экрана.
class AuthBrand extends StatelessWidget {
  const AuthBrand({super.key});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 34,
          height: 34,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Image.asset('assets/logo/fs_logo.png', fit: BoxFit.contain, filterQuality: FilterQuality.high),
        ),
        const SizedBox(width: 8),
        Text('FULL SELLER', style: AppTextStyles.display(size: 13.5, weight: FontWeight.w800)),
      ]);
}

/// Круглая кнопка «назад» с hover.
class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key});

  @override
  Widget build(BuildContext context) => HoverScale(
        onTap: () => Navigator.maybePop(context),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryDark, size: 22),
        ),
      );
}

// ─────────────────────────── Hover / нажатие ───────────────────────────

class HoverScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double hover;
  const HoverScale({super.key, required this.child, this.onTap, this.hover = 1.04});

  @override
  State<HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<HoverScale> {
  bool _h = false, _d = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final scale = !enabled ? 1.0 : (_d ? 0.95 : (_h ? widget.hover : 1.0));
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _d = true) : null,
        onTapCancel: () => setState(() => _d = false),
        onTapUp: enabled ? (_) => setState(() => _d = false) : null,
        onTap: widget.onTap,
        child: AnimatedScale(scale: scale, duration: const Duration(milliseconds: 160), curve: Curves.easeOut, child: widget.child),
      ),
    );
  }
}

// ─────────────────────────── Ошибка ───────────────────────────

class AuthErrorBox extends StatelessWidget {
  final String? error;
  const AuthErrorBox(this.error, {super.key});

  @override
  Widget build(BuildContext context) => AnimatedSize(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        child: error == null
            ? const SizedBox(width: double.infinity)
            : TweenAnimationBuilder<double>(
                key: ValueKey(error),
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 420),
                builder: (context, v, child) => Transform.translate(offset: Offset(sin(v * pi * 4) * 6 * (1 - v), 0), child: child),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDECEC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFF7C9C9)),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 19),
                    const SizedBox(width: 10),
                    Expanded(child: Text(error!, style: AppTextStyles.body(size: 12.8, weight: FontWeight.w700, color: AppColors.danger))),
                  ]),
                ),
              ),
      );
}

// ─────────────────────────── Поля ───────────────────────────

/// Обёртка поля: плавающая подпись, иконка, свечение при фокусе и hover.
class GlowBox extends StatefulWidget {
  final String label;
  final IconData icon;
  final Widget Function(FocusNode focus) builder;
  final Widget? leading;
  final Widget? trailing;
  const GlowBox({super.key, required this.label, required this.icon, required this.builder, this.leading, this.trailing});

  @override
  State<GlowBox> createState() => _GlowBoxState();
}

class _GlowBoxState extends State<GlowBox> {
  final _focus = FocusNode();
  bool _hover = false;

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
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: f ? AppColors.primary : (_hover ? AppColors.g200 : AppColors.border), width: f ? 1.8 : 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.g500.withValues(alpha: f ? 0.18 : (_hover ? 0.08 : 0.0)),
              blurRadius: f ? 22 : 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(children: [
          widget.leading ??
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: f ? AppColors.g500 : AppColors.g50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, size: 19, color: f ? Colors.white : AppColors.g600),
              ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: AppTextStyles.body(size: 11, weight: FontWeight.w800, color: f ? AppColors.g600 : AppColors.text3).copyWith(letterSpacing: 0.3),
                child: Text(widget.label),
              ),
              widget.builder(_focus),
            ]),
          ),
          if (widget.trailing != null) widget.trailing!,
        ]),
      ),
    );
  }
}

InputDecoration _bare(String? hint) => InputDecoration(
      isDense: true,
      filled: false,
      hintText: hint,
      contentPadding: const EdgeInsets.only(top: 3, bottom: 2),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      hintStyle: AppTextStyles.body(size: 15, weight: FontWeight.w600, color: AppColors.text3.withValues(alpha: 0.7)),
    );

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final bool enabled;
  final TextInputType? keyboard;
  final List<TextInputFormatter>? formatters;
  final TextInputAction? action;
  final ValueChanged<String>? onSubmitted;
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.enabled = true,
    this.keyboard,
    this.formatters,
    this.action,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) => GlowBox(
        label: label,
        icon: icon,
        builder: (focus) => TextField(
          controller: controller,
          focusNode: focus,
          enabled: enabled,
          keyboardType: keyboard,
          inputFormatters: formatters,
          textInputAction: action,
          onSubmitted: onSubmitted,
          style: AppTextStyles.body(size: 15.5, weight: FontWeight.w700),
          decoration: _bare(hint),
        ),
      );
}

class AuthPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool enabled;
  final TextInputAction? action;
  final ValueChanged<String>? onSubmitted;
  const AuthPasswordField({
    super.key,
    required this.controller,
    this.label = 'ПАРОЛЬ',
    this.hint = 'Введите пароль',
    this.enabled = true,
    this.action,
    this.onSubmitted,
  });

  @override
  State<AuthPasswordField> createState() => _AuthPasswordFieldState();
}

class _AuthPasswordFieldState extends State<AuthPasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) => GlowBox(
        label: widget.label,
        icon: Icons.lock_outline_rounded,
        trailing: HoverScale(
          hover: 1.12,
          onTap: () => setState(() => _hidden = !_hidden),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (c, a) => RotationTransition(turns: Tween(begin: 0.75, end: 1.0).animate(a), child: FadeTransition(opacity: a, child: c)),
              child: Icon(
                _hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                key: ValueKey(_hidden),
                size: 21,
                color: AppColors.text3,
              ),
            ),
          ),
        ),
        builder: (focus) => TextField(
          controller: widget.controller,
          focusNode: focus,
          enabled: widget.enabled,
          obscureText: _hidden,
          textInputAction: widget.action,
          onSubmitted: widget.onSubmitted,
          style: AppTextStyles.body(size: 15.5, weight: FontWeight.w700),
          decoration: _bare(widget.hint),
        ),
      );
}

// ─────────────────────────── Телефон + страна ───────────────────────────

/// Номер телефона с выбором страны (все страны, поиск по названию и коду).
class PhoneInput extends StatelessWidget {
  final TextEditingController controller;
  final Country country;
  final ValueChanged<Country> onCountry;
  final bool enabled;
  final TextInputAction? action;
  const PhoneInput({
    super.key,
    required this.controller,
    required this.country,
    required this.onCountry,
    this.enabled = true,
    this.action,
  });

  /// Полный номер для backend: +код и цифры.
  static String compose(Country c, String number) => '+${c.dial}${number.replaceAll(RegExp(r'\D'), '')}';

  static bool isValid(String number) {
    final n = number.replaceAll(RegExp(r'\D'), '').length;
    return n >= 6 && n <= 12;
  }

  @override
  Widget build(BuildContext context) => GlowBox(
        label: 'НОМЕР ТЕЛЕФОНА',
        icon: Icons.phone_rounded,
        leading: HoverScale(
          hover: 1.05,
          onTap: enabled
              ? () async {
                  final picked = await showCountryPicker(context, country);
                  if (picked != null) onCountry(picked);
                }
              : null,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(color: AppColors.g50, borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(country.flag, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 6),
              Text('+${country.dial}', style: AppTextStyles.body(size: 14.5, weight: FontWeight.w800, color: AppColors.g700)),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.g600),
            ]),
          ),
        ),
        builder: (focus) => TextField(
          controller: controller,
          focusNode: focus,
          enabled: enabled,
          keyboardType: TextInputType.phone,
          textInputAction: action,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')), LengthLimitingTextInputFormatter(16)],
          style: AppTextStyles.body(size: 15.5, weight: FontWeight.w700).copyWith(letterSpacing: 0.6),
          decoration: _bare('00 000 00 00'),
        ),
      );
}

Future<Country?> showCountryPicker(BuildContext context, Country selected) {
  return showModalBottomSheet<Country>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CountrySheet(selected: selected),
  );
}

class _CountrySheet extends StatefulWidget {
  final Country selected;
  const _CountrySheet({required this.selected});

  @override
  State<_CountrySheet> createState() => _CountrySheetState();
}

class _CountrySheetState extends State<_CountrySheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase().replaceAll('+', '');
    final list = q.isEmpty
        ? kCountries
        : kCountries.where((c) => c.name.toLowerCase().contains(q) || c.dial.startsWith(q) || c.iso.toLowerCase() == q).toList();
    final h = MediaQuery.of(context).size.height;
    return Container(
      height: h * 0.82,
      decoration: const BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(children: [
        const SizedBox(height: 10),
        Container(width: 42, height: 5, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(3))),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(children: [
            Text('Выберите страну', style: AppTextStyles.display(size: 18, weight: FontWeight.w800)),
            const Spacer(),
            Text('${kCountries.length}', style: AppTextStyles.body(size: 12, weight: FontWeight.w800, color: AppColors.text3)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            autofocus: false,
            onChanged: (v) => setState(() => _q = v),
            style: AppTextStyles.body(size: 15, weight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: 'Поиск: страна или код',
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.text3),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border, width: 1.5)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border, width: 1.5)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 1.8)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: list.isEmpty
              ? Center(child: Text('Ничего не найдено', style: AppTextStyles.body(size: 14, color: AppColors.text3)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final c = list[i];
                    final sel = c.iso == widget.selected.iso;
                    return _CountryTile(country: c, selected: sel, onTap: () => Navigator.pop(context, c));
                  },
                ),
        ),
      ]),
    );
  }
}

class _CountryTile extends StatefulWidget {
  final Country country;
  final bool selected;
  final VoidCallback onTap;
  const _CountryTile({required this.country, required this.selected, required this.onTap});

  @override
  State<_CountryTile> createState() => _CountryTileState();
}

class _CountryTileState extends State<_CountryTile> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.country;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: widget.selected ? AppColors.g50 : (_h ? AppColors.surface : Colors.transparent),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: widget.selected ? AppColors.g200 : Colors.transparent),
          ),
          child: Row(children: [
            Text(c.flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(child: Text(c.name, style: AppTextStyles.body(size: 14.5, weight: FontWeight.w700))),
            Text('+${c.dial}', style: AppTextStyles.body(size: 14, weight: FontWeight.w800, color: AppColors.text2)),
            if (widget.selected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
            ],
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────── Кнопки ───────────────────────────

/// Градиентная кнопка с бликом, hover-подъёмом и нажатием.
class GlowButton extends StatefulWidget {
  final String text;
  final IconData? icon;
  final bool loading;
  final VoidCallback? onPressed;
  final Gradient gradient;
  const GlowButton({
    super.key,
    required this.text,
    this.icon,
    this.loading = false,
    this.onPressed,
    this.gradient = AppColors.brandGradient,
  });

  @override
  State<GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<GlowButton> with SingleTickerProviderStateMixin {
  late final AnimationController _shine = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();
  bool _h = false, _d = false;

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _d = true) : null,
        onTapUp: enabled ? (_) => setState(() => _d = false) : null,
        onTapCancel: () => setState(() => _d = false),
        onTap: enabled ? widget.onPressed : null,
        child: AnimatedScale(
          scale: _d ? 0.97 : 1,
          duration: const Duration(milliseconds: 140),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 56,
            transform: Matrix4.translationValues(0, _h && enabled ? -2 : 0, 0),
            decoration: BoxDecoration(
              gradient: widget.gradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.g500.withValues(alpha: enabled ? (_h ? 0.45 : 0.3) : 0.12),
                  blurRadius: _h ? 26 : 16,
                  offset: Offset(0, _h ? 12 : 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(alignment: Alignment.center, children: [
                if (enabled)
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _shine,
                      builder: (context, _) => FractionalTranslation(
                        translation: Offset(-1.2 + _shine.value * 2.4, 0),
                        child: Transform(
                          transform: Matrix4.skewX(-0.35),
                          child: Align(
                            alignment: Alignment.center,
                            child: Container(
                              width: 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  Colors.white.withValues(alpha: 0),
                                  Colors.white.withValues(alpha: 0.28),
                                  Colors.white.withValues(alpha: 0),
                                ]),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: widget.loading
                      ? const SizedBox(key: ValueKey('l'), width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.6, color: Colors.white))
                      : Row(key: const ValueKey('t'), mainAxisSize: MainAxisSize.min, children: [
                          if (widget.icon != null) ...[
                            Icon(widget.icon, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                          ],
                          Text(widget.text, style: AppTextStyles.body(size: 15.5, weight: FontWeight.w800, color: Colors.white)),
                        ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Карточка-ссылка («Нет аккаунта? Зарегистрироваться →»).
class AuthLinkCard extends StatelessWidget {
  final IconData icon;
  final String top;
  final String bottom;
  final VoidCallback onTap;
  const AuthLinkCard({super.key, required this.icon, required this.top, required this.bottom, required this.onTap});

  @override
  Widget build(BuildContext context) => HoverScale(
        hover: 1.02,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: AppColors.g50, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: AppColors.g600, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(top, style: AppTextStyles.body(size: 12, weight: FontWeight.w600, color: AppColors.text3)),
                const SizedBox(height: 2),
                Text(bottom, style: AppTextStyles.body(size: 14.5, weight: FontWeight.w800)),
              ]),
            ),
            const Icon(Icons.arrow_forward_rounded, color: AppColors.g600),
          ]),
        ),
      );
}
