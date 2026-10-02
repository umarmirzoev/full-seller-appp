import 'address.dart';

/// 5 статусов заказа — 1:1 с backend OrderStatus (New=0, Processing=1, InTransit=2, Delivered=3, Cancelled=4).
/// Порядок значений важен: индекс enum-а совпадает с числом, которое присылает/ждёт API.
enum OrderStatus { novyy, vObrabotke, otpravlen, zavershen, otmenen }

extension OrderStatusX on OrderStatus {
  String get label => switch (this) {
        OrderStatus.novyy => 'Новый',
        OrderStatus.vObrabotke => 'В обработке',
        OrderStatus.otpravlen => 'Отправлен',
        OrderStatus.zavershen => 'Доставлен',
        OrderStatus.otmenen => 'Отменён',
      };
}

/// 1:1 с backend PaymentMethod (Card=0, Invoice=1).
enum PaymentMethod { card, invoice }

extension PaymentMethodX on PaymentMethod {
  String get label => this == PaymentMethod.card ? 'Оплата картой' : 'По счёту (юр. лицо)';
}

class OrderItem {
  final String productId;
  final String productName;
  final String imageUrl;
  final int quantity;
  final double unitPrice;
  final String? productVariantId;

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.quantity,
    required this.unitPrice,
    this.productVariantId,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        productId: (json['productId'] as String?) ?? '',
        productName: (json['productName'] as String?) ?? '—',
        imageUrl: '',
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
        productVariantId: json['productVariantId'] as String?,
      );
}

class OrderStatusEvent {
  final OrderStatus status;
  final String? comment;
  final DateTime changedAt;

  const OrderStatusEvent({required this.status, this.comment, required this.changedAt});

  factory OrderStatusEvent.fromJson(Map<String, dynamic> json) => OrderStatusEvent(
        status: OrderStatus.values[(json['status'] as num).toInt()],
        comment: json['comment'] as String?,
        changedAt: DateTime.parse(json['changedAt'] as String),
      );
}

class Order {
  final String id;
  final String orderNumber;
  final OrderStatus status;
  final DeliveryCountry deliveryCountry;
  final PaymentMethod paymentMethod;
  final double totalAmount;
  final double deliveryCost;
  final String? cargoTrackingNumber;
  final DateTime createdAt;
  final List<OrderItem> items;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    this.deliveryCountry = DeliveryCountry.tajikistan,
    this.paymentMethod = PaymentMethod.card,
    required this.totalAmount,
    required this.deliveryCost,
    this.cargoTrackingNumber,
    required this.createdAt,
    this.items = const [],
  });

  int get itemsCount => items.fold(0, (sum, i) => sum + i.quantity);

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as String,
        orderNumber: json['orderNumber'] as String,
        status: OrderStatus.values[(json['status'] as num).toInt()],
        deliveryCountry: DeliveryCountry.values[(json['deliveryCountry'] as num?)?.toInt() ?? 1],
        paymentMethod: PaymentMethod.values[(json['paymentMethod'] as num?)?.toInt() ?? 0],
        totalAmount: (json['totalAmount'] as num).toDouble(),
        deliveryCost: (json['deliveryCost'] as num?)?.toDouble() ?? 0,
        cargoTrackingNumber: json['cargoTrackingNumber'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        items: (json['items'] as List<dynamic>? ?? const [])
            .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
