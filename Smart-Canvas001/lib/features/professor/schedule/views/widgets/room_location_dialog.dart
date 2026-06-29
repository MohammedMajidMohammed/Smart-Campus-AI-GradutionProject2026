import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smart_canvas/features/administrator/rooms/models/room_model.dart';
import 'package:smart_canvas/core/utilies/colors/app_colors.dart';
import 'package:smart_canvas/core/utilies/sizes/sized_config.dart';
import 'package:smart_canvas/core/utilies/map_utils.dart';

class RoomLocationDialog extends StatelessWidget {
  final RoomModel room;

  const RoomLocationDialog({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    // Default to Cairo if no coordinates (or handle null gracefully)
    final initialPos = (room.mapX != null && room.mapY != null)
        ? LatLng(room.mapX!, room.mapY!)
        : const LatLng(30.0444, 31.2357);

    final Set<Marker> markers = (room.mapX != null && room.mapY != null)
        ? {
            Marker(
              markerId: MarkerId(room.id),
              position: initialPos,
              infoWindow: InfoWindow(title: room.name),
            )
          }
        : {};

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBgColor = isDark ? const Color(0xFF1E1B15) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E1B15);
    final subtitleColor = isDark ? Colors.white60 : Colors.grey.shade600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: dialogBgColor,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: SizeConfig.height * 0.55,
        width: double.infinity,
        child: Stack(
          children: [
            Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: dialogBgColor,
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? Colors.white12 : Colors.grey.shade100,
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.kPrimaryColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.meeting_room_rounded,
                          color: AppColors.kPrimaryColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              room.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            Text(
                              "Menoufia National University",
                              style: TextStyle(
                                fontSize: 11,
                                color: subtitleColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: subtitleColor, size: 22),
                        onPressed: () => Navigator.pop(context),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
                // Map
                Expanded(
                  child: ClipRRect(
                    child: room.mapX == null || room.mapY == null
                        ? Center(
                            child: Text(
                              "Location not available",
                              style: TextStyle(color: subtitleColor, fontSize: 14),
                            ),
                          )
                        : GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: initialPos,
                              zoom: 16,
                            ),
                            markers: markers,
                            myLocationEnabled: true,
                            myLocationButtonEnabled: false, // Turn off default button to keep it clean
                            zoomControlsEnabled: true,
                          ),
                  ),
                ),
              ],
            ),
            if (room.mapX != null && room.mapY != null)
              Positioned(
                bottom: 20,
                left: 24,
                right: 24,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.kPrimaryColor.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () {
                        MapUtils.openMap(room.mapX!, room.mapY!);
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.near_me_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Get Directions",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
