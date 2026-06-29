import 'package:flutter/material.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/core/utilies/styles/app_text_styles.dart';

class CollageReview extends StatelessWidget {
  const CollageReview({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ...List.generate(
          4,
          (index) => Icon(
            Icons.star,
            size: SizeConfig.width * 0.035,
            color: Colors.amber,
          ),
        ),
        SizedBox(width: SizeConfig.width * 0.01),
        Text(
          '4.0 (120 reviews)',
          style: AppTextStyles.title12WhiteW500,
        ),
      ],
    );
  }
}
