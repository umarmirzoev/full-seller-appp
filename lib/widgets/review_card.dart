import 'package:flutter/material.dart';
import '../models/review.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';
import 'star_rating.dart';

class ReviewCard extends StatelessWidget {
  final Review review;
  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderSoft),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          CircleAvatar(radius: 14, backgroundColor: AppColors.g100,
              child: Text(review.userName.isNotEmpty ? review.userName[0] : '?', style: AppTextStyles.display(size: 11, color: AppColors.primaryDark))),
          const SizedBox(width: 8),
          Expanded(child: Text(review.userName, style: AppTextStyles.body(size: 12, weight: FontWeight.w800), overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 8),
        StarRating(rating: review.rating.toDouble(), size: 12),
        const SizedBox(height: 6),
        Text(review.comment, maxLines: 3, overflow: TextOverflow.ellipsis, style: AppTextStyles.body(size: 12, color: AppColors.text2)),
      ]),
    );
  }
}
