import '../models/chat_message.dart';
import 'api_client.dart';

class ChatRepository {
  ChatRepository._();

  static Future<List<ChatMessage>> getHistory() async {
    final data = await ApiClient.instance.get('/chat') as List<dynamic>;
    return data.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<ChatMessage> send(String text) async =>
      ChatMessage.fromJson(await ApiClient.instance.post('/chat', body: {'text': text, 'attachmentUrl': null}) as Map<String, dynamic>);
}
