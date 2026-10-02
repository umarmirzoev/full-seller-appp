import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
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
  bool _isLegalEntity = false;

  void _submit() => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);

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
            const SizedBox(height: 24),
            _label('ФИО'),
            TextField(controller: _nameController, decoration: const InputDecoration(hintText: 'Иван Иванов')),
            const SizedBox(height: 16),
            _label('НОМЕР ТЕЛЕФОНА'),
            TextField(controller: _phoneController, keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.border, width: 1.5), borderRadius: BorderRadius.circular(16)),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isLegalEntity,
                onChanged: (v) => setState(() => _isLegalEntity = v),
                activeColor: AppColors.primary,
                title: Text('Юридическое лицо', style: AppTextStyles.body(size: 13.5, weight: FontWeight.w700)),
                subtitle: Text('Для закупок от компании', style: AppTextStyles.body(size: 11.5, weight: FontWeight.w600, color: AppColors.text3)),
              ),
            ),
            if (_isLegalEntity) ...[
              const SizedBox(height: 16),
              _label('НАЗВАНИЕ ОРГАНИЗАЦИИ'),
              TextField(controller: _legalNameController, decoration: const InputDecoration(hintText: 'ИП / ООО «…»')),
            ],
            const SizedBox(height: 28),
            ElevatedButton(onPressed: _submit, child: const Text('Зарегистрироваться')),
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
