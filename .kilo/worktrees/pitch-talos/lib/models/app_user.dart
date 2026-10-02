enum UserRole { customer, legalCustomer, manager, admin, superAdmin }

class AppUser {
  final String id;
  final String phone;
  final String fullName;
  final bool isLegalEntity;
  final String? legalName;
  final int loyaltyPoints;
  final UserRole role;

  const AppUser({
    required this.id,
    required this.phone,
    required this.fullName,
    this.isLegalEntity = false,
    this.legalName,
    this.loyaltyPoints = 0,
    this.role = UserRole.customer,
  });

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    return parts.length > 1 ? '${parts[0][0]}${parts[1][0]}' : parts[0][0];
  }
}
