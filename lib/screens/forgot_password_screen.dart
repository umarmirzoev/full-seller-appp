import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/countries.dart';
import '../routes/app_routes.dart';
import '../services/api_exception.dart';
import '../services/auth_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/auth_ui.dart';

/// Восстановление пароля через Telegram-бота (бесплатно, без SMS):
/// 1) номер → ссылка на бота; 2) бот просит подтвердить номер и присылает код;
/// 3) код + новый пароль → вход.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const _tgGradient = LinearGradient(colors: [Color(0xFF37AEE2), Color(0xFF1E96C8)]);

  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _passController = TextEditingController();
  final _pass2Controller = TextEditingController();
  Country _country = kDefaultCountry;
  int _step = 0;
  bool _loading = false;
  String? _error;
  String? _botUrl;
  bool _argsRead = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsRead) return;
    _argsRead = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      if (args['country'] is Country) _country = args['country'] as Country;
      if (args['phone'] is String) _phoneController.text = args['phone'] as String;
    }
  }

  @override
  void dispose() {
    for (final c in [_phoneController, _codeController, _passController, _pass2Controller]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _phone => PhoneInput.compose(_country, _phoneController.text);

  Future<void> _openBot() async {
    final url = _botUrl;
    if (url == null) return;
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      setState(() => _error = 'Не удалось открыть Telegram. Установите Telegram и попробуйте ещё раз.');
    }
  }

  Future<void> _requestCode() async {
    FocusScope.of(context).unfocus();
    if (!PhoneInput.isValid(_phoneController.text)) {
      setState(() => _error = 'Введите корректный номер телефона');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _botUrl = await AuthRepository.forgotPasswordTelegram(_phone);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _step = 1;
      });
      await _openBot();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Не удалось получить ссылку. Попробуйте ещё раз.';
      });
    }
  }

  Future<void> _reset() async {
    FocusScope.of(context).unfocus();
    String? err;
    if (_codeController.text.trim().length < 4) {
      err = 'Введите код из Telegram';
    } else if (_passController.text.length < 6) {
      err = 'Пароль должен быть не короче 6 символов';
    } else if (_passController.text != _pass2Controller.text) {
      err = 'Пароли не совпадают';
    }
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthRepository.resetPassword(_phone, _codeController.text.trim(), _passController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.text,
          content: Text('Пароль изменён. Добро пожаловать!', style: AppTextStyles.body(size: 13.5, color: Colors.white)),
        ),
      );
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Не удалось сменить пароль. Попробуйте ещё раз.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackdrop(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const Reveal(child: Row(children: [AuthBackButton(), Spacer(), AuthBrand()])),
                  const SizedBox(height: 22),
                  Reveal(
                    delayMs: 80,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: AuthHero(
                        key: ValueKey(_step),
                        icon: _step == 0 ? Icons.key_rounded : Icons.mark_email_read_rounded,
                        title: _step == 0 ? 'Забыли пароль?' : 'Введите код',
                        subtitle: _step == 0
                            ? 'Пришлём код в Telegram — бесплатно и за минуту'
                            : 'Код пришёл в Telegram от нашего бота',
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Reveal(delayMs: 120, child: _Steps(step: _step)),
                  const SizedBox(height: 20),
                  AuthErrorBox(_error),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 380),
                    switchInCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, a) => FadeTransition(
                      opacity: a,
                      child: SlideTransition(position: Tween(begin: const Offset(0.08, 0), end: Offset.zero).animate(a), child: child),
                    ),
                    child: _step == 0 ? _phoneStep() : _codeStep(),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _phoneStep() => Column(key: const ValueKey('phone'), crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Reveal(
          delayMs: 160,
          child: PhoneInput(
            controller: _phoneController,
            country: _country,
            onCountry: (c) => setState(() => _country = c),
            enabled: !_loading,
            action: TextInputAction.done,
          ),
        ),
        const SizedBox(height: 14),
        Reveal(delayMs: 220, child: _hint('Номер в Telegram должен совпадать с номером вашего аккаунта FULL SELLER.')),
        const SizedBox(height: 20),
        Reveal(
          delayMs: 280,
          child: GlowButton(
            text: 'Получить код в Telegram',
            icon: Icons.send_rounded,
            gradient: _tgGradient,
            loading: _loading,
            onPressed: _requestCode,
          ),
        ),
      ]);

  Widget _codeStep() => Column(key: const ValueKey('code'), crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _hint('В Telegram нажмите «Запустить» → «📱 Подтвердить номер». Бот пришлёт 6-значный код.'),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: HoverScale(
              hover: 1.02,
              onTap: _loading ? null : _openBot,
              child: _chip(Icons.open_in_new_rounded, 'Открыть Telegram'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: HoverScale(
              hover: 1.02,
              onTap: _loading
                  ? null
                  : () => setState(() {
                        _step = 0;
                        _error = null;
                      }),
              child: _chip(Icons.edit_rounded, 'Изменить номер'),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        AuthTextField(
          controller: _codeController,
          label: 'КОД ИЗ TELEGRAM',
          hint: '000000',
          icon: Icons.pin_rounded,
          keyboard: TextInputType.number,
          formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
          enabled: !_loading,
          action: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        AuthPasswordField(controller: _passController, label: 'НОВЫЙ ПАРОЛЬ', hint: 'Не менее 6 символов', enabled: !_loading, action: TextInputAction.next),
        const SizedBox(height: 12),
        AuthPasswordField(controller: _pass2Controller, label: 'ПОВТОРИТЕ ПАРОЛЬ', hint: 'Ещё раз', enabled: !_loading, onSubmitted: (_) => _reset()),
        const SizedBox(height: 22),
        GlowButton(text: 'Сохранить и войти', icon: Icons.check_rounded, loading: _loading, onPressed: _reset),
      ]);

  Widget _hint(String text) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF6FC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFCBE8F6)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF1E96C8)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppTextStyles.body(size: 12.8, weight: FontWeight.w600, color: const Color(0xFF1B5E7A)))),
        ]),
      );

  Widget _chip(IconData icon, String text) => Container(
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 17, color: AppColors.g600),
          const SizedBox(width: 8),
          Flexible(child: Text(text, overflow: TextOverflow.ellipsis, style: AppTextStyles.body(size: 13, weight: FontWeight.w800))),
        ]),
      );
}

/// Индикатор шагов: Номер → Код → Новый пароль.
class _Steps extends StatelessWidget {
  final int step;
  const _Steps({required this.step});

  @override
  Widget build(BuildContext context) {
    const labels = ['Номер', 'Код', 'Пароль'];
    final active = step == 0 ? 0 : 2;
    return Row(
      children: List.generate(labels.length * 2 - 1, (i) {
        if (i.isOdd) {
          final done = (i ~/ 2) < active;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(color: done ? AppColors.primary : AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          );
        }
        final idx = i ~/ 2;
        final on = idx <= active;
        return Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: on ? AppColors.brandGradient : null,
              color: on ? null : AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: on ? Colors.transparent : AppColors.border, width: 1.5),
            ),
            child: Text('${idx + 1}', style: AppTextStyles.body(size: 12.5, weight: FontWeight.w800, color: on ? Colors.white : AppColors.text3)),
          ),
          const SizedBox(height: 4),
          Text(labels[idx], style: AppTextStyles.body(size: 11, weight: FontWeight.w700, color: on ? AppColors.text : AppColors.text3)),
        ]);
      }),
    );
  }
}
