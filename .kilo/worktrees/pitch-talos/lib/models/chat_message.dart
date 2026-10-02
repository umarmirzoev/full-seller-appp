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
}
