/// Настройки подключения к backend (FullSeller.WebApi, ASP.NET Core + PostgreSQL).
class ApiConfig {
  ApiConfig._();

  /// Базовый адрес API.
  /// Продакшн-сервер (MVPS, 93.115.16.188): nginx на порту 80 проксирует /api -> backend на 127.0.0.1:5228.
  /// Если позже подключите домен и HTTPS — поменяйте этот адрес на https://ваш-домен/api и пересоберите приложение
  /// (flutter build web --release).
  static const String baseUrl = 'http://93.115.16.188/api';
}
