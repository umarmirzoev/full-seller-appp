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

  factory AppBanner.fromJson(Map<String, dynamic> json) => AppBanner(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        subtitle: json['subtitle'] as String?,
        imageUrl: json['imageUrl'] as String?,
        linkUrl: json['linkUrl'] as String?,
        sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
        isActive: json['isActive'] as bool? ?? true,
      );
}
