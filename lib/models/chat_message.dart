/// 1:1 с backend ChatSenderType (User=0, Manager=1).
enum ChatSenderType { user, manager }

class ChatMessage {
  final String id;
  final String text;
  final bool isMine;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isMine,
    required this.createdAt,
  });

  /// Со стороны приложения покупателя: "моё" сообщение — то, что отправил сам покупатель (User).
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final senderType = ChatSenderType.values[(json['senderType'] as num?)?.toInt() ?? 0];
    return ChatMessage(
      id: json['id'] as String,
      text: json['text'] as String? ?? '',
      isMine: senderType == ChatSenderType.user,
      createdAt: DateTime.parse(json['sentAt'] as String),
    );
  }
}
