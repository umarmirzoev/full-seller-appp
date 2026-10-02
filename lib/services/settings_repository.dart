import '../models/app_settings_data.dart';
import 'api_client.dart';

class SettingsRepository {
  SettingsRepository._();

  static Future<AppSettingsData> getSettings() async =>
      AppSettingsData.fromJson(await ApiClient.instance.get('/settings', auth: false) as Map<String, dynamic>);
}
