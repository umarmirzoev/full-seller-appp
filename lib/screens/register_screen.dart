import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../services/api_exception.dart';
import '../services/auth_repository.dart';
import '../services/profile_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/logo_mark.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController(text: '+992 ');
  final _legalNameController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isLegalEntity = false;
  bool _codeSent = false;
  bool _loading = false;
  String? _error;

  void _showError(String message) => setState(() => _error = message);

  Future<void> _sendCode() async {
    if (_nameController.text.trim().isEmpty) {
      _showError('Введите ФИО');
      return;
    }
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

  Future<void> _submit() async {
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
      await ProfileRepository.updateProfile(
        fullName: _nameController.text.trim(),
        isLegalEntity: _isLegalEntity,
        legalName: _isLegalEntity ? _legalNameController.text.trim() : null,
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError('Не удалось завершить регистрацию. Попробуйте ещё раз.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(leading: const BackButton()),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const LogoMark(),
            const SizedBox(height: 28),
            Text('Регистрация', style: AppTextStyles.display(size: 24)),
            const SizedBox(height: 8),
            Text('Создайте аккаунт оптового покупателя', style: AppTextStyles.body(size: 13.5, weight: FontWeight.w600, color: AppColors.text2)),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: const Color(0xFFFDECEC), borderRadius: BorderRadius.circular(12)),
                child: Text(_error!, style: AppTextStyles.body(size: 12.5, weight: FontWeight.w600, color: const Color(0xFFD64545))),
              ),
            ],
            const SizedBox(height: 24),
            if (!_codeSent) ...[
              _label('ФИО'),
              TextField(controller: _nameController, decoration: const InputDecoration(hintText: 'Иван Иванов'), enabled: !_loading),
              const SizedBox(height: 16),
              _label('НОМЕР ТЕЛЕФОНА'),
              TextField(controller: _phoneController, keyboardType: TextInputType.phone, enabled: !_loading),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.border, width: 1.5), borderRadius: BorderRadius.circular(16)),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isLegalEntity,
                  onChanged: _loading ? null : (v) => setState(() => _isLegalEntity = v),
                  activeColor: AppColors.primary,
                  title: Text('Юридическое лицо', style: AppTextStyles.body(size: 13.5, weight: FontWeight.w700)),
                  subtitle: Text('Для закупок от компании', style: AppTextStyles.body(size: 11.5, weight: FontWeight.w600, color: AppColors.text3)),
                ),
              ),
              if (_isLegalEntity) ...[
                const SizedBox(height: 16),
                _label('НАЗВАНИЕ ОРГАНИЗАЦИИ'),
                TextField(controller: _legalNameController, decoration: const InputDecoration(hintText: 'ИП / ООО «…»'), enabled: !_loading),
              ],
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _loading ? null : _sendCode,
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : const Text('Получить код'),
              ),
            ] else ...[
              Text(
                'Мы отправили SMS с кодом на ${_phoneController.text}',
                style: AppTextStyles.body(size: 13, weight: FontWeight.w600, color: AppColors.text2),
              ),
              const SizedBox(height: 16),
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
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : const Text('Зарегистрироваться'),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _loading ? null : () => setState(() {
                        _codeSent = false;
                        _error = null;
                      }),
                  child: const Text('Изменить данные'),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Уже есть аккаунт? Войти', style: AppTextStyles.body(size: 13, weight: FontWeight.w700, color: AppColors.primaryDark)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: AppTextStyles.body(size: 12, weight: FontWeight.w700, color: AppColors.text3).copyWith(letterSpacing: 0.4)),
      );
}
