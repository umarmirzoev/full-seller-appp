import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/admin/admin_card.dart';
import '../../widgets/admin/admin_sidebar.dart';
import '../../widgets/admin/admin_top_bar.dart';

class _AdminReview {
  final String productName;
  final String userName;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final bool published;
  const _AdminReview({required this.productName, required this.userName, required this.rating, required this.comment, required this.createdAt, required this.published});
}

class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen> {
  String _filter = 'all';
  late final List<_AdminReview> _reviews = () {
    final result = <_AdminReview>[];
    for (var i = 0; i < MockData.products.length; i++) {
      final p = MockData.products[i];
      final reviews = MockData.reviewsFor(p.id);
      for (var j = 0; j < reviews.length; j++) {
        result.add(_AdminReview(
          productName: p.name,
          userName: reviews[j].userName,
          rating: reviews[j].rating,
          comment: reviews[j].comment,
          createdAt: reviews[j].createdAt,
          published: (i + j) % 3 != 0,
        ));
      }
    }
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }();

  @override
  Widget build(BuildContext context) {
    final reviews = _reviews.where((r) => _filter == 'all' || (_filter == 'published') == r.published).toList();
    final avgRating = _reviews.isEmpty ? 0.0 : _reviews.fold(0, (sum, r) => sum + r.rating) / _reviews.length;
    final pendingCount = _reviews.where((r) => !r.published).length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Row(children: [
        const AdminSidebar(active: 'Отзывы'),
        Expanded(
          child: Column(children: [
            const AdminTopBar(title: 'Отзывы'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    _statChip(Icons.star_rounded, AppColors.star, avgRating.toStringAsFixed(1), 'Средний рейтинг'),
                    const SizedBox(width: 14),
                    _statChip(Icons.reviews_outlined, AppColors.primaryDark, '${_reviews.length}', 'Всего отзывов'),
                    const SizedBox(width: 14),
                    _statChip(Icons.hourglass_bottom_rounded, const Color(0xFF9A5B12), '$pendingCount', 'Ожидают модерации'),
                  ]),
                  const SizedBox(height: 20),
                  Wrap(spacing: 8, children: [
                    _chip('Все', _filter == 'all', () => setState(() => _filter = 'all')),
                    _chip('Опубликованные', _filter == 'published', () => setState(() => _filter = 'published')),
                    _chip('На модерации', _filter == 'pending', () => setState(() => _filter = 'pending')),
                  ]),
                  const SizedBox(height: 16),
                  AdminCard(
                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 6),
                    child: Column(
                      children: reviews.map((r) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderSoft))),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            CircleAvatar(radius: 17, backgroundColor: AppColors.g100,
                                child: Text(r.userName.isNotEmpty ? r.userName[0] : '?', style: AppTextStyles.display(size: 12, color: AppColors.primaryDark))),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Text(r.userName, style: AppTextStyles.body(size: 13, weight: FontWeight.w700)),
                                  const SizedBox(width: 8),
                                  Row(children: List.generate(5, (i) => Icon(i < r.rating ? Icons.star_rounded : Icons.star_border_rounded, size: 13, color: AppColors.star))),
                                ]),
                                const SizedBox(height: 2),
                                Text(r.productName, style: AppTextStyles.body(size: 11, weight: FontWeight.w600, color: AppColors.text3)),
                                const SizedBox(height: 6),
                                Text(r.comment, style: AppTextStyles.body(size: 12.5, color: AppColors.text2)),
                              ]),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: r.published ? const Color(0xFFE9F9EE) : const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(r.published ? 'Опубликован' : 'На модерации',
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: r.published ? const Color(0xFF15803D) : const Color(0xFF9A5B12))),
                            ),
                          ]),
                        );
                      }).toList(),
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _statChip(IconData icon, Color color, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.borderSoft), borderRadius: BorderRadius.circular(AppRadius.lg)),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: AppTextStyles.display(size: 17)),
            Text(label, style: AppTextStyles.body(size: 10.5, weight: FontWeight.w600, color: AppColors.text3)),
          ]),
        ]),
      ),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surface,
          border: Border.all(color: active ? AppColors.primary : AppColors.border),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: active ? Colors.white : AppColors.text2)),
      ),
    );
  }
}
