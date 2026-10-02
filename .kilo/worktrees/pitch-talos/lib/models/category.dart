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
}
