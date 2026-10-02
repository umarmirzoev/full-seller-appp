import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../services/api_exception.dart';
import '../services/auth_repository.dart';
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
  final _codeController = TextEditingController();
  bool _codeSent = false;
  bool _loading = false;
  String? _error;

  void _showError(String message) {
    setState(() => _error = message);
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 6) {
      _showError('Введите корректный номер телефона');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthRepository.requestOtp(phone);
      if (!mounted) return;
      setState(() {
        _codeSent = true;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError('Не удалось отправить код. Попробуйте ещё раз.');
    }
  }

  Future<void> _confirm() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      _showError('Введите код из SMS');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthRepository.confirmOtp(_phoneController.text.trim(), code);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError('Не удалось войти. Попробуйте ещё раз.');
    }
  }

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
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: const Color(0xFFFDECEC), borderRadius: BorderRadius.circular(12)),
                child: Text(_error!, style: AppTextStyles.body(size: 12.5, weight: FontWeight.w600, color: const Color(0xFFD64545))),
              ),
            ],
            const SizedBox(height: 28),
            if (!_codeSent) ...[
              Text('НОМЕР ТЕЛЕФОНА', style: AppTextStyles.body(size: 12, weight: FontWeight.w700, color: AppColors.text3).copyWith(letterSpacing: 0.4)),
              const SizedBox(height: 8),
              TextField(controller: _phoneController, keyboardType: TextInputType.phone, enabled: !_loading),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _sendCode,
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : const Text('Получить код'),
              ),
            ] else ...[
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                enabled: !_loading,
                style: AppTextStyles.mono(size: 22),
                decoration: const InputDecoration(hintText: '— — — —'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _confirm,
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : const Text('Войти'),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _loading ? null : () => setState(() {
                        _codeSent = false;
                        _error = null;
                      }),
                  child: const Text('Изменить номер'),
                ),
              ),
            ],
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
