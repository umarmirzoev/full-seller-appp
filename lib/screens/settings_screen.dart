import 'package:flutter/material.dart';
import '../models/app_settings_data.dart';
import '../routes/app_routes.dart';
import '../services/api_exception.dart';
import '../services/auth_repository.dart';
import '../services/chat_repository.dart';
import '../services/settings_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';

/// Настройки: контакты, политика конфиденциальности, удаление аккаунта, версия.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AppSettingsData? _settings;

  @override
  void initState() {
    super.initState();
    SettingsRepository.getSettings().then((s) {
      if (mounted) setState(() => _settings = s);
    }).catchError((_) {});
  }

  Future<void> _deleteAccount() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить аккаунт?'),
        content: const Text(
            'Мы удалим ваш аккаунт и связанные данные (профиль, адреса, корзину, избранное) в течение 30 дней. '
            'История заказов может храниться дольше, если этого требует закон. Действие необратимо.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ChatRepository.send('[УДАЛЕНИЕ АККАУНТА] Пользователь запросил удаление аккаунта и всех данных из приложения.');
      await AuthRepository.logout();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Запрос на удаление принят. Аккаунт будет удалён в течение 30 дней.')),
      );
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.auth, (r) => false);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось отправить запрос. Проверьте интернет и попробуйте ещё раз.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _settings;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text('Настройки', style: AppTextStyles.display(size: 16))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _section('КОНТАКТЫ'),
          _info(Icons.phone_outlined, 'Телефон', s?.contactPhone ?? '—'),
          _info(Icons.location_on_outlined, 'Адрес', s?.contactAddress ?? '—'),
          if (s?.telegramUrl != null) _info(Icons.send_outlined, 'Telegram', s!.telegramUrl!),
          if (s?.whatsAppUrl != null) _info(Icons.chat_outlined, 'WhatsApp', s!.whatsAppUrl!),
          const SizedBox(height: 16),
          _section('ДОКУМЕНТЫ'),
          _tile(Icons.privacy_tip_outlined, 'Политика конфиденциальности', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
          }),
          const SizedBox(height: 16),
          _section('АККАУНТ'),
          _tile(Icons.delete_outline_rounded, 'Удалить аккаунт', _deleteAccount, danger: true),
          const SizedBox(height: 24),
          Center(child: Text('FULL SELLER · версия 1.0.0', style: AppTextStyles.body(size: 11.5, color: AppColors.text3))),
        ],
      ),
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: AppTextStyles.body(size: 11.5, weight: FontWeight.w800, color: AppColors.text3).copyWith(letterSpacing: 0.4)),
      );

  Widget _info(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Icon(icon, size: 19, color: AppColors.text2),
          const SizedBox(width: 14),
          Text(label, style: AppTextStyles.body(size: 13, weight: FontWeight.w700, color: AppColors.text)),
          const SizedBox(width: 12),
          Expanded(child: SelectableText(value, textAlign: TextAlign.right, style: AppTextStyles.body(size: 12.5, color: AppColors.text2))),
        ]),
      );

  Widget _tile(IconData icon, String label, VoidCallback onTap, {bool danger = false}) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(children: [
            Icon(icon, size: 19, color: danger ? AppColors.danger : AppColors.text2),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: AppTextStyles.body(size: 13.5, weight: FontWeight.w700, color: danger ? AppColors.danger : AppColors.text))),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.text3),
          ]),
        ),
      );
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _text = '''
Политика конфиденциальности FULL SELLER

1. Какие данные мы собираем
• Номер телефона — для входа по SMS-коду.
• Имя и адреса доставки — для оформления и доставки заказов.
• Заказы, корзина, избранное, сообщения в чате с менеджером.

2. Зачем
Только для работы приложения: вход, оформление и доставка заказов, связь с менеджером. Мы не продаём данные и не используем их для рекламы.

3. Передача третьим лицам
Данные передаются только службам доставки в объёме, нужном для доставки заказа.

4. Хранение и защита
Данные хранятся на наших серверах. Доступ к ним есть только у сотрудников, обрабатывающих заказы.

5. Удаление данных
Аккаунт можно удалить в приложении: Профиль → Настройки → Удалить аккаунт. Данные удаляются в течение 30 дней, кроме тех, которые мы обязаны хранить по закону.

6. Контакты
По вопросам о данных пишите в чат с менеджером в приложении.
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text('Конфиденциальность', style: AppTextStyles.display(size: 16))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(_text.trim(), style: AppTextStyles.body(size: 13.5, color: AppColors.text)),
      ),
    );
  }
}
