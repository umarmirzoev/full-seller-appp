/// 1:1 с backend NotificationType (OrderStatusChanged=0, NewMessage=1, BonusAccrued=2,
/// BackInStock=3, ReviewRequest=4, Promo=5). Порядок значений важен — совпадает с числом от API.
enum NotificationType { orderStatusChanged, newMessage, bonusAccrued, backInStock, reviewRequest, promo }

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String,
        type: NotificationType.values[(json['type'] as num?)?.toInt() ?? 0],
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
        isRead: json['isRead'] as bool? ?? false,
      );
}
