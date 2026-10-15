import 'package:flutter/material.dart';
import '../data/countries.dart';
import '../routes/app_routes.dart';
import '../services/api_exception.dart';
import '../services/auth_repository.dart';
import '../services/profile_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/auth_ui.dart';

/// Регистрация: ФИО, страна + телефон, пароль, юрлицо.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _password2Controller = TextEditingController();
  final _legalNameController = TextEditingController();
  Country _country = kDefaultCountry;
  bool _isLegalEntity = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_nameController, _phoneController, _passwordController, _password2Controller, _legalNameController]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    String? err;
    if (_nameController.text.trim().isEmpty) {
      err = 'Введите ФИО';
    } else if (!PhoneInput.isValid(_phoneController.text)) {
      err = 'Введите корректный номер телефона';
    } else if (_passwordController.text.length < 6) {
      err = 'Пароль должен быть не короче 6 символов';
    } else if (_passwordController.text != _password2Controller.text) {
      err = 'Пароли не совпадают';
    } else if (_isLegalEntity && _legalNameController.text.trim().isEmpty) {
      err = 'Введите название организации';
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
      await AuthRepository.register(PhoneInput.compose(_country, _phoneController.text), _passwordController.text);
      await ProfileRepository.updateProfile(
        fullName: _nameController.text.trim(),
        isLegalEntity: _isLegalEntity,
        legalName: _isLegalEntity ? _legalNameController.text.trim() : null,
      );
      if (!mounted) return;
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
        _error = 'Не удалось завершить регистрацию. Попробуйте ещё раз.';
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
                  const Reveal(
                    delayMs: 80,
                    child: AuthHero(
                      icon: Icons.storefront_rounded,
                      title: 'Регистрация',
                      subtitle: 'Создайте аккаунт оптового покупателя',
                    ),
                  ),
                  const SizedBox(height: 26),
                  AuthErrorBox(_error),
                  Reveal(
                    delayMs: 140,
                    child: AuthTextField(
                      controller: _nameController,
                      label: 'ФИО',
                      hint: 'Иван Иванов',
                      icon: Icons.person_outline_rounded,
                      enabled: !_loading,
                      action: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Reveal(
                    delayMs: 190,
                    child: PhoneInput(
                      controller: _phoneController,
                      country: _country,
                      onCountry: (c) => setState(() => _country = c),
                      enabled: !_loading,
                      action: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Reveal(
                    delayMs: 240,
                    child: AuthPasswordField(
                      controller: _passwordController,
                      label: 'ПРИДУМАЙТЕ ПАРОЛЬ',
                      hint: 'Не менее 6 символов',
                      enabled: !_loading,
                      action: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Reveal(
                    delayMs: 290,
                    child: AuthPasswordField(
                      controller: _password2Controller,
                      label: 'ПОВТОРИТЕ ПАРОЛЬ',
                      hint: 'Ещё раз',
                      enabled: !_loading,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Reveal(delayMs: 340, child: _legalToggle()),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    child: _isLegalEntity
                        ? Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: AuthTextField(
                              controller: _legalNameController,
                              label: 'НАЗВАНИЕ ОРГАНИЗАЦИИ',
                              hint: 'ИП / ООО «…»',
                              icon: Icons.business_rounded,
                              enabled: !_loading,
                            ),
                          )
                        : const SizedBox(width: double.infinity),
                  ),
                  const SizedBox(height: 22),
                  Reveal(
                    delayMs: 390,
                    child: GlowButton(text: 'Зарегистрироваться', icon: Icons.check_rounded, loading: _loading, onPressed: _submit),
                  ),
                  const SizedBox(height: 18),
                  Reveal(
                    delayMs: 440,
                    child: AuthLinkCard(
                      icon: Icons.login_rounded,
                      top: 'Уже есть аккаунт?',
                      bottom: 'Войти',
                      onTap: () => Navigator.maybePop(context),
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

  Widget _legalToggle() => HoverScale(
        hover: 1.01,
        onTap: _loading ? null : () => setState(() => _isLegalEntity = !_isLegalEntity),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _isLegalEntity ? AppColors.g50 : AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _isLegalEntity ? AppColors.g200 : AppColors.border, width: 1.5),
          ),
          child: Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: _isLegalEntity ? AppColors.g500 : AppColors.g50, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.business_center_rounded, size: 19, color: _isLegalEntity ? Colors.white : AppColors.g600),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Юридическое лицо', style: AppTextStyles.body(size: 14, weight: FontWeight.w800)),
                Text('Для закупок от компании', style: AppTextStyles.body(size: 11.5, weight: FontWeight.w600, color: AppColors.text3)),
              ]),
            ),
            Switch(
              value: _isLegalEntity,
              onChanged: _loading ? null : (v) => setState(() => _isLegalEntity = v),
              activeColor: Colors.white,
              activeTrackColor: AppColors.primary,
            ),
          ]),
        ),
      );
}
