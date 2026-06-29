import 'package:flutter/material.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';

class CollageImage extends StatelessWidget {
  const CollageImage({
    super.key,
    required this.collageImage,
  });

  final String collageImage;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: SizeConfig.width * 0.05,
      child: CircleAvatar(
        radius: SizeConfig.width * 0.11,
        backgroundColor: Colors.white,
        child: CircleAvatar(
          radius: SizeConfig.width * 0.11 - 3,
          backgroundImage: NetworkImage(collageImage),
        ),
      ),
    );
  }
}
