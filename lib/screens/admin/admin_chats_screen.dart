import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/admin/admin_sidebar.dart';
import '../../widgets/admin/admin_top_bar.dart';

class AdminChatsScreen extends StatefulWidget {
  const AdminChatsScreen({super.key});

  @override
  State<AdminChatsScreen> createState() => _AdminChatsScreenState();
}

class _AdminChatsScreenState extends State<AdminChatsScreen> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final threads = MockData.adminChatThreads;
    final selected = threads.firstWhere((c) => c.id == (_selectedId ?? threads.first.id), orElse: () => threads.first);
    final messages = MockData.chatMessages;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Row(children: [
        const AdminSidebar(active: 'Чаты'),
        Expanded(
          child: Column(children: [
            const AdminTopBar(title: 'Чаты'),
            Expanded(
              child: Row(children: [
                Container(
                  width: 320,
                  decoration: const BoxDecoration(color: AppColors.surface, border: Border(right: BorderSide(color: AppColors.borderSoft))),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(10),
                    itemCount: threads.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 2),
                    itemBuilder: (context, i) {
                      final c = threads[i];
                      final isActive = c.id == selected.id;
                      return Material(
                        color: isActive ? AppColors.g50 : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          onTap: () => setState(() => _selectedId = c.id),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(children: [
                              CircleAvatar(radius: 18, backgroundColor: AppColors.g100,
                                  child: Text(c.clientName.isNotEmpty ? c.clientName[0] : '?', style: AppTextStyles.display(size: 13, color: AppColors.primaryDark))),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                                  Text(c.clientName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.body(size: 13, weight: FontWeight.w700)),
                                  const SizedBox(height: 2),
                                  Text(c.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.body(size: 11.5, weight: FontWeight.w600, color: AppColors.text3)),
                                ]),
                              ),
                              if (c.unread > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: const BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.all(Radius.circular(999))),
                                  child: Text('${c.unread}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                                ),
                            ]),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: Column(children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: const BoxDecoration(color: AppColors.surface, border: Border(bottom: BorderSide(color: AppColors.borderSoft))),
                      child: Text(selected.clientName, style: AppTextStyles.display(size: 15)),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: messages.length,
                        itemBuilder: (context, i) {
                          final m = messages[i];
                          return Align(
                            alignment: m.isMine ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              constraints: const BoxConstraints(maxWidth: 380),
                              decoration: BoxDecoration(
                                color: m.isMine ? AppColors.primary : AppColors.surface2,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: Text(m.text, style: AppTextStyles.body(size: 13, weight: FontWeight.w600, color: m.isMine ? Colors.white : AppColors.text)),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.borderSoft))),
                      child: Row(children: [
                        Expanded(
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(AppRadius.md)),
                            alignment: Alignment.centerLeft,
                            child: Text('Написать сообщение…', style: AppTextStyles.body(size: 13, color: AppColors.text3)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                        ),
                      ]),
                    ),
                  ]),
                ),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}
