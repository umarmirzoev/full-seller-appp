import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/logo_mark.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _phoneController = TextEditingController(text: '+992 ');
  bool _codeSent = false;
  final _codeController = TextEditingController();

  void _sendCode() => setState(() => _codeSent = true);

  void _confirm() => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const LogoMark(),
            const SizedBox(height: 32),
            Text(_codeSent ? 'Введите код' : 'Вход в аккаунт', style: AppTextStyles.display(size: 24)),
            const SizedBox(height: 8),
            Text(
              _codeSent ? 'Мы отправили SMS с кодом на ${_phoneController.text}' : 'Введите номер телефона — пришлём код подтверждения',
              style: AppTextStyles.body(size: 13.5, weight: FontWeight.w600, color: AppColors.text2),
            ),
            const SizedBox(height: 28),
            if (!_codeSent) ...[
              Text('НОМЕР ТЕЛЕФОНА', style: AppTextStyles.body(size: 12, weight: FontWeight.w700, color: AppColors.text3).copyWith(letterSpacing: 0.4)),
              const SizedBox(height: 8),
              TextField(controller: _phoneController, keyboardType: TextInputType.phone),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _sendCode, child: const Text('Получить код')),
            ] else ...[
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: AppTextStyles.mono(size: 22),
                decoration: const InputDecoration(hintText: '— — — —'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _confirm, child: const Text('Войти')),
              const SizedBox(height: 12),
              Center(
                child: TextButton(onPressed: () => setState(() => _codeSent = false), child: const Text('Изменить номер')),
              ),
            ],
            const SizedBox(height: 20),
            Row(children: [
              const Expanded(child: Divider()),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('или', style: AppTextStyles.body(size: 12, color: AppColors.text3))),
              const Expanded(child: Divider()),
            ]),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _confirm,
              icon: const Icon(Icons.telegram_rounded, size: 20, color: Color(0xFF229ED9)),
              label: const Text('Войти через Telegram'),
            ),
            const SizedBox(height: 28),
            Center(
              child: RichText(
                text: TextSpan(
                  style: AppTextStyles.body(size: 13, weight: FontWeight.w600, color: AppColors.text2),
                  children: [
                    const TextSpan(text: 'Нет аккаунта? '),
                    TextSpan(
                      text: 'Зарегистрироваться',
                      style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w800),
                      recognizer: (TapGestureRecognizer()..onTap = () => Navigator.pushNamed(context, AppRoutes.register)),
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
