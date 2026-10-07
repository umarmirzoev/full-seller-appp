/// Настройки подключения к backend (FullSeller.WebApi, ASP.NET Core + PostgreSQL).
class ApiConfig {
  ApiConfig._();

  /// Базовый адрес API (HTTPS, сертификат Let's Encrypt). nginx проксирует /api -> backend на 127.0.0.1:5228.
  /// Раньше использовался http://93.115.16.188/api, но после включения HTTPS nginx отдаёт на порту 80 по IP только 404.
  static const String baseUrl = 'https://api.full-seller.com/api';
}
