import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/core/components/custom_icon_button.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/features/administrator/collages/view_models/cubit/add_college_cubit.dart';

class CollegeImage extends StatelessWidget {
  const CollegeImage({super.key});

  @override
  Widget build(BuildContext context) {
    var cubit = context.read<AddCollegeCubit>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'College Image', 
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              clipBehavior: Clip.antiAlias,
              height: SizeConfig.height * 0.18,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1B15) : AppColors.kPrimaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white10 : AppColors.kPrimaryColor.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
              child: BlocBuilder<AddCollegeCubit, AddCollegeState>(
                builder: (context, state) {
                  if (cubit.collegeImageFile != null) {
                    return Image.file(
                       cubit.collegeImageFile!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    );
                  } else if (cubit.existingImageUrl != null) {
                    return Image.network(
                      cubit.existingImageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        log("Error loading network image: $error");
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image_outlined, color: AppColors.kPrimaryColor, size: 40),
                              SizedBox(height: 4),
                              Text("Image error", style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        );
                      },
                    );
                  } else {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            color: isDark ? Colors.white54 : AppColors.kPrimaryColor.withValues(alpha: 0.7),
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Upload college image',
                            style: TextStyle(
                              color: isDark ? Colors.white60 : AppColors.kPrimaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Support JPG, PNG format',
                            style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.grey[500],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: CustomIconButton(
                backgroundColor: AppColors.kPrimaryColor,
                iconColor: Colors.white,
                icon: Icons.camera_alt_outlined,
                iconSize: 22,
                onPressed: () {
                  cubit.pickCollegeImage();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
