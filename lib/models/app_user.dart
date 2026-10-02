enum UserRole { customer, legalCustomer, manager, admin, superAdmin }

class AppUser {
  final String id;
  final String phone;
  final String fullName;
  final bool isLegalEntity;
  final String? legalName;
  final String? taxId;
  final int loyaltyPoints;
  final String language;
  final String preferredCurrency;
  final UserRole role;

  const AppUser({
    required this.id,
    required this.phone,
    required this.fullName,
    this.isLegalEntity = false,
    this.legalName,
    this.taxId,
    this.loyaltyPoints = 0,
    this.language = 'ru',
    this.preferredCurrency = 'RUB',
    this.role = UserRole.customer,
  });

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    return parts.length > 1 ? '${parts[0][0]}${parts[1][0]}' : parts[0][0];
  }

  /// ProfileDto не отдаёт роль пользователя — по умолчанию customer.
  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        phone: json['phone'] as String? ?? '',
        fullName: json['fullName'] as String? ?? '',
        isLegalEntity: json['isLegalEntity'] as bool? ?? false,
        legalName: json['legalName'] as String?,
        taxId: json['taxId'] as String?,
        loyaltyPoints: (json['loyaltyPoints'] as num?)?.toInt() ?? 0,
        language: json['language'] as String? ?? 'ru',
        preferredCurrency: json['preferredCurrency'] as String? ?? 'RUB',
      );
}
