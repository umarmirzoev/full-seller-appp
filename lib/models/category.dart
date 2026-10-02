class Category {
  final String id;
  final String name;
  final String slug;
  final String? parentCategoryId;
  final String iconName;

  const Category({
    required this.id,
    required this.name,
    required this.slug,
    this.parentCategoryId,
    this.iconName = 'box',
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        name: json['name'] as String,
        slug: json['slug'] as String? ?? '',
        parentCategoryId: json['parentCategoryId'] as String?,
      );
}
