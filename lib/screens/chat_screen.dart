import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/chat_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<ChatMessage> _messages = [];
  final _controller = TextEditingController();
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final history = await ChatRepository.getHistory();
      if (!mounted) return;
      setState(() {
        _messages = history;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    _controller.clear();
    setState(() => _sending = true);
    try {
      final sent = await ChatRepository.send(text);
      if (!mounted) return;
      setState(() {
        _messages = [..._messages, sent];
        _sending = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Не удалось отправить сообщение')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text('Чат с менеджером', style: AppTextStyles.display(size: 16))),
      body: SafeArea(
        top: false,
        child: Column(children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(child: Text('Напишите первое сообщение менеджеру', style: AppTextStyles.body(color: AppColors.text3)))
                    : ListView.separated(
                        reverse: false,
                        padding: const EdgeInsets.all(20),
                        itemCount: _messages.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final m = _messages[i];
                          return Align(
                            alignment: m.isMine ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
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
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.borderSoft))),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !_sending,
                  decoration: const InputDecoration(hintText: 'Сообщение...'),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: _sending ? null : _send,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 46, height: 46,
                  decoration: const BoxDecoration(gradient: AppColors.brandGradient, shape: BoxShape.circle),
                  child: _sending
                      ? const Padding(padding: EdgeInsets.all(13), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
