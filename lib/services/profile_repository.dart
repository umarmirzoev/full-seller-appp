import '../models/address.dart';
import '../models/app_user.dart';
import 'api_client.dart';

class ProfileRepository {
  ProfileRepository._();

  static Future<AppUser> getProfile() async => AppUser.fromJson(await ApiClient.instance.get('/profile') as Map<String, dynamic>);

  static Future<AppUser> updateProfile({String? fullName, String? language, bool? isLegalEntity, String? legalName, String? taxId}) async {
    final data = await ApiClient.instance.put('/profile', body: {
      'fullName': fullName,
      'language': language,
      'isLegalEntity': isLegalEntity,
      'legalName': legalName,
      'taxId': taxId,
    }) as Map<String, dynamic>;
    return AppUser.fromJson(data);
  }

  static Future<List<Address>> getAddresses() async {
    final data = await ApiClient.instance.get('/profile/addresses') as List<dynamic>;
    return data.map((e) => Address.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Address> createAddress({required DeliveryCountry country, required String city, required String line}) async {
    final data = await ApiClient.instance.post('/profile/addresses', body: {'country': country.index, 'city': city, 'line': line}) as Map<String, dynamic>;
    return Address.fromJson(data);
  }

  static Future<void> setDefaultAddress(String id) async {
    await ApiClient.instance.put('/profile/addresses/$id/default');
  }
}
