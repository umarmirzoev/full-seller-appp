/// Рекламный баннер главной страницы (не путать с material Banner-виджетом).
class AppBanner {
  final String id;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? linkUrl;
  final int sortOrder;
  final bool isActive;

  const AppBanner({
    required this.id,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.linkUrl,
    this.sortOrder = 0,
    this.isActive = true,
  });
}
