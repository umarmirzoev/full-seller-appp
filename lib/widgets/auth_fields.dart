import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Общие элементы экранов входа / регистрации / сброса пароля.
Widget authLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: AppTextStyles.body(size: 12, weight: FontWeight.w700, color: AppColors.text3).copyWith(letterSpacing: 0.4)),
    );

Widget authError(String? error) => error == null
    ? const SizedBox.shrink()
    : Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: const Color(0xFFFDECEC), borderRadius: BorderRadius.circular(12)),
          child: Text(error, style: AppTextStyles.body(size: 12.5, weight: FontWeight.w600, color: const Color(0xFFD64545))),
        ),
      );

Widget authButton({required String text, required bool loading, required VoidCallback onPressed}) => ElevatedButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
          : Text(text),
    );

/// Поле пароля с кнопкой «показать».
class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final bool enabled;
  const PasswordField({super.key, required this.controller, this.hint = 'Пароль', this.enabled = true});

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) => TextField(
        controller: widget.controller,
        obscureText: _hidden,
        enabled: widget.enabled,
        decoration: InputDecoration(
          hintText: widget.hint,
          suffixIcon: IconButton(
            icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20, color: AppColors.text3),
            onPressed: () => setState(() => _hidden = !_hidden),
          ),
        ),
      );
}
