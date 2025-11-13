import 'package:flutter/material.dart';

/// Widget to display star ratings (1-5 stars with half-star support)
class StarRating extends StatelessWidget {
  final double rating; // 1.0 to 5.0, supports half stars
  final double size;
  final Color? color;
  final bool showLabel;

  const StarRating({
    super.key,
    required this.rating,
    this.size = 16,
    this.color,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Colors.amber;
    final clampedRating = rating.clamp(0.0, 5.0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          final starValue = index + 1;
          if (clampedRating >= starValue) {
            // Full star
            return Icon(
              Icons.star,
              size: size,
              color: effectiveColor,
            );
          } else if (clampedRating >= starValue - 0.5) {
            // Half star
            return Icon(
              Icons.star_half,
              size: size,
              color: effectiveColor,
            );
          } else {
            // Empty star
            return Icon(
              Icons.star_border,
              size: size,
              color: effectiveColor.withValues(alpha: 0.3),
            );
          }
        }),
        if (showLabel) ...[
          const SizedBox(width: 4),
          Text(
            clampedRating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
