import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/features/administrator/buildings/view_models/cubit/add_building_cubit.dart';
import 'package:line_icons/line_icons.dart';

class BuildingImage extends StatelessWidget {
  const BuildingImage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AddBuildingCubit>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Building Image', 
          style: TextStyle(
            fontSize: 16, 
            fontWeight: FontWeight.w800, 
            color: isDark ? Colors.white : const Color(0xFF1E1B15),
          ),
        ),
        const SizedBox(height: 12),
        BlocBuilder<AddBuildingCubit, AddBuildingState>(
          buildWhen: (previous, current) => current is PickImageSuccess || current is PickImageError,
          builder: (context, state) {
            final hasImage = cubit.buildingImage != null;
            
            return GestureDetector(
              onTap: () => cubit.pickBuildingImage(),
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: hasImage
                      ? Image.file(cubit.buildingImage!, fit: BoxFit.cover)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E8449).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(LineIcons.image, color: Color(0xFF1E8449), size: 32),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Click to upload building photo',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white54 : Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Supports JPG, PNG up to 5MB',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white24 : Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
