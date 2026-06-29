import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smart_canvas/core/app_route/route_names.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/features/administrator/buildings/models/building_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_canvas/features/administrator/buildings/view_models/cubit/add_building_cubit.dart';
import 'package:smart_canvas/features/administrator/buildings/view_models/cubit/buildings_cubit.dart';
import 'package:smart_canvas/features/administrator/buildings/views/widgets/add_building_modal_bottom_sheet_body.dart';
import 'package:smart_canvas/features/student/navigation/views/screens/navigation_screen.dart';

class BuildingCard extends StatelessWidget {
  final BuildingModel building;
  final bool canEdit;
  const BuildingCard({super.key, required this.building, this.canEdit = false});

  void _openEditModal(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) => BlocProvider(
        create: (context) => AddBuildingCubit()..initEdit(building),
        child: const AddBuildingModalBottomSheetBody(),
      ),
    ).then((value) {
      if (context.mounted) {
        context.read<BuildingsCubit>().getBuildings();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final String collegeName = building.collegeModel?.name ?? 'General Facility';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B15).withValues(alpha: 0.7) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            offset: const Offset(0, 8),
            blurRadius: 15,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(
                context,
                RouteNames.roomsScreen,
                arguments: building.id,
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _buildArtisticImage(building.image, building.id),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopRow(context, building.buildingType),
                        const SizedBox(height: 6),
                        Text(
                          building.name,
                          style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF0F0E0A),
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        _buildCollegeInfo(collegeName),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _buildInfoChip(Icons.meeting_room_outlined, "Lobbies", isDark),
                                  _buildInfoChip(Icons.layers_outlined, "Floor 2", isDark),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (canEdit) _buildActionIcon(context, isDark),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArtisticImage(String imageUrl, dynamic id) {
    return Stack(
      children: [
        Hero(
          tag: id,
          child: Container(
            height: 90, width: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade100,
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.kPrimaryColor.withValues(alpha: 0.08),
                        child: const Icon(Icons.apartment_rounded, size: 36, color: AppColors.kPrimaryColor),
                      ),
                    )
                  : Container(
                      color: AppColors.kPrimaryColor.withValues(alpha: 0.08),
                      child: const Icon(Icons.apartment_rounded, size: 36, color: AppColors.kPrimaryColor),
                    ),
            ),
          ),
        ),
        Positioned(
          top: 4, right: 4,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                )
              ]
            ),
            child: Icon(Icons.star_rounded, size: 12, color: Colors.amber[700]),
          ).animate().shimmer(),
        ),
      ],
    );
  }

  Widget _buildTopRow(BuildContext context, BuildingType type) {
    final colors = _getBuildingTypeColors(type);
    final icon = _getBuildingTypeIcon(type);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: colors[0].withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: colors[0].withValues(alpha: 0.2), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 10, color: colors[0]),
              const SizedBox(width: 4),
              Text(
                type.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 9, fontWeight: FontWeight.w900,
                  color: colors[0], letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NavigationScreen(
                  destLat: building.latitude,
                  destLng: building.longitude,
                  destName: building.name,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E8449).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.directions_outlined, size: 16, color: Color(0xFF1E8449)),
          ),
        ),
      ],
    );
  }

  Widget _buildCollegeInfo(String collegeName) {
    return Row(
      children: [
        const Icon(Icons.apartment_rounded, size: 12, color: Color(0xFF1E8449)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            collegeName,
            style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.grey.shade500),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () => _openEditModal(context),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E8449).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF1E8449).withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: const Icon(Icons.edit_note_rounded, color: Color(0xFF1E8449), size: 18),
      ),
    );
  }

  IconData _getBuildingTypeIcon(BuildingType type) {
    switch (type) {
      case BuildingType.admin:
        return Icons.admin_panel_settings_rounded;
      case BuildingType.educational:
        return Icons.school_rounded;
      case BuildingType.lab:
        return Icons.science_rounded;
    }
  }

  List<Color> _getBuildingTypeColors(BuildingType type) {
    switch (type) {
      case BuildingType.admin:
        return [const Color(0xFF2ECC71), const Color(0xFF1E8449)];
      case BuildingType.educational:
        return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
      case BuildingType.lab:
        return [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)];
    }
  }
}
