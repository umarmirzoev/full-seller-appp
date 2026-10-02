import '../models/review.dart';
import 'api_client.dart';

class ReviewsRepository {
  ReviewsRepository._();

  static Future<List<Review>> getByProduct(String productId) async {
    final data = await ApiClient.instance.get('/reviews/product/$productId', auth: false) as List<dynamic>;
    return data.map((e) => Review.fromJson(e as Map<String, dynamic>)).toList();
  }
}
