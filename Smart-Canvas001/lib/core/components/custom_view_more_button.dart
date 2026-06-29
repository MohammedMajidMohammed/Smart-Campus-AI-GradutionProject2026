import 'package:flutter/material.dart';

class ViewMoreButton extends StatelessWidget {
  final String title;
  final VoidCallback onViewMoreTapped;
  final Color? titleColor;
  final Color? viewMoreColor;
  final double? titleFontSize;
  final double? viewMoreFontSize;
  final FontWeight? titleFontWeight;
  final FontWeight? viewMoreFontWeight;

  const ViewMoreButton({
    super.key,
    required this.title,
    required this.onViewMoreTapped,
    this.titleColor = Colors.black,
    this.viewMoreColor = Colors.black,
    this.titleFontSize = 18,
    this.viewMoreFontSize = 14,
    this.titleFontWeight = FontWeight.bold,
    this.viewMoreFontWeight = FontWeight.w500,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: titleFontWeight,
            color: titleColor,
          ),
        ),
        GestureDetector(
          onTap: onViewMoreTapped,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View More',
                  style: TextStyle(
                    fontSize: viewMoreFontSize,
                    color: viewMoreColor,
                    fontWeight: viewMoreFontWeight,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: viewMoreColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
