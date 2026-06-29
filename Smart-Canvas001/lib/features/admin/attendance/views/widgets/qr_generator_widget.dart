import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:smart_canvas/core/components/glass_box.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';

class QrGeneratorWidget extends StatelessWidget {
  final String data;
  final double size;

  const QrGeneratorWidget({
    super.key,
    required this.data,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    return GlassBox(
      color: Colors.white,
      borderOpacity: 0.5,
      borderRadius: 20,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: data,
              version: QrVersions.auto,
              size: size,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: AppColors.kPrimaryColor,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: AppColors.kPrimaryColor,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Scan to check-in",
              style: TextStyle(
                color: AppColors.kPrimaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
