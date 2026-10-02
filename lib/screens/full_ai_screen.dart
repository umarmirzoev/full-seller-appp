import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';

class _AiMessage {
  final String text;
  final bool isMine;
  const _AiMessage(this.text, this.isMine);
}

class FullAiScreen extends StatefulWidget {
  const FullAiScreen({super.key});

  @override
  State<FullAiScreen> createState() => _FullAiScreenState();
}

class _FullAiScreenState extends State<FullAiScreen> {
  final _messages = <_AiMessage>[
    const _AiMessage('Здравствуйте! Я FULL AI — помогу подобрать товар, посчитать партию или ответить на вопрос по каталогу.', false),
  ];
  final _controller = TextEditingController();

  static const _suggestions = ['Подбери носки до 40₽/шт', 'Сколько будет доставка 80кг в РФ?', 'Что сейчас по акции?'];

  void _send([String? text]) {
    final value = (text ?? _controller.text).trim();
    if (value.isEmpty) return;
    setState(() {
      _messages.add(_AiMessage(value, true));
      _controller.clear();
      _messages.add(const _AiMessage('Секунду, подбираю варианты по вашему запросу…', false));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 30, height: 30,
            decoration: const BoxDecoration(gradient: AppColors.brandGradient, shape: BoxShape.circle),
            child: const Icon(Icons.auto_awesome_rounded, size: 15, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Text('FULL AI', style: AppTextStyles.display(size: 16)),
        ]),
      ),
      body: SafeArea(
        top: false,
        child: Column(children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final m = _messages[i];
                return Align(
                  alignment: m.isMine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: m.isMine ? AppColors.primary : AppColors.surface,
                      border: m.isMine ? null : Border.all(color: AppColors.borderSoft),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text(m.text, style: AppTextStyles.body(size: 13.5, weight: FontWeight.w600, color: m.isMine ? Colors.white : AppColors.text)),
                  ),
                );
              },
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) => InkWell(
                onTap: () => _send(_suggestions[i]),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.g50, borderRadius: BorderRadius.circular(999)),
                  child: Text(_suggestions[i], style: AppTextStyles.body(size: 12, weight: FontWeight.w700, color: AppColors.primaryDark)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.borderSoft))),
            child: Row(children: [
              Expanded(
                child: TextField(controller: _controller, decoration: const InputDecoration(hintText: 'Спросите что-нибудь...'), onSubmitted: (_) => _send()),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: () => _send(),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 46, height: 46,
                  decoration: const BoxDecoration(gradient: AppColors.brandGradient, shape: BoxShape.circle),
                  child: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
