/// 6 статусов заказа (ТЗ FULL SELLER 2.0 → раздел «Статусы заказа»).
enum OrderStatus { novyy, podtverzhden, vObrabotke, otpravlen, zavershen, otmenen }

extension OrderStatusX on OrderStatus {
  String get label => switch (this) {
        OrderStatus.novyy => 'Новый',
        OrderStatus.podtverzhden => 'Подтверждён',
        OrderStatus.vObrabotke => 'В обработке',
        OrderStatus.otpravlen => 'Отправлен',
        OrderStatus.zavershen => 'Завершён',
        OrderStatus.otmenen => 'Отменён',
      };
}

class OrderItem {
  final String productId;
  final String productName;
  final String imageUrl;
  final int quantity;
  final double unitPrice;

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.quantity,
    required this.unitPrice,
  });
}

class Order {
  final String id;
  final String orderNumber;
  final OrderStatus status;
  final double totalAmount;
  final double deliveryCost;
  final String? cargoTrackingNumber;
  final DateTime createdAt;
  final List<OrderItem> items;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.totalAmount,
    required this.deliveryCost,
    this.cargoTrackingNumber,
    required this.createdAt,
    this.items = const [],
  });

  int get itemsCount => items.fold(0, (sum, i) => sum + i.quantity);
}
