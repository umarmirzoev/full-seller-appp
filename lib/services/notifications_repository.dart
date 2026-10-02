import '../models/app_notification.dart';
import 'api_client.dart';

class NotificationsRepository {
  NotificationsRepository._();

  static Future<List<AppNotification>> getMy() async {
    final data = await ApiClient.instance.get('/notifications') as List<dynamic>;
    return data.map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> markRead(String id) async {
    await ApiClient.instance.put('/notifications/$id/read');
  }
}
