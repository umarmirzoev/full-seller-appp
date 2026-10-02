/// 1:1 с backend ReviewStatus (Pending=0, Approved=1, Rejected=2).
enum ReviewStatus { pending, approved, rejected }

/// Примечание: backend ReviewDto отдаёт только UserId (без имени/аватара) — публичного
/// эндпоинта профилей других пользователей нет, поэтому userName для отзывов из реального API
/// собирается как короткая подпись по UserId, а не настоящее имя покупателя.
class Review {
  final String id;
  final String productId;
  final String userName;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final ReviewStatus status;

  const Review({
    required this.id,
    required this.productId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.status = ReviewStatus.approved,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    final userId = json['userId'] as String? ?? '';
    return Review(
      id: json['id'] as String,
      productId: json['productId'] as String,
      userName: userId.length >= 6 ? 'Покупатель #${userId.substring(0, 6)}' : 'Покупатель',
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      comment: json['text'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: ReviewStatus.values[(json['status'] as num?)?.toInt() ?? 1],
    );
  }
}
