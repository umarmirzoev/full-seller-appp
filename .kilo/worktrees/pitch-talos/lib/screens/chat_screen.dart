import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../models/chat_message.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messages = List<ChatMessage>.from(MockData.chatMessages);
  final _controller = TextEditingController();

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(id: 'local-${_messages.length}', text: text, isMine: true, createdAt: DateTime.now()));
      _controller.clear();
    });
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
            child: ListView.separated(
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
                  decoration: const InputDecoration(hintText: 'Сообщение...'),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: _send,
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
