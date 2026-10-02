import '../models/brand.dart';
import '../models/category.dart';
import '../models/product.dart';
import 'api_client.dart';

class ProductPage {
  final List<Product> items;
  final int totalCount;
  final int page;
  final int pageSize;
  const ProductPage({required this.items, required this.totalCount, required this.page, required this.pageSize});
  bool get hasMore => page * pageSize < totalCount;
}

class CatalogRepository {
  CatalogRepository._();

  static List<Brand>? _brandsCache;

  static Future<List<Category>> getCategories() async {
    final data = await ApiClient.instance.get('/catalog/categories', auth: false) as List<dynamic>;
    return data.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<Brand>> getBrands({bool forceRefresh = false}) async {
    if (_brandsCache != null && !forceRefresh) return _brandsCache!;
    final data = await ApiClient.instance.get('/catalog/brands', auth: false) as List<dynamic>;
    _brandsCache = data.map((e) => Brand.fromJson(e as Map<String, dynamic>)).toList();
    return _brandsCache!;
  }

  static String? _resolveBrandName(String? brandId, List<Brand> brands) {
    if (brandId == null) return null;
    for (final b in brands) {
      if (b.id == brandId) return b.name;
    }
    return null;
  }

  static Future<ProductPage> getProducts({
    String? categoryId,
    String? brandId,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
    int page = 1,
    int pageSize = 20,
  }) async {
    final brands = await getBrands();
    final data = await ApiClient.instance.get('/catalog/products', auth: false, query: {
      'categoryId': categoryId,
      'brandId': brandId,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'sortBy': sortBy,
      'page': page,
      'pageSize': pageSize,
    }) as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>).map((raw) {
      final map = raw as Map<String, dynamic>;
      return Product.fromListItemJson(map, brandName: _resolveBrandName(map['brandId'] as String?, brands));
    }).toList();
    return ProductPage(items: items, totalCount: data['totalCount'] as int, page: data['page'] as int, pageSize: data['pageSize'] as int);
  }

  static Future<ProductPage> search(String query, {int page = 1, int pageSize = 20}) async {
    final brands = await getBrands();
    final data = await ApiClient.instance.get('/catalog/search', auth: false, query: {'q': query, 'page': page, 'pageSize': pageSize}) as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>).map((raw) {
      final map = raw as Map<String, dynamic>;
      return Product.fromListItemJson(map, brandName: _resolveBrandName(map['brandId'] as String?, brands));
    }).toList();
    return ProductPage(items: items, totalCount: data['totalCount'] as int, page: data['page'] as int, pageSize: data['pageSize'] as int);
  }

  static Future<Product> getProduct(String id) async {
    final brands = await getBrands();
    final data = await ApiClient.instance.get('/catalog/products/$id', auth: false) as Map<String, dynamic>;
    return Product.fromDetailsJson(data, brandName: _resolveBrandName(data['brandId'] as String?, brands));
  }
}
