import 'api_client.dart';
import 'token_storage.dart';

class AuthRepository {
  AuthRepository._();

  static Future<void> requestOtp(String phone) async {
    await ApiClient.instance.post('/auth/otp/request', body: {'phone': phone}, auth: false);
  }

  static Future<void> confirmOtp(String phone, String code) async {
    final data = await ApiClient.instance.post('/auth/otp/confirm', body: {'phone': phone, 'code': code}, auth: false) as Map<String, dynamic>;
    await TokenStorage.save(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      expiresAt: DateTime.parse(data['accessTokenExpiresAt'] as String),
    );
  }

  static Future<bool> isLoggedIn() => TokenStorage.hasToken();

  static Future<void> logout() => TokenStorage.clear();
}
