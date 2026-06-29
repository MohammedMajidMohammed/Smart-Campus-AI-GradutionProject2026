import 'package:flutter/material.dart';
import 'package:smart_canvas/core/utilies/assets/images/app_images.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';

class WaveImage extends StatelessWidget {
  final Color? color;
  const WaveImage({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -SizeConfig.height * 0.15,
      left: -SizeConfig.width * 0.6,
      child: Image.asset(
        AppImages.waveBackgroundImage,
        height: SizeConfig.height * 0.4,
        opacity: const AlwaysStoppedAnimation(0.3),
        color: color,
      ),
    );
  }
}
