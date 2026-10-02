import '../models/app_banner.dart';
import 'api_client.dart';

class BannersRepository {
  BannersRepository._();

  static Future<List<AppBanner>> getActive() async {
    final data = await ApiClient.instance.get('/banners', auth: false) as List<dynamic>;
    return data.map((e) => AppBanner.fromJson(e as Map<String, dynamic>)).toList();
  }
}
