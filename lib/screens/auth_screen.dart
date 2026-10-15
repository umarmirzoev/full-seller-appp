import 'package:flutter/material.dart';
import '../data/countries.dart';
import '../routes/app_routes.dart';
import '../services/api_exception.dart';
import '../services/auth_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/auth_ui.dart';

/// Вход: страна + номер телефона и пароль.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  Country _country = kDefaultCountry;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!PhoneInput.isValid(_phoneController.text)) {
      setState(() => _error = 'Введите корректный номер телефона');
      return;
    }
    if (_passwordController.text.isEmpty) {
      setState(() => _error = 'Введите пароль');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthRepository.login(PhoneInput.compose(_country, _phoneController.text), _passwordController.text);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.isUnauthorized ? 'Неверный номер или пароль' : e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Не удалось войти. Попробуйте ещё раз.';
      });
    }
  }

  void _forgot() => Navigator.pushNamed(context, AppRoutes.forgotPassword, arguments: {
        'country': _country,
        'phone': _phoneController.text,
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackdrop(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const Reveal(child: Align(alignment: Alignment.centerLeft, child: AuthBrand())),
                  const SizedBox(height: 26),
                  const Reveal(
                    delayMs: 80,
                    child: AuthHero(
                      icon: Icons.lock_rounded,
                      title: 'С возвращением!',
                      subtitle: 'Войдите по номеру телефона и паролю',
                    ),
                  ),
                  const SizedBox(height: 28),
                  AuthErrorBox(_error),
                  Reveal(
                    delayMs: 160,
                    child: PhoneInput(
                      controller: _phoneController,
                      country: _country,
                      onCountry: (c) => setState(() => _country = c),
                      enabled: !_loading,
                      action: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Reveal(
                    delayMs: 230,
                    child: AuthPasswordField(
                      controller: _passwordController,
                      enabled: !_loading,
                      action: TextInputAction.done,
                      onSubmitted: (_) => _login(),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Reveal(
                    delayMs: 280,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: HoverScale(
                        onTap: _loading ? null : _forgot,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          child: Text('Забыли пароль?', style: AppTextStyles.body(size: 13.5, weight: FontWeight.w800, color: AppColors.g600)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Reveal(
                    delayMs: 330,
                    child: GlowButton(text: 'Войти', icon: Icons.login_rounded, loading: _loading, onPressed: _login),
                  ),
                  const SizedBox(height: 22),
                  Reveal(
                    delayMs: 400,
                    child: AuthLinkCard(
                      icon: Icons.person_add_alt_1_rounded,
                      top: 'Нет аккаунта?',
                      bottom: 'Зарегистрироваться за 30 секунд',
                      onTap: () => Navigator.pushNamed(context, AppRoutes.register),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
