class Brand {
  final String id;
  final String name;
  final String? logoUrl;

  const Brand({required this.id, required this.name, this.logoUrl});

  factory Brand.fromJson(Map<String, dynamic> json) => Brand(
        id: json['id'] as String,
        name: json['name'] as String,
        logoUrl: json['logoUrl'] as String?,
      );
}
