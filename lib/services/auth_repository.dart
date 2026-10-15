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

  static Future<void> _saveTokens(Map<String, dynamic> data) => TokenStorage.save(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
        expiresAt: DateTime.parse(data['accessTokenExpiresAt'] as String),
      );

  /// Вход по номеру и паролю. POST /auth/login {phone, password}
  static Future<void> login(String phone, String password) async {
    final data = await ApiClient.instance.post('/auth/login', body: {'phone': phone, 'password': password}, auth: false) as Map<String, dynamic>;
    await _saveTokens(data);
  }

  /// Регистрация: номер + пароль. POST /auth/register {phone, password}
  static Future<void> register(String phone, String password) async {
    final data = await ApiClient.instance.post('/auth/register', body: {'phone': phone, 'password': password}, auth: false) as Map<String, dynamic>;
    await _saveTokens(data);
  }

  /// Забыли пароль: получить ссылку на Telegram-бота, который пришлёт код.
  /// POST /auth/password/forgot-telegram {phone} → {url, bot}
  static Future<String> forgotPasswordTelegram(String phone) async {
    final data = await ApiClient.instance.post('/auth/password/forgot-telegram', body: {'phone': phone}, auth: false) as Map<String, dynamic>;
    return data['url'] as String;
  }

  /// Сброс пароля по коду (из Telegram или SMS) и сразу вход. POST /auth/password/reset {phone, code, password}
  static Future<void> resetPassword(String phone, String code, String password) async {
    final data = await ApiClient.instance.post('/auth/password/reset', body: {'phone': phone, 'code': code, 'password': password}, auth: false) as Map<String, dynamic>;
    await _saveTokens(data);
  }

  static Future<bool> isLoggedIn() => TokenStorage.hasToken();

  static Future<void> logout() => TokenStorage.clear();
}
