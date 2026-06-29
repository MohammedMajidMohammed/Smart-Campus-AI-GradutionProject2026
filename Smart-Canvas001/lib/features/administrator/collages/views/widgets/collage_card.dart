import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/features/administrator/collages/models/collage_model.dart';

class CollageCard extends StatelessWidget {
  const CollageCard({super.key, required this.collage});
  final CollegeModel collage;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B15).withValues(alpha: 0.7) : Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.kPrimaryColor.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Stack(
          children: [
            // Background Accent Gradient
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.kPrimaryColor.withValues(alpha: isDark ? 0.05 : 0.12),
                      AppColors.kPrimaryColor.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Row(
                children: [
                  // College Logo with premium frame
                  Container(
                    width: SizeConfig.width * 0.2,
                    height: SizeConfig.width * 0.2,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A2720) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.kPrimaryColor.withValues(alpha: 0.1),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.kPrimaryColor.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: collage.image.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: collage.image,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.school_rounded, color: AppColors.kPrimaryColor, size: 30),
                            )
                          : const Icon(Icons.school_rounded, color: AppColors.kPrimaryColor, size: 30),
                    ),
                  ),
                  
                  SizedBox(width: SizeConfig.width * 0.04),
                  
                  // Text Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          collage.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F0E0A),
                            height: 1.2,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.kPrimaryColor.withValues(alpha: isDark ? 0.15 : 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.kPrimaryColor.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                collage.abbreviation,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.kPrimaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(Icons.star_rounded, color: Colors.amber[700], size: 14),
                            const SizedBox(width: 4),
                            Text(
                              "Active",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.grey.shade400 : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 11, color: isDark ? Colors.grey.shade500 : Colors.grey[400]),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat.yMMMd().format(collage.createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.grey.shade400 : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Action Arrow
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: isDark ? Colors.grey.shade600 : AppColors.kPrimaryColor.withValues(alpha: 0.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
