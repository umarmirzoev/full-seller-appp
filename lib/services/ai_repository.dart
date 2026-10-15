import 'api_client.dart';

class AiReply {
  final String text;
  final List<String> productIds;
  const AiReply(this.text, this.productIds);
}

/// FULL AI на сервере: POST /ai/chat {messages:[{role, content}]} → {reply, productIds}.
class AiRepository {
  AiRepository._();

  static Future<AiReply> chat(List<Map<String, String>> messages) async {
    final data = await ApiClient.instance.post('/ai/chat', body: {'messages': messages}, auth: false) as Map<String, dynamic>;
    return AiReply(
      data['reply'] as String? ?? '',
      (data['productIds'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(),
    );
  }
}
