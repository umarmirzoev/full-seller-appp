/// Поставщик каталога FULL SELLER (продавец опта — фабрика/цех/дистрибьютор).
enum SupplierStatus { active, moderation, blocked }

extension SupplierStatusX on SupplierStatus {
  String get label => switch (this) {
        SupplierStatus.active => 'Активен',
        SupplierStatus.moderation => 'На модерации',
        SupplierStatus.blocked => 'Заблокирован',
      };
}

class Supplier {
  final String id;
  final String companyName;
  final String contactName;
  final String phone;
  final String categoryName;
  final int productsCount;
  final double rating;
  final SupplierStatus status;
  final DateTime joinedAt;

  const Supplier({
    required this.id,
    required this.companyName,
    required this.contactName,
    required this.phone,
    required this.categoryName,
    this.productsCount = 0,
    this.rating = 0,
    this.status = SupplierStatus.active,
    required this.joinedAt,
  });

  String get initials {
    final parts = companyName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    return parts.length > 1 ? '${parts[0][0]}${parts[1][0]}' : parts[0][0];
  }
}
